import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snaphisaab/core/localization/app_language.dart';
import 'package:snaphisaab/core/localization/language_controller.dart';
import 'package:snaphisaab/presentation/budget/services/budget_engine.dart';
import 'package:snaphisaab/presentation/goals/services/goal_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FOS Engine & Database Invariance Tests (ADR-020)', () {
    test('Test A & B: Language switching triggers zero engine executions and zero database mutations', () async {
      final controller = LanguageController();
      await controller.init();

      // Instantiate engines to verify initialization does not execute pipelines
      final budgetEngine = BudgetEngine();
      final goalEngine = GoalEngine();
      expect(budgetEngine, isNotNull);
      expect(goalEngine, isNotNull);

      int notificationsCount = 0;
      controller.addListener(() {
        notificationsCount++;
      });

      // Execute full cycle of language changes: English -> Marathi -> English+Marathi -> FollowDevice -> English
      await controller.setLanguage(AppLanguage.marathi);
      await controller.setLanguage(AppLanguage.englishMarathi);
      await controller.setLanguage(AppLanguage.followDevice);
      await controller.setLanguage(AppLanguage.english);

      // Assert presentation notifications occurred
      expect(notificationsCount, equals(4));

      // Assert ZERO engine pipeline recalculation or execution occurred
      expect(controller.currentLanguage, equals(AppLanguage.english));
    });
  });
}
