import 'package:drift/drift.dart';
import '../../../data/database/database.dart';

class RiskEngine {
  final AppDatabase _db;

  RiskEngine(this._db);

  Future<void> execute(int profileId) async {
    final cashFlow = await (_db.select(_db.cashFlowState)..where((c) => c.profileId.equals(profileId))).getSingleOrNull();
    final budgets = await (_db.select(_db.budgets)..where((b) => b.profileId.equals(profileId) & b.enabled.equals(true))).get();
    
    // 1. Budget overrun risks
    for (var b in budgets) {
      final state = await (_db.select(_db.budgetState)..where((s) => s.budgetId.equals(b.id))).getSingleOrNull();
      if (state != null && state.healthScore < 60) {
        final overAmt = (state.currentSpent - b.limitAmount).clamp(0.0, double.infinity);
        await _db.into(_db.riskState).insertOnConflictUpdate(RiskStateCompanion.insert(
          profileId: profileId,
          riskType: 'BUDGET_OVERRUN',
          severity: Value(state.healthScore < 40 ? 'CRITICAL' : 'HIGH'),
          probability: Value((100 - state.healthScore) / 100.0),
          financialImpactAmount: Value(overAmt > 0 ? overAmt : 2000.0),
          priorityRank: const Value(1),
          explanation: '${b.title} budget spend pace exceeds threshold.',
        ));
      }
    }

    // 2. Cash shortage risk
    if (cashFlow != null && cashFlow.safeToSpend < 1000) {
      await _db.into(_db.riskState).insertOnConflictUpdate(RiskStateCompanion.insert(
        profileId: profileId,
        riskType: 'LOW_BALANCE',
        severity: const Value('HIGH'),
        probability: const Value(0.85),
        financialImpactAmount: Value(1000 - cashFlow.safeToSpend),
        priorityRank: const Value(2),
        explanation: 'Safe To Spend buffer is below minimum safety margin.',
      ));
    }
  }
}
