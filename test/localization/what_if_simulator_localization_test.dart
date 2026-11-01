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

  group('L5.2 What-If Simulator Localization Tests', () {
    testWidgets('What-If Simulator labels and categories translate correctly across language modes', (tester) async {
      await languageController.setLanguage(AppLanguage.english);

      late String englishNotice;
      late String englishRun;

      await tester.pumpWidget(
        buildTestWidget(
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            englishNotice = l10n.isolatedSandboxNotice;
            englishRun = l10n.runWhatIfSimulation;
            return Text('$englishNotice | $englishRun');
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(englishNotice, contains('Isolated Sandbox'));
      expect(englishRun, equals('Run What-If Simulation'));

      await languageController.setLanguage(AppLanguage.marathi);

      late String marathiNotice;
      late String marathiRun;

      await tester.pumpWidget(
        buildTestWidget(
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            marathiNotice = l10n.isolatedSandboxNotice;
            marathiRun = l10n.runWhatIfSimulation;
            return Text('$marathiNotice | $marathiRun');
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(marathiNotice, contains('अलिप्त वाळूचा चौकट'));
      expect(marathiRun, equals('सिम्युलेशन चालवा'));
    });
  });
}
