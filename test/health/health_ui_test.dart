import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/data/models/health_models.dart';
import 'package:snaphisaab/data/repositories/health_repository.dart';
import 'package:snaphisaab/presentation/health/health_home_view.dart';
import 'package:snaphisaab/presentation/health/doctor_view.dart';
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
    } catch (_) {}
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    database = db;
    repository = HealthRepository(db);
    healthRepository = repository;

    profileId = await db.into(db.profiles).insert(
      ProfilesCompanion.insert(
        name: 'Family Shop',
        type: ProfileType.PERSONAL,
      ),
    );
  });

  tearDown(() async {
    repository.dispose();
    await db.close();
  });

  Widget buildTestApp(Widget child) {
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

  group('Health Hisaab UI Tests', () {
    testWidgets('1. HealthHomeView renders AppBar, Tabs, Patient Bar, and Add button', (tester) async {
      await languageController.setLanguage(AppLanguage.english);

      await tester.pumpWidget(buildTestApp(HealthHomeView(profileId: profileId)));
      await tester.pumpAndSettle();

      // Check AppBar Title
      expect(find.text('Health Hisaab'), findsOneWidget);

      // Check Doctor View button
      expect(find.text('Doctor View'), findsOneWidget);

      // Check Tabs
      expect(find.text('Timeline'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Analysis'), findsOneWidget);

      // Check Floating Action Button
      expect(find.widgetWithText(FloatingActionButton, 'Add Health Record'), findsOneWidget);

      // Check Patient selector
      expect(find.text('Patient:'), findsOneWidget);
      expect(find.text('All Family'), findsOneWidget);
      expect(find.text('Me (Self)'), findsOneWidget);
    });

    testWidgets('2. Tapping Add Health Record opens choice modal (Quick Capture vs Detailed Entry)', (tester) async {
      await tester.pumpWidget(buildTestApp(HealthHomeView(profileId: profileId)));
      await tester.pumpAndSettle();

      // Tap FAB
      await tester.tap(find.widgetWithText(FloatingActionButton, 'Add Health Record'));
      await tester.pumpAndSettle();

      // Verify choice sheet is presented
      expect(find.text('Quick Capture'), findsOneWidget);
      expect(find.text('Detailed Health Entry'), findsOneWidget);
    });

    testWidgets('3. DoctorView renders filter bar, patient banner, and Export PDF action', (tester) async {
      final fatherId = await repository.addPatient(
        profileId: profileId,
        name: 'Father',
        relationship: 'Father',
      );

      await repository.addQuickPrescription(
        profileId: profileId,
        patientId: fatherId,
        purpose: 'Fever',
      );

      final patients = await repository.getPatients(profileId);

      await tester.pumpWidget(
        buildTestApp(
          DoctorView(
            profileId: profileId,
            patients: patients,
            initialPatientId: fatherId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Doctor View'), findsOneWidget);
      expect(find.text('Export 8-Part Doctor Report (PDF)'), findsOneWidget);
      expect(find.text('📄 DOCUMENTS & ORIGINAL EVIDENCE'), findsOneWidget);
      expect(find.text('📊 STRUCTURED MEASUREMENTS'), findsOneWidget);
    });
  });
}
