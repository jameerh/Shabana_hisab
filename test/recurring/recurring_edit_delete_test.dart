import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/presentation/home/services/recurring_schedule_engine.dart';
import 'package:snaphisaab/core/utils/date_utils.dart';

void main() {
  group('Recurring Edit, Delete, Skip & Snooze Gate', () {
    late AppDatabase db;
    late int profileId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      profileId = await db.into(db.profiles).insert(
        ProfilesCompanion.insert(
          name: 'Edit Test Profile',
          type: ProfileType.SHOP,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Skip occurrence sets status to SKIPPED, actionTaken = SKIP, 0 transactions created', () async {
      final today = parseDateOnly(DateTime.now());

      final ruleId = await db.into(db.recurringRule).insert(
        RecurringRuleCompanion.insert(
          profileId: profileId,
          title: 'Petrol Allowance',
          defaultAmount: 2000.0,
          amountStrategy: 'FIXED',
          frequency: 'WEEKLY',
          interval: 1,
          startDate: today,
          nextDueDate: today,
          status: 'ACTIVE',
        ),
      );

      final engine = RecurringScheduleEngine(db);
      await engine.processDueSchedules();

      final histories = await (db.select(db.recurringHistory)..where((h) => h.ruleId.equals(ruleId))).get();
      expect(histories.length, 1);

      await engine.skip(histories.first.id);

      final updatedHistory = await (db.select(db.recurringHistory)..where((h) => h.id.equals(histories.first.id))).getSingle();
      final transactions = await db.select(db.transactions).get();

      expect(updatedHistory.status, 'SKIPPED');
      expect(updatedHistory.actionTaken, 'SKIP');
      expect(transactions.length, 0);
    });

    test('Snooze occurrence sets status to SNOOZED, sets snoozeUntil, 0 duplicate occurrences created', () async {
      final today = parseDateOnly(DateTime.now());
      final tomorrow = today.add(const Duration(days: 1));

      final ruleId = await db.into(db.recurringRule).insert(
        RecurringRuleCompanion.insert(
          profileId: profileId,
          title: 'Electricity Bill',
          defaultAmount: 3500.0,
          amountStrategy: 'FIXED',
          frequency: 'MONTHLY',
          interval: 1,
          startDate: today,
          nextDueDate: today,
          status: 'ACTIVE',
        ),
      );

      final engine = RecurringScheduleEngine(db);
      await engine.processDueSchedules();

      final histories = await (db.select(db.recurringHistory)..where((h) => h.ruleId.equals(ruleId))).get();
      expect(histories.length, 1);

      await engine.snooze(histories.first.id, targetDate: tomorrow);

      final updatedHistory = await (db.select(db.recurringHistory)..where((h) => h.id.equals(histories.first.id))).getSingle();
      expect(updatedHistory.status, 'SNOOZED');
      expect(updatedHistory.snoozeUntil, tomorrow);

      // Re-run process engine
      await engine.processDueSchedules();
      final afterHistories = await (db.select(db.recurringHistory)..where((h) => h.ruleId.equals(ruleId))).get();
      expect(afterHistories.length, 1, reason: 'Snoozing must not produce duplicate history rows');
    });

    test('Editing rule defaultAmount from 12000 to 13000 leaves past paid transaction untouched', () async {
      final today = parseDateOnly(DateTime.now());

      final ruleId = await db.into(db.recurringRule).insert(
        RecurringRuleCompanion.insert(
          profileId: profileId,
          title: 'House Rent',
          defaultAmount: 12000.0,
          amountStrategy: 'FIXED',
          frequency: 'MONTHLY',
          interval: 1,
          startDate: today,
          nextDueDate: today,
          status: 'ACTIVE',
        ),
      );

      final engine = RecurringScheduleEngine(db);
      await engine.processDueSchedules();

      final histories = await (db.select(db.recurringHistory)..where((h) => h.ruleId.equals(ruleId))).get();
      await engine.markAsPaid(histories.first.id);

      final pastTxs = await db.select(db.transactions).get();
      expect(pastTxs.first.amount, 12000.0);

      // Edit rule amount to 13000
      await (db.update(db.recurringRule)..where((r) => r.id.equals(ruleId))).write(
        const RecurringRuleCompanion(defaultAmount: Value(13000.0)),
      );

      final afterPastTxs = await db.select(db.transactions).get();
      expect(afterPastTxs.first.amount, 12000.0, reason: 'Past logged transactions must remain immutable when editing rule');
    });
  });
}
