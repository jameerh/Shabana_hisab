import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snaphisaab/core/localization/app_language.dart';
import 'package:snaphisaab/core/localization/language_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LanguageController Tests', () {
    test('Default language is English', () async {
      final controller = LanguageController();
      await controller.init();

      expect(controller.currentLanguage, equals(AppLanguage.english));
      expect(controller.isBilingual, isFalse);
      expect(controller.currentLocale?.languageCode, equals('en'));
    });

    test('Switch to Marathi updates state and notifies listeners', () async {
      final controller = LanguageController();
      await controller.init();

      bool notified = false;
      controller.addListener(() {
        notified = true;
      });

      await controller.setLanguage(AppLanguage.marathi);

      expect(controller.currentLanguage, equals(AppLanguage.marathi));
      expect(controller.isBilingual, isFalse);
      expect(controller.currentLocale?.languageCode, equals('mr'));
      expect(notified, isTrue);
    });

    test('Switch to English + Marathi sets bilingual presentation mode', () async {
      final controller = LanguageController();
      await controller.init();

      await controller.setLanguage(AppLanguage.englishMarathi);

      expect(controller.currentLanguage, equals(AppLanguage.englishMarathi));
      expect(controller.isBilingual, isTrue);
      // Maps to standard Locale('en') under the hood rather than fake en_MR
      expect(controller.currentLocale?.languageCode, equals('en'));
    });

    test('Language choice persists across controller re-initialization', () async {
      final controller1 = LanguageController();
      await controller1.init();
      await controller1.setLanguage(AppLanguage.marathi);

      // Create new instance simulating app restart
      final controller2 = LanguageController();
      await controller2.init();

      expect(controller2.currentLanguage, equals(AppLanguage.marathi));
      expect(controller2.currentLocale?.languageCode, equals('mr'));
    });
  });
}
