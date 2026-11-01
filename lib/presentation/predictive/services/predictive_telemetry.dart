class PredictiveEngineTelemetry {
  final String engineId;
  final int executionTimeMs;
  final bool isHealthy;
  final String? errorMessage;
  final DateTime lastExecuted;

  PredictiveEngineTelemetry({
    required this.engineId,
    required this.executionTimeMs,
    required this.isHealthy,
    this.errorMessage,
    DateTime? lastExecuted,
  }) : lastExecuted = lastExecuted ?? DateTime.now();
}

class PredictiveTelemetryRegistry {
  static final PredictiveTelemetryRegistry _instance = PredictiveTelemetryRegistry._internal();
  factory PredictiveTelemetryRegistry() => _instance;
  PredictiveTelemetryRegistry._internal();

  final Map<String, PredictiveEngineTelemetry> _engineTelemetry = {};
  int _cacheHits = 0;
  int _cacheMisses = 0;

  void recordTelemetry(PredictiveEngineTelemetry telemetry) {
    _engineTelemetry[telemetry.engineId] = telemetry;
  }

  void recordCacheHit() => _cacheHits++;
  void recordCacheMiss() => _cacheMisses++;

  List<PredictiveEngineTelemetry> get allTelemetry => _engineTelemetry.values.toList();

  int get cacheHits => _cacheHits;
  int get cacheMisses => _cacheMisses;
  double get cacheHitRate => (_cacheHits + _cacheMisses) > 0 
      ? (_cacheHits / (_cacheHits + _cacheMisses)) * 100.0 
      : 0.0;
}
