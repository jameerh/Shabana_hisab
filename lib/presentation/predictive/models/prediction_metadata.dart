class PredictionMetadata {
  final String predictionType;
  final String headline;
  final String details;
  final double confidence; // 0.0 to 1.0
  final List<String> confidenceFactors;
  final double metricValue;
  final String sourceEngine;
  final Duration validityDuration;
  final DateTime generatedAt;

  PredictionMetadata({
    required this.predictionType,
    required this.headline,
    required this.details,
    required this.confidence,
    required this.confidenceFactors,
    required this.metricValue,
    required this.sourceEngine,
    required this.validityDuration,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  DateTime get validUntil => generatedAt.add(validityDuration);

  bool get isExpired => DateTime.now().isAfter(validUntil);
}
