import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../data/database/database.dart';

class SimulationScenarioInput {
  final String scenarioTitle;
  final String scenarioCategory; // SALARY, PURCHASE, RENT, SAVINGS, LOAN, INVESTMENT, EDUCATION, VACATION, MEDICAL, HOUSE, BUSINESS
  final double lumpSumCost;
  final double monthlyDeltaCost;
  final double monthlyDeltaIncome;

  SimulationScenarioInput({
    required this.scenarioTitle,
    required this.scenarioCategory,
    this.lumpSumCost = 0.0,
    this.monthlyDeltaCost = 0.0,
    this.monthlyDeltaIncome = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'scenarioTitle': scenarioTitle,
        'scenarioCategory': scenarioCategory,
        'lumpSumCost': lumpSumCost,
        'monthlyDeltaCost': monthlyDeltaCost,
        'monthlyDeltaIncome': monthlyDeltaIncome,
      };
}

class SimulationResult {
  final String scenarioTitle;
  final double impactGoalDelayMonths;
  final double impactCashFlowDelta;
  final double impactSafeToSpendDelta;
  final int simulatedHealthScore;

  SimulationResult({
    required this.scenarioTitle,
    required this.impactGoalDelayMonths,
    required this.impactCashFlowDelta,
    required this.impactSafeToSpendDelta,
    required this.simulatedHealthScore,
  });
}

class SimulationSandbox {
  final AppDatabase _db;

  SimulationSandbox(this._db);

  Future<SimulationResult> runScenario({
    required int profileId,
    required SimulationScenarioInput input,
  }) async {
    // 1. Fetch published FOS Core states in read-only mode
    final cashFlow = await (_db.select(_db.cashFlowState)..where((c) => c.profileId.equals(profileId))).getSingleOrNull();
    final forecast = await (_db.select(_db.forecastState)..where((f) => f.profileId.equals(profileId))).getSingleOrNull();

    final currentCash = cashFlow?.cashPosition ?? 0.0;
    final currentSafe = cashFlow?.safeToSpend ?? 0.0;
    final currentHealth = cashFlow?.healthScore ?? 100;

    // 2. Apply hypothetical scenario changes in memory
    final netLumpSum = currentCash - input.lumpSumCost;
    final monthlyNetDelta = input.monthlyDeltaIncome - input.monthlyDeltaCost;
    final newSafe = (currentSafe + monthlyNetDelta - (input.lumpSumCost / 3.0)).clamp(0.0, double.infinity);

    double goalDelayMonths = 0.0;
    if (input.lumpSumCost > 0) {
      goalDelayMonths = (input.lumpSumCost / (forecast?.expectedIncome ?? 30000.0 * 0.2)).clamp(0.0, 24.0);
    }

    int newHealth = currentHealth;
    if (netLumpSum < 0) newHealth -= 30;
    if (monthlyNetDelta < 0) newHealth -= 15;
    if (monthlyNetDelta > 0) newHealth += 10;
    newHealth = newHealth.clamp(0, 100);

    final result = SimulationResult(
      scenarioTitle: input.scenarioTitle,
      impactGoalDelayMonths: goalDelayMonths,
      impactCashFlowDelta: monthlyNetDelta,
      impactSafeToSpendDelta: newSafe - currentSafe,
      simulatedHealthScore: newHealth,
    );

    // 3. Persist simulation result to SimulationState without mutating core live tables
    await _db.into(_db.simulationState).insert(SimulationStateCompanion.insert(
      profileId: profileId,
      scenarioTitle: input.scenarioTitle,
      scenarioCategory: Value(input.scenarioCategory),
      inputParamsJson: jsonEncode(input.toJson()),
      impactGoalDelayMonths: Value(goalDelayMonths),
      impactCashFlowDelta: Value(monthlyNetDelta),
      impactSafeToSpendDelta: Value(newSafe - currentSafe),
      simulatedHealthScore: Value(newHealth),
    ));

    return result;
  }
}
