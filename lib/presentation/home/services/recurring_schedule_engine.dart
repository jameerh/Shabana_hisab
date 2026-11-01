import 'package:drift/drift.dart';
import 'dart:convert';
import '../../../data/database/database.dart';
import '../models/dashboard_card.dart';
import 'dashboard_registry.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/date_utils.dart';

class RecurringScheduleEngine implements DashboardCardProvider {
  final AppDatabase database;
  
  static RecurringScheduleEngine? _instance;

  RecurringScheduleEngine._(this.database) {
    DashboardRegistry().registerProvider(this);
  }

  factory RecurringScheduleEngine(AppDatabase db) {
    if (_instance == null || _instance!.database != db) {
      _instance = RecurringScheduleEngine._(db);
    }
    return _instance!;
  }

  /// Analyzes all ACTIVE recurring rules where nextDueDate is <= Today.
  /// Generates a RecurringHistory entry for each due date and bumps nextDueDate cleanly to the first future occurrence.
  /// Wrapped in a transaction with idempotency checks and DB unique key guards.
  Future<void> processDueSchedules() async {
    final now = DateTime.now();
    final today = parseDateOnly(now);

    await database.transaction(() async {
      // Find all rules that are ACTIVE and due
      final dueRules = await (database.select(database.recurringRule)
            ..where((r) => r.status.equals('ACTIVE'))
            ..where((r) => r.nextDueDate.isSmallerOrEqualValue(today)))
          .get();

      for (final rule in dueRules) {
        var currentDue = parseDateOnly(rule.nextDueDate);

        while (!currentDue.isAfter(today)) {
          final statusStr = currentDue.isBefore(today) ? 'OVERDUE' : 'PENDING';

          // Idempotency check: verify if history record already exists for (ruleId, currentDue)
          final existing = await (database.select(database.recurringHistory)
                ..where((h) => h.ruleId.equals(rule.id) & h.dueDate.equals(currentDue)))
              .getSingleOrNull();

          if (existing == null) {
            try {
              await database.into(database.recurringHistory).insert(
                    RecurringHistoryCompanion.insert(
                      ruleId: rule.id,
                      dueDate: currentDue,
                      status: statusStr,
                    ),
                  );
            } catch (_) {
              // Ignore duplicate error caught by DB unique key (ruleId, dueDate)
            }
          }

          // Advance currentDue to next interval
          currentDue = calculateNextDueDate(
            currentDue,
            rule.frequency,
            rule.interval,
            monthRule: rule.monthRule,
            weekdays: rule.weekdays,
            requestedDay: rule.startDate.day,
          );
        }

        // Update the rule's next due date to the first future occurrence (> today)
        await (database.update(database.recurringRule)
              ..where((r) => r.id.equals(rule.id)))
            .write(
          RecurringRuleCompanion(
            nextDueDate: Value(currentDue),
            lastGenerated: Value(now),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  /// Provides due transactions as Recommendation Cards
  @override
  Future<List<DashboardCard>> getAvailableCards() async {
    final now = DateTime.now();
    final today = parseDateOnly(now);

    // Fetch all PENDING or OVERDUE or SNOOZED items due today or earlier
    final dueHistories = await (database.select(database.recurringHistory)
      ..where((h) => 
        (h.status.equals('PENDING') | h.status.equals('OVERDUE') | (h.status.equals('SNOOZED') & h.snoozeUntil.isSmallerOrEqualValue(today)))
      )
      ..where((h) => h.dueDate.isSmallerOrEqualValue(today))).get();

    List<DashboardCard> cards = [];

    if (dueHistories.isEmpty) return cards;

    if (dueHistories.length == 1) {
      final history = dueHistories.first;
      final rule = await (database.select(database.recurringRule)..where((r) => r.id.equals(history.ruleId))).getSingle();
      final isOverdue = history.dueDate.isBefore(today);
      
      cards.add(
        DashboardCard(
          id: 'recurring_due_${history.id}',
          title: isOverdue ? '⚠ Overdue: ${rule.title}' : '⚠ Due Today: ${rule.title}',
          subtitle: '₹${rule.defaultAmount.toStringAsFixed(2)} • Due: ${formatDateOnly(history.dueDate)}',
          score: isOverdue ? 99.0 : 95.0, // High priority
          actionLabel: 'Pay',
          secondaryActionLabel: 'Edit',
          tertiaryActionLabel: 'Snooze',
          moreActions: [
            const PopupMenuItem(value: 'skip', child: Text('Skip Once')),
            const PopupMenuItem(value: 'pause', child: Text('Pause Rule')),
            const PopupMenuItem(value: 'history', child: Text('View History')),
            const PopupMenuItem(value: 'delete', child: Text('Delete Rule', style: TextStyle(color: Colors.red))),
          ],
          onAction: () async {
            await markAsPaid(history.id);
          },
          onSecondaryAction: () {
            // Edit logic to be handled by UI
          },
          onTertiaryAction: () async {
            await snooze(history.id);
          },
          onMoreActionSelected: (value) async {
            if (value == 'skip') {
              await skip(history.id);
            } else if (value == 'pause') {
              await (database.update(database.recurringRule)..where((r) => r.id.equals(rule.id))).write(
                const RecurringRuleCompanion(status: Value('PAUSED'))
              );
            } else if (value == 'delete') {
              await (database.update(database.recurringRule)..where((r) => r.id.equals(rule.id))).write(
                const RecurringRuleCompanion(status: Value('DELETED'))
              );
            }
          },
          icon: Icons.event_repeat,
          color: Colors.red, // Red indicating due
        )
      );
    } else {
      // Aggregated Card
      List<String> titles = [];
      double totalAmount = 0;
      for (var history in dueHistories) {
        final rule = await (database.select(database.recurringRule)..where((r) => r.id.equals(history.ruleId))).getSingle();
        titles.add(rule.title);
        totalAmount += rule.defaultAmount;
      }
      
      String subtitle = titles.take(3).join('\n');
      if (titles.length > 3) {
        subtitle += '\n+${titles.length - 3} more';
      }

      cards.add(
        DashboardCard(
          id: 'recurring_due_aggregated',
          title: '⚠ ${dueHistories.length} Payments Due',
          subtitle: subtitle,
          score: 95.0, 
          actionLabel: 'Pay All (₹${totalAmount.toStringAsFixed(0)})',
          secondaryActionLabel: 'Pay Selected',
          onAction: () async {
            await payMultiple(dueHistories.map((e) => e.id).toList());
          },
          onSecondaryAction: () {
            // Will open a bottom sheet handled by UI router/dialog registry
          },
          icon: Icons.event_repeat,
          color: Colors.red, 
        )
      );
    }

    return cards;
  }

  Future<void> payMultiple(List<int> historyIds) async {
    for (var id in historyIds) {
      await markAsPaid(id);
    }
  }

  /// Marks a specific occurrence history record as SKIPPED.
  Future<void> skip(int historyId) async {
    final history = await (database.select(database.recurringHistory)..where((h) => h.id.equals(historyId))).getSingleOrNull();
    if (history == null || history.status == 'PAID') return;

    await (database.update(database.recurringHistory)..where((h) => h.id.equals(historyId))).write(
      RecurringHistoryCompanion(
        status: const Value('SKIPPED'),
        actionTaken: const Value('SKIP'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Snoozes a specific occurrence history record until [targetDate] (defaults to tomorrow).
  Future<void> snooze(int historyId, {DateTime? targetDate}) async {
    final history = await (database.select(database.recurringHistory)..where((h) => h.id.equals(historyId))).getSingleOrNull();
    if (history == null || history.status == 'PAID') return;

    final snoozeDate = targetDate ?? parseDateOnly(DateTime.now().add(const Duration(days: 1)));
    await (database.update(database.recurringHistory)..where((h) => h.id.equals(historyId))).write(
      RecurringHistoryCompanion(
        status: const Value('SNOOZED'),
        actionTaken: const Value('SNOOZE'),
        snoozeUntil: Value(snoozeDate),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Explicitly marks a recurring history item as PAID and creates a Hisaab transaction.
  /// Enforces 1-to-1 idempotency (if already paid or transaction linked, returns early).
  /// Atomic execution inside database.transaction().
  Future<void> markAsPaid(int historyId) async {
    final now = DateTime.now();

    await database.transaction(() async {
      final history = await (database.select(database.recurringHistory)..where((h) => h.id.equals(historyId))).getSingleOrNull();
      if (history == null || history.status == 'PAID' || history.transactionId != null) {
        return; // 1-to-1 Pay Idempotency Guard
      }

      final rule = await (database.select(database.recurringRule)..where((r) => r.id.equals(history.ruleId))).getSingle();

      // 1. Create transaction with full metadata mapping
      final metadataMap = {
        'recurringHistoryId': history.id,
        'recurringRuleId': rule.id,
      };

      final newTxId = await database.into(database.transactions).insert(
        TransactionsCompanion.insert(
          amount: history.amount ?? rule.defaultAmount,
          partyName: rule.title,
          type: 'Expense',
          profileId: rule.profileId,
          timestamp: now,
          metadata: Value(jsonEncode(metadataMap)),
        ),
      );

      // 2. Update Recurring History status
      await (database.update(database.recurringHistory)..where((h) => h.id.equals(history.id))).write(
        RecurringHistoryCompanion(
          status: const Value('PAID'),
          actionTaken: const Value('PAY'),
          transactionId: Value(newTxId),
          amount: Value(history.amount ?? rule.defaultAmount),
          completedAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // 3. Update Rule lastCompleted timestamp
      await (database.update(database.recurringRule)..where((r) => r.id.equals(rule.id))).write(
        RecurringRuleCompanion(
          lastCompleted: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
  }

  static DateTime calculateNextDueDate(
    DateTime currentDue,
    String frequency,
    int interval, {
    String? monthRule,
    String? weekdays,
    int? requestedDay,
  }) {
    if (frequency == 'DAILY') {
      return shiftCalendarDay(currentDue, interval);
    } else if (frequency == 'WEEKLY') {
      return shiftCalendarDay(currentDue, 7 * interval);
    } else if (frequency == 'MONTHLY') {
      final reqDay = requestedDay ?? (monthRule != null ? int.tryParse(monthRule) : null) ?? currentDue.day;
      return shiftCalendarMonth(currentDue, interval, preferredDay: reqDay);
    } else if (frequency == 'QUARTERLY') {
      final reqDay = requestedDay ?? (monthRule != null ? int.tryParse(monthRule) : null) ?? currentDue.day;
      return shiftCalendarMonth(currentDue, 3 * interval, preferredDay: reqDay);
    } else if (frequency == 'YEARLY') {
      final reqDay = requestedDay ?? currentDue.day;
      final totalMonths = interval * 12;
      return shiftCalendarMonth(currentDue, totalMonths, preferredDay: reqDay);
    }
    return shiftCalendarDay(currentDue, 30);
  }
}
