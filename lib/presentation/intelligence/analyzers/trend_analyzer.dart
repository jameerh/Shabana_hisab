import '../../../data/database/database.dart';
import 'package:drift/drift.dart';

class TrendAnalysisResult {
  final String title;
  final String observation;
  final String category;
  final String severity;
  final String? metricChange;

  TrendAnalysisResult({
    required this.title,
    required this.observation,
    required this.category,
    required this.severity,
    this.metricChange,
  });
}

class TrendAnalyzer {
  final AppDatabase _db;

  TrendAnalyzer(this._db);

  Future<List<TrendAnalysisResult>> analyze(int profileId) async {
    List<TrendAnalysisResult> results = [];
    final now = DateTime.now();

    // 1. Compare last 30 days expense vs prior 30-60 days
    final last30DaysStart = now.subtract(const Duration(days: 30));
    final prior30DaysStart = now.subtract(const Duration(days: 60));

    final recentTxs = await (_db.select(_db.transactions)
          ..where((t) => t.profileId.equals(profileId) & t.timestamp.isBiggerOrEqualValue(last30DaysStart)))
        .get();

    final priorTxs = await (_db.select(_db.transactions)
          ..where((t) => t.profileId.equals(profileId) & t.timestamp.isBetweenValues(prior30DaysStart, last30DaysStart)))
        .get();

    double recentExpense = recentTxs.where((t) => t.type == 'Expense').fold(0.0, (s, t) => s + t.amount);
    double priorExpense = priorTxs.where((t) => t.type == 'Expense').fold(0.0, (s, t) => s + t.amount);

    if (priorExpense > 0) {
      double diffPct = ((recentExpense - priorExpense) / priorExpense) * 100.0;
      if (diffPct <= -10.0) {
        results.add(TrendAnalysisResult(
          title: 'Spending Trend Improved',
          observation: 'Your overall expenses reduced by ${diffPct.abs().toStringAsFixed(0)}% compared to the previous period.',
          category: 'SPENDING',
          severity: 'SUCCESS',
          metricChange: '${diffPct.toStringAsFixed(0)}%',
        ));
      } else if (diffPct >= 20.0) {
        results.add(TrendAnalysisResult(
          title: 'Expense Spike Detected',
          observation: 'Expenses increased by ${diffPct.toStringAsFixed(0)}% over the last 30 days.',
          category: 'SPENDING',
          severity: 'WARNING',
          metricChange: '+${diffPct.toStringAsFixed(0)}%',
        ));
      }
    }

    return results;
  }
}
