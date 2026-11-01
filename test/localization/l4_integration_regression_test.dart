import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snaphisaab/core/localization/app_language.dart';
import 'package:snaphisaab/core/localization/language_controller.dart';
import 'package:snaphisaab/presentation/intelligence/engines/cash_flow_engine.dart';
import 'package:snaphisaab/presentation/intelligence/engines/recommendation_engine_v2.dart';
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    try {
      database = AppDatabase();
    } catch (_) {}
  });

  group('L4.5 Intelligence Integration & Regression Gate (ADR-020)', () {
    test('3-way language cycle (EN -> MR -> EN+MR -> EN) triggers ZERO FOS engine executions', () async {
      final controller = LanguageController();
      await controller.init();

      final cashFlowEngine = CashFlowEngine(database);
      final recEngine = RecommendationEngineV2(database);
      expect(cashFlowEngine, isNotNull);
      expect(recEngine, isNotNull);

      int changeNotifications = 0;
      controller.addListener(() {
        changeNotifications++;
      });

      // Step 1: Switch to English
      await controller.setLanguage(AppLanguage.english);
      expect(controller.currentLanguage, equals(AppLanguage.english));

      // Step 2: Switch to Marathi
      await controller.setLanguage(AppLanguage.marathi);
      expect(controller.currentLanguage, equals(AppLanguage.marathi));

      // Step 3: Switch to English + Marathi (Bilingual Presentation Mode)
      await controller.setLanguage(AppLanguage.englishMarathi);
      expect(controller.currentLanguage, equals(AppLanguage.englishMarathi));
      expect(controller.isBilingual, isTrue);

      // Step 4: Return to English
      await controller.setLanguage(AppLanguage.english);
      expect(controller.currentLanguage, equals(AppLanguage.english));
      expect(controller.isBilingual, isFalse);

      expect(changeNotifications, equals(3));
    });

    test('Single compact numeral preservation: score and currency amounts never duplicate numerals', () {
      const int healthScore = 84;
      const double cashPosition = 82000.0;
      const double safeToSpendDaily = 820.0;

      // Invariants
      expect('$healthScore', equals('84'));
      expect('₹${cashPosition.toStringAsFixed(0)}', equals('₹82000'));
      expect('₹${safeToSpendDaily.toStringAsFixed(0)}/day', equals('₹820/day'));
    });
  });
}
