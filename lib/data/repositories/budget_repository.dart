import '../../../data/database/database.dart';
import 'package:drift/drift.dart';

class BudgetWithState {
  final Budget budget;
  final BudgetStateData? state;

  BudgetWithState({required this.budget, this.state});
}

class BudgetRepository {
  final AppDatabase _db;

  BudgetRepository(this._db);

  // --- Budgets ---

  Future<List<Budget>> getActiveBudgets(int profileId) async {
    return await (_db.select(_db.budgets)
      ..where((b) => b.profileId.equals(profileId))
      ..where((b) => b.enabled.equals(true))
    ).get();
  }

  Stream<List<BudgetWithState>> watchBudgetsWithState(int profileId) {
    final query = _db.select(_db.budgets).join([
      leftOuterJoin(_db.budgetState, _db.budgetState.budgetId.equalsExp(_db.budgets.id)),
    ])..where(_db.budgets.profileId.equals(profileId));

    return query.watch().map((rows) {
      return rows.map((row) {
        return BudgetWithState(
          budget: row.readTable(_db.budgets),
          state: row.readTableOrNull(_db.budgetState),
        );
      }).toList();
    });
  }

  Future<int> insertBudget(BudgetsCompanion budget, List<String> categoryIds) async {
    return await _db.transaction(() async {
      final budgetId = await _db.into(_db.budgets).insert(budget);
      
      for (var catId in categoryIds) {
        await _db.into(_db.budgetCategoryMappings).insert(
          BudgetCategoryMappingsCompanion.insert(
            budgetId: budgetId,
            categoryId: catId,
          )
        );
      }
      return budgetId;
    });
  }

  Future<void> updateBudget(BudgetsCompanion budget, List<String> categoryIds) async {
    await _db.transaction(() async {
      await _db.update(_db.budgets).replace(budget);
      
      // Update mappings: delete old, insert new
      await (_db.delete(_db.budgetCategoryMappings)
        ..where((m) => m.budgetId.equals(budget.id.value))).go();
        
      for (var catId in categoryIds) {
        await _db.into(_db.budgetCategoryMappings).insert(
          BudgetCategoryMappingsCompanion.insert(
            budgetId: budget.id.value,
            categoryId: catId,
          )
        );
      }
    });
  }

  Future<void> disableBudget(int budgetId) async {
    await (_db.update(_db.budgets)..where((b) => b.id.equals(budgetId))).write(
      const BudgetsCompanion(enabled: Value(false))
    );
  }

  // --- Snapshots ---

  Future<BudgetSnapshot?> getCurrentSnapshot(int budgetId) async {
    final now = DateTime.now();
    final periodStart = DateTime(now.year, now.month, 1);
    
    return await (_db.select(_db.budgetSnapshots)
      ..where((s) => s.budgetId.equals(budgetId))
      ..where((s) => s.periodStart.equals(periodStart))
    ).getSingleOrNull();
  }
}
