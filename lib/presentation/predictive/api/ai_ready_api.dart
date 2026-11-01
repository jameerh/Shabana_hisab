import '../../../data/database/database.dart';
import '../sandbox/simulation_sandbox.dart';

class AiReadyApi {
  final AppDatabase _db;

  AiReadyApi(this._db);

  Future<List<PredictionStateData>> getActivePredictions(int profileId) async {
    return (_db.select(_db.predictionState)..where((p) => p.profileId.equals(profileId) & p.status.equals('ACTIVE'))).get();
  }

  Future<List<RiskStateData>> getActiveRisks(int profileId) async {
    return (_db.select(_db.riskState)..where((r) => r.profileId.equals(profileId))).get();
  }

  Future<List<OptimizationStateData>> getOptimizations(int profileId) async {
    return (_db.select(_db.optimizationState)..where((o) => o.profileId.equals(profileId))).get();
  }

  Future<SimulationResult> runSimulationSandbox({
    required int profileId,
    required SimulationScenarioInput scenario,
  }) async {
    final sandbox = SimulationSandbox(_db);
    return sandbox.runScenario(profileId: profileId, input: scenario);
  }
}
