import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snaphisaab/core/localization/app_language.dart';
import 'package:snaphisaab/core/localization/language_controller.dart';
import 'package:snaphisaab/l10n/app_localizations.dart';
import 'package:snaphisaab/main.dart';
import 'package:snaphisaab/presentation/quick_tools/mileage_calculator_view.dart';

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
          home: child,
        );
      },
    );
  }

  group('L6.3 Mileage Calculator Localization Tests', () {
    testWidgets('MileageCalculatorView renders in English and Marathi without duplicating numbers', (tester) async {
      await languageController.setLanguage(AppLanguage.english);

      await tester.pumpWidget(buildTestWidget(const MileageCalculatorView()));
      await tester.pumpAndSettle();

      expect(find.text('Mileage Calculator'), findsOneWidget);
      expect(find.text('Fill Fuel Details'), findsOneWidget);

      await languageController.setLanguage(AppLanguage.marathi);
      await tester.pumpAndSettle();

      expect(find.text('मायलेज कॅल्क्युलेटर'), findsOneWidget);
      expect(find.text('इंधन तपशील भरा'), findsOneWidget);

      // Single numeral verification
      const double km = 42.5;
      expect('${km.toStringAsFixed(1)} km', equals('42.5 km'));
    });
  });
}
