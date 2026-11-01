import 'package:drift/drift.dart';
import '../../../data/database/database.dart';

class PredictiveInsightEngine {
  final AppDatabase _db;

  PredictiveInsightEngine(this._db);

  Future<void> execute(int profileId) async {
    final trends = await (_db.select(_db.trendState)..where((t) => t.profileId.equals(profileId))).get();
    final seasonality = await (_db.select(_db.seasonalityState)..where((s) => s.profileId.equals(profileId))).get();

    for (var t in trends) {
      if (t.velocity == 'INCREASING' && t.percentageChange > 20.0) {
        await _db.into(_db.insights).insertOnConflictUpdate(InsightsCompanion.insert(
          profileId: profileId,
          title: '${t.categoryName} Acceleration',
          observation: '${t.categoryName} spend velocity increased by ${t.percentageChange.toStringAsFixed(0)}% vs last month.',
          category: 'SPENDING',
          severity: const Value('WARNING'),
          status: const Value('ACTIVE'),
          metricChange: Value('+${t.percentageChange.toStringAsFixed(0)}%'),
          sourceEngine: 'TrendEngine',
          createdAt: Value(DateTime.now()),
        ));
      }
    }

    for (var s in seasonality) {
      await _db.into(_db.insights).insertOnConflictUpdate(InsightsCompanion.insert(
        profileId: profileId,
        title: '${s.seasonName} Seasonal Pattern',
        observation: 'Upcoming ${s.seasonName} seasonal period historically increases spend by ${s.expectedSpikePct.toStringAsFixed(0)}%.',
        category: 'SEASONAL',
        severity: const Value('INFO'),
        status: const Value('ACTIVE'),
        metricChange: Value('+${s.expectedSpikePct.toStringAsFixed(0)}%'),
        sourceEngine: 'SeasonalityEngine',
        createdAt: Value(DateTime.now()),
      ));
    }
  }
}
