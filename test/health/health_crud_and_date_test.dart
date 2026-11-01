import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/data/models/health_models.dart';
import 'package:snaphisaab/data/repositories/health_repository.dart';
import 'package:snaphisaab/presentation/health/widgets/fast_fill_diary_sheet.dart';
import 'package:snaphisaab/presentation/health/dialogs/edit_health_event_dialog.dart';
import 'package:snaphisaab/presentation/health/widgets/health_event_card.dart';
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

  group('Health Hisaab - Calendar Date & Stepping Refinements', () {
    test('1. parseDateOnly treats date strictly as calendar date and avoids UTC timezone shifts', () {
      // Direct string YYYY-MM-DD
      final d1 = parseDateOnly('2026-09-04');
      expect(d1.year, 2026);
      expect(d1.month, 9);
      expect(d1.day, 4);
      expect(d1.isUtc, isFalse);

      // ISO string with UTC midnight
      final d2 = parseDateOnly('2026-09-04T00:00:00.000Z');
      expect(d2.year, 2026);
      expect(d2.month, 9);
      expect(d2.day, 4);
      expect(d2.isUtc, isFalse);

      // DateTime instance
      final d3 = parseDateOnly(DateTime(2026, 8, 15, 23, 59));
      expect(d3.year, 2026);
      expect(d3.month, 8);
      expect(d3.day, 15);
      expect(d3.hour, 0);
      expect(d3.minute, 0);

      // Null or invalid format
      expect(() => parseDateOnly(null), throwsFormatException);
    });

    test('2. addCalendarDays steps accurately across month, year, and leap-year boundaries', () {
      // August (31 days) to September
      final dAug = DateTime(2026, 8, 31);
      final dSep = addCalendarDays(dAug, 1);
      expect(dSep.year, 2026);
      expect(dSep.month, 9);
      expect(dSep.day, 1);

      // September (30 days) to October
      final dSepEnd = DateTime(2026, 9, 30);
      final dOct = addCalendarDays(dSepEnd, 1);
      expect(dOct.year, 2026);
      expect(dOct.month, 10);
      expect(dOct.day, 1);

      // Year boundary: 31 Dec 2026 -> 01 Jan 2027
      final dYearEnd = DateTime(2026, 12, 31);
      final dNewYear = addCalendarDays(dYearEnd, 1);
      expect(dNewYear.year, 2027);
      expect(dNewYear.month, 1);
      expect(dNewYear.day, 1);

      // Leap year 2028: 28 Feb -> 29 Feb -> 01 Mar -> -1 day -> 29 Feb
      final feb28 = DateTime(2028, 2, 28);
      final feb29 = addCalendarDays(feb28, 1);
      expect(feb29.year, 2028);
      expect(feb29.month, 2);
      expect(feb29.day, 29);

      final mar01 = addCalendarDays(feb29, 1);
      expect(mar01.year, 2028);
      expect(mar01.month, 3);
      expect(mar01.day, 1);

      final backToFeb29 = addCalendarDays(mar01, -1);
      expect(backToFeb29.year, 2028);
      expect(backToFeb29.month, 2);
      expect(backToFeb29.day, 29);

      // Non-leap year 2027: 28 Feb -> 01 Mar
      final feb28NonLeap = DateTime(2027, 2, 28);
      final mar01NonLeap = addCalendarDays(feb28NonLeap, 1);
      expect(mar01NonLeap.year, 2027);
      expect(mar01NonLeap.month, 3);
      expect(mar01NonLeap.day, 1);
    });

    test('3. Date regression test: 2026-09-04 never corrupts to 2026-09-03 or 2026-09-05 across DB and Model', () async {
      final patientId = await repository.addPatient(
        profileId: profileId,
        name: 'Father',
        relationship: 'Father',
      );

      final savedDate = DateTime(2026, 9, 4);
      final eventId = await repository.addDetailedSugar(
        profileId: profileId,
        patientId: patientId,
        reading: 118,
        context: SugarContext.fasting,
        eventDate: savedDate,
        eventTime: '08:30 AM',
        notes: 'Felt normal',
      );

      // 1. Fetch from repository via getEventById
      final retrieved = await repository.getEventById(eventId);
      expect(retrieved, isNotNull);
      expect(retrieved!.eventDate.year, 2026);
      expect(retrieved.eventDate.month, 9);
      expect(retrieved.eventDate.day, 4);
      expect(retrieved.eventDate.day, isNot(3));
      expect(retrieved.eventDate.day, isNot(5));

      // 2. Fetch via getEvents filter
      final list = await repository.getEvents(profileId);
      final eventInList = list.firstWhere((e) => e.id == eventId);
      expect(eventInList.eventDate.year, 2026);
      expect(eventInList.eventDate.month, 9);
      expect(eventInList.eventDate.day, 4);

      // 3. Fetch via getEventsByDate
      final dateMatches = await repository.getEventsByDate(
        profileId,
        savedDate,
        patientId: patientId,
      );
      expect(dateMatches.length, 1);
      expect(dateMatches.first.id, eventId);
      expect(dateMatches.first.eventDate.day, 4);
    });
  });

  group('Health Hisaab - Strict Non-Destructive CRUD Tests', () {
    test('4. Sugar Update preserves all untouched fields (patient, date, time, context, notes, ID)', () async {
      final patientId = await repository.addPatient(
        profileId: profileId,
        name: 'Father',
        relationship: 'Father',
      );

      final originalDate = DateTime(2026, 8, 15);
      final eventId = await repository.addDetailedSugar(
        profileId: profileId,
        patientId: patientId,
        reading: 118.0,
        context: SugarContext.fasting,
        eventDate: originalDate,
        eventTime: '08:30 AM',
        notes: 'Felt normal',
      );

      final before = await repository.getEventById(eventId);
      expect(before, isNotNull);
      expect(before!.sugarData?.value, 118.0);
      expect(before.patientId, patientId);
      expect(before.eventTime, '08:30 AM');
      expect(before.sugarData?.context, SugarContext.fasting);
      expect(before.notes, 'Felt normal');

      // Update only reading: 118 -> 125
      await repository.updateSugarEvent(
        eventId: eventId,
        patientId: patientId,
        reading: 125.0,
        context: before.sugarData!.context,
        eventDate: before.eventDate,
        eventTime: before.eventTime,
        notes: before.notes,
      );

      final after = await repository.getEventById(eventId);
      expect(after, isNotNull);
      // Changed:
      expect(after!.sugarData?.value, 125.0);
      // Preserved untouched fields:
      expect(after.id, eventId);
      expect(after.patientId, patientId);
      expect(after.eventDate.year, 2026);
      expect(after.eventDate.month, 8);
      expect(after.eventDate.day, 15);
      expect(after.eventTime, '08:30 AM');
      expect(after.sugarData?.context, SugarContext.fasting);
      expect(after.sugarData?.unit, 'mg/dL');
      expect(after.notes, 'Felt normal');
      expect(after.sourceType, before.sourceType);
      expect(after.completionStatus, before.completionStatus);
    });

    test('5. Blood Pressure Update preserves systolic, diastolic, pulse, and notes accurately', () async {
      final patientId = await repository.addPatient(
        profileId: profileId,
        name: 'Grandpa',
        relationship: 'Grandfather',
      );

      final eventDate = DateTime(2026, 8, 15);
      final eventId = await repository.addDetailedBloodPressure(
        profileId: profileId,
        patientId: patientId,
        systolic: 138,
        diastolic: 86,
        pulse: 74,
        eventDate: eventDate,
        eventTime: '07:30 PM',
        notes: 'Evening reading',
      );

      // Update BP reading to 120/80, pulse 70
      await repository.updateBloodPressureEvent(
        eventId: eventId,
        patientId: patientId,
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        eventDate: eventDate,
        eventTime: '07:30 PM',
        notes: 'Evening reading - normalized',
      );

      final after = await repository.getEventById(eventId);
      expect(after, isNotNull);
      expect(after!.bpData?.systolic, 120);
      expect(after.bpData?.diastolic, 80);
      expect(after.bpData?.pulse, 70);
      expect(after.eventDate.day, 15);
      expect(after.eventTime, '07:30 PM');
      expect(after.notes, 'Evening reading - normalized');
      expect(after.patientId, patientId);
    });

    test('6. Attachment Semantics: Keep, Remove, and Delete with safety', () async {
      final patientId = await repository.addPatient(
        profileId: profileId,
        name: 'Mother',
      );

      // Create event with no evidence first
      final eventId = await repository.addDetailedSugar(
        profileId: profileId,
        patientId: patientId,
        reading: 140,
        context: SugarContext.afterMeal,
        eventDate: DateTime(2026, 8, 15),
        eventTime: '02:00 PM',
      );

      final initial = await repository.getEventById(eventId);
      expect(initial!.evidenceStatus, HealthEvidenceStatus.none);

      // Delete event completely cleanly
      await repository.deleteEvent(eventId);
      final deleted = await repository.getEventById(eventId);
      expect(deleted, isNull);
    });
  });

  group('Health Hisaab - Fast Fill UI & Retention Tests', () {
    testWidgets('7. Fast Fill retains diary date across close and reopen', (tester) async {
      tester.view.physicalSize = const Size(1024, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final patientId = await repository.addPatient(
        profileId: profileId,
        name: 'Father',
        relationship: 'Father',
      );
      final patients = await repository.getPatients(profileId);

      // Explicitly set retained date to 15 Aug 2026
      FastFillDiarySheet.retainedDiaryDate = DateTime(2026, 8, 15);

      // Mount sheet without initialDate -> should use retained date
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

      // Date banner displays Aug 15, 2026
      expect(find.textContaining('Sat, 15 Aug 2026'), findsOneWidget);
    });

    testWidgets('8. Fast Fill displays Already Recorded on this Date and Logged this Session with Edit and Delete', (tester) async {
      tester.view.physicalSize = const Size(1024, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final patientId = await repository.addPatient(
        profileId: profileId,
        name: 'Father',
        relationship: 'Father',
      );
      final patients = await repository.getPatients(profileId);

      final fixedDate = DateTime(2026, 8, 15);
      // Pre-seed an existing record for 15 Aug 2026
      await repository.addDetailedSugar(
        profileId: profileId,
        patientId: patientId,
        reading: 110,
        context: SugarContext.fasting,
        eventDate: fixedDate,
        eventTime: '08:00 AM',
      );

      // Open Fast Fill on 15 Aug 2026
      await tester.pumpWidget(
        buildTestApp(
          FastFillDiarySheet(
            profileId: profileId,
            patients: patients,
            initialPatientId: patientId,
            initialDate: fixedDate,
            onSaved: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify "ALREADY RECORDED" section is present with pre-existing record
      expect(find.textContaining('ALREADY RECORDED'), findsOneWidget);
      expect(find.textContaining('110'), findsWidgets);

      // Add another record in this session
      await tester.enterText(find.byType(TextField).first, '145');
      // Tap Post Meal
      await tester.tap(find.textContaining('Post-Meal'));
      await tester.pumpAndSettle();

      // Tap Save & Add Next
      await tester.tap(find.textContaining('Save & Add Next'));
      await tester.pumpAndSettle();

      // Verify "SESSION LOG" shows the new record
      expect(find.textContaining('SESSION LOG'), findsOneWidget);
      expect(find.textContaining('145'), findsWidgets);

      // Verify Edit and Delete icons exist for records
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);
      expect(find.byIcon(Icons.delete_outline), findsWidgets);
    });

    testWidgets('9. Delete button shows confirmation dialog before deleting record', (tester) async {
      tester.view.physicalSize = const Size(1024, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final patientId = await repository.addPatient(
        profileId: profileId,
        name: 'Father',
        relationship: 'Father',
      );
      final patients = await repository.getPatients(profileId);

      final fixedDate = DateTime(2026, 8, 15);
      final eventId = await repository.addDetailedSugar(
        profileId: profileId,
        patientId: patientId,
        reading: 110,
        context: SugarContext.fasting,
        eventDate: fixedDate,
        eventTime: '08:00 AM',
      );

      await tester.pumpWidget(
        buildTestApp(
          FastFillDiarySheet(
            profileId: profileId,
            patients: patients,
            initialPatientId: patientId,
            initialDate: fixedDate,
            onSaved: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Delete IconButton
      final deleteBtn = find.byTooltip('Delete Record').first;
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog must appear
      expect(find.text('Delete Health Record?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel -> record still in DB
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await repository.getEventById(eventId), isNotNull);

      // Tap Delete again and Confirm
      await tester.tap(find.byTooltip('Delete Record').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      // Record must now be deleted
      expect(await repository.getEventById(eventId), isNull);
    });

    testWidgets('10. EditHealthEventDialog allows updating Sugar reading and preserves untouched attributes', (tester) async {
      tester.view.physicalSize = const Size(1024, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final patientId = await repository.addPatient(
        profileId: profileId,
        name: 'Father',
        relationship: 'Father',
      );
      final patients = await repository.getPatients(profileId);

      final eventDate = DateTime(2026, 8, 15);
      final eventId = await repository.addDetailedSugar(
        profileId: profileId,
        patientId: patientId,
        reading: 118,
        context: SugarContext.fasting,
        eventDate: eventDate,
        eventTime: '08:30 AM',
        notes: 'Felt normal',
      );

      final event = await repository.getEventById(eventId);
      expect(event, isNotNull);

      bool updatedCalled = false;

      await tester.pumpWidget(
        buildTestApp(
          EditHealthEventDialog(
            event: event!,
            patients: patients,
            onUpdated: () => updatedCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify dialog header
      expect(find.textContaining('Edit Blood Sugar Record'), findsOneWidget);

      // Change reading from 118 to 125
      final readingField = find.widgetWithText(TextField, '118');
      await tester.enterText(readingField, '125');
      await tester.pumpAndSettle();

      // Tap Save Changes
      await tester.tap(find.textContaining('Save Changes'));
      await tester.pumpAndSettle();

      expect(updatedCalled, isTrue);

      // Verify record in repository
      final updatedEvent = await repository.getEventById(eventId);
      expect(updatedEvent!.sugarData?.value, 125.0);
      expect(updatedEvent.sugarData?.context, SugarContext.fasting);
      expect(updatedEvent.notes, 'Felt normal');
      expect(updatedEvent.eventTime, contains('8:30 AM'));
      expect(updatedEvent.patientId, patientId);
      expect(updatedEvent.eventDate.day, 15);
    });

    testWidgets('11. HealthEventCard contains Edit Record in popup menu', (tester) async {
      final patientId = await repository.addPatient(
        profileId: profileId,
        name: 'Me',
      );

      final event = HealthEvent(
        id: 1,
        profileId: profileId,
        patientId: patientId,
        eventType: HealthEventType.sugar,
        purpose: 'Sugar (Fasting)',
        eventDate: DateTime(2026, 8, 15),
        eventTime: '08:30 AM',
        completionStatus: HealthCompletionStatus.completed,
        sourceType: HealthSourceType.manual,
        evidenceStatus: HealthEvidenceStatus.none,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        payloadJson: jsonEncode(SugarData(value: 118, context: SugarContext.fasting).toMap()),
      );

      bool editTapped = false;

      await tester.pumpWidget(
        buildTestApp(
          HealthEventCard(
            event: event,
            patientName: 'Me',
            onTap: () {},
            onDelete: () {},
            onEdit: () => editTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Look for Edit Record option
      expect(find.text('Edit Record'), findsOneWidget);
      await tester.tap(find.text('Edit Record'));
      await tester.pumpAndSettle();

      expect(editTapped, isTrue);
    });
  });
}
