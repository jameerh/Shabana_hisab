class UserContext {
  final DateTime currentTime;
  final String location;
  final bool isWeekend;
  final bool isMonthEnd;
  
  UserContext({
    required this.currentTime,
    required this.location,
    required this.isWeekend,
    required this.isMonthEnd,
  });
}

class ContextEngine {
  static final ContextEngine _instance = ContextEngine._internal();
  factory ContextEngine() => _instance;
  ContextEngine._internal();

  UserContext getCurrentContext() {
    final now = DateTime.now();
    return UserContext(
      currentTime: now,
      location: 'Default',
      isWeekend: now.weekday == DateTime.saturday || now.weekday == DateTime.sunday,
      isMonthEnd: DateTime(now.year, now.month + 1, 0).difference(now).inDays <= 3,
    );
  }
}
