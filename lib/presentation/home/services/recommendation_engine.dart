class RecommendationEngine {
  static final RecommendationEngine _instance = RecommendationEngine._internal();
  factory RecommendationEngine() => _instance;
  RecommendationEngine._internal();

  /// Calculates a dynamic score (0-100) for a dashboard card.
  /// Replaces the old static priority queue system.
  double calculateScore({
    required double baseUrgency,
    required double importance,
    required double frequency,
    required double personalization,
    required double recency,
    required double aiConfidence,
  }) {
    // Weighted formula prioritizing urgency, importance, and AI confidence
    return (baseUrgency * 0.35) +
           (importance * 0.25) +
           (aiConfidence * 0.20) +
           (recency * 0.10) +
           (personalization * 0.05) +
           (frequency * 0.05);
  }
}
