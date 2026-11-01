import '../../../data/database/database.dart';
import 'package:drift/drift.dart';
import '../models/engine_metadata.dart';

/// RecommendationEngineV2 implements ADR-014 (Recommendation Contract).
/// Consumes published states from GoalEngine, BudgetEngine, ForecastEngine, LiquidityEngine, and CashFlowEngine.
class RecommendationEngineV2 {
  final AppDatabase _db;
  static const String engineId = 'RecommendationEngineV2';
  static const String engineVersion = '1.0.0';

  RecommendationEngineV2(this._db) {
    EngineTelemetryRegistry().registerOrUpdate(EngineMetadata(
      engineId: engineId,
      engineVersion: engineVersion,
      inputStates: ['ForecastState', 'LiquidityState', 'BudgetState', 'GoalState', 'CashFlowState'],
      outputStates: ['Recommendations'],
      executionOrder: 6,
      executionFrequency: 'ON_MUTATION_AND_START',
    ));
  }

  Future<void> run(int profileId) async {
    final stopwatch = Stopwatch()..start();
    try {
      List<RecommendationsCompanion> candidates = [];

      // 1. Read Published Domain Engine States (Read-only, Decoupled)
      final forecast = await (_db.select(_db.forecastState)..where((f) => f.profileId.equals(profileId))).getSingleOrNull();
      final liquidity = await (_db.select(_db.liquidityState)..where((l) => l.profileId.equals(profileId))).getSingleOrNull();

      // Forecast Engine Candidates
      if (forecast != null) {
        if (forecast.forecastRisk == 'CRITICAL' || forecast.expectedBalance < 0) {
          candidates.add(RecommendationsCompanion.insert(
            profileId: profileId,
            title: 'Critical Cash Flow Risk',
            description: 'Expected expenses exceed projected balance this month.',
            score: 95.0,
            priority: 1,
            confidence: 0.95,
            category: 'RISK',
            sourceEngine: 'ForecastEngine',
            whyShown: 'Projected month-end balance falls below ₹0 based on active spending trends.',
            action: const Value('REVIEW_BUDGETS'),
            expiresAt: Value(DateTime.now().add(const Duration(days: 7))),
          ));
        } else if (forecast.forecastRisk == 'HIGH') {
          candidates.add(RecommendationsCompanion.insert(
            profileId: profileId,
            title: 'High Expense Velocity',
            description: 'Projected balance is under 20% of your current liquid balance.',
            score: 75.0,
            priority: 3,
            confidence: 0.85,
            category: 'RISK',
            sourceEngine: 'ForecastEngine',
            whyShown: 'Spending velocity is high relative to expected incoming cash flow.',
            action: const Value('VIEW_RECURRING'),
            expiresAt: Value(DateTime.now().add(const Duration(days: 7))),
          ));
        }
      }

      // Liquidity Engine Candidates
      if (liquidity != null) {
        if (liquidity.liquidityRatio < 15.0 && liquidity.liquidAssets > 0) {
          candidates.add(RecommendationsCompanion.insert(
            profileId: profileId,
            title: 'Liquidity Constrained',
            description: 'Liquidity is low. Avoid discretionary purchases today.',
            score: 88.0,
            priority: 2,
            confidence: 0.90,
            category: 'LIQUIDITY',
            sourceEngine: 'LiquidityEngine',
            whyShown: 'Over 85% of liquid assets are tied up in reserved budgets or goals.',
            action: const Value('VIEW_ACCOUNTS'),
            expiresAt: Value(DateTime.now().add(const Duration(days: 3))),
          ));
        }
      }

      // Budget Engine Candidates
      final budgets = await (_db.select(_db.budgets)..where((b) => b.profileId.equals(profileId))).get();
      for (var b in budgets) {
        final state = await (_db.select(_db.budgetState)..where((s) => s.budgetId.equals(b.id))).getSingleOrNull();
        if (state != null) {
          final spentPct = b.limitAmount > 0 ? (state.currentSpent / b.limitAmount) * 100.0 : 0.0;
          if (state.healthScore < 50) {
            candidates.add(RecommendationsCompanion.insert(
              profileId: profileId,
              title: '${b.title} Budget Warning',
              description: '${b.title} budget is experiencing high burn rate (${spentPct.toStringAsFixed(0)}% spent).',
              score: 90.0,
              priority: 2,
              confidence: 0.95,
              category: 'BUDGET',
              sourceEngine: 'BudgetEngine',
              whyShown: '${b.title} budget health dropped to ${state.healthScore}/100.',
              action: const Value('VIEW_BUDGETS'),
              expiresAt: Value(DateTime.now().add(const Duration(days: 5))),
            ));
          }
        }
      }

      // Goal Engine Candidates
      final goals = await (_db.select(_db.goals)..where((g) => g.profileId.equals(profileId) & g.status.equals('ACTIVE'))).get();
      for (var g in goals) {
        final state = await (_db.select(_db.goalState)..where((s) => s.goalId.equals(g.id))).getSingleOrNull();
        if (state != null) {
          if (state.healthScore >= 90 && state.velocity > 0) {
            candidates.add(RecommendationsCompanion.insert(
              profileId: profileId,
              title: 'Boost ${g.title} Goal',
              description: 'Contribute ₹500 today to finish ${g.title} 1 month early.',
              score: 70.0,
              priority: 4,
              confidence: 0.90,
              category: 'GOAL',
              sourceEngine: 'GoalEngine',
              whyShown: '${g.title} velocity is strong (Health Score: ${state.healthScore}).',
              action: const Value('CONTRIBUTE_GOAL'),
              expiresAt: Value(DateTime.now().add(const Duration(days: 10))),
            ));
          }
        }
      }

      // 2. Rank, Deduplicate & Prioritize Candidates
      candidates.sort((a, b) => b.score.value.compareTo(a.score.value));

      final Map<String, RecommendationsCompanion> uniqueCandidates = {};
      for (var candidate in candidates) {
        final titleKey = candidate.title.value;
        if (!uniqueCandidates.containsKey(titleKey)) {
          uniqueCandidates[titleKey] = candidate;
        }
      }

      final topCandidates = uniqueCandidates.values.take(5).toList();

      // 3. Atomically Persist Recommendations
      await (_db.delete(_db.recommendations)..where((r) => r.profileId.equals(profileId))).go();

      for (int i = 0; i < topCandidates.length; i++) {
        final c = topCandidates[i];
        final indexedCandidate = RecommendationsCompanion.insert(
          profileId: c.profileId.value,
          title: c.title.value,
          description: c.description.value,
          score: c.score.value,
          priority: i + 1,
          confidence: c.confidence.value,
          category: c.category.value,
          sourceEngine: c.sourceEngine.value,
          whyShown: c.whyShown.value,
          action: c.action,
          expiresAt: c.expiresAt,
        );
        await _db.into(_db.recommendations).insert(indexedCandidate);
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
