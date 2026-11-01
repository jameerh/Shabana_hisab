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

  group('L4.2 Recommendations Localization Tests', () {
    testWidgets('Recommendations header and labels render correctly across language modes', (tester) async {
      await languageController.setLanguage(AppLanguage.english);

      late String englishRecs;
      late String englishWhy;

      await tester.pumpWidget(
        buildTestWidget(
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            englishRecs = l10n.recommendations;
            englishWhy = l10n.whyThisIsShown;
            return Text('$englishRecs | $englishWhy');
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(englishRecs, equals('Recommendations'));
      expect(englishWhy, equals('Why this is shown'));

      await languageController.setLanguage(AppLanguage.marathi);

      late String marathiRecs;
      late String marathiWhy;

      await tester.pumpWidget(
        buildTestWidget(
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            marathiRecs = l10n.recommendations;
            marathiWhy = l10n.whyThisIsShown;
            return Text('$marathiRecs | $marathiWhy');
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(marathiRecs, equals('शिफारसी'));
      expect(marathiWhy, equals('हे का दाखवले आहे'));
    });
  });
}
