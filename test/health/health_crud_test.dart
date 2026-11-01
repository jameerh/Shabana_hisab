import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/data/models/health_models.dart';
import 'package:snaphisaab/data/repositories/health_repository.dart';
import 'package:snaphisaab/core/localization/language_controller.dart';
import 'package:snaphisaab/core/localization/app_language.dart';
import 'package:snaphisaab/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late HealthRepository repository;
  late int profileId;
  late int patientId;

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

    patientId = await repository.addPatient(
      profileId: profileId,
      name: 'Ramesh Patil',
      relationship: 'Self',
      dateOfBirth: DateTime(1980, 5, 15),
      gender: 'MALE',
      bloodGroup: 'B+',
    );
  });

  tearDown(() async {
    repository.dispose();
    await db.close();
  });

  group('Health CRUD Operations Gate', () {
    test('Create, Read, and Update HealthPatient', () async {
      final patient = await repository.getPatientById(patientId);
      expect(patient, isNotNull);
      expect(patient!.name, 'Ramesh Patil');
      expect(patient.relationship, 'Self');
      expect(patient.bloodGroup, 'B+');

      await repository.updatePatient(
        patient.copyWith(
          name: 'Rameshwar Patil',
          relationship: 'Head of Family',
        ),
      );

      final updated = await repository.getPatientById(patientId);
      expect(updated!.name, 'Rameshwar Patil');
      expect(updated.relationship, 'Head of Family');
    });

    test('Create, Read, Update, and Delete HealthEvent (Prescription)', () async {
      final initialDate = DateTime(2026, 9, 10);
      final eventId = await repository.addQuickPrescription(
        profileId: profileId,
        patientId: patientId,
        purpose: 'Viral Fever Routine Check',
        eventDate: initialDate,
        notes: 'Take paracetamol thrice daily',
      );

      // Read
      final event = await repository.getEventById(eventId);
      expect(event, isNotNull);
      expect(event!.eventType, HealthEventType.prescription);
      expect(event.purpose, 'Viral Fever Routine Check');
      expect(event.notes, 'Take paracetamol thrice daily');
      expect(event.eventDate.year, 2026);
      expect(event.eventDate.month, 9);
      expect(event.eventDate.day, 10);

      // Update
      final newDate = DateTime(2026, 9, 12);
      await repository.updateEvent(
        eventId: eventId,
        eventDate: newDate,
        eventTime: '11:00 AM',
        purpose: 'Viral Fever Routine Check (Follow-up)',
        notes: 'Fever reduced, continue vitamins',
        payloadJson: jsonEncode({'purpose': 'Viral Fever Follow-up'}),
      );

      final updatedEvent = await repository.getEventById(eventId);
      expect(updatedEvent, isNotNull);
      expect(updatedEvent!.purpose, 'Viral Fever Routine Check (Follow-up)');
      expect(updatedEvent.notes, 'Fever reduced, continue vitamins');
      expect(updatedEvent.eventDate.year, 2026);
      expect(updatedEvent.eventDate.month, 9);
      expect(updatedEvent.eventDate.day, 12);

      // Delete
      await repository.deleteEvent(eventId);
      final deletedEvent = await repository.getEventById(eventId);
      expect(deletedEvent, isNull);
    });

    test('Detailed Sugar Entry: Create and Non-Destructive Update preserves context and date', () async {
      final eventDate = DateTime(2026, 8, 25);
      final eventId = await repository.addDetailedSugar(
        profileId: profileId,
        patientId: patientId,
        reading: 110.0,
        context: SugarContext.fasting,
        eventDate: eventDate,
        eventTime: '07:30 AM',
        notes: 'Morning fasting sugar',
      );

      final event = await repository.getEventById(eventId);
      expect(event, isNotNull);
      expect(event!.eventType, HealthEventType.sugar);
      expect(event.eventDate, DateTime(2026, 8, 25));
      expect(event.sugarData?.value, 110.0);
      expect(event.sugarData?.context, SugarContext.fasting);

      // Update reading and preserve untouched fields
      await repository.updateSugarEvent(
        eventId: eventId,
        patientId: patientId,
        reading: 115.0,
        context: SugarContext.fasting,
        eventDate: DateTime(2026, 8, 26),
        eventTime: '08:00 AM',
        notes: 'Updated morning reading',
      );

      final updated = await repository.getEventById(eventId);
      expect(updated!.eventDate, DateTime(2026, 8, 26));
      expect(updated.sugarData?.value, 115.0);
      expect(updated.sugarData?.context, SugarContext.fasting);
      expect(updated.notes, 'Updated morning reading');
    });
  });
}
