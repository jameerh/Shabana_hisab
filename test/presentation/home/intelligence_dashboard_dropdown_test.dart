import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/main.dart';
import 'package:snaphisaab/core/localization/language_controller.dart';
import 'package:snaphisaab/presentation/home/widgets/intelligence_dashboard_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IntelligenceDashboardSection Expand/Collapse Gate', () {
    late AppDatabase testDb;

    setUp(() {
      testDb = AppDatabase.forTesting(NativeDatabase.memory());
      database = testDb;
      languageController = LanguageController();
    });

    tearDown(() async {
      await testDb.close();
    });

    testWidgets('Hidden by default and expands/collapses on tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: IntelligenceDashboardSection(profileId: 1),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header is rendered
      expect(find.text('Financial Intelligence'), findsOneWidget);

      // Verify crossfade starts collapsed (showFirst)
      final crossFadeFinder = find.byType(AnimatedCrossFade);
      expect(crossFadeFinder, findsOneWidget);
      AnimatedCrossFade crossFade = tester.widget(crossFadeFinder);
      expect(crossFade.crossFadeState, CrossFadeState.showFirst);

      // Tap header to expand
      await tester.tap(find.text('Financial Intelligence'));
      await tester.pumpAndSettle();

      // Verify crossfade is now expanded (showSecond)
      crossFade = tester.widget(crossFadeFinder);
      expect(crossFade.crossFadeState, CrossFadeState.showSecond);

      // Tap header again to collapse
      await tester.tap(find.text('Financial Intelligence'));
      await tester.pumpAndSettle();

      // Verify crossfade is collapsed again (showFirst)
      crossFade = tester.widget(crossFadeFinder);
      expect(crossFade.crossFadeState, CrossFadeState.showFirst);

      // Clean unmount to drain drift stream query timers
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
