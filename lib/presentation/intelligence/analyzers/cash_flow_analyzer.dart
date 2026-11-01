import '../../../data/database/database.dart';
import 'trend_analyzer.dart';

class CashFlowAnalyzer {
  final AppDatabase _db;

  CashFlowAnalyzer(this._db);

  Future<List<TrendAnalysisResult>> analyze(int profileId) async {
    List<TrendAnalysisResult> results = [];

    final cashFlow = await (_db.select(_db.cashFlowState)..where((c) => c.profileId.equals(profileId))).getSingleOrNull();
    final liquidity = await (_db.select(_db.liquidityState)..where((l) => l.profileId.equals(profileId))).getSingleOrNull();

    if (cashFlow != null) {
      if (cashFlow.netPosition > 0) {
        results.add(TrendAnalysisResult(
          title: 'Positive Cash Flow',
          observation: 'Net monthly cash flow is positive by ₹${cashFlow.netPosition.toStringAsFixed(0)}.',
          category: 'CASH_FLOW',
          severity: 'SUCCESS',
          metricChange: '+₹${cashFlow.netPosition.toStringAsFixed(0)}',
        ));
      }
    }

    if (liquidity != null && liquidity.liquidityRatio > 50.0) {
      results.add(TrendAnalysisResult(
        title: 'Strong Liquidity Reserve',
        observation: 'Liquid assets cover over 50% of total assets after reserves.',
        category: 'LIQUIDITY',
        severity: 'SUCCESS',
        metricChange: '${liquidity.liquidityRatio.toStringAsFixed(0)}%',
      ));
    }

    return results;
  }
}
