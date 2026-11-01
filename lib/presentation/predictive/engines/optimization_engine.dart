import 'package:drift/drift.dart';
import '../../../data/database/database.dart';

class OptimizationEngine {
  final AppDatabase _db;

  OptimizationEngine(this._db);

  Future<void> execute(int profileId) async {
    final behaviors = await (_db.select(_db.behaviorState)..where((b) => b.profileId.equals(profileId))).get();

    for (var b in behaviors) {
      if (b.routineScore == 'ROUTINE' && b.typicalAmount > 50 && b.typicalAmount < 500) {
        final monthlyOpt = b.typicalAmount * 0.20 * 30;
        final yearlyOpt = monthlyOpt * 12;

        await _db.into(_db.optimizationState).insertOnConflictUpdate(OptimizationStateCompanion.insert(
          profileId: profileId,
          opportunityTitle: 'Optimize ${b.patternName.toUpperCase()} Micro-Spend',
          optimizationType: const Value('SAVE'),
          potentialMonthlySavings: Value(monthlyOpt),
          potentialYearlySavings: Value(yearlyOpt),
          difficulty: const Value('EASY'),
          recommendationAction: Value('Reduce daily ${b.patternName} expense by 20%'),
          whyShown: 'Frequent routine habit detected (${b.frequency}). Small adjustments yield ₹${yearlyOpt.toStringAsFixed(0)} annual savings.',
        ));
      }
    }

    final recurring = await (_db.select(_db.recurringRule)..where((r) => r.profileId.equals(profileId) & r.enabled.equals(true))).get();
    if (recurring.length > 5) {
      await _db.into(_db.optimizationState).insertOnConflictUpdate(OptimizationStateCompanion.insert(
        profileId: profileId,
        opportunityTitle: 'Review Subscriptions & Recurring Bills',
        optimizationType: const Value('REDUCE_RECURRING'),
        potentialMonthlySavings: const Value(500.0),
        potentialYearlySavings: const Value(6000.0),
        difficulty: const Value('MEDIUM'),
        recommendationAction: const Value('Audit active recurring commitments'),
        whyShown: 'Found ${recurring.length} active recurring rules. Consolidating plans can free up ₹6,000/year.',
      ));
    }
  }
}
