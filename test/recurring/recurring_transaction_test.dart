import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/presentation/home/services/recurring_schedule_engine.dart';
import 'package:snaphisaab/core/utils/date_utils.dart';

void main() {
  group('Recurring Transaction & 1-to-1 Pay Idempotency Gate', () {
    late AppDatabase db;
    late int profileId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      profileId = await db.into(db.profiles).insert(
        ProfilesCompanion.insert(
          name: 'Tx Test Profile',
          type: ProfileType.SHOP,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Paying a due item creates a Hisaab transaction with full partyName, amount, profileId, and metadata link', () async {
      final today = parseDateOnly(DateTime.now());

      final ruleId = await db.into(db.recurringRule).insert(
        RecurringRuleCompanion.insert(
          profileId: profileId,
          title: 'Internet Service',
          defaultAmount: 999.0,
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

      await engine.markAsPaid(histories.first.id);

      final transactions = await db.select(db.transactions).get();
      final updatedHistory = await (db.select(db.recurringHistory)..where((h) => h.id.equals(histories.first.id))).getSingle();

      expect(transactions.length, 1);
      expect(transactions.first.partyName, 'Internet Service');
      expect(transactions.first.amount, 999.0);
      expect(transactions.first.profileId, profileId);
      expect(updatedHistory.status, 'PAID');
      expect(updatedHistory.transactionId, transactions.first.id);
    });

    test('1-to-1 Pay Idempotency: Calling markAsPaid twice on the same history item is a safe no-op', () async {
      final today = parseDateOnly(DateTime.now());

      final ruleId = await db.into(db.recurringRule).insert(
        RecurringRuleCompanion.insert(
          profileId: profileId,
          title: 'Water Supply',
          defaultAmount: 500.0,
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

      // First call
      await engine.markAsPaid(histories.first.id);
      // Second call (Simulating rapid double-tap or retry)
      await engine.markAsPaid(histories.first.id);

      final transactions = await db.select(db.transactions).get();
      expect(transactions.length, 1, reason: 'Double-calling markAsPaid MUST produce maximum ONE Hisaab transaction');
    });

    test('Concurrent Pay Execution (Rapid Double Tap): Future.wait markAsPaid creates exactly 1 transaction', () async {
      final today = parseDateOnly(DateTime.now());

      final ruleId = await db.into(db.recurringRule).insert(
        RecurringRuleCompanion.insert(
          profileId: profileId,
          title: 'Rapid Tap Electricity',
          defaultAmount: 2400.0,
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
      final historyId = histories.first.id;

      // Simulate simultaneous/racing Pay requests (e.g. user rapid double-tapping 'Pay')
      await Future.wait([
        engine.markAsPaid(historyId),
        engine.markAsPaid(historyId),
      ]);

      final allHistories = await (db.select(db.recurringHistory)..where((h) => h.ruleId.equals(ruleId))).get();
      final allTransactions = await db.select(db.transactions).get();

      expect(allHistories.length, 1, reason: 'Exactly 1 RecurringHistory row');
      expect(allTransactions.length, 1, reason: 'Exactly 1 Hisaab transaction produced');
      expect(allHistories.first.status, 'PAID');
      expect(allHistories.first.transactionId, isNotNull);
      expect(allHistories.first.transactionId, allTransactions.first.id);
    });
  });
}
