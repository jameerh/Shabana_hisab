import 'package:flutter_test/flutter_test.dart';
import 'package:snaphisaab/presentation/home/services/recurring_schedule_engine.dart';

void main() {
  group('31st Recurrence Semantics & Date Calculations Gate', () {
    test('31st of month rule preserves 31 across all months without collapsing to 28th/30th', () {
      final jan31 = DateTime(2026, 1, 31);
      const requestedDay = 31;

      // 1. Jan 31 -> Feb 28 (Clamped for non-leap year)
      final feb = RecurringScheduleEngine.calculateNextDueDate(
        jan31,
        'MONTHLY',
        1,
        requestedDay: requestedDay,
      );
      expect(feb, DateTime(2026, 2, 28));

      // 2. Feb 28 -> Mar 31 (Rule 31st preserved!)
      final mar = RecurringScheduleEngine.calculateNextDueDate(
        feb,
        'MONTHLY',
        1,
        requestedDay: requestedDay,
      );
      expect(mar, DateTime(2026, 3, 31));

      // 3. Mar 31 -> Apr 30 (Clamped for 30-day month)
      final apr = RecurringScheduleEngine.calculateNextDueDate(
        mar,
        'MONTHLY',
        1,
        requestedDay: requestedDay,
      );
      expect(apr, DateTime(2026, 4, 30));

      // 4. Apr 30 -> May 31 (Rule 31st preserved!)
      final may = RecurringScheduleEngine.calculateNextDueDate(
        apr,
        'MONTHLY',
        1,
        requestedDay: requestedDay,
      );
      expect(may, DateTime(2026, 5, 31));

      // 5. May 31 -> Jun 30
      final jun = RecurringScheduleEngine.calculateNextDueDate(
        may,
        'MONTHLY',
        1,
        requestedDay: requestedDay,
      );
      expect(jun, DateTime(2026, 6, 30));

      // 6. Jun 30 -> Jul 31
      final jul = RecurringScheduleEngine.calculateNextDueDate(
        jun,
        'MONTHLY',
        1,
        requestedDay: requestedDay,
      );
      expect(jul, DateTime(2026, 7, 31));
    });

    test('31st recurrence semantics in a leap year (2024)', () {
      final jan31 = DateTime(2024, 1, 31);
      const requestedDay = 31;

      // Jan 31 -> Feb 29 (Leap day)
      final feb = RecurringScheduleEngine.calculateNextDueDate(
        jan31,
        'MONTHLY',
        1,
        requestedDay: requestedDay,
      );
      expect(feb, DateTime(2024, 2, 29));

      // Feb 29 -> Mar 31
      final mar = RecurringScheduleEngine.calculateNextDueDate(
        feb,
        'MONTHLY',
        1,
        requestedDay: requestedDay,
      );
      expect(mar, DateTime(2024, 3, 31));
    });

    test('Year-end boundary preserves requested day across new year transition', () {
      final dec31 = DateTime(2025, 12, 31);
      const requestedDay = 31;

      final jan31 = RecurringScheduleEngine.calculateNextDueDate(
        dec31,
        'MONTHLY',
        1,
        requestedDay: requestedDay,
      );
      expect(jan31, DateTime(2026, 1, 31));

      final feb28 = RecurringScheduleEngine.calculateNextDueDate(
        jan31,
        'MONTHLY',
        1,
        requestedDay: requestedDay,
      );
      expect(feb28, DateTime(2026, 2, 28));
    });

    test('Daily and Weekly recurring calculations', () {
      final start = DateTime(2026, 5, 1);

      // Daily interval = 2
      final nextDaily = RecurringScheduleEngine.calculateNextDueDate(
        start,
        'DAILY',
        2,
      );
      expect(nextDaily, DateTime(2026, 5, 3));

      // Weekly interval = 1 (7 days)
      final nextWeekly = RecurringScheduleEngine.calculateNextDueDate(
        start,
        'WEEKLY',
        1,
      );
      expect(nextWeekly, DateTime(2026, 5, 8));

      // Bi-weekly interval = 2 (14 days)
      final nextBiWeekly = RecurringScheduleEngine.calculateNextDueDate(
        start,
        'WEEKLY',
        2,
      );
      expect(nextBiWeekly, DateTime(2026, 5, 15));
    });

    test('Yearly recurrence preserves anniversary day', () {
      final leapStart = DateTime(2024, 2, 29);
      final nextYear = RecurringScheduleEngine.calculateNextDueDate(
        leapStart,
        'YEARLY',
        1,
        requestedDay: 29,
      );
      expect(nextYear, DateTime(2025, 2, 28), reason: 'Clamps to Feb 28 in non-leap year');

      final regularStart = DateTime(2025, 6, 15);
      final nextRegular = RecurringScheduleEngine.calculateNextDueDate(
        regularStart,
        'YEARLY',
        1,
        requestedDay: 15,
      );
      expect(nextRegular, DateTime(2026, 6, 15));
    });

    test('Quarterly recurrence advances 3 months cleanly', () {
      final start = DateTime(2026, 1, 15);

      // 1. Jan 15 -> Apr 15
      final q1 = RecurringScheduleEngine.calculateNextDueDate(
        start,
        'QUARTERLY',
        1,
        requestedDay: 15,
      );
      expect(q1, DateTime(2026, 4, 15));

      // 2. Apr 15 -> Jul 15
      final q2 = RecurringScheduleEngine.calculateNextDueDate(
        q1,
        'QUARTERLY',
        1,
        requestedDay: 15,
      );
      expect(q2, DateTime(2026, 7, 15));

      // 3. Jan 31 -> Apr 30 (Quarterly end of month clamping)
      final jan31 = DateTime(2026, 1, 31);
      final q3 = RecurringScheduleEngine.calculateNextDueDate(
        jan31,
        'QUARTERLY',
        1,
        requestedDay: 31,
      );
      expect(q3, DateTime(2026, 4, 30));
    });
  });
}
