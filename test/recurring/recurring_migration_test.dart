import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/presentation/home/services/recurring_schedule_engine.dart';

void main() {
  group('Recurring Migration & Data Preservation Compatibility Gate', () {
    late AppDatabase db;
    late int profileId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());

      profileId = await db.into(db.profiles).insert(
        ProfilesCompanion.insert(
          name: 'Merchant Family',
          type: ProfileType.SHOP,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Existing recurring data is preserved with zero deletions, resets, or data loss', () async {
      // 1. Seed existing legacy recurring schedules into database
      final schedule1 = await db.into(db.recurringRule).insert(
        RecurringRuleCompanion.insert(
          profileId: profileId,
          title: 'Shop Monthly Rent',
          description: const Value('To landlord by 31st'),
          defaultAmount: 15000.0,
          amountStrategy: 'FIXED',
          frequency: 'MONTHLY',
          interval: 1,
          startDate: DateTime(2025, 1, 31),
          nextDueDate: DateTime(2026, 9, 30),
          status: 'ACTIVE',
          monthRule: const Value('31'),
          paymentMode: const Value('CASH'),
        ),
      );

      final schedule2 = await db.into(db.recurringRule).insert(
        RecurringRuleCompanion.insert(
          profileId: profileId,
          title: 'MSEDCL Bill',
          description: const Value('Consumer No 123456'),
          defaultAmount: 3200.0,
          amountStrategy: 'FIXED',
          frequency: 'MONTHLY',
          interval: 1,
          startDate: DateTime(2025, 6, 10),
          nextDueDate: DateTime(2026, 10, 10),
          status: 'ACTIVE',
          monthRule: const Value('10'),
          paymentMode: const Value('BANK'),
        ),
      );

      // Seed existing recurring history
      await db.into(db.recurringHistory).insert(
        RecurringHistoryCompanion.insert(
          ruleId: schedule1,
          dueDate: DateTime(2026, 8, 31),
          status: 'PAID',
          actionTaken: const Value('PAY'),
          amount: const Value(15000.0),
        ),
      );

      // 2. Snapshot BEFORE state
      final beforeRules = await db.select(db.recurringRule).get();
      final beforeHistories = await db.select(db.recurringHistory).get();

      expect(beforeRules.length, 2);
      expect(beforeHistories.length, 1);

      // 3. Run RecurringScheduleEngine in RC2
      RecurringScheduleEngine(db);

      // Verify that no automatic re-creation, deletion, or resetting happened
      final afterRules = await db.select(db.recurringRule).get();
      final afterHistories = await db.select(db.recurringHistory).get();

      // IDs must be exactly identical
      expect(afterRules.map((r) => r.id).toList(), equals(beforeRules.map((r) => r.id).toList()));

      // Schedule 1 field-by-field preservation
      final rule1 = afterRules.firstWhere((r) => r.id == schedule1);
      expect(rule1.title, 'Shop Monthly Rent');
      expect(rule1.frequency, 'MONTHLY');
      expect(rule1.interval, 1);
      expect(rule1.defaultAmount, 15000.0);
      expect(rule1.startDate, DateTime(2025, 1, 31));
      expect(rule1.status, 'ACTIVE');
      expect(rule1.monthRule, '31');
      expect(rule1.paymentMode, 'CASH');
      expect(rule1.description, 'To landlord by 31st');

      // Schedule 2 field-by-field preservation
      final rule2 = afterRules.firstWhere((r) => r.id == schedule2);
      expect(rule2.title, 'MSEDCL Bill');
      expect(rule2.frequency, 'MONTHLY');
      expect(rule2.interval, 1);
      expect(rule2.defaultAmount, 3200.0);
      expect(rule2.startDate, DateTime(2025, 6, 10));
      expect(rule2.status, 'ACTIVE');
      expect(rule2.paymentMode, 'BANK');
      expect(rule2.description, 'Consumer No 123456');

      // History must be preserved with zero duplicates
      expect(afterHistories.length, 1);
      expect(afterHistories.first.ruleId, schedule1);
      expect(afterHistories.first.status, 'PAID');
      expect(afterHistories.first.amount, 15000.0);
    });
  });
}
