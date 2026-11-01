import '../../../data/database/database.dart';
import 'package:drift/drift.dart';
import '../models/engine_metadata.dart';

class LiquidityEngine {
  final AppDatabase _db;
  static const String engineId = 'LiquidityEngine';
  static const String engineVersion = '1.0.0';

  LiquidityEngine(this._db) {
    EngineTelemetryRegistry().registerOrUpdate(EngineMetadata(
      engineId: engineId,
      engineVersion: engineVersion,
      inputStates: ['Accounts', 'BudgetState', 'GoalState'],
      outputStates: ['LiquidityState'],
      executionOrder: 4,
      executionFrequency: 'ON_MUTATION_AND_START',
    ));
  }

  Future<void> run(int profileId) async {
    final stopwatch = Stopwatch()..start();
    try {
      // 1. Gather all liquid assets
      final accounts = await (_db.select(_db.accounts)..where((a) => a.profileId.equals(profileId) & a.active.equals(true))).get();
      
      double liquidAssets = 0;
      for (var acc in accounts) {
        if (['CASH', 'BANK', 'UPI', 'WALLET'].contains(acc.type)) {
          liquidAssets += acc.currentBalance;
        }
      }

      // 2. Gather Reserves (Goals + Budget Remaining)
      final budgets = await (_db.select(_db.budgets)..where((b) => b.profileId.equals(profileId))).get();
      double budgetReserved = 0;
      for (var b in budgets) {
        final state = await (_db.select(_db.budgetState)..where((s) => s.budgetId.equals(b.id))).getSingleOrNull();
        if (state != null && state.expectedRemaining > 0) {
          budgetReserved += state.expectedRemaining;
        }
      }

      final goals = await (_db.select(_db.goals)..where((g) => g.profileId.equals(profileId) & g.status.equals('ACTIVE'))).get();
      double goalReserved = 0;
      double emergencyReserve = 0;
      
      for (var g in goals) {
        final state = await (_db.select(_db.goalState)..where((s) => s.goalId.equals(g.id))).getSingleOrNull();
        if (state != null) {
          if (g.title.toLowerCase().contains('emergency')) {
            emergencyReserve += state.currentAmount;
          } else {
            goalReserved += state.currentAmount;
          }
        }
      }

      double totalReserved = budgetReserved + goalReserved;
      double available = liquidAssets - totalReserved - emergencyReserve;
      
      double liquidityRatio = liquidAssets > 0 ? (available / liquidAssets) * 100 : 0;

      // 3. Publish State
      final existing = await (_db.select(_db.liquidityState)..where((l) => l.profileId.equals(profileId))).getSingleOrNull();
      
      final state = LiquidityStateCompanion(
        profileId: Value(profileId),
        liquidAssets: Value(liquidAssets),
        reserved: Value(totalReserved),
        available: Value(available),
        emergencyReserve: Value(emergencyReserve),
        liquidityRatio: Value(liquidityRatio),
        lastCalculated: Value(DateTime.now()),
      );

      if (existing != null) {
        await (_db.update(_db.liquidityState)..where((l) => l.id.equals(existing.id))).write(state);
      } else {
        await _db.into(_db.liquidityState).insert(state);
      }

      stopwatch.stop();
      EngineTelemetryRegistry().recordExecution(
        engineId: engineId,
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      EngineTelemetryRegistry().recordExecution(
        engineId: engineId,
        durationMs: stopwatch.elapsedMilliseconds,
        error: e.toString(),
      );
      rethrow;
    }
  }
}
