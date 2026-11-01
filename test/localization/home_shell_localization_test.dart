import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snaphisaab/core/localization/app_language.dart';
import 'package:snaphisaab/core/localization/language_controller.dart';
import 'package:snaphisaab/l10n/app_localizations.dart';
import 'package:snaphisaab/main.dart';
import 'package:snaphisaab/presentation/home/widgets/greeting_section.dart';
import 'package:snaphisaab/presentation/home/widgets/balance_summary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    languageController = LanguageController();
    await languageController.init();
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

  group('Phase L2 Home Shell Localization Tests', () {
    testWidgets('GreetingSection displays English Net Balance in English mode', (tester) async {
      await languageController.setLanguage(AppLanguage.english);

      await tester.pumpWidget(
        buildTestWidget(
          GreetingSection(profileName: 'Store', netBalance: '₹5,000'),
        ),
      );

      expect(find.text('Net Balance'), findsOneWidget);
      expect(find.text('एकूण शिल्लक'), findsNothing);
    });

    testWidgets('GreetingSection displays Marathi Net Balance in Marathi mode', (tester) async {
      await languageController.setLanguage(AppLanguage.marathi);

      await tester.pumpWidget(
        buildTestWidget(
          GreetingSection(profileName: 'Store', netBalance: '₹5,000'),
        ),
      );

      expect(find.text('एकूण शिल्लक'), findsOneWidget);
      expect(find.text('Net Balance'), findsNothing);
    });

    testWidgets('GreetingSection displays both English & Marathi Net Balance in English+Marathi mode', (tester) async {
      await languageController.setLanguage(AppLanguage.englishMarathi);

      await tester.pumpWidget(
        buildTestWidget(
          GreetingSection(profileName: 'Store', netBalance: '₹5,000'),
        ),
      );

      expect(find.text('Net Balance'), findsOneWidget);
      expect(find.text('एकूण शिल्लक'), findsOneWidget);
    });

    testWidgets('BalanceSummary renders localized collapsed preview items', (tester) async {
      await languageController.setLanguage(AppLanguage.english);

      await tester.pumpWidget(
        buildTestWidget(
          const BalanceSummary(transactions: []),
        ),
      );

      expect(find.textContaining('Income: ₹0'), findsOneWidget);
      expect(find.textContaining('Expense: ₹0'), findsOneWidget);
    });
  });
}
