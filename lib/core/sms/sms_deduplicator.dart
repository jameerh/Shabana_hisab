import '../../data/database/database.dart';
import 'sms_parsed_result.dart';

class SmsDeduplicator {
  /// Deduplicates in-memory parsed results against:
  /// 1. Database SHA-256 fingerprints in [existingHashes]
  /// 2. In-session duplicate fingerprints
  /// 3. Existing core database transactions by amount, timeframe, and account
  static List<SmsParsedResult> filterNewResults({
    required List<SmsParsedResult> candidates,
    required Set<String> existingHashes,
    required List<Transaction> existingTransactions,
  }) {
    final List<SmsParsedResult> deduplicated = [];
    final Set<String> sessionHashes = {};

    for (final candidate in candidates) {
      // Check SHA-256 fingerprint collision
      if (existingHashes.contains(candidate.hashFingerprint) ||
          sessionHashes.contains(candidate.hashFingerprint)) {
        continue; // Skip duplicate hash
      }

      // Check transaction financial collision (same amount & timestamp window ±5 mins)
      final hasTxCollision = existingTransactions.any((tx) {
        if ((tx.amount - candidate.amount).abs() > 0.01) return false;
        final timeDiff = tx.timestamp.difference(candidate.timestamp).inMinutes.abs();
        return timeDiff <= 5;
      });

      if (hasTxCollision) {
        continue; // Skip transaction collision
      }

      sessionHashes.add(candidate.hashFingerprint);
      deduplicated.add(candidate);
    }

    return deduplicated;
  }
}
