class CalculationLine {
  final String? operator;
  final double value;

  CalculationLine({this.operator, required this.value});

  CalculationLine copyWith({String? operator, double? value}) {
    return CalculationLine(
      operator: operator ?? this.operator,
      value: value ?? this.value,
    );
  }
}
