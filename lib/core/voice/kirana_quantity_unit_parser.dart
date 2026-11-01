import '../voice_ai/dialect_normalizer.dart';

class QtyUnitParseResult {
  final String itemName;
  final double quantity;
  final String unit;
  final bool hasExplicitQty;
  final bool hasExplicitUnit;

  QtyUnitParseResult({
    required this.itemName,
    required this.quantity,
    required this.unit,
    this.hasExplicitQty = false,
    this.hasExplicitUnit = false,
  });
}

class KiranaQuantityUnitParser {
  static const Map<String, double> _fractionMap = {
    '½': 0.5,
    '¼': 0.25,
    '¾': 0.75,
    '⅓': 0.33,
    '⅔': 0.67,
    'half': 0.5,
    'quarter': 0.25,
    'अर्धा': 0.5,
    'ardha': 0.5,
    'aadha': 0.5,
    'पाव': 0.25,
    'pav': 0.25,
    'paav': 0.25,
    'पाऊण': 0.75,
    'paoon': 0.75,
    'सव्वा': 1.25,
    'savva': 1.25,
    'दीड': 1.5,
    'deed': 1.5,
    'अडीच': 2.5,
    'adeech': 2.5,
    'साडेतीन': 3.5,
  };

  static const Map<String, double> _wordNumbers = {
    'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
    'एक': 1, 'दोन': 2, 'तीन': 3, 'चार': 4, 'पाच': 5, 'सहा': 6, 'सात': 7, 'आठ': 8, 'नऊ': 9, 'दहा': 10,
  };

  static const Map<String, String> _unitAliasMap = {
    'kg': 'kilo', 'kilo': 'kilo', 'kgs': 'kilo', 'kilos': 'kilo',
    'g': 'gm', 'gm': 'gm', 'gram': 'gm', 'grams': 'gm', 'gramm': 'gm',
    'l': 'liter', 'ltr': 'liter', 'liter': 'liter', 'litre': 'liter', 'liters': 'liter', 'litres': 'liter',
    'ml': 'ml',
    'packet': 'packet', 'packit': 'packet', 'pkt': 'packet', 'pk': 'packet', 'pack': 'packet', 'packets': 'packet',
    'bottle': 'bottle', 'bot': 'bottle', 'bottles': 'bottle',
    'dozen': 'dozen', 'duzzan': 'dozen', 'dazzen': 'dozen', 'doz': 'dozen',
    'bundle': 'bundle', 'bundles': 'bundle',
    'piece': 'pc', 'pieces': 'pc', 'pcs': 'pc', 'pc': 'pc',
    'unit': 'unit', 'units': 'unit',
    'nos': 'nos', 'no': 'nos', 'number': 'nos', 'numbers': 'nos', 'nag': 'nos',
  };

  QtyUnitParseResult parseLine(String line) {
    String text = line.trim();
    if (text.isEmpty) {
      return QtyUnitParseResult(itemName: '', quantity: 1.0, unit: 'nos');
    }

    // 1. Special colloquial terms
    if (RegExp(r'\bpavsher\b|\bpav\s*kilo\b|\bpav-kilo\b', caseSensitive: false).hasMatch(text)) {
      text = text.replaceAll(RegExp(r'\bpavsher\b|\bpav\s*kilo\b|\bpav-kilo\b', caseSensitive: false), '0.25 kilo');
    }

    // 2. Unicode composite and standalone fractions
    text = _convertUnicodeFractions(text);

    // 3. Fraction slash spaces e.g. "1 / 2" -> "1/2"
    text = text.replaceAllMapped(RegExp(r'(\d+)\s*/\s*(\d+)'), (m) => '${m[1]}/${m[2]}');

    // 4. Multiplier formatting e.g. "Sugar x2" or "Sugar 2x" -> "Sugar 2"
    text = text.replaceAllMapped(RegExp(r'\b[xX]\s*(\d+(?:\.\d+)?)\b'), (m) => m[1]!);
    text = text.replaceAllMapped(RegExp(r'\b(\d+(?:\.\d+)?)\s*[xX]\b'), (m) => m[1]!);

    // 5. Hyphenated quantity e.g. "Sugar-2" -> "Sugar 2"
    text = text.replaceAllMapped(RegExp(r'([a-zA-Z\u0900-\u097F]+)-(\d+(?:\.\d+)?)'), (m) => '${m[1]} ${m[2]}');

    // 6. Item attached number e.g. "Chhole1" -> "Chhole 1"
    text = text.replaceAllMapped(RegExp(r'([a-zA-Z\u0900-\u097F]{2,})(\d+(?:\.\d+)?)'), (m) => '${m[1]} ${m[2]}');

    // 7. Quantity attached unit e.g. "1kilo" -> "1 kilo", "250gm" -> "250 gm"
    text = text.replaceAllMapped(RegExp(r'\b(\d+(?:\.\d+)?)\s*([a-zA-Z\u0900-\u097F]+)\b'), (m) {
      return '${m[1]} ${m[2]}';
    });

    List<String> words = text.split(RegExp(r'\s+'));
    if (words.isEmpty) {
      return QtyUnitParseResult(itemName: text, quantity: 1.0, unit: 'nos');
    }

    double? extractedQty;
    String? extractedUnit;
    int qtyIndex = -1;
    int unitIndex = -1;

    // Search for quantity in words
    for (int i = 0; i < words.length; i++) {
      double? numVal = _tryParseQuantity(words[i]);

      if (numVal != null) {
        extractedQty = numVal;
        qtyIndex = i;

        // Check if next word is unit
        if (i + 1 < words.length) {
          final nextW = words[i + 1].toLowerCase();
          if (_unitAliasMap.containsKey(nextW)) {
            extractedUnit = _unitAliasMap[nextW];
            unitIndex = i + 1;
          }
        }
        break;
      }
    }

    // If unit was not right after qty, search elsewhere in words
    if (extractedUnit == null) {
      for (int i = 0; i < words.length; i++) {
        if (i == qtyIndex) continue;
        final w = words[i].toLowerCase();
        if (_unitAliasMap.containsKey(w)) {
          extractedUnit = _unitAliasMap[w];
          unitIndex = i;
          break;
        }
      }
    }

    // Build Item Name by excluding quantity and unit words
    List<String> nameWords = [];
    for (int i = 0; i < words.length; i++) {
      if (i == qtyIndex || i == unitIndex) continue;
      nameWords.add(words[i]);
    }

    String itemName = nameWords.join(' ').trim();
    if (itemName.isEmpty) {
      itemName = text; // Fallback
    }

    return QtyUnitParseResult(
      itemName: itemName,
      quantity: extractedQty ?? 1.0,
      unit: extractedUnit ?? (extractedQty != null ? 'nos' : 'nos'),
      hasExplicitQty: extractedQty != null,
      hasExplicitUnit: extractedUnit != null,
    );
  }

  double? _tryParseQuantity(String token) {
    String w = token.trim().toLowerCase();
    if (w.isEmpty) return null;

    // Direct double parsing e.g. "2", "0.5", "1.5"
    double? val = double.tryParse(w);
    if (val != null) return val;

    // Decimal starting with dot e.g. ".5"
    if (w.startsWith('.')) {
      val = double.tryParse('0$w');
      if (val != null) return val;
    }

    // Fraction e.g. "1/2", "3/4", "1/4"
    if (w.contains('/')) {
      final parts = w.split('/');
      if (parts.length == 2) {
        final n = double.tryParse(parts[0].trim());
        final d = double.tryParse(parts[1].trim());
        if (n != null && d != null && d != 0) {
          return n / d;
        }
      }
    }

    // Fraction map e.g. "half", "quarter", "अर्धा", "पाव"
    if (_fractionMap.containsKey(w)) {
      return _fractionMap[w];
    }

    // Dialect normalizer & word numbers e.g. "एक", "दोन", "two"
    val = DialectNormalizer.normalizeNumber(w);
    if (val != null) return val;

    if (_wordNumbers.containsKey(w)) {
      return _wordNumbers[w];
    }

    return null;
  }

  String _convertUnicodeFractions(String input) {
    String res = input;
    // Composite unicode fractions e.g. "1½" -> "1.5"
    res = res.replaceAllMapped(RegExp(r'(\d+)½'), (m) => '${double.parse(m[1]!) + 0.5}');
    res = res.replaceAllMapped(RegExp(r'(\d+)¼'), (m) => '${double.parse(m[1]!) + 0.25}');
    res = res.replaceAllMapped(RegExp(r'(\d+)¾'), (m) => '${double.parse(m[1]!) + 0.75}');
    // Standalone unicode fractions e.g. "½" -> "0.5"
    res = res.replaceAll('½', '0.5');
    res = res.replaceAll('¼', '0.25');
    res = res.replaceAll('¾', '0.75');
    res = res.replaceAll('⅓', '0.33');
    res = res.replaceAll('⅔', '0.67');
    return res;
  }
}
