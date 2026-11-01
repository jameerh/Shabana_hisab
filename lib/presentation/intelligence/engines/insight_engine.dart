import '../../../data/database/database.dart';
import 'package:drift/drift.dart';
import '../analyzers/trend_analyzer.dart';
import '../analyzers/budget_analyzer.dart';
import '../analyzers/goal_analyzer.dart';
import '../analyzers/cash_flow_analyzer.dart';
import '../analyzers/forecast_analyzer.dart';
import '../analyzers/behavior_analyzer.dart';
import '../models/engine_metadata.dart';

/// InsightEngine produces analytical observations (distinct from action Recommendations).
/// It aggregates sub-analyzers (Trend, Budget, Goal, Cash Flow, Forecast, Behavior)
/// and writes to the Insights Drift DB entity.
class InsightEngine {
  final AppDatabase _db;
  late final TrendAnalyzer _trendAnalyzer;
  late final BudgetAnalyzer _budgetAnalyzer;
  late final GoalAnalyzer _goalAnalyzer;
  late final CashFlowAnalyzer _cashFlowAnalyzer;
  late final ForecastAnalyzer _forecastAnalyzer;
  late final BehaviorAnalyzer _behaviorAnalyzer;

  static const String engineId = 'InsightEngine';
  static const String engineVersion = '1.0.0';

  InsightEngine(this._db) {
    _trendAnalyzer = TrendAnalyzer(_db);
    _budgetAnalyzer = BudgetAnalyzer(_db);
    _goalAnalyzer = GoalAnalyzer(_db);
    _cashFlowAnalyzer = CashFlowAnalyzer(_db);
    _forecastAnalyzer = ForecastAnalyzer(_db);
    _behaviorAnalyzer = BehaviorAnalyzer(_db);

    // Register ADR-016 Engine Metadata
    EngineTelemetryRegistry().registerOrUpdate(EngineMetadata(
      engineId: engineId,
      engineVersion: engineVersion,
      inputStates: ['ForecastState', 'BudgetState', 'GoalState', 'LiquidityState', 'CashFlowState', 'Transactions'],
      outputStates: ['Insights'],
      executionOrder: 7,
      executionFrequency: 'ON_MUTATION_AND_START',
    ));
  }

  Future<void> run(int profileId) async {
    final stopwatch = Stopwatch()..start();
    try {
      List<TrendAnalysisResult> candidates = [];

      // Run sub-analyzers
      candidates.addAll(await _trendAnalyzer.analyze(profileId));
      candidates.addAll(await _budgetAnalyzer.analyze(profileId));
      candidates.addAll(await _goalAnalyzer.analyze(profileId));
      candidates.addAll(await _cashFlowAnalyzer.analyze(profileId));
      candidates.addAll(await _forecastAnalyzer.analyze(profileId));
      candidates.addAll(await _behaviorAnalyzer.analyze(profileId));

      // Deduplicate by title
      final Map<String, TrendAnalysisResult> uniqueInsights = {};
      for (var c in candidates) {
        if (!uniqueInsights.containsKey(c.title)) {
          uniqueInsights[c.title] = c;
        }
      }

      final topInsights = uniqueInsights.values.take(6).toList();

      // Persist to Insights table (Replace active)
      await (_db.delete(_db.insights)..where((i) => i.profileId.equals(profileId))).go();

      for (var item in topInsights) {
        await _db.into(_db.insights).insert(InsightsCompanion.insert(
          profileId: profileId,
          title: item.title,
          observation: item.observation,
          category: item.category,
          severity: Value(item.severity),
          status: const Value('ACTIVE'),
          metricChange: Value(item.metricChange),
          sourceEngine: engineId,
          expiresAt: Value(DateTime.now().add(const Duration(days: 7))),
        ));
      }

      stopwatch.stop();
      EngineTelemetryRegistry().recordExecution(
        engineId: engineId,
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      EngineTelemetryRegistry().recordExecution(
        engineId: engineId,
        durationMs: stopwatch.elapsedMilliseconds,
        error: e.toString(),
      );
      rethrow;
    }
  }
}
