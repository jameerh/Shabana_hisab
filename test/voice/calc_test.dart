import 'package:flutter_test/flutter_test.dart';
import 'package:snaphisaab/core/voice/arithmetic_parser.dart';
import 'package:snaphisaab/core/voice/number_parser.dart';

void main() {
  test('Check voice calculator with Marathi numbers', () {
    final inputs = [
      'तेराशे पन्नास',
      'बाराशे पन्नास',
      'एक हजार पन्नास',
      'तेराशे अधिक पन्नास',
      '13शे अधिक 50',
      '1300 अधिक पन्नास',
      'तेराशे पन्नास अधिक दोनशे',
    ];

    for (var inp in inputs) {
      final res = ArithmeticParser.parse(inp);
      final seq = NumberParser.parseSequence(inp);
      print("INPUT: '$inp' -> ArithmeticParser: ${res?.expression} = ${res?.result} | NumberParser: $seq");
    }
  });
}
