import 'text_preprocessor.dart';
import 'kirana_quantity_unit_parser.dart';
import 'kirana_dictionary_resolver.dart';
import 'kirana_category_engine.dart';
import 'kirana_duplicate_detector.dart';

enum DuplicateStrategy {
  merge,
  keepBoth,
  replace,
  skip,
}

class ImportedParsedItem {
  final String id; // temporary unique ID for UI tracking
  String rawText;
  String canonicalName;
  double quantity;
  String unit;
  String category;
  int confidence; // 0 to 100
  bool isUnknown;
  bool isDuplicate;
  DuplicateStrategy duplicateStrategy;

  ImportedParsedItem({
    required this.id,
    required this.rawText,
    required this.canonicalName,
    required this.quantity,
    required this.unit,
    required this.category,
    this.confidence = 100,
    this.isUnknown = false,
    this.isDuplicate = false,
    this.duplicateStrategy = DuplicateStrategy.merge,
  });

  ImportedParsedItem copyWith({
    String? id,
    String? rawText,
    String? canonicalName,
    double? quantity,
    String? unit,
    String? category,
    int? confidence,
    bool? isUnknown,
    bool? isDuplicate,
    DuplicateStrategy? duplicateStrategy,
  }) {
    return ImportedParsedItem(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      canonicalName: canonicalName ?? this.canonicalName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
      isUnknown: isUnknown ?? this.isUnknown,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      duplicateStrategy: duplicateStrategy ?? this.duplicateStrategy,
    );
  }
}

class ImportSummary {
  final int totalParsed;
  final int totalImported;
  final int totalMerged;
  final int totalUnknown;
  final int failedCount;

  ImportSummary({
    required this.totalParsed,
    required this.totalImported,
    required this.totalMerged,
    required this.totalUnknown,
    required this.failedCount,
  });
}

abstract class GroceryImportEngine {
  List<ImportedParsedItem> parse(String input);
}

class KiranaRegexImportEngine implements GroceryImportEngine {
  final TextPreprocessor preprocessor;
  final KiranaQuantityUnitParser qtyUnitParser;
  final KiranaDictionaryResolver dictionaryResolver;
  final KiranaCategoryEngine categoryEngine;
  final KiranaDuplicateDetector duplicateDetector;

  KiranaRegexImportEngine({
    TextPreprocessor? preprocessor,
    KiranaQuantityUnitParser? qtyUnitParser,
    KiranaDictionaryResolver? dictionaryResolver,
    KiranaCategoryEngine? categoryEngine,
    KiranaDuplicateDetector? duplicateDetector,
  })  : preprocessor = preprocessor ?? TextPreprocessor(),
        qtyUnitParser = qtyUnitParser ?? KiranaQuantityUnitParser(),
        dictionaryResolver = dictionaryResolver ?? KiranaDictionaryResolver(),
        categoryEngine = categoryEngine ?? KiranaCategoryEngine(),
        duplicateDetector = duplicateDetector ?? KiranaDuplicateDetector();

  @override
  List<ImportedParsedItem> parse(String input) {
    if (input.trim().isEmpty) return [];

    // Step 1: Preprocess multi-line raw text
    final cleanedLines = preprocessor.processText(input);

    List<ImportedParsedItem> parsedItems = [];
    int idCounter = 1;

    for (var line in cleanedLines) {
      if (line.trim().isEmpty) continue;

      // Step 2: Parse Quantity & Unit & Extract Item Name
      final result = qtyUnitParser.parseLine(line);
      if (result.itemName.trim().isEmpty) continue;

      // Step 3: Resolve Dictionary canonical name and confidence score
      final dictResult = dictionaryResolver.resolve(result.itemName);

      // Step 4: Category Engine resolution
      final category = categoryEngine.detectCategory(dictResult.canonicalName, result.itemName);

      // Calculate confidence score (0 - 100)
      int score = dictResult.confidence;
      if (result.hasExplicitQty) score = (score + 5).clamp(0, 100);
      if (result.hasExplicitUnit) score = (score + 5).clamp(0, 100);

      bool isUnknown = dictResult.isUnknown;

      parsedItems.add(ImportedParsedItem(
        id: 'item_${DateTime.now().microsecondsSinceEpoch}_${idCounter++}',
        rawText: line,
        canonicalName: dictResult.canonicalName,
        quantity: result.quantity,
        unit: result.unit,
        category: category,
        confidence: score,
        isUnknown: isUnknown,
      ));
    }

    // Step 5: Deduplicate intra-list items
    return duplicateDetector.autoMergeIntraList(parsedItems);
  }
}
