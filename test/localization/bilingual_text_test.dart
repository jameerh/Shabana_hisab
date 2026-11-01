import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snaphisaab/core/localization/app_language.dart';
import 'package:snaphisaab/core/localization/bilingual_text.dart';
import 'package:snaphisaab/core/localization/language_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BilingualText Widget Tests', () {
    testWidgets('Renders English text in English mode', (WidgetTester tester) async {
      final controller = LanguageController();
      await controller.init();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BilingualText(
              english: 'Safe to Spend',
              marathi: 'आज सुरक्षित खर्च',
              languageController: controller,
            ),
          ),
        ),
      );

      expect(find.text('Safe to Spend'), findsOneWidget);
      expect(find.text('आज सुरक्षित खर्च'), findsNothing);
    });

    testWidgets('Renders Marathi text in Marathi mode', (WidgetTester tester) async {
      final controller = LanguageController();
      await controller.init();
      await controller.setLanguage(AppLanguage.marathi);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BilingualText(
              english: 'Safe to Spend',
              marathi: 'आज सुरक्षित खर्च',
              languageController: controller,
            ),
          ),
        ),
      );

      expect(find.text('आज सुरक्षित खर्च'), findsOneWidget);
      expect(find.text('Safe to Spend'), findsNothing);
    });

    testWidgets('Renders both English and Marathi text in English+Marathi mode', (WidgetTester tester) async {
      final controller = LanguageController();
      await controller.init();
      await controller.setLanguage(AppLanguage.englishMarathi);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BilingualText(
              english: 'Safe to Spend',
              marathi: 'आज सुरक्षित खर्च',
              languageController: controller,
            ),
          ),
        ),
      );

      expect(find.text('Safe to Spend'), findsOneWidget);
      expect(find.text('आज सुरक्षित खर्च'), findsOneWidget);
    });
  });
}
