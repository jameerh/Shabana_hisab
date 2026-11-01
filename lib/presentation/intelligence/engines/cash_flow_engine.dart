import '../../../data/database/database.dart';
import 'package:drift/drift.dart';
import '../models/engine_metadata.dart';

/// CashFlowEngine consumes published outputs from ForecastEngine, BudgetEngine,
/// GoalEngine, and LiquidityEngine to calculate cash flow metrics and the hero metric:
/// Global Financial Health Score (0-100).
class CashFlowEngine {
  final AppDatabase _db;
  static const String engineId = 'CashFlowEngine';
  static const String engineVersion = '1.0.0';

  CashFlowEngine(this._db) {
    EngineTelemetryRegistry().registerOrUpdate(EngineMetadata(
      engineId: engineId,
      engineVersion: engineVersion,
      inputStates: ['ForecastState', 'LiquidityState', 'BudgetState', 'GoalState'],
      outputStates: ['CashFlowState'],
      executionOrder: 5,
      executionFrequency: 'ON_MUTATION_AND_START',
    ));
  }

  Future<void> run(int profileId) async {
    final stopwatch = Stopwatch()..start();
    try {
      // 1. Read Published Domain Engine States (Decoupled Output Consumption)
      final forecast = await (_db.select(_db.forecastState)..where((f) => f.profileId.equals(profileId))).getSingleOrNull();
      final liquidity = await (_db.select(_db.liquidityState)..where((l) => l.profileId.equals(profileId))).getSingleOrNull();

      // Calculate Average Budget Health & Total Safe To Spend across active budgets
      final budgets = await (_db.select(_db.budgets)..where((b) => b.profileId.equals(profileId))).get();
      double safeToSpend = 0;
      int budgetHealthSum = 0;
      int budgetCount = 0;

      for (var b in budgets) {
        final state = await (_db.select(_db.budgetState)..where((s) => s.budgetId.equals(b.id))).getSingleOrNull();
        if (state != null) {
          safeToSpend += state.safeToSpend;
          budgetHealthSum += state.healthScore;
          budgetCount++;
        }
      }
      double avgBudgetHealth = budgetCount > 0 ? (budgetHealthSum / budgetCount) : 100.0;

      // Calculate Average Goal Health across active goals
      final goals = await (_db.select(_db.goals)..where((g) => g.profileId.equals(profileId) & g.status.equals('ACTIVE'))).get();
      int goalHealthSum = 0;
      int goalCount = 0;
      for (var g in goals) {
        final state = await (_db.select(_db.goalState)..where((s) => s.goalId.equals(g.id))).getSingleOrNull();
        if (state != null) {
          goalHealthSum += state.healthScore;
          goalCount++;
        }
      }
      double avgGoalHealth = goalCount > 0 ? (goalHealthSum / goalCount) : 100.0;

      // 2. Compute Cash Flow Metrics
      double cashPosition = liquidity?.liquidAssets ?? 0;
      double burnRate = forecast?.expectedExpense ?? 0;
      double expectedInc = forecast?.expectedIncome ?? 0;
      double expectedExp = forecast?.expectedExpense ?? 0;
      double expectedRec = forecast?.expectedRecurring ?? 0;
      double netPosition = expectedInc - expectedExp - expectedRec;
      double forecastBalance = forecast?.expectedBalance ?? 0;

      if (safeToSpend == 0 && (liquidity?.available ?? 0) > 0) {
        safeToSpend = liquidity!.available;
      }

      // 3. Compute Global Hero Health Score (0–100)
      double liquidityScore = 100;
      if (liquidity != null) {
        if (liquidity.liquidityRatio < 10) {
          liquidityScore = 20;
        } else if (liquidity.liquidityRatio < 25) {
          liquidityScore = 55;
        } else if (liquidity.liquidityRatio < 50) {
          liquidityScore = 80;
        } else {
          liquidityScore = 95;
        }
      }

      double netScore = 100;
      if (forecast?.forecastRisk == 'CRITICAL' || forecastBalance < 0) {
        netScore = 25;
      } else if (netPosition < 0) {
        netScore = 45;
      } else if (netPosition == 0) {
        netScore = 70;
      } else {
        netScore = 95;
      }

      int globalHealthScore = (
        (avgBudgetHealth * 0.30) + 
        (avgGoalHealth * 0.30) + 
        (liquidityScore * 0.20) + 
        (netScore * 0.20)
      ).round();

      globalHealthScore = globalHealthScore.clamp(0, 100);

      // 4. Publish State to CashFlowState Table
      final existing = await (_db.select(_db.cashFlowState)..where((c) => c.profileId.equals(profileId))).getSingleOrNull();

      final state = CashFlowStateCompanion(
        profileId: Value(profileId),
        cashPosition: Value(cashPosition),
        safeToSpend: Value(safeToSpend),
        burnRate: Value(burnRate),
        netPosition: Value(netPosition),
        forecastBalance: Value(forecastBalance),
        healthScore: Value(globalHealthScore),
        lastCalculated: Value(DateTime.now()),
      );

      if (existing != null) {
        await (_db.update(_db.cashFlowState)..where((c) => c.id.equals(existing.id))).write(state);
      } else {
        await _db.into(_db.cashFlowState).insert(state);
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
