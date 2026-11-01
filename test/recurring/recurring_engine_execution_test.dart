import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/presentation/home/services/recurring_schedule_engine.dart';
import 'package:snaphisaab/core/utils/date_utils.dart';

void main() {
  group('Recurring Engine Execution & Concurrency Gate', () {
    late AppDatabase db;
    late int profileId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      profileId = await db.into(db.profiles).insert(
        ProfilesCompanion.insert(
          name: 'Engine Test Profile',
          type: ProfileType.SHOP,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('processDueSchedules executes cleanly inside database transaction', () async {
      final today = parseDateOnly(DateTime.now());

      await db.into(db.recurringRule).insert(
        RecurringRuleCompanion.insert(
          profileId: profileId,
          title: 'Daily Milk',
          defaultAmount: 70.0,
          amountStrategy: 'FIXED',
          frequency: 'DAILY',
          interval: 1,
          startDate: today,
          nextDueDate: today,
          status: 'ACTIVE',
        ),
      );

      final engine = RecurringScheduleEngine(db);
      await engine.processDueSchedules();

      final histories = await db.select(db.recurringHistory).get();
      expect(histories.length, 1);
      expect(histories.first.status, 'PENDING');
    });

    test('Concurrent processDueSchedules executions produce exactly ONE occurrence (Race condition guard)', () async {
      final today = parseDateOnly(DateTime.now());

      final ruleId = await db.into(db.recurringRule).insert(
        RecurringRuleCompanion.insert(
          profileId: profileId,
          title: 'Concurrent Rent Test',
          defaultAmount: 15000.0,
          amountStrategy: 'FIXED',
          frequency: 'MONTHLY',
          interval: 1,
          startDate: today,
          nextDueDate: today,
          status: 'ACTIVE',
        ),
      );

      final engine = RecurringScheduleEngine(db);

      // Launch 2 engine process executions simultaneously
      await Future.wait([
        engine.processDueSchedules(),
        engine.processDueSchedules(),
      ]);

      final histories = await (db.select(db.recurringHistory)..where((h) => h.ruleId.equals(ruleId))).get();
      expect(histories.length, 1, reason: 'Concurrent runs must produce exactly ONE occurrence for (ruleId, dueDate)');
    });
  });
}
