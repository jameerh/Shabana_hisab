import 'package:drift/drift.dart';
import '../../../data/database/database.dart';

class PredictiveRecommendationEngine {
  final AppDatabase _db;

  PredictiveRecommendationEngine(this._db);

  Future<void> execute(int profileId) async {
    final risks = await (_db.select(_db.riskState)..where((r) => r.profileId.equals(profileId))).get();
    final opts = await (_db.select(_db.optimizationState)..where((o) => o.profileId.equals(profileId))).get();

    for (var r in risks) {
      if (r.severity == 'CRITICAL' || r.severity == 'HIGH') {
        await _db.into(_db.recommendations).insertOnConflictUpdate(RecommendationsCompanion.insert(
          profileId: profileId,
          title: 'Mitigate ${r.riskType}',
          description: r.explanation,
          score: 95.0,
          priority: 1,
          confidence: 0.95,
          category: 'RISK',
          sourceEngine: 'PredictiveRiskEngine',
          whyShown: 'Predictive risk engine calculated high probability of financial friction.',
          action: const Value('VIEW_RISKS'),
          expiresAt: Value(DateTime.now().add(const Duration(days: 3))),
        ));
      }
    }

    for (var o in opts) {
      if (o.potentialYearlySavings > 3000) {
        await _db.into(_db.recommendations).insertOnConflictUpdate(RecommendationsCompanion.insert(
          profileId: profileId,
          title: o.opportunityTitle,
          description: o.whyShown,
          score: 85.0,
          priority: 2,
          confidence: 0.90,
          category: 'LIQUIDITY',
          sourceEngine: 'OptimizationEngine',
          whyShown: 'Potential to unlock ₹${o.potentialYearlySavings.toStringAsFixed(0)} in annual savings.',
          action: const Value('VIEW_OPTIMIZATIONS'),
          expiresAt: Value(DateTime.now().add(const Duration(days: 7))),
        ));
      }
    }
  }
}
