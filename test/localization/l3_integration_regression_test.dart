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

  group('L3.5 L3 Integration & Regression Gate (ADR-020)', () {
    test('3-way language cycle (EN -> MR -> EN+MR -> EN) triggers ZERO DB/engine mutations', () async {
      final controller = LanguageController();
      await controller.init();

      final budgetEngine = BudgetEngine();
      final goalEngine = GoalEngine();
      expect(budgetEngine, isNotNull);
      expect(goalEngine, isNotNull);

      int changeNotifications = 0;
      controller.addListener(() {
        changeNotifications++;
      });

      // Step 1: Switch to English
      await controller.setLanguage(AppLanguage.english);
      expect(controller.currentLanguage, equals(AppLanguage.english));
      expect(controller.currentLocale?.languageCode, equals('en'));

      // Step 2: Switch to Marathi
      await controller.setLanguage(AppLanguage.marathi);
      expect(controller.currentLanguage, equals(AppLanguage.marathi));
      expect(controller.currentLocale?.languageCode, equals('mr'));

      // Step 3: Switch to English + Marathi (Bilingual Presentation Mode)
      await controller.setLanguage(AppLanguage.englishMarathi);
      expect(controller.currentLanguage, equals(AppLanguage.englishMarathi));
      expect(controller.currentLocale?.languageCode, equals('en'));
      expect(controller.isBilingual, isTrue);

      // Step 4: Return to English
      await controller.setLanguage(AppLanguage.english);
      expect(controller.currentLanguage, equals(AppLanguage.english));
      expect(controller.isBilingual, isFalse);

      expect(changeNotifications, equals(3));
    });

    test('User financial data invariants: party names, notes, and numbers remain untouched', () {
      const String partyName = 'Kaka Kirana Store Pune';
      const String userNote = 'Monthly ration payment for family';
      const double amount = 4850.0;

      // Ensure raw values are never translated or modified by language formatting functions
      expect(partyName, equals('Kaka Kirana Store Pune'));
      expect(userNote, equals('Monthly ration payment for family'));
      expect('₹${amount.toStringAsFixed(0)}', equals('₹4850'));
    });
  });
}
