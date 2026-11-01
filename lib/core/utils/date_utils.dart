/// Centralized, high-precision calendar date utility for Shabana Hisaab.
///
/// Guarantees:
/// 1. A diary/calendar date is treated strictly as a local date (Year, Month, Day),
///    completely isolated from UTC timestamps and timezone offset drifts.
/// 2. Date arithmetic (day/month shifts) never rolls over into unwanted months
///    (e.g., Jan 31 + 1 month clamps to Feb 28/29 without jumping to March 3).
library;

/// Parses any dynamic date input (String, DateTime, ISO-8601) strictly into a
/// local calendar date [DateTime] with hour, minute, second set to 0.
DateTime parseDateOnly(dynamic value) {
  if (value == null) {
    throw const FormatException('Date cannot be null');
  }

  if (value is DateTime) {
    return DateTime(value.year, value.month, value.day);
  }

  final text = value.toString().trim();
  if (text.isEmpty) {
    throw const FormatException('Date string cannot be empty');
  }

  // 1. Direct match for canonical YYYY-MM-DD
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
  if (match != null) {
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  // 2. Fallback for ISO strings or other parseable formats
  final parsed = DateTime.parse(text);
  return DateTime(parsed.year, parsed.month, parsed.day);
}

/// Formats a [DateTime] into a canonical `yyyy-MM-dd` date-only string.
String formatDateOnly(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Shifts a calendar date by [days] days without duration or DST hour drift.
DateTime shiftCalendarDay(DateTime date, int days) {
  return DateTime(date.year, date.month, date.day + days);
}

/// Alias for shiftCalendarDay for backward compatibility with existing codebase.
DateTime addCalendarDays(DateTime date, int days) => shiftCalendarDay(date, days);

/// Checks if a year is a leap year.
bool isLeapYear(int year) {
  return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
}

/// Returns the exact number of days in a given [month] of [year].
int daysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}

/// Clamps [targetDay] to the maximum available days in [month] of [year].
/// For example, targeting day 31 in February 2028 returns 29.
int clampMonthDay(int year, int month, int targetDay) {
  final maxDays = daysInMonth(year, month);
  if (targetDay > maxDays) return maxDays;
  if (targetDay < 1) return 1;
  return targetDay;
}

/// Shifts a date by [months] months while preserving the [preferredDay]
/// (defaults to [date.day]) using month-clamping.
///
/// Example:
/// - Jan 31 + 1 month -> Feb 28 (or Feb 29 in leap year)
/// - If [preferredDay] is 31: Feb 28 + 1 month -> Mar 31!
/// This preserves the 31st recurrence semantics across shorter months.
DateTime shiftCalendarMonth(
  DateTime date,
  int months, {
  int? preferredDay,
  bool preserveTime = true,
}) {
  final totalMonths = (date.year * 12 + (date.month - 1)) + months;
  final targetYear = totalMonths ~/ 12;
  final targetMonth = (totalMonths % 12) + 1;

  final reqDay = preferredDay ?? date.day;
  final effDay = clampMonthDay(targetYear, targetMonth, reqDay);

  if (preserveTime) {
    return DateTime(
      targetYear,
      targetMonth,
      effDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
    );
  }

  return DateTime(targetYear, targetMonth, effDay);
}

/// Checks whether two [DateTime] instances represent the same calendar day.
bool isSameCalendarDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
