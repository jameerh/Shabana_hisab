import '../../../data/database/database.dart';
import 'package:drift/drift.dart';
import '../models/engine_metadata.dart';

class ForecastEngine {
  final AppDatabase _db;
  static const String engineId = 'ForecastEngine';
  static const String engineVersion = '1.0.0';

  ForecastEngine(this._db) {
    EngineTelemetryRegistry().registerOrUpdate(EngineMetadata(
      engineId: engineId,
      engineVersion: engineVersion,
      inputStates: ['Transactions', 'RecurringRule', 'Accounts'],
      outputStates: ['ForecastState'],
      executionOrder: 3,
      executionFrequency: 'ON_MUTATION_AND_START',
    ));
  }

  Future<void> run(int profileId) async {
    final stopwatch = Stopwatch()..start();
    try {
      // 1. Gather historical data for average income/expense
      final past30Days = DateTime.now().subtract(const Duration(days: 30));
      final transactions = await (_db.select(_db.transactions)
            ..where((t) => t.profileId.equals(profileId) & t.timestamp.isBiggerOrEqualValue(past30Days)))
          .get();

      double pastIncome = 0;
      double pastExpense = 0;
      for (var tx in transactions) {
        if (tx.type == 'Income') pastIncome += tx.amount;
        if (tx.type == 'Expense') pastExpense += tx.amount;
      }

      // 2. Gather active recurring schedules for next 30 days
      final now = DateTime.now();
      final next30Days = now.add(const Duration(days: 30));
      
      final recurringRules = await (_db.select(_db.recurringRule)
            ..where((r) => r.profileId.equals(profileId) & r.enabled.equals(true) & r.status.equals('ACTIVE')))
          .get();

      double expectedRecurring = 0;
      for (var rule in recurringRules) {
        if (rule.nextDueDate.isBefore(next30Days) && rule.nextDueDate.isAfter(now)) {
          expectedRecurring += rule.defaultAmount;
        }
      }

      // 3. Current Accounts Balance
      final accounts = await (_db.select(_db.accounts)..where((a) => a.profileId.equals(profileId))).get();
      double currentBalance = accounts.fold(0, (sum, a) => sum + a.currentBalance);

      // 4. Calculate Forecast
      double expectedBalance = currentBalance + pastIncome - pastExpense - expectedRecurring;
      
      String risk = 'LOW';
      if (expectedBalance < 0) {
        risk = 'CRITICAL';
      } else if (expectedBalance < currentBalance * 0.2) {
        risk = 'HIGH';
      } else if (expectedBalance < currentBalance * 0.5) {
        risk = 'MEDIUM';
      }

      // 5. Publish State
      final existing = await (_db.select(_db.forecastState)..where((f) => f.profileId.equals(profileId))).getSingleOrNull();
      
      final state = ForecastStateCompanion(
        profileId: Value(profileId),
        expectedIncome: Value(pastIncome),
        expectedExpense: Value(pastExpense),
        expectedRecurring: Value(expectedRecurring),
        expectedBalance: Value(expectedBalance),
        forecastRisk: Value(risk),
        lastCalculated: Value(DateTime.now()),
      );

      if (existing != null) {
        await (_db.update(_db.forecastState)..where((f) => f.id.equals(existing.id))).write(state);
      } else {
        await _db.into(_db.forecastState).insert(state);
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
