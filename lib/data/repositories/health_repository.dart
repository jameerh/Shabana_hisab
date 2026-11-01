import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import '../models/health_models.dart';
import '../services/health_attachment_service.dart';

class HealthRepository {
  final AppDatabase _database;

  // Broadcast streams to ensure responsive UI updates
  final StreamController<void> _eventChangeNotifier = StreamController<void>.broadcast();
  final StreamController<void> _patientChangeNotifier = StreamController<void>.broadcast();

  HealthRepository(this._database);

  void _notifyChanges() {
    if (!_eventChangeNotifier.isClosed) _eventChangeNotifier.add(null);
    if (!_patientChangeNotifier.isClosed) _patientChangeNotifier.add(null);
  }

  // ==========================================
  // PATIENT MANAGEMENT
  // ==========================================

  /// Watches all patients for a profile, auto-seeding only "Me" (Self) if completely empty
  Stream<List<HealthPatient>> watchPatients(int profileId) async* {
    yield await getPatients(profileId);
    await for (final _ in _patientChangeNotifier.stream) {
      yield await getPatients(profileId);
    }
  }

  /// Fetches patients for a profile. Seeds cautious default ("Me") on first launch
  Future<List<HealthPatient>> getPatients(int profileId) async {
    final rows = await _database.customSelect(
      'SELECT * FROM health_patients WHERE profile_id = ? ORDER BY id ASC',
      variables: [Variable.withInt(profileId)],
    ).get();

    if (rows.isEmpty) {
      // Cautious seeding: Only seed "Me" (Self)
      await addPatient(
        profileId: profileId,
        name: 'Me',
        relationship: 'Self',
      );
      final refreshed = await _database.customSelect(
        'SELECT * FROM health_patients WHERE profile_id = ? ORDER BY id ASC',
        variables: [Variable.withInt(profileId)],
      ).get();
      return refreshed.map((r) => HealthPatient.fromMap(r.data)).toList();
    }

    return rows.map((r) => HealthPatient.fromMap(r.data)).toList();
  }

  Future<HealthPatient?> getPatientById(int patientId) async {
    final rows = await _database.customSelect(
      'SELECT * FROM health_patients WHERE id = ?',
      variables: [Variable.withInt(patientId)],
    ).get();
    if (rows.isEmpty) return null;
    return HealthPatient.fromMap(rows.first.data);
  }

  Future<int> addPatient({
    required int profileId,
    required String name,
    String? relationship,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodGroup,
  }) async {
    final now = DateTime.now().toIso8601String();
    final result = await _database.customInsert(
      '''
      INSERT INTO health_patients (profile_id, name, relationship, date_of_birth, gender, blood_group, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withInt(profileId),
        Variable.withString(name.trim()),
        Variable.withString(relationship ?? 'Family'),
        Variable.withString(dateOfBirth?.toIso8601String() ?? ''),
        Variable.withString(gender ?? ''),
        Variable.withString(bloodGroup ?? ''),
        Variable.withString(now),
        Variable.withString(now),
      ],
    );
    _notifyChanges();
    return result;
  }

  Future<void> updatePatient(HealthPatient patient) async {
    final now = DateTime.now().toIso8601String();
    await _database.customStatement(
      '''
      UPDATE health_patients
      SET name = ?, relationship = ?, date_of_birth = ?, gender = ?, blood_group = ?, updated_at = ?
      WHERE id = ?
      ''',
      [
        patient.name.trim(),
        patient.relationship ?? 'Family',
        patient.dateOfBirth?.toIso8601String() ?? '',
        patient.gender ?? '',
        patient.bloodGroup ?? '',
        now,
        patient.id,
      ],
    );
    _notifyChanges();
  }

  Future<void> deletePatient(int patientId) async {
    // Delete events first
    final events = await _database.customSelect(
      'SELECT id FROM health_events WHERE patient_id = ?',
      variables: [Variable.withInt(patientId)],
    ).get();
    for (final e in events) {
      await deleteEvent((e.data['id'] as num).toInt());
    }

    await _database.customStatement(
      'DELETE FROM health_patients WHERE id = ?',
      [patientId],
    );
    _notifyChanges();
  }

  // ==========================================
  // EVENT & EVIDENCE MANAGEMENT
  // ==========================================

  /// Watches events with optional filters (patient, eventType, date range)
  Stream<List<HealthEvent>> watchEvents(
    int profileId, {
    int? patientId,
    HealthEventType? eventType,
    DateTime? startDate,
    DateTime? endDate,
  }) async* {
    yield await getEvents(
      profileId,
      patientId: patientId,
      eventType: eventType,
      startDate: startDate,
      endDate: endDate,
    );
    await for (final _ in _eventChangeNotifier.stream) {
      yield await getEvents(
        profileId,
        patientId: patientId,
        eventType: eventType,
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  Future<List<HealthEvent>> getEvents(
    int profileId, {
    int? patientId,
    HealthEventType? eventType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final whereClauses = <String>['profile_id = ?'];
    final variables = <Variable>[Variable.withInt(profileId)];

    if (patientId != null) {
      whereClauses.add('patient_id = ?');
      variables.add(Variable.withInt(patientId));
    }
    if (eventType != null) {
      whereClauses.add('event_type = ?');
      variables.add(Variable.withString(eventType.name));
    }
    if (startDate != null) {
      final cStart = parseDateOnly(startDate);
      whereClauses.add('event_date >= ?');
      variables.add(Variable.withString(DateFormat('yyyy-MM-dd').format(cStart)));
    }
    if (endDate != null) {
      final cEnd = parseDateOnly(endDate);
      whereClauses.add('event_date <= ?');
      variables.add(Variable.withString(DateFormat('yyyy-MM-dd').format(cEnd)));
    }

    final query = '''
      SELECT * FROM health_events
      WHERE ${whereClauses.join(' AND ')}
      ORDER BY event_date DESC, id DESC
    ''';

    final rows = await _database.customSelect(query, variables: variables).get();
    if (rows.isEmpty) return [];

    final eventIds = rows.map((r) => (r.data['id'] as num).toInt()).toList();

    // Batch fetch evidence in chunks (SQLite limit is 999 variables per query, chunk by 500)
    // Eliminates N+1 queries: 500 events now require exactly 2 queries instead of 501.
    final evidenceMap = <int, List<HealthEvidence>>{};
    for (int i = 0; i < eventIds.length; i += 500) {
      final chunk = eventIds.sublist(i, (i + 500 < eventIds.length) ? i + 500 : eventIds.length);
      final placeholders = List.filled(chunk.length, '?').join(',');
      final evidenceRows = await _database.customSelect(
        'SELECT * FROM health_evidence WHERE event_id IN ($placeholders) ORDER BY id ASC',
        variables: chunk.map((id) => Variable.withInt(id)).toList(),
      ).get();
      for (final er in evidenceRows) {
        final ev = HealthEvidence.fromMap(er.data);
        evidenceMap.putIfAbsent(ev.eventId, () => []).add(ev);
      }
    }

    final events = <HealthEvent>[];
    for (final r in rows) {
      final eventId = (r.data['id'] as num).toInt();
      final evidenceList = evidenceMap[eventId] ?? const [];
      events.add(HealthEvent.fromMap(r.data, evidence: evidenceList));
    }

    return events;
  }

  Future<HealthEvent?> getEventById(int eventId) async {
    final rows = await _database.customSelect(
      'SELECT * FROM health_events WHERE id = ?',
      variables: [Variable.withInt(eventId)],
    ).get();
    if (rows.isEmpty) return null;

    final evidenceRows = await _database.customSelect(
      'SELECT * FROM health_evidence WHERE event_id = ? ORDER BY id ASC',
      variables: [Variable.withInt(eventId)],
    ).get();
    final evidenceList = evidenceRows.map((er) => HealthEvidence.fromMap(er.data)).toList();

    return HealthEvent.fromMap(rows.first.data, evidence: evidenceList);
  }

  /// Fetches all events logged on a specific calendar date (strictly date-only comparison)
  Future<List<HealthEvent>> getEventsByDate(
    int profileId,
    DateTime date, {
    int? patientId,
    HealthEventType? eventType,
  }) async {
    final canonicalDate = parseDateOnly(date);
    return getEvents(
      profileId,
      patientId: patientId,
      eventType: eventType,
      startDate: canonicalDate,
      endDate: canonicalDate,
    );
  }

  /// Watches all events logged on a specific calendar date
  Stream<List<HealthEvent>> watchEventsByDate(
    int profileId,
    DateTime date, {
    int? patientId,
    HealthEventType? eventType,
  }) async* {
    final canonicalDate = parseDateOnly(date);
    yield await getEventsByDate(profileId, canonicalDate, patientId: patientId, eventType: eventType);
    await for (final _ in _eventChangeNotifier.stream) {
      yield await getEventsByDate(profileId, canonicalDate, patientId: patientId, eventType: eventType);
    }
  }

  /// Watches all evidence attachments across a profile
  Stream<List<HealthEvidence>> watchAllEvidence(int profileId, {int? patientId}) async* {
    yield await getAllEvidence(profileId, patientId: patientId);
    await for (final _ in _eventChangeNotifier.stream) {
      yield await getAllEvidence(profileId, patientId: patientId);
    }
  }

  Future<List<HealthEvidence>> getAllEvidence(int profileId, {int? patientId}) async {
    String query;
    List<Variable> variables;

    if (patientId != null) {
      query = '''
        SELECT e.* FROM health_evidence e
        INNER JOIN health_events ev ON e.event_id = ev.id
        WHERE ev.profile_id = ? AND ev.patient_id = ?
        ORDER BY e.id DESC
      ''';
      variables = [Variable.withInt(profileId), Variable.withInt(patientId)];
    } else {
      query = '''
        SELECT e.* FROM health_evidence e
        INNER JOIN health_events ev ON e.event_id = ev.id
        WHERE ev.profile_id = ?
        ORDER BY e.id DESC
      ''';
      variables = [Variable.withInt(profileId)];
    }

    final rows = await _database.customSelect(query, variables: variables).get();
    return rows.map((r) => HealthEvidence.fromMap(r.data)).toList();
  }

  // ==========================================
  // QUICK CAPTURE CREATION (LAZY USER FLOW)
  // ==========================================

  /// Quick Capture: Prescription (Patient + Purpose + Photo/PDF)
  Future<int> addQuickPrescription({
    required int profileId,
    required int patientId,
    required String purpose,
    DateTime? eventDate,
    String? eventTime,
    List<String> filePaths = const [],
    String? notes,
  }) async {
    final patient = await getPatientById(patientId);
    final patientName = patient?.name ?? 'Patient';

    final effectiveDate = parseDateOnly(eventDate ?? DateTime.now());
    final effectiveTime = eventTime ?? DateFormat('hh:mm a').format(DateTime.now());
    final hasFiles = filePaths.isNotEmpty;

    final prescriptionData = PrescriptionData(purpose: purpose);
    final payloadJson = jsonEncode(prescriptionData.toMap());

    final eventId = await _insertEventRecord(
      profileId: profileId,
      patientId: patientId,
      eventType: HealthEventType.prescription,
      reportType: null,
      purpose: purpose,
      eventDate: effectiveDate,
      eventTime: effectiveTime,
      completionStatus: HealthCompletionStatus.captured,
      sourceType: HealthSourceType.manual,
      evidenceStatus: hasFiles ? HealthEvidenceStatus.attached : HealthEvidenceStatus.none,
      payloadJson: payloadJson,
      notes: notes,
    );

    // Save evidence attachments with human-readable labels
    for (final path in filePaths) {
      await _attachFileToEvent(
        eventId: eventId,
        sourceFilePath: path,
        category: 'Prescription',
        patientName: patientName,
        purposeOrReport: purpose,
        eventDate: effectiveDate,
      );
    }

    _notifyChanges();
    return eventId;
  }

  /// Quick Capture: Lab Report (Patient + ReportType + Photo/PDF + Optional Result)
  Future<int> addQuickLabReport({
    required int profileId,
    required int patientId,
    required LabReportType reportType,
    String? customReportName,
    String? resultSummary,
    DateTime? eventDate,
    String? eventTime,
    List<String> filePaths = const [],
    String? notes,
  }) async {
    final patient = await getPatientById(patientId);
    final patientName = patient?.name ?? 'Patient';

    final effectiveDate = parseDateOnly(eventDate ?? DateTime.now());
    final effectiveTime = eventTime ?? DateFormat('hh:mm a').format(DateTime.now());
    final hasFiles = filePaths.isNotEmpty;

    final reportName = customReportName?.trim().isNotEmpty == true
        ? customReportName!.trim()
        : reportType.name;

    final labData = LabReportData(
      reportType: reportType.name,
      customReportName: customReportName,
      resultSummary: resultSummary,
    );
    final payloadJson = jsonEncode(labData.toMap());

    final eventId = await _insertEventRecord(
      profileId: profileId,
      patientId: patientId,
      eventType: HealthEventType.labReport,
      reportType: reportType.name,
      purpose: reportName,
      eventDate: effectiveDate,
      eventTime: effectiveTime,
      completionStatus: HealthCompletionStatus.captured,
      sourceType: HealthSourceType.manual,
      evidenceStatus: hasFiles ? HealthEvidenceStatus.attached : HealthEvidenceStatus.none,
      payloadJson: payloadJson,
      notes: notes,
    );

    // Save evidence attachments with human-readable labels: e.g. CBC_Father_04-Sep-2026.pdf
    for (final path in filePaths) {
      await _attachFileToEvent(
        eventId: eventId,
        sourceFilePath: path,
        category: reportName,
        patientName: patientName,
        purposeOrReport: 'Report',
        eventDate: effectiveDate,
      );
    }

    _notifyChanges();
    return eventId;
  }

  /// Quick Capture: Generic Document (Hospital Paper, Doctor's Advice, Health Note)
  Future<int> addQuickDocument({
    required int profileId,
    required int patientId,
    required HealthEventType eventType,
    required String purpose,
    DateTime? eventDate,
    String? eventTime,
    List<String> filePaths = const [],
    String? notes,
  }) async {
    final patient = await getPatientById(patientId);
    final patientName = patient?.name ?? 'Patient';

    final effectiveDate = parseDateOnly(eventDate ?? DateTime.now());
    final effectiveTime = eventTime ?? DateFormat('hh:mm a').format(DateTime.now());
    final hasFiles = filePaths.isNotEmpty;

    final eventId = await _insertEventRecord(
      profileId: profileId,
      patientId: patientId,
      eventType: eventType,
      reportType: null,
      purpose: purpose,
      eventDate: effectiveDate,
      eventTime: effectiveTime,
      completionStatus: HealthCompletionStatus.captured,
      sourceType: HealthSourceType.manual,
      evidenceStatus: hasFiles ? HealthEvidenceStatus.attached : HealthEvidenceStatus.none,
      payloadJson: null,
      notes: notes,
    );

    for (final path in filePaths) {
      await _attachFileToEvent(
        eventId: eventId,
        sourceFilePath: path,
        category: eventType.name,
        patientName: patientName,
        purposeOrReport: purpose,
        eventDate: effectiveDate,
      );
    }

    _notifyChanges();
    return eventId;
  }

  // ==========================================
  // DETAILED ENTRY (STRUCTURED TRACKING)
  // ==========================================

  /// Detailed Entry: Blood Sugar (Value, Unit, Context, Date/Time, optional photo)
  Future<int> addDetailedSugar({
    required int profileId,
    required int patientId,
    required double reading,
    required SugarContext context,
    String unit = 'mg/dL',
    DateTime? eventDate,
    String? eventTime,
    List<String> filePaths = const [],
    String? notes,
  }) async {
    final patient = await getPatientById(patientId);
    final patientName = patient?.name ?? 'Patient';

    final effectiveDate = parseDateOnly(eventDate ?? DateTime.now());
    final effectiveTime = eventTime ?? DateFormat('hh:mm a').format(DateTime.now());
    final hasFiles = filePaths.isNotEmpty;

    final sugarData = SugarData(value: reading, context: context, unit: unit);
    final payloadJson = jsonEncode(sugarData.toMap());

    final purpose = 'Sugar (${context.label})';

    final eventId = await _insertEventRecord(
      profileId: profileId,
      patientId: patientId,
      eventType: HealthEventType.sugar,
      reportType: null,
      purpose: purpose,
      eventDate: effectiveDate,
      eventTime: effectiveTime,
      completionStatus: HealthCompletionStatus.completed,
      sourceType: HealthSourceType.manual,
      evidenceStatus: hasFiles ? HealthEvidenceStatus.attached : HealthEvidenceStatus.none,
      payloadJson: payloadJson,
      notes: notes,
    );

    for (final path in filePaths) {
      await _attachFileToEvent(
        eventId: eventId,
        sourceFilePath: path,
        category: 'Sugar',
        patientName: patientName,
        purposeOrReport: context.label,
        eventDate: effectiveDate,
      );
    }

    _notifyChanges();
    return eventId;
  }

  /// Detailed Entry: Blood Pressure (Systolic, Diastolic, Pulse, Date/Time, optional photo)
  Future<int> addDetailedBloodPressure({
    required int profileId,
    required int patientId,
    required int systolic,
    required int diastolic,
    int? pulse,
    DateTime? eventDate,
    String? eventTime,
    List<String> filePaths = const [],
    String? notes,
  }) async {
    final patient = await getPatientById(patientId);
    final patientName = patient?.name ?? 'Patient';

    final effectiveDate = parseDateOnly(eventDate ?? DateTime.now());
    final effectiveTime = eventTime ?? DateFormat('hh:mm a').format(DateTime.now());
    final hasFiles = filePaths.isNotEmpty;

    final bpData = BloodPressureData(systolic: systolic, diastolic: diastolic, pulse: pulse);
    final payloadJson = jsonEncode(bpData.toMap());

    final purpose = 'BP ($systolic/$diastolic)';

    final eventId = await _insertEventRecord(
      profileId: profileId,
      patientId: patientId,
      eventType: HealthEventType.bloodPressure,
      reportType: null,
      purpose: purpose,
      eventDate: effectiveDate,
      eventTime: effectiveTime,
      completionStatus: HealthCompletionStatus.completed,
      sourceType: HealthSourceType.manual,
      evidenceStatus: hasFiles ? HealthEvidenceStatus.attached : HealthEvidenceStatus.none,
      payloadJson: payloadJson,
      notes: notes,
    );

    for (final path in filePaths) {
      await _attachFileToEvent(
        eventId: eventId,
        sourceFilePath: path,
        category: 'BP',
        patientName: patientName,
        purposeOrReport: '$systolic-$diastolic',
        eventDate: effectiveDate,
      );
    }

    _notifyChanges();
    return eventId;
  }

  /// Detailed Entry: Other Vitals (Weight, Temperature, SpO2)
  Future<int> addDetailedVital({
    required int profileId,
    required int patientId,
    required HealthEventType eventType,
    required double value,
    required String unit,
    DateTime? eventDate,
    String? eventTime,
    List<String> filePaths = const [],
    String? notes,
  }) async {
    final patient = await getPatientById(patientId);
    final patientName = patient?.name ?? 'Patient';

    final effectiveDate = parseDateOnly(eventDate ?? DateTime.now());
    final effectiveTime = eventTime ?? DateFormat('hh:mm a').format(DateTime.now());
    final hasFiles = filePaths.isNotEmpty;

    String payloadJson = '';
    String purpose = '';

    switch (eventType) {
      case HealthEventType.weight:
        payloadJson = jsonEncode(WeightData(value: value, unit: unit).toMap());
        purpose = 'Weight ($value $unit)';
        break;
      case HealthEventType.temperature:
        payloadJson = jsonEncode(TemperatureData(value: value, unit: unit).toMap());
        purpose = 'Temp ($value $unit)';
        break;
      case HealthEventType.spo2:
        payloadJson = jsonEncode(SpO2Data(value: value, unit: unit).toMap());
        purpose = 'SpO2 ($value $unit)';
        break;
      default:
        purpose = eventType.englishLabel;
    }

    final eventId = await _insertEventRecord(
      profileId: profileId,
      patientId: patientId,
      eventType: eventType,
      reportType: null,
      purpose: purpose,
      eventDate: effectiveDate,
      eventTime: effectiveTime,
      completionStatus: HealthCompletionStatus.completed,
      sourceType: HealthSourceType.manual,
      evidenceStatus: hasFiles ? HealthEvidenceStatus.attached : HealthEvidenceStatus.none,
      payloadJson: payloadJson,
      notes: notes,
    );

    for (final path in filePaths) {
      await _attachFileToEvent(
        eventId: eventId,
        sourceFilePath: path,
        category: eventType.name,
        patientName: patientName,
        purposeOrReport: '$value-$unit',
        eventDate: effectiveDate,
      );
    }

    _notifyChanges();
    return eventId;
  }

  // ==========================================
  // ATTACH FIRST, FILL LATER WORKFLOW
  // ==========================================

  /// Completes details for an existing quick-captured event
  Future<void> completeEventDetails({
    required int eventId,
    required String payloadJson,
    String? notes,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _database.customStatement(
      '''
      UPDATE health_events
      SET payload_json = ?, notes = COALESCE(?, notes), completion_status = ?, updated_at = ?
      WHERE id = ?
      ''',
      [
        payloadJson,
        notes,
        HealthCompletionStatus.completed.name,
        now,
        eventId,
      ],
    );
    _notifyChanges();
  }

  /// Updates an existing Blood Sugar event with strict non-destructive preservation of untouched fields.
  Future<void> updateSugarEvent({
    required int eventId,
    int? patientId,
    required double reading,
    required SugarContext context,
    String unit = 'mg/dL',
    required DateTime eventDate,
    required String eventTime,
    String? notes,
    List<String> newFilePaths = const [],
    List<int> removeEvidenceIds = const [],
  }) async {
    final existing = await getEventById(eventId);
    if (existing == null) throw StateError('Health event #$eventId not found');

    final effectivePatientId = patientId ?? existing.patientId;
    final patient = await getPatientById(effectivePatientId);
    final patientName = patient?.name ?? 'Patient';

    final canonicalDate = parseDateOnly(eventDate);
    final eventDateStr = DateFormat('yyyy-MM-dd').format(canonicalDate);

    // 1. Remove any explicitly deleted evidence files
    for (final evId in removeEvidenceIds) {
      await deleteEvidence(evId);
    }

    // 2. Attach any new evidence files (existing untouched files are preserved)
    for (final path in newFilePaths) {
      await _attachFileToEvent(
        eventId: eventId,
        sourceFilePath: path,
        category: 'Sugar',
        patientName: patientName,
        purposeOrReport: context.label,
        eventDate: canonicalDate,
      );
    }

    // 3. Count remaining evidence
    final evidenceRows = await _database.customSelect(
      'SELECT COUNT(*) as c FROM health_evidence WHERE event_id = ?',
      variables: [Variable.withInt(eventId)],
    ).get();
    final evidenceCount = (evidenceRows.first.data['c'] as num).toInt();
    final hasEvidence = evidenceCount > 0;

    final sugarData = SugarData(value: reading, context: context, unit: unit);
    final payloadJson = jsonEncode(sugarData.toMap());
    final purpose = 'Sugar (${context.label})';
    final now = DateTime.now().toIso8601String();

    await _database.customStatement(
      '''
      UPDATE health_events SET
        patient_id = ?,
        purpose = ?,
        event_date = ?,
        event_time = ?,
        payload_json = ?,
        notes = ?,
        evidence_status = ?,
        updated_at = ?
      WHERE id = ?
      ''',
      [
        effectivePatientId,
        purpose,
        eventDateStr,
        eventTime,
        payloadJson,
        notes ?? existing.notes,
        hasEvidence ? HealthEvidenceStatus.attached.name : HealthEvidenceStatus.none.name,
        now,
        eventId,
      ],
    );
    _notifyChanges();
  }

  /// Updates an existing Blood Pressure event with strict non-destructive preservation of untouched fields.
  Future<void> updateBloodPressureEvent({
    required int eventId,
    int? patientId,
    required int systolic,
    required int diastolic,
    int? pulse,
    required DateTime eventDate,
    required String eventTime,
    String? notes,
    List<String> newFilePaths = const [],
    List<int> removeEvidenceIds = const [],
  }) async {
    final existing = await getEventById(eventId);
    if (existing == null) throw StateError('Health event #$eventId not found');

    final effectivePatientId = patientId ?? existing.patientId;
    final patient = await getPatientById(effectivePatientId);
    final patientName = patient?.name ?? 'Patient';

    final canonicalDate = parseDateOnly(eventDate);
    final eventDateStr = DateFormat('yyyy-MM-dd').format(canonicalDate);

    // 1. Remove explicitly deleted evidence
    for (final evId in removeEvidenceIds) {
      await deleteEvidence(evId);
    }

    // 2. Attach new evidence
    for (final path in newFilePaths) {
      await _attachFileToEvent(
        eventId: eventId,
        sourceFilePath: path,
        category: 'BP',
        patientName: patientName,
        purposeOrReport: '$systolic-$diastolic',
        eventDate: canonicalDate,
      );
    }

    final evidenceRows = await _database.customSelect(
      'SELECT COUNT(*) as c FROM health_evidence WHERE event_id = ?',
      variables: [Variable.withInt(eventId)],
    ).get();
    final evidenceCount = (evidenceRows.first.data['c'] as num).toInt();
    final hasEvidence = evidenceCount > 0;

    final bpData = BloodPressureData(systolic: systolic, diastolic: diastolic, pulse: pulse);
    final payloadJson = jsonEncode(bpData.toMap());
    final purpose = 'BP ($systolic/$diastolic)';
    final now = DateTime.now().toIso8601String();

    await _database.customStatement(
      '''
      UPDATE health_events SET
        patient_id = ?,
        purpose = ?,
        event_date = ?,
        event_time = ?,
        payload_json = ?,
        notes = ?,
        evidence_status = ?,
        updated_at = ?
      WHERE id = ?
      ''',
      [
        effectivePatientId,
        purpose,
        eventDateStr,
        eventTime,
        payloadJson,
        notes ?? existing.notes,
        hasEvidence ? HealthEvidenceStatus.attached.name : HealthEvidenceStatus.none.name,
        now,
        eventId,
      ],
    );
    _notifyChanges();
  }

  /// General update for health events preserving untouched fields.
  Future<void> updateEvent({
    required int eventId,
    int? patientId,
    DateTime? eventDate,
    String? eventTime,
    String? purpose,
    String? payloadJson,
    String? notes,
    HealthCompletionStatus? completionStatus,
    List<String> newFilePaths = const [],
    List<int> removeEvidenceIds = const [],
  }) async {
    final existing = await getEventById(eventId);
    if (existing == null) throw StateError('Health event #$eventId not found');

    final effectivePatientId = patientId ?? existing.patientId;
    final patient = await getPatientById(effectivePatientId);
    final patientName = patient?.name ?? 'Patient';

    final effectiveDate = eventDate != null ? parseDateOnly(eventDate) : existing.eventDate;
    final eventDateStr = DateFormat('yyyy-MM-dd').format(effectiveDate);

    for (final evId in removeEvidenceIds) {
      await deleteEvidence(evId);
    }

    for (final path in newFilePaths) {
      await _attachFileToEvent(
        eventId: eventId,
        sourceFilePath: path,
        category: existing.eventType.name,
        patientName: patientName,
        purposeOrReport: purpose ?? existing.purpose,
        eventDate: effectiveDate,
      );
    }

    final evidenceRows = await _database.customSelect(
      'SELECT COUNT(*) as c FROM health_evidence WHERE event_id = ?',
      variables: [Variable.withInt(eventId)],
    ).get();
    final evidenceCount = (evidenceRows.first.data['c'] as num).toInt();
    final hasEvidence = evidenceCount > 0;

    final now = DateTime.now().toIso8601String();

    await _database.customStatement(
      '''
      UPDATE health_events SET
        patient_id = ?,
        purpose = COALESCE(?, purpose),
        event_date = ?,
        event_time = COALESCE(?, event_time),
        payload_json = COALESCE(?, payload_json),
        notes = COALESCE(?, notes),
        completion_status = COALESCE(?, completion_status),
        evidence_status = ?,
        updated_at = ?
      WHERE id = ?
      ''',
      [
        effectivePatientId,
        purpose,
        eventDateStr,
        eventTime,
        payloadJson,
        notes,
        completionStatus?.name,
        hasEvidence ? HealthEvidenceStatus.attached.name : HealthEvidenceStatus.none.name,
        now,
        eventId,
      ],
    );
    _notifyChanges();
  }

  /// Deletes a specific physical evidence file and its database row.
  Future<void> deleteEvidence(int evidenceId) async {
    final rows = await _database.customSelect(
      'SELECT file_path, event_id FROM health_evidence WHERE id = ?',
      variables: [Variable.withInt(evidenceId)],
    ).get();
    if (rows.isNotEmpty) {
      final path = rows.first.data['file_path'] as String;
      final eventId = (rows.first.data['event_id'] as num).toInt();
      await HealthAttachmentService.deleteFile(path);
      await _database.customStatement(
        'DELETE FROM health_evidence WHERE id = ?',
        [evidenceId],
      );
      final remaining = await _database.customSelect(
        'SELECT COUNT(*) as c FROM health_evidence WHERE event_id = ?',
        variables: [Variable.withInt(eventId)],
      ).get();
      final count = (remaining.first.data['c'] as num).toInt();
      if (count == 0) {
        await _database.customStatement(
          "UPDATE health_events SET evidence_status = 'none' WHERE id = ?",
          [eventId],
        );
      }
      _notifyChanges();
    }
  }

  /// Deletes an event and its attached physical evidence files
  Future<void> deleteEvent(int eventId) async {
    // Delete physical files
    final evidenceRows = await _database.customSelect(
      'SELECT file_path FROM health_evidence WHERE event_id = ?',
      variables: [Variable.withInt(eventId)],
    ).get();
    for (final er in evidenceRows) {
      final path = er.data['file_path'] as String;
      await HealthAttachmentService.deleteFile(path);
    }

    await _database.customStatement(
      'DELETE FROM health_evidence WHERE event_id = ?',
      [eventId],
    );
    await _database.customStatement(
      'DELETE FROM health_events WHERE id = ?',
      [eventId],
    );
    _notifyChanges();
  }

  // ==========================================
  // INTERNAL HELPERS
  // ==========================================

  Future<int> _insertEventRecord({
    required int profileId,
    required int patientId,
    required HealthEventType eventType,
    required String? reportType,
    required String purpose,
    required DateTime eventDate,
    required String eventTime,
    required HealthCompletionStatus completionStatus,
    required HealthSourceType sourceType,
    required HealthEvidenceStatus evidenceStatus,
    required String? payloadJson,
    required String? notes,
  }) async {
    final now = DateTime.now().toIso8601String();
    final canonicalDate = parseDateOnly(eventDate);
    final eventDateStr = DateFormat('yyyy-MM-dd').format(canonicalDate);

    final eventId = await _database.customInsert(
      '''
      INSERT INTO health_events (
        profile_id, patient_id, event_type, report_type, purpose,
        event_date, event_time, completion_status, source_type,
        evidence_status, payload_json, notes, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withInt(profileId),
        Variable.withInt(patientId),
        Variable.withString(eventType.name),
        Variable.withString(reportType ?? ''),
        Variable.withString(purpose),
        Variable.withString(eventDateStr),
        Variable.withString(eventTime),
        Variable.withString(completionStatus.name),
        Variable.withString(sourceType.name),
        Variable.withString(evidenceStatus.name),
        Variable.withString(payloadJson ?? ''),
        Variable.withString(notes ?? ''),
        Variable.withString(now),
        Variable.withString(now),
      ],
    );
    return eventId;
  }

  Future<void> _attachFileToEvent({
    required int eventId,
    required String sourceFilePath,
    required String category,
    required String patientName,
    required String purposeOrReport,
    required DateTime eventDate,
  }) async {
    try {
      final stored = await HealthAttachmentService.storeEvidenceFile(
        sourceFilePath: sourceFilePath,
        eventCategoryOrType: category,
        patientName: patientName,
        purposeOrReport: purposeOrReport,
        eventDate: eventDate,
      );

      final now = DateTime.now().toIso8601String();
      await _database.customInsert(
        '''
        INSERT INTO health_evidence (
          event_id, file_path, original_name, display_name, mime_type, evidence_type, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        ''',
        variables: [
          Variable.withInt(eventId),
          Variable.withString(stored.permanentPath),
          Variable.withString(stored.originalName),
          Variable.withString(stored.displayName),
          Variable.withString(stored.mimeType),
          Variable.withString(stored.evidenceType),
          Variable.withString(now),
        ],
      );
    } catch (e) {
      // If copying fails, fallback gracefully without throwing out whole record
    }
  }

  void dispose() {
    _eventChangeNotifier.close();
    _patientChangeNotifier.close();
  }
}
