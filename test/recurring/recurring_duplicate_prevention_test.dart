import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/presentation/home/services/recurring_schedule_engine.dart';
import 'package:snaphisaab/core/utils/date_utils.dart';

void main() {
  group('Recurring Duplicate Prevention Gate', () {
    late AppDatabase db;
    late int profileId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      profileId = await db.into(db.profiles).insert(
        ProfilesCompanion.insert(
          name: 'Duplicate Test Profile',
          type: ProfileType.SHOP,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Running processDueSchedules 5 times consecutively produces zero duplicate occurrences or transactions', () async {
      final today = parseDateOnly(DateTime.now());

      final ruleId = await db.into(db.recurringRule).insert(
        RecurringRuleCompanion.insert(
          profileId: profileId,
          title: 'Internet Bill',
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

      for (int i = 0; i < 5; i++) {
        await engine.processDueSchedules();
      }

      final histories = await (db.select(db.recurringHistory)..where((h) => h.ruleId.equals(ruleId))).get();
      final transactions = await db.select(db.transactions).get();

      expect(histories.length, 1);
      expect(transactions.length, 0, reason: 'Engine processing must NEVER automatically create paid transactions');
    });

    test('Open -> Close -> Open app restart loop produces no duplicates', () async {
      final today = parseDateOnly(DateTime.now());

      final ruleId = await db.into(db.recurringRule).insert(
        RecurringRuleCompanion.insert(
          profileId: profileId,
          title: 'Mobile Recharge',
          defaultAmount: 499.0,
          amountStrategy: 'FIXED',
          frequency: 'MONTHLY',
          interval: 1,
          startDate: today,
          nextDueDate: today,
          status: 'ACTIVE',
        ),
      );

      // Simulation 1: Cold start
      final engine1 = RecurringScheduleEngine(db);
      await engine1.processDueSchedules();

      // Simulation 2: App restart
      final engine2 = RecurringScheduleEngine(db);
      await engine2.processDueSchedules();

      final histories = await (db.select(db.recurringHistory)..where((h) => h.ruleId.equals(ruleId))).get();
      expect(histories.length, 1);
    });
  });
}
