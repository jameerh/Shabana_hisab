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

  group('SMS Import Localization & ADR-020 Integration Tests', () {
    testWidgets('SMS Import strings translate dynamically in English and Marathi modes', (tester) async {
      await languageController.setLanguage(AppLanguage.english);

      late String englishImport;
      late String englishScan;

      await tester.pumpWidget(
        buildTestWidget(
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            englishImport = l10n.smsImport;
            englishScan = l10n.scanSmsInbox;
            return Text('$englishImport | $englishScan');
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(englishImport, equals('Bank & Card SMS Import'));
      expect(englishScan, equals('Scan Bank & Card SMS'));

      await languageController.setLanguage(AppLanguage.marathi);

      late String marathiImport;
      late String marathiScan;

      await tester.pumpWidget(
        buildTestWidget(
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            marathiImport = l10n.smsImport;
            marathiScan = l10n.scanSmsInbox;
            return Text('$marathiImport | $marathiScan');
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(marathiImport, equals('बँक आणि कार्ड SMS आयात'));
      expect(marathiScan, equals('बँक आणि कार्ड SMS स्कॅन करा'));
    });
  });
}
