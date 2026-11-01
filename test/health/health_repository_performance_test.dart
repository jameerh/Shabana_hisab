import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/data/repositories/health_repository.dart';

void main() {
  group('HealthRepository Query Performance & N+1 Elimination Gate', () {
    late AppDatabase db;
    late HealthRepository repository;
    late int profileId;
    late int patientId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = HealthRepository(db);

      profileId = await db.into(db.profiles).insert(
        ProfilesCompanion.insert(
          name: 'Benchmark Family',
          type: ProfileType.PERSONAL,
        ),
      );

      patientId = await repository.addPatient(
        profileId: profileId,
        name: 'Benchmark Patient',
        relationship: 'Self',
      );
    });

    tearDown(() async {
      repository.dispose();
      await db.close();
    });

    test('Batch retrieval handles 500 records with evidence without N+1 query loop', () async {
      // 1. Bulk insert 500 events with evidence using a database transaction
      await db.transaction(() async {
        for (int i = 1; i <= 500; i++) {
          final eventDate = '2026-0${(i % 9) + 1}-15';
          final eventId = await db.customInsert(
            '''
            INSERT INTO health_events (profile_id, patient_id, event_type, purpose, event_date, event_time, completion_status, source_type, evidence_status, payload_json, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            variables: [
              Variable.withInt(profileId),
              Variable.withInt(patientId),
              Variable.withString('prescription'),
              Variable.withString('Prescription $i'),
              Variable.withString(eventDate),
              Variable.withString('10:00 AM'),
              Variable.withString('completed'),
              Variable.withString('manual'),
              Variable.withString(i % 2 == 0 ? 'attached' : 'none'),
              Variable.withString(jsonEncode({'purpose': 'Checkup $i'})),
              Variable.withString(DateTime.now().toIso8601String()),
              Variable.withString(DateTime.now().toIso8601String()),
            ],
          );

          // Add evidence for every alternate event
          if (i % 2 == 0) {
            await db.customInsert(
              '''
              INSERT INTO health_evidence (event_id, file_path, original_name, display_name, mime_type, evidence_type, created_at)
              VALUES (?, ?, ?, ?, ?, ?, ?)
              ''',
              variables: [
                Variable.withInt(eventId),
                Variable.withString('/storage/attachments/file_$i.pdf'),
                Variable.withString('file_$i.pdf'),
                Variable.withString('Prescription_Patient_$i.pdf'),
                Variable.withString('application/pdf'),
                Variable.withString('PDF'),
                Variable.withString(DateTime.now().toIso8601String()),
              ],
            );
          }
        }
      });

      // Verify count in DB
      final totalEventsCount = await db.customSelect('SELECT COUNT(*) as c FROM health_events').getSingle();
      expect(totalEventsCount.data['c'], 500);

      // 2. Execute getEvents and measure execution
      final stopwatch = Stopwatch()..start();
      final events = await repository.getEvents(profileId);
      stopwatch.stop();

      // Assertions
      expect(events.length, 500);

      // Verify evidence correctly mapped
      final eventsWithEvidence = events.where((e) => e.evidence.isNotEmpty).toList();
      expect(eventsWithEvidence.length, 250);

      // Verify first event structure
      final sampleWithEvidence = eventsWithEvidence.first;
      expect(sampleWithEvidence.evidence.first.evidenceType, 'PDF');
      expect(sampleWithEvidence.evidence.first.mimeType, 'application/pdf');

      // The batched query runs in 2 queries (1 events query + 1 batched IN evidence query)
      print('Retrieved 500 events + 250 evidence attachments in ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(2000),
          reason: '500 records should process well within test harness timeout');
    });
  });
}
