import 'package:drift/drift.dart';
import '../../../data/database/database.dart';

class AnomalyEngine {
  final AppDatabase _db;

  AnomalyEngine(this._db);

  Future<void> execute(int profileId) async {
    final now = DateTime.now();
    final past7Days = now.subtract(const Duration(days: 7));

    final txs = await (_db.select(_db.transactions)
          ..where((t) => t.profileId.equals(profileId) & t.timestamp.isBiggerOrEqualValue(past7Days))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .get();

    for (int i = 0; i < txs.length; i++) {
      for (int j = i + 1; j < txs.length; j++) {
        if (txs[i].amount == txs[j].amount &&
            txs[i].partyName.toLowerCase() == txs[j].partyName.toLowerCase() &&
            txs[i].type == txs[j].type &&
            txs[i].timestamp.difference(txs[j].timestamp).inMinutes.abs() < 10) {
          
          await _db.into(_db.predictionState).insertOnConflictUpdate(PredictionStateCompanion.insert(
            profileId: profileId,
            predictionType: 'ANOMALY',
            headline: 'Potential Duplicate Transaction Detected',
            details: 'Found two identical transactions of ₹${txs[i].amount} to ${txs[i].partyName} within 10 minutes.',
            confidence: const Value(0.95),
            confidenceFactorsJson: const Value('["Matching Party", "Matching Amount", "Time Proximity < 10 min"]'),
            metricValue: Value(txs[i].amount),
            sourceEngine: 'AnomalyEngine',
            validUntil: Value(DateTime.now().add(const Duration(days: 3))),
            generatedAt: Value(DateTime.now()),
          ));
        }
      }
    }
  }
}
