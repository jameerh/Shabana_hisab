import 'package:drift/drift.dart';
import '../../../data/database/database.dart';
import 'trend_analyzer.dart';

class BehaviorAnalyzer {
  final AppDatabase _db;

  BehaviorAnalyzer(this._db);

  Future<List<TrendAnalysisResult>> analyze(int profileId) async {
    List<TrendAnalysisResult> results = [];
    final now = DateTime.now();
    final past14Days = now.subtract(const Duration(days: 14));

    final txs = await (_db.select(_db.transactions)
          ..where((t) => t.profileId.equals(profileId) & t.timestamp.isBiggerOrEqualValue(past14Days)))
        .get();

    // Check weekend vs weekday spending behavior
    double weekendSpend = 0;
    double weekdaySpend = 0;

    for (var t in txs) {
      if (t.type == 'Expense') {
        if (t.timestamp.weekday == DateTime.saturday || t.timestamp.weekday == DateTime.sunday) {
          weekendSpend += t.amount;
        } else {
          weekdaySpend += t.amount;
        }
      }
    }

    if (weekendSpend > weekdaySpend * 1.5 && weekendSpend > 1000) {
      results.add(TrendAnalysisResult(
        title: 'Weekend Spend Bias',
        observation: 'Weekend discretionary spending accounts for over 60% of bi-weekly expenses.',
        category: 'SPENDING',
        severity: 'INFO',
        metricChange: 'Weekend Bias',
      ));
    }

    return results;
  }
}
