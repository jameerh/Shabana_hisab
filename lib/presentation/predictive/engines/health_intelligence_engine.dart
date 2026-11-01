import 'package:drift/drift.dart';
import '../../../data/database/database.dart';

class ComponentHealthBreakdown {
  final int overallScore;
  final int budgetHealth;
  final int goalHealth;
  final int cashFlowHealth;
  final int liquidityHealth;
  final int recurringHealth;

  ComponentHealthBreakdown({
    required this.overallScore,
    required this.budgetHealth,
    required this.goalHealth,
    required this.cashFlowHealth,
    required this.liquidityHealth,
    required this.recurringHealth,
  });
}

class HealthIntelligenceEngine {
  final AppDatabase _db;

  HealthIntelligenceEngine(this._db);

  Future<ComponentHealthBreakdown> analyze(int profileId) async {
    final cashFlow = await (_db.select(_db.cashFlowState)..where((c) => c.profileId.equals(profileId))).getSingleOrNull();
    final liquidity = await (_db.select(_db.liquidityState)..where((l) => l.profileId.equals(profileId))).getSingleOrNull();
    final budgetStates = await (_db.select(_db.budgetState)).get();
    final goalStates = await (_db.select(_db.goalState)).get();

    int bScore = 100;
    if (budgetStates.isNotEmpty) {
      int sum = 0;
      for (var s in budgetStates) sum += s.healthScore;
      bScore = (sum / budgetStates.length).round();
    }

    int gScore = 100;
    if (goalStates.isNotEmpty) {
      int sum = 0;
      for (var s in goalStates) sum += s.healthScore;
      gScore = (sum / goalStates.length).round();
    }

    int cfScore = cashFlow?.healthScore ?? 100;
    int lScore = liquidity != null ? liquidity.liquidityRatio.clamp(0.0, 100.0).round() : 100;
    int rScore = 95; // Default recurring health score

    int overall = ((bScore * 0.25) + (gScore * 0.25) + (cfScore * 0.25) + (lScore * 0.15) + (rScore * 0.10)).round();

    return ComponentHealthBreakdown(
      overallScore: overall,
      budgetHealth: bScore,
      goalHealth: gScore,
      cashFlowHealth: cfScore,
      liquidityHealth: lScore,
      recurringHealth: rScore,
    );
  }
}
