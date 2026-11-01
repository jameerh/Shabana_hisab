import 'kirana_import_engine.dart';

class KiranaDuplicateDetector {
  List<ImportedParsedItem> autoMergeIntraList(List<ImportedParsedItem> items) {
    if (items.length <= 1) return items;

    final Map<String, List<ImportedParsedItem>> grouped = {};

    for (var item in items) {
      final key = '${item.canonicalName.toLowerCase()}_${item.unit.toLowerCase()}';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    List<ImportedParsedItem> result = [];

    for (var group in grouped.values) {
      if (group.length == 1) {
        result.add(group.first);
      } else {
        // Merge quantities for items with matching canonical name and unit
        final first = group.first;
        double totalQty = 0;
        List<String> rawTexts = [];
        int maxConfidence = 0;

        for (var item in group) {
          totalQty += item.quantity;
          rawTexts.add(item.rawText);
          if (item.confidence > maxConfidence) {
            maxConfidence = item.confidence;
          }
        }

        result.add(first.copyWith(
          quantity: totalQty,
          rawText: rawTexts.join(' + '),
          confidence: maxConfidence,
          isDuplicate: true,
          duplicateStrategy: DuplicateStrategy.merge,
        ));
      }
    }

    return result;
  }
}
