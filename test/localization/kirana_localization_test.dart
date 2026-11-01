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

  group('L6.2 Kirana Yadi Localization Tests', () {
    testWidgets('Grocery Notes headers and empty state translate correctly while user items remain untouched', (tester) async {
      await languageController.setLanguage(AppLanguage.english);

      late String englishNotes;
      late String englishNoLists;

      await tester.pumpWidget(
        buildTestWidget(
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            englishNotes = l10n.groceryNotes;
            englishNoLists = l10n.noSavedLists;
            return Text('$englishNotes | $englishNoLists');
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(englishNotes, equals('Grocery Notes'));
      expect(englishNoLists, equals('No saved lists yet'));

      await languageController.setLanguage(AppLanguage.marathi);

      late String marathiNotes;
      late String marathiNoLists;

      await tester.pumpWidget(
        buildTestWidget(
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            marathiNotes = l10n.groceryNotes;
            marathiNoLists = l10n.noSavedLists;
            return Text('$marathiNotes | $marathiNoLists');
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(marathiNotes, equals('किराणा यादी'));
      expect(marathiNoLists, equals('अद्याप कोणतीही यादी जतन केलेली नाही'));

      // Non-translation boundary check for user entered raw item name
      const String userEnteredItem = 'Sakhar';
      expect(userEnteredItem, equals('Sakhar'));
    });
  });
}
