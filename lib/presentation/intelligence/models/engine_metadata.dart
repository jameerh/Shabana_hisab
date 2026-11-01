import 'package:flutter/foundation.dart';

/// EngineMetadata implements ADR-016 Engine Metadata Contract.
/// Exposes contract metadata, input/output dependencies, and real-time execution telemetry.
class EngineMetadata {
  final String engineId;
  final String engineVersion;
  final List<String> inputStates;
  final List<String> outputStates;
  final int executionOrder;
  final String executionFrequency;
  
  // Dynamic Telemetry
  int executionTimeMs;
  DateTime lastExecution;
  String healthStatus; // 'HEALTHY', 'DEGRADED', 'ERROR'
  String? lastError;

  EngineMetadata({
    required this.engineId,
    required this.engineVersion,
    required this.inputStates,
    required this.outputStates,
    required this.executionOrder,
    required this.executionFrequency,
    this.executionTimeMs = 0,
    DateTime? lastExecution,
    this.healthStatus = 'HEALTHY',
    this.lastError,
  }) : lastExecution = lastExecution ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'engineId': engineId,
    'engineVersion': engineVersion,
    'inputStates': inputStates,
    'outputStates': outputStates,
    'executionOrder': executionOrder,
    'executionFrequency': executionFrequency,
    'executionTimeMs': executionTimeMs,
    'lastExecution': lastExecution.toIso8601String(),
    'healthStatus': healthStatus,
    'lastError': lastError,
  };
}

/// Global Engine Telemetry Registry for developer diagnostics (ADR-016)
class EngineTelemetryRegistry extends ChangeNotifier {
  static final EngineTelemetryRegistry _instance = EngineTelemetryRegistry._internal();
  factory EngineTelemetryRegistry() => _instance;
  EngineTelemetryRegistry._internal();

  final Map<String, EngineMetadata> _registry = {};

  List<EngineMetadata> get allMetadata {
    final list = _registry.values.toList();
    list.sort((a, b) => a.executionOrder.compareTo(b.executionOrder));
    return list;
  }

  EngineMetadata? getMetadata(String engineId) => _registry[engineId];

  void registerOrUpdate(EngineMetadata metadata) {
    _registry[metadata.engineId] = metadata;
    notifyListeners();
  }

  void recordExecution({
    required String engineId,
    required int durationMs,
    String? error,
  }) {
    final existing = _registry[engineId];
    if (existing != null) {
      existing.executionTimeMs = durationMs;
      existing.lastExecution = DateTime.now();
      if (error != null) {
        existing.healthStatus = 'ERROR';
        existing.lastError = error;
      } else if (durationMs > 50) {
        existing.healthStatus = 'DEGRADED';
        existing.lastError = null;
      } else {
        existing.healthStatus = 'HEALTHY';
        existing.lastError = null;
      }
      notifyListeners();
    }
  }
}
