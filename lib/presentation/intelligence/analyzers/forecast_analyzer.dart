import '../../../data/database/database.dart';
import 'trend_analyzer.dart';

class ForecastAnalyzer {
  final AppDatabase _db;

  ForecastAnalyzer(this._db);

  Future<List<TrendAnalysisResult>> analyze(int profileId) async {
    List<TrendAnalysisResult> results = [];

    final forecast = await (_db.select(_db.forecastState)..where((f) => f.profileId.equals(profileId))).getSingleOrNull();

    if (forecast != null && forecast.forecastRisk == 'LOW') {
      results.add(TrendAnalysisResult(
        title: 'Stable 30-Day Forecast',
        observation: 'Expected end-of-month balance is healthy based on active recurring and spending rates.',
        category: 'FORECAST',
        severity: 'SUCCESS',
        metricChange: 'LOW Risk',
      ));
    }

    return results;
  }
}
