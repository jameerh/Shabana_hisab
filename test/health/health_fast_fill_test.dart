import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/data/models/health_models.dart';
import 'package:snaphisaab/data/repositories/health_repository.dart';
import 'package:snaphisaab/presentation/health/widgets/fast_fill_diary_sheet.dart';
import 'package:snaphisaab/presentation/health/widgets/health_chart_view.dart';
import 'package:snaphisaab/core/localization/language_controller.dart';
import 'package:snaphisaab/core/localization/app_language.dart';
import 'package:snaphisaab/l10n/app_localizations.dart';
import 'package:snaphisaab/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late HealthRepository repository;
  late int profileId;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      languageController = LanguageController();
      await languageController.init();
      await languageController.setLanguage(AppLanguage.english);
    } catch (_) {}
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    database = db;
    repository = HealthRepository(db);
    healthRepository = repository;

    profileId = await db.into(db.profiles).insert(
      ProfilesCompanion.insert(
        name: 'Test Family',
        type: ProfileType.PERSONAL,
      ),
    );
  });

  tearDown(() async {
    repository.dispose();
    await db.close();
  });

  Widget buildTestApp(Widget child) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  group('Health Hisaab Paper Diary Fast Fill & Separate Charts Tests', () {
    testWidgets('1. FastFillDiarySheet renders sugar mode, date stepper, meal contexts, and Save & Add Next button', (tester) async {
      tester.view.physicalSize = const Size(1024, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final patientId = await repository.addPatient(
        profileId: profileId,
        name: 'Grandpa',
        relationship: 'Grandfather',
      );
      final patients = await repository.getPatients(profileId);

      await tester.pumpWidget(
        buildTestApp(
          FastFillDiarySheet(
            profileId: profileId,
            patients: patients,
            initialPatientId: patientId,
            onSaved: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and titles
      expect(find.text('Paper Diary Fast Fill'), findsOneWidget);
      expect(find.text('Blood Sugar'), findsOneWidget);
      expect(find.text('Blood Pressure'), findsOneWidget);

      // Check date stepper
      expect(find.text('◀ -1 Day'), findsOneWidget);
      expect(find.text('+1 Day ▶'), findsOneWidget);

      // Check meal contexts
      expect(find.textContaining('Fasting'), findsWidgets);
      expect(find.textContaining('Post-Meal'), findsWidgets);
      expect(find.textContaining('Random'), findsWidgets);

      // Check Save & Add Next button
      expect(find.textContaining('Save & Add Next'), findsOneWidget);
      expect(find.text('OPTIONAL'), findsOneWidget);
    });

    testWidgets('2. FastFillDiarySheet Save & Add Next saves Sugar entry, keeps sheet open and date fixed', (tester) async {
      tester.view.physicalSize = const Size(1024, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final patientId = await repository.addPatient(
        profileId: profileId,
        name: 'Grandpa',
        relationship: 'Grandfather',
      );
      final patients = await repository.getPatients(profileId);
      bool onSavedCalled = false;

      await tester.pumpWidget(
        buildTestApp(
          FastFillDiarySheet(
            profileId: profileId,
            patients: patients,
            initialPatientId: patientId,
            onSaved: () => onSavedCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter sugar reading 118
      final sugarField = find.byType(TextField).first;
      await tester.enterText(sugarField, '118');
      await tester.pumpAndSettle();

      // Tap 'Save & Add Next'
      final saveBtn = find.textContaining('Save & Add Next');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify onSaved was invoked
      expect(onSavedCalled, isTrue);

      // Verify sheet is STILL OPEN (modal did not close)
      expect(find.text('Paper Diary Fast Fill'), findsOneWidget);

      // Verify session log shows the saved record
      expect(find.text('Sugar: 118 mg/dL (Fasting)'), findsOneWidget);
      expect(find.text('Done (1)'), findsOneWidget);

      // Verify database contains the record with structured date and time
      final events = await repository.getEvents(profileId, patientId: patientId);
      expect(events.length, 1);
      expect(events.first.eventType, HealthEventType.sugar);
      expect(events.first.sugarData?.value, 118.0);
      expect(events.first.sugarData?.context, SugarContext.fasting);
      expect(events.first.hasEvidence, isFalse); // Optional attachment was empty -> Manual record
    });

    testWidgets('3. FastFillDiarySheet switches to Blood Pressure and logs BP records continuously', (tester) async {
      tester.view.physicalSize = const Size(1024, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final patientId = await repository.addPatient(
        profileId: profileId,
        name: 'Grandpa',
        relationship: 'Grandfather',
      );
      final patients = await repository.getPatients(profileId);

      await tester.pumpWidget(
        buildTestApp(
          FastFillDiarySheet(
            profileId: profileId,
            patients: patients,
            initialPatientId: patientId,
            initialType: HealthEventType.bloodPressure,
            onSaved: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter BP: 130 / 85, pulse 72
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '130'); // Systolic
      await tester.enterText(textFields.at(1), '85');  // Diastolic
      await tester.enterText(textFields.at(2), '72');  // Pulse
      await tester.pumpAndSettle();

      final saveBtn = find.textContaining('Save & Add Next');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify in session ledger
      expect(find.text('BP: 130/85 mmHg (Pulse: 72)'), findsOneWidget);

      // Verify in database
      final events = await repository.getEvents(profileId, patientId: patientId);
      expect(events.length, 1);
      expect(events.first.eventType, HealthEventType.bloodPressure);
      expect(events.first.bpData?.systolic, 130);
      expect(events.first.bpData?.diastolic, 85);
      expect(events.first.bpData?.pulse, 72);
    });

    testWidgets('4. HealthChartView provides dedicated separate charts for Pre-Meal, Post-Meal, Random, and All', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final patientId = await repository.addPatient(
        profileId: profileId,
        name: 'Grandpa',
      );

      final date1 = DateTime(2026, 8, 10);
      final date2 = DateTime(2026, 8, 11);
      final date3 = DateTime(2026, 8, 12);

      // 1. Fasting reading (Pre-Meal)
      await repository.addDetailedSugar(
        profileId: profileId,
        patientId: patientId,
        reading: 92,
        context: SugarContext.fasting,
        eventDate: date1,
        eventTime: '08:00 AM',
      );

      // 2. Post-Meal reading
      await repository.addDetailedSugar(
        profileId: profileId,
        patientId: patientId,
        reading: 148,
        context: SugarContext.afterMeal,
        eventDate: date2,
        eventTime: '01:30 PM',
      );

      // 3. Random reading
      await repository.addDetailedSugar(
        profileId: profileId,
        patientId: patientId,
        reading: 110,
        context: SugarContext.random,
        eventDate: date3,
        eventTime: '05:00 PM',
      );

      final events = await repository.getEvents(profileId);

      bool fastFillTapped = false;
      await tester.pumpWidget(
        buildTestApp(
          HealthChartView(
            events: events,
            onOpenFastFill: (_) => fastFillTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Pre-Meal view is default
      expect(find.text('Pre-Meal / Fasting Sugar (उपवासाची साखर)'), findsOneWidget);
      expect(find.text('92 mg/dL'), findsWidgets); // Average / Min / Max in stats
      expect(find.text('100%'), findsOneWidget);   // 92 <= 100 mg/dL target

      // 2. Switch to Post-Meal chart
      final postMealChip = find.textContaining('Post-Meal');
      await tester.ensureVisible(postMealChip);
      await tester.tap(postMealChip);
      await tester.pumpAndSettle();

      expect(find.text('Post-Meal Sugar (जेवणानंतरची साखर)'), findsOneWidget);
      expect(find.text('148 mg/dL'), findsWidgets);

      // 3. Switch to Random chart
      final randomChip = find.textContaining('Random');
      await tester.ensureVisible(randomChip);
      await tester.tap(randomChip);
      await tester.pumpAndSettle();

      expect(find.text('Random Sugar (कधीही तपासलेली साखर)'), findsOneWidget);
      expect(find.text('110 mg/dL'), findsWidgets);

      // 4. Switch to All Combined
      final allCombinedChip = find.textContaining('All Combined');
      await tester.ensureVisible(allCombinedChip);
      await tester.tap(allCombinedChip);
      await tester.pumpAndSettle();

      expect(find.text('All Sugar Readings (सर्व एकत्रित आलेख)'), findsOneWidget);
      expect(find.text('3'), findsWidgets); // 3 readings total

      // 5. Verify direct Fast Fill shortcut button in chart view
      expect(find.text('Fast Fill Paper Log'), findsOneWidget);
      await tester.tap(find.text('Fast Fill Paper Log'));
      await tester.pumpAndSettle();
      expect(fastFillTapped, isTrue);
    });
  });
}
