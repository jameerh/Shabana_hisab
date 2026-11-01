import 'package:drift/drift.dart';
import '../../../data/database/database.dart';
import 'trend_analyzer.dart';

class BudgetAnalyzer {
  final AppDatabase _db;

  BudgetAnalyzer(this._db);

  Future<List<TrendAnalysisResult>> analyze(int profileId) async {
    List<TrendAnalysisResult> results = [];

    final budgets = await (_db.select(_db.budgets)..where((b) => b.profileId.equals(profileId) & b.enabled.equals(true))).get();
    for (var b in budgets) {
      final state = await (_db.select(_db.budgetState)..where((s) => s.budgetId.equals(b.id))).getSingleOrNull();
      if (state != null) {
        final spentPct = b.limitAmount > 0 ? (state.currentSpent / b.limitAmount) * 100.0 : 0.0;
        if (state.healthScore == 100 && state.currentSpent > 0) {
          results.add(TrendAnalysisResult(
            title: '${b.title} Under Budget',
            observation: '${b.title} budget is well managed with ₹${state.expectedRemaining.toStringAsFixed(0)} remaining.',
            category: 'BUDGET',
            severity: 'SUCCESS',
            metricChange: '${spentPct.toStringAsFixed(0)}% spent',
          ));
        } else if (state.status == 'WARNING' || state.status == 'CRITICAL') {
          results.add(TrendAnalysisResult(
            title: '${b.title} Budget Variance',
            observation: '${b.title} spending pace is higher than baseline trajectory.',
            category: 'BUDGET',
            severity: state.status == 'CRITICAL' ? 'CRITICAL' : 'WARNING',
            metricChange: '${spentPct.toStringAsFixed(0)}% spent',
          ));
        }
      }
    }

    return results;
  }
}
