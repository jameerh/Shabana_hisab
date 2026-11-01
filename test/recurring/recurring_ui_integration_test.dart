import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/presentation/home/services/recurring_schedule_engine.dart';
import 'package:snaphisaab/core/utils/date_utils.dart';

void main() {
  group('Recurring UI Integration & Dashboard Cards Gate', () {
    late AppDatabase db;
    late int profileId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      profileId = await db.into(db.profiles).insert(
        ProfilesCompanion.insert(
          name: 'UI Test Profile',
          type: ProfileType.SHOP,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('DashboardCardProvider generates due cards for PENDING/OVERDUE items', () async {
      final today = parseDateOnly(DateTime.now());

      await db.into(db.recurringRule).insert(
        RecurringRuleCompanion.insert(
          profileId: profileId,
          title: 'Shop Electricity',
          defaultAmount: 4200.0,
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

      final cards = await engine.getAvailableCards();
      expect(cards.length, 1);
      expect(cards.first.title.contains('Shop Electricity'), isTrue);
      expect(cards.first.actionLabel, 'Pay');
    });
  });
}
