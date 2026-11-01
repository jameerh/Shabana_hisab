import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/presentation/home/services/recurring_schedule_engine.dart';
import 'package:snaphisaab/core/utils/date_utils.dart';

void main() {
  group('Recurring Overdue & Catch-Up Gate', () {
    late AppDatabase db;
    late int profileId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      profileId = await db.into(db.profiles).insert(
        ProfilesCompanion.insert(
          name: 'Overdue Test Profile',
          type: ProfileType.PERSONAL,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Existing schedule missed for 3 months generates 3 distinct OVERDUE occurrences and sets nextDueDate to future', () async {
      final today = parseDateOnly(DateTime.now());
      // 3 months ago: e.g. June 10, July 10, August 10 when today is Sep 10
      final initialDue = DateTime(today.year, today.month - 3, 10);

      final ruleId = await db.into(db.recurringRule).insert(
        RecurringRuleCompanion.insert(
          profileId: profileId,
          title: 'Shop Rent Overdue',
          defaultAmount: 15000.0,
          amountStrategy: 'FIXED',
          frequency: 'MONTHLY',
          interval: 1,
          startDate: DateTime(2024, 1, 10),
          nextDueDate: initialDue,
          status: 'ACTIVE',
        ),
      );

      final engine = RecurringScheduleEngine(db);
      await engine.processDueSchedules();

      final histories = await (db.select(db.recurringHistory)..where((h) => h.ruleId.equals(ruleId))).get();
      final rule = await (db.select(db.recurringRule)..where((r) => r.id.equals(ruleId))).getSingle();
      final transactions = await db.select(db.transactions).get();

      // Catch up creates missed occurrences
      expect(histories.length, greaterThanOrEqualTo(3));
      for (final h in histories) {
        if (h.dueDate.isBefore(today)) {
          expect(h.status, 'OVERDUE');
        }
      }

      // Zero transactions created automatically
      expect(transactions.length, 0);

      // nextDueDate points to the first future occurrence (> today)
      expect(rule.nextDueDate.isAfter(today), isTrue);
    });
  });
}
