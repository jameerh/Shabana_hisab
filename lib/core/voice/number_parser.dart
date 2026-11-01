import '../voice_ai/dialect_normalizer.dart';

class NumberParser {
  static List<double> parseSequence(String text) {
    String cleaned = DialectNormalizer.cleanNoise(text);
    
    // Convert operators and local number words to a processable format
    List<String> words = cleaned.split(RegExp(r'\s+'));
    List<double> numbers = [];

    for (var word in words) {
      double? val = double.tryParse(word);
      val ??= DialectNormalizer.normalizeNumber(word);
      
      if (val != null) {
        numbers.add(val);
      }
    }

    return numbers;
  }
}
