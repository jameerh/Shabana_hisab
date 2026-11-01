import 'package:drift/drift.dart';
import '../../data/database/database.dart';

class GoalWithState {
  final Goal goal;
  final GoalStateData state;
  GoalWithState({required this.goal, required this.state});
}

class GoalRepository {
  final AppDatabase _db;

  GoalRepository(this._db);

  Stream<List<Goal>> watchGoals(int profileId) {
    return (_db.select(_db.goals)
      ..where((g) => g.profileId.equals(profileId) & g.status.isNotIn(['ARCHIVED', 'CANCELLED']))
      ..orderBy([(g) => OrderingTerm.asc(g.priority)])
    ).watch();
  }

  Stream<List<GoalWithState>> watchGoalsWithState(int profileId) {
    final query = _db.select(_db.goals).join([
      innerJoin(_db.goalState, _db.goalState.goalId.equalsExp(_db.goals.id)),
    ])
      ..where(_db.goals.profileId.equals(profileId) & _db.goals.status.isNotIn(['ARCHIVED', 'CANCELLED']))
      ..orderBy([OrderingTerm.asc(_db.goals.priority)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return GoalWithState(
          goal: row.readTable(_db.goals),
          state: row.readTable(_db.goalState),
        );
      }).toList();
    });
  }

  Future<int> insertGoal(GoalsCompanion goal) async {
    return await _db.into(_db.goals).insert(goal);
  }

  Future<bool> updateGoal(Goal goal) async {
    return await _db.update(_db.goals).replace(goal);
  }
  
  Future<void> updateGoalStatus(int goalId, String status) async {
    await (_db.update(_db.goals)..where((g) => g.id.equals(goalId))).write(
      GoalsCompanion(status: Value(status))
    );
  }

  // --- GoalState Cache ---
  Stream<GoalStateData?> watchGoalState(int goalId) {
    return (_db.select(_db.goalState)
      ..where((s) => s.goalId.equals(goalId))
    ).watchSingleOrNull();
  }
  
  Future<void> upsertGoalState(GoalStateCompanion state) async {
    final existing = await (_db.select(_db.goalState)..where((s) => s.goalId.equals(state.goalId.value))).getSingleOrNull();
    if (existing != null) {
      await (_db.update(_db.goalState)..where((s) => s.id.equals(existing.id))).write(state);
    } else {
      await _db.into(_db.goalState).insert(state);
    }
  }

  // --- GoalHistory ---
  Stream<List<GoalHistoryData>> watchGoalHistory(int goalId) {
    return (_db.select(_db.goalHistory)
      ..where((h) => h.goalId.equals(goalId))
      ..orderBy([(h) => OrderingTerm.desc(h.date)])
    ).watch();
  }
  
  Future<void> addHistoryEntry(GoalHistoryCompanion history) async {
    await _db.into(_db.goalHistory).insert(history);
  }
}
