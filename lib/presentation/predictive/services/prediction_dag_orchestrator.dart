import '../../../data/database/database.dart';
import '../engines/trend_engine.dart';
import '../engines/behavior_engine.dart';
import '../engines/seasonality_engine.dart';
import '../engines/cash_flow_prediction_engine.dart';
import '../engines/risk_engine.dart';
import '../engines/health_intelligence_engine.dart';
import '../engines/optimization_engine.dart';
import '../engines/anomaly_engine.dart';
import '../engines/predictive_recommendation_engine.dart';
import '../engines/predictive_insight_engine.dart';
import 'predictive_telemetry.dart';

class PredictionDagOrchestrator {
  final AppDatabase _db;
  final PredictiveTelemetryRegistry _telemetry = PredictiveTelemetryRegistry();

  PredictionDagOrchestrator(this._db);

  Future<void> executePipeline(int profileId) async {
    final sw = Stopwatch()..start();

    // Node 1: Trend Engine
    await _executeNode('TrendEngine', () => TrendEngine(_db).execute(profileId));

    // Node 2: Behavior Engine
    await _executeNode('BehaviorEngine', () => BehaviorEngine(_db).execute(profileId));

    // Node 3: Seasonality Engine
    await _executeNode('SeasonalityEngine', () => SeasonalityEngine(_db).execute(profileId));

    // Node 4: Cash Flow Prediction Engine
    await _executeNode('CashFlowPredictionEngine', () => CashFlowPredictionEngine(_db).predict(profileId));

    // Node 5: Risk Engine
    await _executeNode('RiskEngine', () => RiskEngine(_db).execute(profileId));

    // Node 6: Health Intelligence Engine
    await _executeNode('HealthIntelligenceEngine', () => HealthIntelligenceEngine(_db).analyze(profileId));

    // Node 7: Optimization Engine
    await _executeNode('OptimizationEngine', () => OptimizationEngine(_db).execute(profileId));

    // Node 8: Anomaly Engine
    await _executeNode('AnomalyEngine', () => AnomalyEngine(_db).execute(profileId));

    // Node 9: Predictive Recommendation Engine
    await _executeNode('PredictiveRecommendationEngine', () => PredictiveRecommendationEngine(_db).execute(profileId));

    // Node 10: Predictive Insight Engine
    await _executeNode('PredictiveInsightEngine', () => PredictiveInsightEngine(_db).execute(profileId));

    sw.stop();
    _telemetry.recordTelemetry(PredictiveEngineTelemetry(
      engineId: 'PredictionDagOrchestrator',
      executionTimeMs: sw.elapsedMilliseconds,
      isHealthy: true,
    ));
  }

  Future<void> _executeNode(String name, Future<dynamic> Function() action) async {
    final sw = Stopwatch()..start();
    bool healthy = true;
    String? err;
    try {
      await action();
    } catch (e) {
      healthy = false;
      err = e.toString();
    } finally {
      sw.stop();
      _telemetry.recordTelemetry(PredictiveEngineTelemetry(
        engineId: name,
        executionTimeMs: sw.elapsedMilliseconds,
        isHealthy: healthy,
        errorMessage: err,
      ));
    }
  }
}
