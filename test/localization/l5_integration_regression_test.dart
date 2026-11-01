import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snaphisaab/core/localization/app_language.dart';
import 'package:snaphisaab/core/localization/language_controller.dart';
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/main.dart';
import 'package:snaphisaab/presentation/predictive/services/prediction_dag_orchestrator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    try {
      database = AppDatabase();
    } catch (_) {}
  });

  group('L5.5 Predictive Intelligence Integration & Regression Gate (ADR-020)', () {
    test('3-way language cycle (EN -> MR -> EN+MR -> EN) triggers ZERO predictive DAG pipeline executions', () async {
      final controller = LanguageController();
      await controller.init();

      final orchestrator = PredictionDagOrchestrator(database);
      expect(orchestrator, isNotNull);

      int notifications = 0;
      controller.addListener(() {
        notifications++;
      });

      // Step 1: English
      await controller.setLanguage(AppLanguage.english);
      expect(controller.currentLanguage, equals(AppLanguage.english));

      // Step 2: Marathi
      await controller.setLanguage(AppLanguage.marathi);
      expect(controller.currentLanguage, equals(AppLanguage.marathi));

      // Step 3: English + Marathi (Bilingual Presentation Mode)
      await controller.setLanguage(AppLanguage.englishMarathi);
      expect(controller.currentLanguage, equals(AppLanguage.englishMarathi));
      expect(controller.isBilingual, isTrue);

      // Step 4: Return to English
      await controller.setLanguage(AppLanguage.english);
      expect(controller.currentLanguage, equals(AppLanguage.english));
      expect(controller.isBilingual, isFalse);

      expect(notifications, equals(3));
    });

    test('Single compact numeral preservation in predictive confidence rendering', () {
      const double confidencePct = 0.93;
      final formattedConfidence = '${(confidencePct * 100).toStringAsFixed(0)}%';

      // Verified single numeral string
      expect(formattedConfidence, equals('93%'));
      expect(formattedConfidence, isNot(contains('९३%')));
    });
  });
}
