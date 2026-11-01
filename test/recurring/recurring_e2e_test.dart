import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/presentation/home/services/recurring_schedule_engine.dart';
import 'package:snaphisaab/core/utils/date_utils.dart';

void main() {
  group('Recurring End-to-End (E2E) Golden Scenario Gate', () {
    late AppDatabase db;
    late int profileId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      profileId = await db.into(db.profiles).insert(
        ProfilesCompanion.insert(
          name: 'Golden E2E Profile',
          type: ProfileType.SHOP,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Full E2E: Missed 3 months -> catch up 3 overdue -> pay 1 -> restart app -> verify 0 duplicates -> pay rest -> nextDueDate in future', () async {
      final today = parseDateOnly(DateTime.now());
      // Existing rule created 3 months ago (e.g. 3 missed months)
      final initialDue = DateTime(today.year, today.month - 3, 10);

      // 1. Existing schedule in database
      final ruleId = await db.into(db.recurringRule).insert(
        RecurringRuleCompanion.insert(
          profileId: profileId,
          title: 'Warehouse Rent',
          defaultAmount: 25000.0,
          amountStrategy: 'FIXED',
          frequency: 'MONTHLY',
          interval: 1,
          startDate: DateTime(2024, 1, 10),
          nextDueDate: initialDue,
          status: 'ACTIVE',
        ),
      );

      // 2. Open app -> engine processes due schedules
      final engine1 = RecurringScheduleEngine(db);
      await engine1.processDueSchedules();

      // 3. Catch up generated overdue occurrences without creating transactions automatically
      final histories1 = await (db.select(db.recurringHistory)..where((h) => h.ruleId.equals(ruleId))).get();
      final txs1 = await db.select(db.transactions).get();

      expect(histories1.length, greaterThanOrEqualTo(3));
      expect(txs1.length, 0, reason: 'Engine run MUST NOT auto-create paid transactions');

      // 4. User explicitly pays 1 overdue item
      final firstOverdue = histories1.first;
      await engine1.markAsPaid(firstOverdue.id);

      final txs2 = await db.select(db.transactions).get();
      expect(txs2.length, 1);
      expect(txs2.first.amount, 25000.0);
      expect(txs2.first.partyName, 'Warehouse Rent');

      // 5. App restart simulation (re-initialize engine)
      final engine2 = RecurringScheduleEngine(db);
      await engine2.processDueSchedules();

      final histories2 = await (db.select(db.recurringHistory)..where((h) => h.ruleId.equals(ruleId))).get();
      final txs3 = await db.select(db.transactions).get();

      expect(histories2.length, histories1.length, reason: 'Re-running engine after restart must produce ZERO duplicates');
      expect(txs3.length, 1, reason: 'Re-running engine must NOT re-log paid transactions');

      // 6. User pays remaining overdue items
      for (final h in histories2) {
        if (h.id != firstOverdue.id) {
          await engine2.markAsPaid(h.id);
        }
      }

      final finalTxs = await db.select(db.transactions).get();
      final finalRule = await (db.select(db.recurringRule)..where((r) => r.id.equals(ruleId))).getSingle();

      expect(finalTxs.length, histories2.length);
      expect(finalRule.nextDueDate.isAfter(today), isTrue, reason: 'nextDueDate must point cleanly to the first future occurrence date');
    });
  });
}
