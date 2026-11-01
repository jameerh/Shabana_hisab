import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snaphisaab/core/localization/app_language.dart';
import 'package:snaphisaab/core/localization/language_controller.dart';
import 'package:snaphisaab/core/localization/localization_service.dart';
import 'package:snaphisaab/l10n/app_localizations.dart';
import 'package:snaphisaab/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      languageController = LanguageController();
      await languageController.init();
    } catch (_) {}
  });

  Widget buildTestWidget(Widget child) {
    return ListenableBuilder(
      listenable: languageController,
      builder: (context, _) {
        return MaterialApp(
          locale: languageController.currentLocale ?? const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        );
      },
    );
  }

  group('L4.1 Financial Health Localization Tests', () {
    testWidgets('FinancialHealthTheme labels translate dynamically in English and Marathi', (tester) async {
      await languageController.setLanguage(AppLanguage.english);

      late String englishHealthy;
      late String englishWarning;

      await tester.pumpWidget(
        buildTestWidget(
          Builder(builder: (context) {
            englishHealthy = LocalizationService.getHealthLabel(context, 'Healthy');
            englishWarning = LocalizationService.getHealthLabel(context, 'Warning');
            return Text('$englishHealthy | $englishWarning');
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(englishHealthy, equals('Healthy'));
      expect(englishWarning, equals('Warning'));

      // Switch to Marathi
      await languageController.setLanguage(AppLanguage.marathi);

      late String marathiHealthy;
      late String marathiWarning;

      await tester.pumpWidget(
        buildTestWidget(
          Builder(builder: (context) {
            marathiHealthy = LocalizationService.getHealthLabel(context, 'Healthy');
            marathiWarning = LocalizationService.getHealthLabel(context, 'Warning');
            return Text('$marathiHealthy | $marathiWarning');
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(marathiHealthy, equals('निरोगी'));
      expect(marathiWarning, equals('इशारा'));
    });
  });
}
