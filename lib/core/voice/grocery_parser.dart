import '../voice_ai/dialect_normalizer.dart';
import '../voice_ai/voice_understanding_engine.dart';
import '../voice_ai/grocery_dictionary.dart';

class GroceryParsedItem {
  final String itemName;
  final double quantity;
  final String unit;

  final String category;

  GroceryParsedItem({required this.itemName, required this.quantity, required this.unit, this.category = 'Other'});
}

class GroceryParser {
  final VoiceUnderstandingEngine engine;

  GroceryParser({required this.engine});

  Future<List<GroceryParsedItem>> parse(String text) async {
    // Noise filtering and multi-item splitting
    String cleaned = DialectNormalizer.cleanNoise(text);
    
    // Split by common separators OR by "item-looking" boundaries
    // Pattern: split at space when the next part looks like [ItemName] [Number]
    // Uses lookahead to find space followed by non-digit text then a digit
    List<String> segments = cleaned.split(RegExp(r'\b(आणि|plus|and|,)\b|\s+(?=[^0-9\s]+\s+[0-9])'));
    
    List<GroceryParsedItem> items = [];

    for (var segment in segments) {
      if (segment.trim().isEmpty) continue;
      
      // Parse individual segment
      final item = await _parseSegment(segment.trim());
      if (item != null) {
        items.add(item);
      }
    }

    return items;
  }

  Future<GroceryParsedItem?> _parseSegment(String segment) async {
    List<String> words = segment.split(RegExp(r'\s+'));
    
    String rawItemName = "";
    double quantity = 1.0;
    String unit = "nos";
    
    int qtyIndex = -1;

    // Search for numbers or local number words
    for (int i = 0; i < words.length; i++) {
      double? val = double.tryParse(words[i]);
      val ??= DialectNormalizer.normalizeNumber(words[i]);
      
      if (val != null) {
        qtyIndex = i;
        quantity = val;
        break;
      }
    }

    if (qtyIndex != -1) {
      rawItemName = words.sublist(0, qtyIndex).join(' ');
      if (qtyIndex + 1 < words.length) {
        unit = words.sublist(qtyIndex + 1).join(' ');
      }
    } else {
      rawItemName = segment;
    }

    // Use Engine to understand the raw item name
    final understood = await engine.understandGrocery(rawItemName);
    
    if (understood.correctedText.isNotEmpty) {
      final category = GroceryDictionary.getCategory(understood.correctedText);
      return GroceryParsedItem(
        itemName: understood.correctedText,
        quantity: quantity,
        unit: unit,
        category: category,
      );
    }
    
    return null;
  }
}
