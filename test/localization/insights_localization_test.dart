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

  group('L4.3 Insights Localization Tests', () {
    testWidgets('Financial Insights and Hub labels render correctly across language modes', (tester) async {
      await languageController.setLanguage(AppLanguage.english);

      late String englishInsights;
      late String englishHub;

      await tester.pumpWidget(
        buildTestWidget(
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            englishInsights = l10n.financialInsights;
            englishHub = l10n.intelligenceHub;
            return Text('$englishInsights | $englishHub');
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(englishInsights, equals('Financial Insights'));
      expect(englishHub, equals('Intelligence Hub'));

      await languageController.setLanguage(AppLanguage.marathi);

      late String marathiInsights;
      late String marathiHub;

      await tester.pumpWidget(
        buildTestWidget(
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            marathiInsights = l10n.financialInsights;
            marathiHub = l10n.intelligenceHub;
            return Text('$marathiInsights | $marathiHub');
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(marathiInsights, equals('आर्थिक निरिक्षणे'));
      expect(marathiHub, equals('बुद्धिमत्ता केंद्र'));
    });
  });
}
