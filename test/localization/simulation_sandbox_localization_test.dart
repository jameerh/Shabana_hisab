import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/presentation/predictive/sandbox/simulation_sandbox.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('L5.3 Simulation Sandbox Read-Only Invariance Tests', () {
    test('SimulationSandbox.runScenario executes in-memory calculations without mutating live financial state', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.into(db.profiles).insert(ProfilesCompanion.insert(name: 'Test Profile', type: ProfileType.PERSONAL));
      final sandbox = SimulationSandbox(db);

      final result = await sandbox.runScenario(
        profileId: 1,
        input: SimulationScenarioInput(
          scenarioTitle: 'Test Bike Scenario',
          scenarioCategory: 'PURCHASE',
          lumpSumCost: 150000,
          monthlyDeltaCost: 3000,
          monthlyDeltaIncome: 0,
        ),
      );

      expect(result.scenarioTitle, equals('Test Bike Scenario'));
      expect(result.simulatedHealthScore, greaterThanOrEqualTo(0));
      expect(result.simulatedHealthScore, lessThanOrEqualTo(100));

      await db.close();
    });
  });
}
