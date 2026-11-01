import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snaphisaab/core/localization/app_language.dart';
import 'package:snaphisaab/core/localization/language_controller.dart';
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

  group('L5.1 Predictive Dashboard Localization Tests', () {
    testWidgets('Predictive Intelligence headers and confidence labels translate correctly across language modes', (tester) async {
      await languageController.setLanguage(AppLanguage.english);

      late String englishPrediction;
      late String englishConfidence;

      await tester.pumpWidget(
        buildTestWidget(
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            englishPrediction = l10n.todaysPrediction;
            englishConfidence = l10n.confidence;
            return Text('$englishPrediction | $englishConfidence');
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(englishPrediction, equals("Today's Prediction"));
      expect(englishConfidence, equals('Confidence'));

      await languageController.setLanguage(AppLanguage.marathi);

      late String marathiPrediction;
      late String marathiConfidence;

      await tester.pumpWidget(
        buildTestWidget(
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            marathiPrediction = l10n.todaysPrediction;
            marathiConfidence = l10n.confidence;
            return Text('$marathiPrediction | $marathiConfidence');
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(marathiPrediction, equals('आजचा अंदाज'));
      expect(marathiConfidence, equals('विश्वासार्हता'));
    });
  });
}
