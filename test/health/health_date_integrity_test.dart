import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:snaphisaab/core/utils/date_utils.dart';
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/data/models/health_models.dart';
import 'package:snaphisaab/data/repositories/health_repository.dart';

void main() {
  group('Date Utilities & Calendar Math Gate', () {
    test('parseDateOnly extracts strict calendar year, month, and day', () {
      expect(parseDateOnly('2026-09-09'), DateTime(2026, 9, 9));
      expect(parseDateOnly('2026-02-28'), DateTime(2026, 2, 28));
      expect(parseDateOnly('2024-02-29'), DateTime(2024, 2, 29));
      expect(parseDateOnly(DateTime(2026, 12, 31, 23, 59, 59)), DateTime(2026, 12, 31));
      expect(parseDateOnly(DateTime.utc(2026, 1, 1, 0, 0, 0)), DateTime(2026, 1, 1));
    });

    test('formatDateOnly produces strict ISO-8601 yyyy-MM-dd calendar string', () {
      expect(formatDateOnly(DateTime(2026, 9, 9)), '2026-09-09');
      expect(formatDateOnly(DateTime(2026, 1, 5)), '2026-01-05');
      expect(formatDateOnly(DateTime(2024, 2, 29)), '2024-02-29');
    });

    test('isLeapYear and daysInMonth accurately handle leap and non-leap years', () {
      expect(isLeapYear(2020), isTrue);
      expect(isLeapYear(2024), isTrue);
      expect(isLeapYear(2000), isTrue);
      expect(isLeapYear(1900), isFalse);
      expect(isLeapYear(2025), isFalse);
      expect(isLeapYear(2026), isFalse);

      expect(daysInMonth(2024, 2), 29);
      expect(daysInMonth(2026, 2), 28);
      expect(daysInMonth(2026, 1), 31);
      expect(daysInMonth(2026, 4), 30);
    });

    test('clampMonthDay clamps out-of-range days to the valid month end', () {
      expect(clampMonthDay(2026, 2, 31), 28);
      expect(clampMonthDay(2024, 2, 31), 29);
      expect(clampMonthDay(2026, 4, 31), 30);
      expect(clampMonthDay(2026, 3, 31), 31);
    });

    test('shiftCalendarMonth preserves preferred 31st recurrence across full calendar year', () {
      final startJan31 = DateTime(2026, 1, 31);
      const requestedDay = 31;

      // Jan 31 + 1 month = Feb 28 (clamped)
      final feb = shiftCalendarMonth(startJan31, 1, preferredDay: requestedDay);
      expect(feb, DateTime(2026, 2, 28));

      // Feb 28 + 1 month (with preferredDay 31) = Mar 31 (rule preserved!)
      final mar = shiftCalendarMonth(feb, 1, preferredDay: requestedDay);
      expect(mar, DateTime(2026, 3, 31));

      // Mar 31 + 1 month = Apr 30 (clamped)
      final apr = shiftCalendarMonth(mar, 1, preferredDay: requestedDay);
      expect(apr, DateTime(2026, 4, 30));

      // Apr 30 + 1 month (with preferredDay 31) = May 31 (rule preserved!)
      final may = shiftCalendarMonth(apr, 1, preferredDay: requestedDay);
      expect(may, DateTime(2026, 5, 31));
    });

    test('shiftCalendarDay and addCalendarDays shift days cleanly without DST / hour drift', () {
      final base = DateTime(2026, 3, 15);
      expect(shiftCalendarDay(base, 10), DateTime(2026, 3, 25));
      expect(shiftCalendarDay(base, -20), DateTime(2026, 2, 23));
      expect(addCalendarDays(base, 5), DateTime(2026, 3, 20));
    });
  });

  group('Health Date Database Integrity Gate', () {
    late AppDatabase db;
    late HealthRepository repository;
    late int profileId;
    late int patientId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = HealthRepository(db);

      profileId = await db.into(db.profiles).insert(
        ProfilesCompanion.insert(
          name: 'Date Integrity Family',
          type: ProfileType.PERSONAL,
        ),
      );

      patientId = await repository.addPatient(
        profileId: profileId,
        name: 'Aarti',
        relationship: 'Daughter',
      );
    });

    tearDown(() async {
      repository.dispose();
      await db.close();
    });

    test('Saving and querying events preserves exact calendar date without drift', () async {
      final testDates = [
        DateTime(2026, 1, 1),
        DateTime(2024, 2, 29), // Leap day
        DateTime(2026, 2, 28),
        DateTime(2026, 12, 31),
        DateTime(2026, 7, 15),
      ];

      for (final date in testDates) {
        final eventId = await repository.addQuickPrescription(
          profileId: profileId,
          patientId: patientId,
          purpose: 'Routine Check on ${formatDateOnly(date)}',
          eventDate: date,
        );

        final event = await repository.getEventById(eventId);
        expect(event, isNotNull);
        expect(event!.eventDate.year, date.year, reason: 'Year must match');
        expect(event.eventDate.month, date.month, reason: 'Month must match');
        expect(event.eventDate.day, date.day, reason: 'Day must match');

        // Query by exact calendar date
        final byDate = await repository.getEventsByDate(profileId, date);
        expect(byDate.any((e) => e.id == eventId), isTrue,
            reason: 'getEventsByDate must find record for exact calendar day');
      }
    });
  });
}
