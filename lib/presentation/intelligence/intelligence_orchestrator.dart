import 'engines/forecast_engine.dart';
import 'engines/liquidity_engine.dart';
import 'engines/cash_flow_engine.dart';
import 'engines/recommendation_engine_v2.dart';
import 'engines/insight_engine.dart';
import '../budget/services/budget_engine.dart';
import '../goals/services/goal_engine.dart';
import '../../data/database/database.dart';
import 'models/engine_metadata.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';

/// IntelligenceOrchestrator enforces the decoupled pipeline sequence per ADR-015:
/// Forecast -> Budget -> Goal -> Liquidity -> Cash Flow -> Recommendation -> Insight Engine
class IntelligenceOrchestrator {
  final AppDatabase _db;
  late final BudgetEngine _budgetEngine;
  late final GoalEngine _goalEngine;
  late final ForecastEngine _forecastEngine;
  late final LiquidityEngine _liquidityEngine;
  late final CashFlowEngine _cashFlowEngine;
  late final RecommendationEngineV2 _recommendationEngine;
  late final InsightEngine _insightEngine;

  IntelligenceOrchestrator(this._db) {
    _budgetEngine = BudgetEngine();
    _goalEngine = GoalEngine();
    _forecastEngine = ForecastEngine(_db);
    _liquidityEngine = LiquidityEngine(_db);
    _cashFlowEngine = CashFlowEngine(_db);
    _recommendationEngine = RecommendationEngineV2(_db);
    _insightEngine = InsightEngine(_db);

    // Register BudgetEngine & GoalEngine Metadata per ADR-016
    EngineTelemetryRegistry().registerOrUpdate(EngineMetadata(
      engineId: 'BudgetEngine',
      engineVersion: '1.0.0',
      inputStates: ['Budgets', 'Transactions', 'BudgetCategoryMappings'],
      outputStates: ['BudgetState', 'BudgetSnapshots'],
      executionOrder: 1,
      executionFrequency: 'ON_MUTATION_AND_START',
    ));

    EngineTelemetryRegistry().registerOrUpdate(EngineMetadata(
      engineId: 'GoalEngine',
      engineVersion: '1.0.0',
      inputStates: ['Goals', 'GoalHistory'],
      outputStates: ['GoalState'],
      executionOrder: 2,
      executionFrequency: 'ON_MUTATION_AND_START',
    ));
  }

  Future<void> runPipeline(int profileId) async {
    try {
      debugPrint('Running Financial Intelligence Pipeline for Profile $profileId');

      // 1. Budget Engine Execution & Telemetry
      final bStopwatch = Stopwatch()..start();
      await _budgetEngine.evaluateBudgetStateAndSnapshots(profileId);
      bStopwatch.stop();
      EngineTelemetryRegistry().recordExecution(
        engineId: 'BudgetEngine',
        durationMs: bStopwatch.elapsedMilliseconds,
      );

      // 2. Goal Engine Execution & Telemetry
      final gStopwatch = Stopwatch()..start();
      final activeGoals = await (_db.select(_db.goals)..where((g) => g.profileId.equals(profileId))).get();
      for (var goal in activeGoals) {
        final history = await (_db.select(_db.goalHistory)..where((h) => h.goalId.equals(goal.id))).get();
        final stateCompanion = _goalEngine.evaluateGoal(goal: goal, history: history);
        
        final existing = await (_db.select(_db.goalState)..where((s) => s.goalId.equals(goal.id))).getSingleOrNull();
        if (existing == null) {
          await _db.into(_db.goalState).insert(stateCompanion);
        } else {
          await (_db.update(_db.goalState)..where((s) => s.id.equals(existing.id))).write(stateCompanion);
        }
      }
      gStopwatch.stop();
      EngineTelemetryRegistry().recordExecution(
        engineId: 'GoalEngine',
        durationMs: gStopwatch.elapsedMilliseconds,
      );

      // 3. Forecast Engine (ForecastState)
      await _forecastEngine.run(profileId);

      // 4. Liquidity Engine (LiquidityState)
      await _liquidityEngine.run(profileId);

      // 5. Cash Flow Engine (CashFlowState & FOS Hero Score)
      await _cashFlowEngine.run(profileId);

      // 6. Recommendation Engine V2 (Recommendations per ADR-014)
      await _recommendationEngine.run(profileId);

      // 7. Insight Engine (Insights per ADR-015/016)
      await _insightEngine.run(profileId);

      debugPrint('Financial Intelligence Pipeline Completed Successfully for Profile $profileId');
    } catch (e, stack) {
      debugPrint('Error in Financial Intelligence Pipeline: $e\n$stack');
    }
  }
}
