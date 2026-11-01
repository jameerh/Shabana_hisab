import 'phonetic_matcher.dart';
import 'grocery_dictionary.dart';
import 'dialect_normalizer.dart';
import '../../main.dart';
import '../../data/database/database.dart';
import 'package:drift/drift.dart' as drift;

class VoiceUnderstandingResult {
  final String originalText;
  final String correctedText;
  final double confidence;
  final List<String> suggestions;

  VoiceUnderstandingResult({
    required this.originalText,
    required this.correctedText,
    required this.confidence,
    this.suggestions = const [],
  });
}

class VoiceUnderstandingEngine {
  final int profileId;

  VoiceUnderstandingEngine({required this.profileId});

  Future<VoiceUnderstandingResult> understandGrocery(String text) async {
    String cleaned = DialectNormalizer.cleanNoise(text);
    
    // 1. Check Learning Memory (DB)
    final corrections = await database.getVoiceCorrections(profileId, 'grocery');
    for (var corr in corrections) {
      if (corr.rawInput.toLowerCase() == cleaned.toLowerCase()) {
        return VoiceUnderstandingResult(
          originalText: text,
          correctedText: corr.correctedText,
          confidence: 1.0,
        );
      }
    }

    // 2. Dictionary Lookup
    String? canonical = GroceryDictionary.lookup(cleaned);
    if (canonical != null) {
      return VoiceUnderstandingResult(
        originalText: text,
        correctedText: canonical,
        confidence: 0.95,
      );
    }

    // 3. Phonetic Fuzzy Matching
    final allAliases = GroceryDictionary.getAllAliases();
    String? bestMatchAlias = PhoneticMatcher.findBestMatch(cleaned, allAliases, threshold: 0.7);
    
    if (bestMatchAlias != null) {
      String bestCanonical = GroceryDictionary.getCanonicalByAlias(bestMatchAlias);
      double sim = PhoneticMatcher.similarity(cleaned, bestMatchAlias);
      
      return VoiceUnderstandingResult(
        originalText: text,
        correctedText: bestCanonical,
        confidence: sim,
        suggestions: [bestCanonical],
      );
    }

    // 4. Fallback: No change
    return VoiceUnderstandingResult(
      originalText: text,
      correctedText: text,
      confidence: 0.5,
    );
  }

  Future<void> learnCorrection(String raw, String corrected, String contextType) async {
    await database.addOrUpdateCorrection(VoiceCorrectionsCompanion.insert(
      rawInput: raw,
      correctedText: corrected,
      contextType: contextType,
      profileId: profileId,
    ));
  }
}
