class FilterCriteria {
  final String? type;
  final String? dateRange; // 'ALL_TIME', 'TODAY', 'THIS_WEEK', 'THIS_MONTH'
  final String? category;

  FilterCriteria({
    this.type,
    this.dateRange,
    this.category,
  });

  FilterCriteria copyWith({
    String? type,
    String? dateRange,
    String? category,
  }) {
    return FilterCriteria(
      type: type ?? this.type,
      dateRange: dateRange ?? this.dateRange,
      category: category ?? this.category,
    );
  }

  DateTime? get startDate {
    if (dateRange == null || dateRange == 'ALL_TIME') return null;
    final now = DateTime.now();
    if (dateRange == 'TODAY') {
      return DateTime(now.year, now.month, now.day);
    } else if (dateRange == 'THIS_WEEK') {
      return DateTime(now.year, now.month, now.day - now.weekday + 1);
    } else if (dateRange == 'THIS_MONTH') {
      return DateTime(now.year, now.month, 1);
    }
    return null;
  }

  DateTime? get endDate {
    if (dateRange == null || dateRange == 'ALL_TIME') return null;
    final now = DateTime.now();
    if (dateRange == 'TODAY') {
      return DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (dateRange == 'THIS_WEEK') {
      final start = DateTime(now.year, now.month, now.day - now.weekday + 1);
      return start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    } else if (dateRange == 'THIS_MONTH') {
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      return nextMonth.subtract(const Duration(seconds: 1));
    }
    return null;
  }

  bool get hasActiveFilters => 
    (type != null && type != 'All') || 
    (dateRange != null && dateRange != 'ALL_TIME') || 
    category != null;
}
