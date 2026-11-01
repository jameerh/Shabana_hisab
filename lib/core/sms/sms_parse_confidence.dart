class SmsParseConfidence {
  final double amountConfidence;
  final double accountConfidence;
  final double typeConfidence;
  final double merchantConfidence;
  final double categoryConfidence;

  const SmsParseConfidence({
    required this.amountConfidence,
    required this.accountConfidence,
    required this.typeConfidence,
    required this.merchantConfidence,
    required this.categoryConfidence,
  });

  double get overallScore {
    return (amountConfidence * 0.35) +
        (accountConfidence * 0.25) +
        (typeConfidence * 0.20) +
        (merchantConfidence * 0.10) +
        (categoryConfidence * 0.10);
  }

  bool get isHighConfidence => overallScore >= 0.90;
  bool get isReviewRequired => overallScore >= 0.50 && overallScore < 0.90;
  bool get isExcluded => overallScore < 0.50;
}
