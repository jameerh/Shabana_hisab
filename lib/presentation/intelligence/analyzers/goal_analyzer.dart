import 'package:drift/drift.dart';
import '../../../data/database/database.dart';
import 'trend_analyzer.dart';

class GoalAnalyzer {
  final AppDatabase _db;

  GoalAnalyzer(this._db);

  Future<List<TrendAnalysisResult>> analyze(int profileId) async {
    List<TrendAnalysisResult> results = [];

    final goals = await (_db.select(_db.goals)..where((g) => g.profileId.equals(profileId) & g.status.equals('ACTIVE'))).get();
    for (var g in goals) {
      final state = await (_db.select(_db.goalState)..where((s) => s.goalId.equals(g.id))).getSingleOrNull();
      if (state != null) {
        if (state.completionPercent >= 100.0) {
          results.add(TrendAnalysisResult(
            title: '${g.title} Goal Achieved',
            observation: 'Congratulations! You have reached 100% of your target for ${g.title}.',
            category: 'GOALS',
            severity: 'MILESTONE',
            metricChange: '100%',
          ));
        } else if (state.healthScore >= 90) {
          results.add(TrendAnalysisResult(
            title: '${g.title} Velocity Optimal',
            observation: '${g.title} contribution velocity is strong (Health Score: ${state.healthScore}).',
            category: 'GOALS',
            severity: 'SUCCESS',
            metricChange: '+₹${state.velocity.toStringAsFixed(0)}/mo',
          ));
        }
      }
    }

    return results;
  }
}
