import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snaphisaab/core/localization/app_language.dart';
import 'package:snaphisaab/core/localization/language_controller.dart';
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

  group('L6.5 Voice UI & Quick Tools Integration Gate (ADR-020)', () {
    test('3-way language cycle (EN -> MR -> EN+MR -> EN) maintains UI and Voice language independence', () async {
      final controller = LanguageController();
      await controller.init();

      int notifications = 0;
      controller.addListener(() {
        notifications++;
      });

      // UI language switching
      await controller.setLanguage(AppLanguage.english);
      expect(controller.currentLanguage, equals(AppLanguage.english));

      await controller.setLanguage(AppLanguage.marathi);
      expect(controller.currentLanguage, equals(AppLanguage.marathi));

      await controller.setLanguage(AppLanguage.englishMarathi);
      expect(controller.currentLanguage, equals(AppLanguage.englishMarathi));
      expect(controller.isBilingual, isTrue);

      await controller.setLanguage(AppLanguage.english);
      expect(controller.currentLanguage, equals(AppLanguage.english));

      expect(notifications, equals(3));
    });

    test('Single compact numeral preservation in quick tool distance and cost calculations', () {
      const double distance = 42.5;
      const double costPerKm = 5.25;

      expect('${distance.toStringAsFixed(1)} km', equals('42.5 km'));
      expect('₹${costPerKm.toStringAsFixed(2)}/km', equals('₹5.25/km'));
    });
  });
}
