import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snaphisaab/core/localization/app_language.dart';
import 'package:snaphisaab/core/localization/language_controller.dart';
import 'package:snaphisaab/l10n/app_localizations.dart';
import 'package:snaphisaab/main.dart';
import 'package:snaphisaab/presentation/home/widgets/smart_mic_fab.dart';

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

  group('L6.1 Voice UI Localization Tests', () {
    testWidgets('SmartMicFab long press displays input options sheet in selected UI language', (tester) async {
      await languageController.setLanguage(AppLanguage.english);

      await tester.pumpWidget(
        buildTestWidget(
          SmartMicFab(
            isListening: false,
            onTap: () {},
            onTypePressed: () {},
            onScanPressed: () {},
            onPastePressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger long press to open input options sheet
      await tester.longPress(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Input Options'), findsOneWidget);
      expect(find.text('Speak'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Scan Receipt'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);
    });
  });
}
