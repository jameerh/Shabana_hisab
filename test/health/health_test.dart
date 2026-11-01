import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/data/models/health_models.dart';
import 'package:snaphisaab/data/repositories/health_repository.dart';
import 'package:snaphisaab/data/services/health_attachment_service.dart';
import 'package:snaphisaab/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late HealthRepository repository;
  late int profileId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    database = db;
    repository = HealthRepository(db);

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

  group('Health Hisaab - Architectural & Model Tests', () {
    test('1. Patient management: Cautious seeding only seeds "Me" (Self)', () async {
      final patients = await repository.getPatients(profileId);
      expect(patients.length, 1);
      expect(patients.first.name, 'Me');
      expect(patients.first.relationship, 'Self');
    });

    test('2. Patient age calculation works accurately from dateOfBirth', () async {
      final dob = DateTime(1980, 5, 15);
      final patient = HealthPatient(
        id: 1,
        profileId: profileId,
        name: 'Father',
        relationship: 'Father',
        dateOfBirth: dob,
        gender: 'Male',
        bloodGroup: 'B+',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final expectedAge = (DateTime.now().difference(dob).inDays ~/ 365);
      expect(patient.ageInYears, expectedAge);
    });

    test('3. Authoritative patientId reference (No stale patientName in events)', () async {
      // Add Father
      final fatherId = await repository.addPatient(
        profileId: profileId,
        name: 'Father',
        relationship: 'Father',
      );

      // Create quick prescription
      final eventId = await repository.addQuickPrescription(
        profileId: profileId,
        patientId: fatherId,
        purpose: 'Fever',
        eventDate: DateTime(2026, 9, 4),
      );

      final event = await repository.getEventById(eventId);
      expect(event, isNotNull);
      expect(event!.patientId, fatherId);

      // Verify event itself does NOT hardcode a stale name column;
      // resolution is dynamic:
      final patient = await repository.getPatientById(event.patientId);
      expect(patient!.name, 'Father');

      // Rename patient: Father -> Abdul
      await repository.updatePatient(patient.copyWith(name: 'Abdul'));

      // Event still references fatherId, dynamically resolving to 'Abdul'
      final updatedPatient = await repository.getPatientById(event.patientId);
      expect(updatedPatient!.name, 'Abdul');
    });

    test('4. Auto-generated human-readable filename labels match user requirement', () {
      final label1 = HealthAttachmentService.generateDisplayName(
        eventCategoryOrType: 'Prescription',
        patientName: 'Father',
        purposeOrReport: 'Cold / Fever',
        eventDate: DateTime(2026, 9, 4),
        fileExtension: '.jpg',
      );
      expect(label1, 'Prescription_Father_Cold-Fever_04-Sep-2026.jpg');

      final label2 = HealthAttachmentService.generateDisplayName(
        eventCategoryOrType: 'CBC',
        patientName: 'Father',
        purposeOrReport: 'Report',
        eventDate: DateTime(2026, 9, 4),
        fileExtension: '.pdf',
      );
      expect(label2, 'CBC_Father_Report_04-Sep-2026.pdf');
    });

    test('5. Quick Capture: Prescription saves in CAPTURED state without forcing structured typing', () async {
      final fatherId = await repository.addPatient(
        profileId: profileId,
        name: 'Father',
        relationship: 'Father',
      );

      final eventId = await repository.addQuickPrescription(
        profileId: profileId,
        patientId: fatherId,
        purpose: 'Cold / Fever',
        eventDate: DateTime(2026, 9, 4),
      );

      final event = await repository.getEventById(eventId);
      expect(event, isNotNull);
      expect(event!.eventType, HealthEventType.prescription);
      expect(event.purpose, 'Cold / Fever');
      expect(event.completionStatus, HealthCompletionStatus.captured);
      expect(event.sourceType, HealthSourceType.manual);
    });

    test('6. Quick Capture: Lab Report preserves reportType without forcing manual parameter entry', () async {
      final fatherId = await repository.addPatient(
        profileId: profileId,
        name: 'Father',
        relationship: 'Father',
      );

      final eventId = await repository.addQuickLabReport(
        profileId: profileId,
        patientId: fatherId,
        reportType: LabReportType.dengue,
        resultSummary: 'NS1 - Positive',
        eventDate: DateTime(2026, 8, 21),
      );

      final event = await repository.getEventById(eventId);
      expect(event, isNotNull);
      expect(event!.eventType, HealthEventType.labReport);
      expect(event.reportType, LabReportType.dengue.name);
      expect(event.labReportData?.resultSummary, 'NS1 - Positive');
      expect(event.completionStatus, HealthCompletionStatus.captured);
    });

    test('7. Detailed Health Entry: Blood Sugar with strongly typed SugarData and SugarContext', () async {
      final motherId = await repository.addPatient(
        profileId: profileId,
        name: 'Mother',
        relationship: 'Mother',
      );

      final eventId = await repository.addDetailedSugar(
        profileId: profileId,
        patientId: motherId,
        reading: 128.0,
        context: SugarContext.afterMeal,
        unit: 'mg/dL',
        eventDate: DateTime(2026, 9, 4),
      );

      final event = await repository.getEventById(eventId);
      expect(event, isNotNull);
      expect(event!.eventType, HealthEventType.sugar);

      final sugarData = event.sugarData;
      expect(sugarData, isNotNull);
      expect(sugarData!.value, 128.0);
      expect(sugarData.context, SugarContext.afterMeal);
      expect(sugarData.unit, 'mg/dL');
      expect(event.completionStatus, HealthCompletionStatus.completed);
    });

    test('8. Detailed Health Entry: Blood Pressure with strongly typed BloodPressureData', () async {
      final fatherId = await repository.addPatient(
        profileId: profileId,
        name: 'Father',
        relationship: 'Father',
      );

      final eventId = await repository.addDetailedBloodPressure(
        profileId: profileId,
        patientId: fatherId,
        systolic: 138,
        diastolic: 86,
        pulse: 74,
        eventDate: DateTime(2026, 9, 4),
      );

      final event = await repository.getEventById(eventId);
      expect(event, isNotNull);
      expect(event!.eventType, HealthEventType.bloodPressure);

      final bpData = event.bpData;
      expect(bpData, isNotNull);
      expect(bpData!.systolic, 138);
      expect(bpData.diastolic, 86);
      expect(bpData.pulse, 74);
      expect(event.completionStatus, HealthCompletionStatus.completed);
    });

    test('9. Attach First, Fill Later workflow: Transitioning from CAPTURED to COMPLETED', () async {
      final fatherId = await repository.addPatient(
        profileId: profileId,
        name: 'Father',
        relationship: 'Father',
      );

      // Phase 1: At clinic/hospital, snap photo and save in 5 seconds
      final eventId = await repository.addQuickPrescription(
        profileId: profileId,
        patientId: fatherId,
        purpose: 'Fever',
        eventDate: DateTime(2026, 9, 4),
      );

      var event = await repository.getEventById(eventId);
      expect(event!.completionStatus, HealthCompletionStatus.captured);

      // Phase 2: Later at home, enter medicines and mark COMPLETED
      final completedRx = PrescriptionData(
        purpose: 'Fever',
        doctorName: 'Dr. Patil',
        medicines: ['Paracetamol 650mg 1-0-1', 'Vitamin C 500mg 1-0-0'],
      );

      await repository.completeEventDetails(
        eventId: eventId,
        payloadJson: jsonEncode(completedRx.toMap()),
        notes: 'Take medicines after meals',
      );

      event = await repository.getEventById(eventId);
      expect(event!.completionStatus, HealthCompletionStatus.completed);
      expect(event.prescriptionData?.doctorName, 'Dr. Patil');
      expect(event.prescriptionData?.medicines.length, 2);
      expect(event.notes, 'Take medicines after meals');
    });

    test('10. Date concept: eventDate (measurement date) vs createdAt (database timestamp)', () async {
      final fatherId = await repository.addPatient(
        profileId: profileId,
        name: 'Father',
        relationship: 'Father',
      );

      final pastDate = DateTime(2026, 8, 15);
      final eventId = await repository.addQuickLabReport(
        profileId: profileId,
        patientId: fatherId,
        reportType: LabReportType.cbc,
        eventDate: pastDate,
      );

      final event = await repository.getEventById(eventId);
      expect(event!.eventDate.year, 2026);
      expect(event.eventDate.month, 8);
      expect(event.eventDate.day, 15);

      // Database entry was created today
      expect(event.createdAt.difference(DateTime.now()).inMinutes.abs(), lessThan(2));
    });

    test('11. Delete event cleans up associated record cleanly', () async {
      final fatherId = await repository.addPatient(
        profileId: profileId,
        name: 'Father',
        relationship: 'Father',
      );

      final eventId = await repository.addQuickPrescription(
        profileId: profileId,
        patientId: fatherId,
        purpose: 'Cough',
      );

      expect(await repository.getEventById(eventId), isNotNull);

      await repository.deleteEvent(eventId);
      expect(await repository.getEventById(eventId), isNull);
    });
  });
}
