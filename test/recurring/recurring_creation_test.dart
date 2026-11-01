import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/presentation/home/services/recurring_schedule_engine.dart';
import 'package:snaphisaab/core/utils/date_utils.dart';

void main() {
  group('Recurring Creation & Start Date Safeguards', () {
    late AppDatabase db;
    late int profileId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      profileId = await db.into(db.profiles).insert(
        ProfilesCompanion.insert(
          name: 'Creation Test Profile',
          type: ProfileType.PERSONAL,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Rule created with start date = today sets nextDueDate = today (not skipped)', () async {
      final now = DateTime.now();
      final today = parseDateOnly(now);

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

      // Rule nextDueDate advanced to next month, and 1 PENDING history item generated for today
      final rule = await (db.select(db.recurringRule)..where((r) => r.id.equals(ruleId))).getSingle();
      final histories = await (db.select(db.recurringHistory)..where((h) => h.ruleId.equals(ruleId))).get();

      expect(histories.length, 1);
      expect(histories.first.dueDate, today);
      expect(histories.first.status, 'PENDING');
      expect(rule.nextDueDate.isAfter(today), isTrue);
    });

    test('Rule created with future start date sets nextDueDate = startDate', () async {
      final futureDate = parseDateOnly(DateTime.now().add(const Duration(days: 10)));

      final ruleId = await db.into(db.recurringRule).insert(
        RecurringRuleCompanion.insert(
          profileId: profileId,
          title: 'Future Insurance',
          defaultAmount: 5000.0,
          amountStrategy: 'FIXED',
          frequency: 'YEARLY',
          interval: 1,
          startDate: futureDate,
          nextDueDate: futureDate,
          status: 'ACTIVE',
        ),
      );

      final engine = RecurringScheduleEngine(db);
      await engine.processDueSchedules();

      final histories = await (db.select(db.recurringHistory)..where((h) => h.ruleId.equals(ruleId))).get();
      final rule = await (db.select(db.recurringRule)..where((r) => r.id.equals(ruleId))).getSingle();

      expect(histories.isEmpty, isTrue, reason: 'Future schedule must not produce due histories yet');
      expect(rule.nextDueDate, futureDate);
    });

    test('Newly created rule with past start date sets nextDueDate to earliest recurrence date >= today without auto-backfilling past months', () async {
      final today = parseDateOnly(DateTime.now());
      final pastStart = parseDateOnly(DateTime.now().subtract(const Duration(days: 90))); // 3 months ago

      // Newly created rule logic: calculate earliest recurrence >= today
      var nextDue = pastStart;
      while (nextDue.isBefore(today)) {
        nextDue = RecurringScheduleEngine.calculateNextDueDate(
          nextDue,
          'MONTHLY',
          1,
          requestedDay: pastStart.day,
        );
      }

      final ruleId = await db.into(db.recurringRule).insert(
        RecurringRuleCompanion.insert(
          profileId: profileId,
          title: 'New Rule with Old Start Date',
          defaultAmount: 1000.0,
          amountStrategy: 'FIXED',
          frequency: 'MONTHLY',
          interval: 1,
          startDate: pastStart,
          nextDueDate: nextDue,
          status: 'ACTIVE',
        ),
      );

      final engine = RecurringScheduleEngine(db);
      await engine.processDueSchedules();

      final histories = await (db.select(db.recurringHistory)..where((h) => h.ruleId.equals(ruleId))).get();
      expect(histories.length, isSameCalendarDay(nextDue, today) ? 1 : 0, 
        reason: 'Newly created rule must not silently generate 3 historical overdue rows');
    });
  });
}
