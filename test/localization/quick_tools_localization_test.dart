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

  group('L6.4 Quick Tools & Calculator Localization Tests', () {
    testWidgets('Quick tools and unit management labels render correctly across language modes', (tester) async {
      await languageController.setLanguage(AppLanguage.english);

      late String englishManage;
      late String englishAdd;

      await tester.pumpWidget(
        buildTestWidget(
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            englishManage = l10n.manageUnits;
            englishAdd = l10n.addNewUnit;
            return Text('$englishManage | $englishAdd');
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(englishManage, equals('Manage Units'));
      expect(englishAdd, equals('Add New Unit'));

      await languageController.setLanguage(AppLanguage.marathi);

      late String marathiManage;
      late String marathiAdd;

      await tester.pumpWidget(
        buildTestWidget(
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            marathiManage = l10n.manageUnits;
            marathiAdd = l10n.addNewUnit;
            return Text('$marathiManage | $marathiAdd');
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(marathiManage, equals('युनिट व्यवस्थापन'));
      expect(marathiAdd, equals('नवीन युनिट जोडा'));
    });
  });
}
