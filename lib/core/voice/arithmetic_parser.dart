import 'package:math_expressions/math_expressions.dart';
import '../voice_ai/dialect_normalizer.dart';

class ArithmeticResult {
  final String expression;
  final double result;
  final String? rawInput;

  ArithmeticResult(this.expression, this.result, {this.rawInput});
}

class ArithmeticParser {
  static final Map<String, String> _operatorMap = {
    // Addition
    'plus': '+', 'add': '+', 'added to': '+', 'and': '+', 'अधिक': '+', 'अजून': '+', 'आणि': '+', 'मिळवून': '+', 'मिळवले': '+', 'प्लस': '+', 'टाकले': '+',
    // Subtraction
    'minus': '-', 'less': '-', 'take away': '-', 'subtracted from': '-', 'subtract': '-', 'discount': '-', 'vaja': '-', 'वजा': '-', 'कमी': '-', 'कमी केले': '-', 'घालवले': '-', 'मायनस': '-', 'काढले': '-',
    // Multiplication
    'multiplied by': '*', 'multiply by': '*', 'into': '*', 'multiply': '*', 'times': '*', 'गुणिले': '*', 'पट': '*', 'गुणाकार': '*', 'इंटू': '*', 'guntile': '*', 'गुंतिले': '*',
    // Division
    'divided by': '/', 'divide by': '/', 'upon': '/', 'divide': '/', 'divided': '/', 'भागिले': '/', 'हिस्से': '/', 'डिव्हाइड': '/', 'वाटले': '/', 'bhag dila': '/', 'bhag de': '/',
  };

  static final Map<String, double> _colloquialNumbers = {
    'दीडशे': 150, 'didshe': 150,
    'अडीचशे': 250, 'adichshe': 250,
    'सव्वाशे': 125, 'savvashe': 125,
    'साडेतीनशे': 350, 'sadetinshe': 350,
    'साडेचारशे': 450, 'sadecharshe': 450,
    'साडेपाचशे': 550, 'sadepachshe': 550,
    'सव्वा दोनशे': 225, 'सव्वा दोन': 2.25,
    'पावणेदोनशे': 175, 'pavane donshe': 175,
    'पावणे दोनशे': 175,
    'पावणेतीनशे': 275, 'pavane tinshe': 275,
    'पावणे तीनशे': 275,
    'पावणेचारशे': 375, 'pavane charshe': 375,
    'पावणे चारशे': 375,
    // Hundreds Combinations (1100 to 1900)
    'अकराशे': 1100, 'akarashe': 1100,
    'बाराशे': 1200, 'barashe': 1200,
    'तेराशे': 1300, 'terashe': 1300,
    'चौदाशे': 1400, 'chaudashe': 1400,
    'पंधराशे': 1500, 'pandhrashe': 1500,
    'सोळाशे': 1600, 'solashe': 1600,
    'सतराशे': 1700, 'satarashe': 1700,
    'अठराशे': 1800, 'atharashe': 1800,
    'एकोणीसशे': 1900, 'ekonishe': 1900,

    'सव्वा': 1.25,
    'दीड': 1.5,
    'अडीच': 2.5,
    'साडे': 0.5,
  };

  static final List<String> _stopWords = [
    'रुपये', 'रुपया', 'rupees', 'rupee', 'पैसे', 'paise', 'द्या', 'घ्या', 'झाले', 'total', 'झालेत', 'घे', 'दे',
    'is equal to', 'equals to', 'equals', 'equal', 'barobar kiti', 'barobar', 'kiti', 'hota', 'zale', 'किती', 'बरोबर'
  ];

  static ArithmeticResult? parse(String text) {
    if (text.isEmpty) return null;
    
    String raw = text;
    String cleaned = text.toLowerCase();
    
    // 1. Remove Stop Words
    for (var stop in _stopWords) {
      cleaned = cleaned.replaceAll(stop, '');
    }

    // 2. Normalize Devanagari digits to ASCII digits
    cleaned = cleaned
        .replaceAll('०', '0').replaceAll('१', '1').replaceAll('२', '2')
        .replaceAll('३', '3').replaceAll('४', '4').replaceAll('५', '5')
        .replaceAll('६', '6').replaceAll('७', '7').replaceAll('८', '8')
        .replaceAll('९', '9');

    // 2.1 Handle hybrid STT digit + 'शे' patterns (e.g., "13शे" -> "1300", "12 शे" -> "1200")
    cleaned = cleaned.replaceAllMapped(RegExp(r'(\d+)\s*शे(?=[^\u0900-\u097F]|$)'), (m) {
      final multiplier = int.tryParse(m.group(1)!) ?? 1;
      return ' ${multiplier * 100} ';
    });

    // 2.2 Handle Colloquial Numbers & Hundreds Combinations
    _colloquialNumbers.forEach((key, value) {
      cleaned = cleaned.replaceAll(key, ' ${value.toString()} ');
    });

    // 3. Map Operators (Longest first to avoid partial matches)
    final sortedKeys = _operatorMap.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    for (var key in sortedKeys) {
      cleaned = cleaned.replaceAll(key, ' ${_operatorMap[key]} ');
    }

    // 4. Tokenize
    List<String> rawTokens = cleaned.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    List<String> normalizedTokens = [];

    // 5. Advanced Number Word Combination (Marathi specific)
    double currentNum = 0;
    bool inNumMode = false;

    for (int i = 0; i < rawTokens.length; i++) {
      String token = rawTokens[i];

      if (['+', '-', '*', '/'].contains(token)) {
        if (inNumMode) {
          normalizedTokens.add(currentNum.toString());
          inNumMode = false;
          currentNum = 0;
        }
        normalizedTokens.add(token);
        continue;
      }

      double? val = double.tryParse(token);
      val ??= DialectNormalizer.normalizeNumber(token);

      if (val != null) {
        if (!inNumMode) {
          currentNum = val;
          inNumMode = true;
        } else {
          // Combination logic
          if (val == 100 || val == 1000 || val == 100000 || val == 10000000) {
            // It's a multiplier (e.g., "don" "hazar")
            if (currentNum > 0) currentNum *= val;
            else currentNum = val;
          } else {
            // It's an additive number (e.g., "don hazar" "pachshe")
            if (val > currentNum && currentNum < 100) {
              // Handle "one thousand" where "thousand" is bigger
              currentNum *= val;
            } else {
               currentNum += val;
            }
          }
        }
      } else {
        // Not a number or operator, flush if needed
        if (inNumMode) {
          normalizedTokens.add(currentNum.toString());
          inNumMode = false;
          currentNum = 0;
        }
      }
    }
    
    if (inNumMode) {
      normalizedTokens.add(currentNum.toString());
    }

    if (normalizedTokens.isEmpty) return null;

    // 6. Build and Evaluate
    return _evaluate(normalizedTokens, raw);
  }

  static ArithmeticResult? _evaluate(List<String> tokens, String raw) {
    // Preserve all tokens including leading operators for incremental commands
    if (tokens.isEmpty) return null;

    String expressionStr = tokens.join(' ');
    
    try {
      Parser p = Parser();
      Expression exp = p.parse(expressionStr);
      ContextModel cm = ContextModel();
      double evalResult = exp.evaluate(EvaluationType.REAL, cm);
      
      return ArithmeticResult(
        expressionStr, 
        evalResult, 
        rawInput: raw
      );
    } catch (e) {
      // Fallback: Sequential evaluation if math_expressions fails for some reason
      return _sequentialFallback(tokens, raw);
    }
  }

  static ArithmeticResult? _sequentialFallback(List<String> tokens, String raw) {
    if (tokens.isEmpty) return null;

    double result = 0;
    String currentOp = '+';
    String finalExpr = "";

    for (int i = 0; i < tokens.length; i++) {
      String token = tokens[i];
      if (['+', '-', '*', '/'].contains(token)) {
        currentOp = token;
        finalExpr += " $token ";
      } else {
        double? val = double.tryParse(token);
        if (val == null) {
          val = DialectNormalizer.normalizeNumber(token);
        }
        if (val == null) continue;
        
        // If this is not the first token and the previous token was a number,
        // assume addition as the implicit operator (handles sequences like "100 200").
        if (i > 0 && !['+', '-', '*', '/'].contains(tokens[i - 1])) {
          currentOp = '+';
          finalExpr += " + ";
        }

        String displayVal = val.toString();
        if (displayVal.endsWith('.0')) {
          displayVal = displayVal.substring(0, displayVal.length - 2);
        }
        finalExpr += displayVal;

        switch (currentOp) {
          case '+': result += val; break;
          case '-': result -= val; break;
          case '*': result *= val; break;
          case '/': if (val != 0) result /= val; break;
          case '': result += val; break; // Default to addition
        }
        currentOp = ''; // Reset op for next iteration
      }
    }

    if (finalExpr.isEmpty) return null;

    return ArithmeticResult(finalExpr.trim(), result, rawInput: raw);
  }
}
