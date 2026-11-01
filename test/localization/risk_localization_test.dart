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

  group('L4.4 Risk Alerts Localization Tests', () {
    testWidgets('Risk level labels translate dynamically in English and Marathi', (tester) async {
      await languageController.setLanguage(AppLanguage.english);

      late String englishLow;
      late String englishCritical;

      await tester.pumpWidget(
        buildTestWidget(
          Builder(builder: (context) {
            englishLow = LocalizationService.getRiskLabel(context, 'LOW');
            englishCritical = LocalizationService.getRiskLabel(context, 'CRITICAL');
            return Text('$englishLow | $englishCritical');
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(englishLow, equals('Low Risk'));
      expect(englishCritical, equals('Critical Risk'));

      await languageController.setLanguage(AppLanguage.marathi);

      late String marathiLow;
      late String marathiCritical;

      await tester.pumpWidget(
        buildTestWidget(
          Builder(builder: (context) {
            marathiLow = LocalizationService.getRiskLabel(context, 'LOW');
            marathiCritical = LocalizationService.getRiskLabel(context, 'CRITICAL');
            return Text('$marathiLow | $marathiCritical');
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(marathiLow, equals('कमी धोका'));
      expect(marathiCritical, equals('गंभीर धोका'));
    });
  });
}
