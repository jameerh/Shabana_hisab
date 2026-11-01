import 'dart:convert';
import 'package:intl/intl.dart';
import '../../core/utils/date_utils.dart';
export '../../core/utils/date_utils.dart';


/// Event Types supported in Health Hisaab
enum HealthEventType {
  prescription,
  labReport,
  hospitalVisit,
  healthNote,
  sugar,
  bloodPressure,
  weight,
  temperature,
  spo2,
}

extension HealthEventTypeExtension on HealthEventType {
  String get name {
    switch (this) {
      case HealthEventType.prescription:
        return 'prescription';
      case HealthEventType.labReport:
        return 'labReport';
      case HealthEventType.hospitalVisit:
        return 'hospitalVisit';
      case HealthEventType.healthNote:
        return 'healthNote';
      case HealthEventType.sugar:
        return 'sugar';
      case HealthEventType.bloodPressure:
        return 'bloodPressure';
      case HealthEventType.weight:
        return 'weight';
      case HealthEventType.temperature:
        return 'temperature';
      case HealthEventType.spo2:
        return 'spo2';
    }
  }

  String get englishLabel {
    switch (this) {
      case HealthEventType.prescription:
        return 'Prescription';
      case HealthEventType.labReport:
        return 'Lab Report';
      case HealthEventType.hospitalVisit:
        return 'Hospital Visit';
      case HealthEventType.healthNote:
        return 'Health Note';
      case HealthEventType.sugar:
        return 'Blood Sugar';
      case HealthEventType.bloodPressure:
        return 'Blood Pressure';
      case HealthEventType.weight:
        return 'Weight';
      case HealthEventType.temperature:
        return 'Temperature';
      case HealthEventType.spo2:
        return 'SpO2';
    }
  }

  String get marathiLabel {
    switch (this) {
      case HealthEventType.prescription:
        return 'प्रिस्क्रिप्शन';
      case HealthEventType.labReport:
        return 'लॅब रिपोर्ट';
      case HealthEventType.hospitalVisit:
        return 'दवाखाना भेट';
      case HealthEventType.healthNote:
        return 'आरोग्य नोंद';
      case HealthEventType.sugar:
        return 'रक्तातील साखर';
      case HealthEventType.bloodPressure:
        return 'रक्तदाब (BP)';
      case HealthEventType.weight:
        return 'वजन';
      case HealthEventType.temperature:
        return 'तापमान';
      case HealthEventType.spo2:
        return 'ऑक्सिजन (SpO2)';
    }
  }

  String get emoji {
    switch (this) {
      case HealthEventType.prescription:
        return '💊';
      case HealthEventType.labReport:
        return '📄';
      case HealthEventType.hospitalVisit:
        return '🏥';
      case HealthEventType.healthNote:
        return '📝';
      case HealthEventType.sugar:
        return '🩸';
      case HealthEventType.bloodPressure:
        return '❤️';
      case HealthEventType.weight:
        return '⚖️';
      case HealthEventType.temperature:
        return '🌡️';
      case HealthEventType.spo2:
        return '🫁';
    }
  }
}

/// Standardized Lab Report Types
enum LabReportType {
  cbc,
  bloodSugar,
  hba1c,
  lipidProfile,
  dengue,
  malaria,
  hiv,
  liverFunction,
  kidneyFunction,
  thyroid,
  urine,
  ecg,
  xray,
  ctMri,
  other,
}

extension LabReportTypeExtension on LabReportType {
  String get name {
    switch (this) {
      case LabReportType.cbc:
        return 'CBC';
      case LabReportType.bloodSugar:
        return 'Blood Sugar';
      case LabReportType.hba1c:
        return 'HbA1c';
      case LabReportType.lipidProfile:
        return 'Lipid Profile';
      case LabReportType.dengue:
        return 'Dengue';
      case LabReportType.malaria:
        return 'Malaria';
      case LabReportType.hiv:
        return 'HIV';
      case LabReportType.liverFunction:
        return 'Liver Function (LFT)';
      case LabReportType.kidneyFunction:
        return 'Kidney Function (KFT)';
      case LabReportType.thyroid:
        return 'Thyroid';
      case LabReportType.urine:
        return 'Urine Routine';
      case LabReportType.ecg:
        return 'ECG';
      case LabReportType.xray:
        return 'X-Ray';
      case LabReportType.ctMri:
        return 'CT / MRI';
      case LabReportType.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case LabReportType.cbc:
      case LabReportType.bloodSugar:
      case LabReportType.hba1c:
      case LabReportType.lipidProfile:
      case LabReportType.liverFunction:
      case LabReportType.kidneyFunction:
        return '🩸';
      case LabReportType.dengue:
      case LabReportType.malaria:
      case LabReportType.hiv:
        return '🦠';
      case LabReportType.thyroid:
        return '🦋';
      case LabReportType.urine:
        return '🧪';
      case LabReportType.ecg:
        return '❤️';
      case LabReportType.xray:
        return '🫁';
      case LabReportType.ctMri:
        return '🧠';
      case LabReportType.other:
        return '📋';
    }
  }
}

/// Measurement Context for Blood Sugar
enum SugarContext {
  fasting,
  beforeMeal,
  afterMeal,
  random,
}

extension SugarContextExtension on SugarContext {
  String get label {
    switch (this) {
      case SugarContext.fasting:
        return 'Fasting';
      case SugarContext.beforeMeal:
        return 'Before Meal';
      case SugarContext.afterMeal:
        return 'After Meal';
      case SugarContext.random:
        return 'Random';
    }
  }

  String get marathiLabel {
    switch (this) {
      case SugarContext.fasting:
        return 'उपाशीपोटी';
      case SugarContext.beforeMeal:
        return 'जेवणापूर्वी';
      case SugarContext.afterMeal:
        return 'जेवणानंतर';
      case SugarContext.random:
        return 'कधीही (Random)';
    }
  }
}

/// Source of Health Record (Decoupled from Evidence Status)
enum HealthSourceType {
  manual,
  device,
  importSource,
  ocr,
}

/// Evidence status (Never medically verified, only document attached)
enum HealthEvidenceStatus {
  none,
  attached,
}

/// Completion status for "Attach First, Fill Later"
enum HealthCompletionStatus {
  captured,
  partiallyCompleted,
  completed,
}

// ==========================================
// Strongly Typed Payloads
// ==========================================

class SugarData {
  final double value;
  final SugarContext context;
  final String unit;

  const SugarData({
    required this.value,
    required this.context,
    this.unit = 'mg/dL',
  });

  Map<String, dynamic> toMap() => {
        'value': value,
        'context': context.name,
        'unit': unit,
      };

  factory SugarData.fromMap(Map<String, dynamic> map) {
    return SugarData(
      value: (map['value'] as num).toDouble(),
      context: SugarContext.values.firstWhere(
        (c) => c.name == map['context'],
        orElse: () => SugarContext.random,
      ),
      unit: map['unit'] as String? ?? 'mg/dL',
    );
  }
}

class BloodPressureData {
  final int systolic;
  final int diastolic;
  final int? pulse;

  const BloodPressureData({
    required this.systolic,
    required this.diastolic,
    this.pulse,
  });

  Map<String, dynamic> toMap() => {
        'systolic': systolic,
        'diastolic': diastolic,
        if (pulse != null) 'pulse': pulse,
      };

  factory BloodPressureData.fromMap(Map<String, dynamic> map) {
    return BloodPressureData(
      systolic: (map['systolic'] as num).toInt(),
      diastolic: (map['diastolic'] as num).toInt(),
      pulse: map['pulse'] != null ? (map['pulse'] as num).toInt() : null,
    );
  }

  String get summary => '$systolic / $diastolic mmHg${pulse != null ? ' • $pulse bpm' : ''}';
}

class WeightData {
  final double value;
  final String unit;

  const WeightData({required this.value, this.unit = 'kg'});

  Map<String, dynamic> toMap() => {'value': value, 'unit': unit};

  factory WeightData.fromMap(Map<String, dynamic> map) => WeightData(
        value: (map['value'] as num).toDouble(),
        unit: map['unit'] as String? ?? 'kg',
      );
}

class TemperatureData {
  final double value;
  final String unit;

  const TemperatureData({required this.value, this.unit = '°F'});

  Map<String, dynamic> toMap() => {'value': value, 'unit': unit};

  factory TemperatureData.fromMap(Map<String, dynamic> map) => TemperatureData(
        value: (map['value'] as num).toDouble(),
        unit: map['unit'] as String? ?? '°F',
      );
}

class SpO2Data {
  final double value;
  final String unit;

  const SpO2Data({required this.value, this.unit = '%'});

  Map<String, dynamic> toMap() => {'value': value, 'unit': unit};

  factory SpO2Data.fromMap(Map<String, dynamic> map) => SpO2Data(
        value: (map['value'] as num).toDouble(),
        unit: map['unit'] as String? ?? '%',
      );
}

class PrescriptionData {
  final String purpose;
  final String? doctorName;
  final String? clinic;
  final String? instructions;
  final List<String> medicines;

  const PrescriptionData({
    required this.purpose,
    this.doctorName,
    this.clinic,
    this.instructions,
    this.medicines = const [],
  });

  Map<String, dynamic> toMap() => {
        'purpose': purpose,
        if (doctorName != null) 'doctorName': doctorName,
        if (clinic != null) 'clinic': clinic,
        if (instructions != null) 'instructions': instructions,
        'medicines': medicines,
      };

  factory PrescriptionData.fromMap(Map<String, dynamic> map) {
    return PrescriptionData(
      purpose: map['purpose'] as String? ?? '',
      doctorName: map['doctorName'] as String?,
      clinic: map['clinic'] as String?,
      instructions: map['instructions'] as String?,
      medicines: (map['medicines'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

class LabReportData {
  final String reportType;
  final String? customReportName;
  final String? resultSummary;
  final Map<String, String> extractedParameters;

  const LabReportData({
    required this.reportType,
    this.customReportName,
    this.resultSummary,
    this.extractedParameters = const {},
  });

  Map<String, dynamic> toMap() => {
        'reportType': reportType,
        if (customReportName != null) 'customReportName': customReportName,
        if (resultSummary != null) 'resultSummary': resultSummary,
        'extractedParameters': extractedParameters,
      };

  factory LabReportData.fromMap(Map<String, dynamic> map) {
    return LabReportData(
      reportType: map['reportType'] as String? ?? 'CBC',
      customReportName: map['customReportName'] as String?,
      resultSummary: map['resultSummary'] as String?,
      extractedParameters: (map['extractedParameters'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ) ??
          const {},
    );
  }
}

// ==========================================
// Core Entities
// ==========================================

class HealthPatient {
  final int id;
  final int profileId;
  final String name;
  final String? relationship;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HealthPatient({
    required this.id,
    required this.profileId,
    required this.name,
    this.relationship,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    required this.createdAt,
    required this.updatedAt,
  });

  int? get ageInYears {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month || (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age >= 0 ? age : null;
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'profile_id': profileId,
        'name': name,
        'relationship': relationship,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'gender': gender,
        'blood_group': bloodGroup,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory HealthPatient.fromMap(Map<String, dynamic> map) {
    return HealthPatient(
      id: (map['id'] as num).toInt(),
      profileId: (map['profile_id'] as num).toInt(),
      name: map['name'] as String,
      relationship: map['relationship'] as String?,
      dateOfBirth: map['date_of_birth'] != null && (map['date_of_birth'] as String).isNotEmpty
          ? parseDateOnly(map['date_of_birth'])
          : null,
      gender: map['gender'] as String?,
      bloodGroup: map['blood_group'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  HealthPatient copyWith({
    String? name,
    String? relationship,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodGroup,
  }) {
    return HealthPatient(
      id: id,
      profileId: profileId,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class HealthEvidence {
  final int id;
  final int eventId;
  final String filePath;
  final String originalName;
  final String displayName;
  final String mimeType;
  final String evidenceType; // PHOTO, PDF, SCAN
  final DateTime createdAt;

  const HealthEvidence({
    required this.id,
    required this.eventId,
    required this.filePath,
    required this.originalName,
    required this.displayName,
    required this.mimeType,
    required this.evidenceType,
    required this.createdAt,
  });

  bool get isPdf => mimeType.contains('pdf') || filePath.toLowerCase().endsWith('.pdf');
  bool get isImage => !isPdf;

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'event_id': eventId,
        'file_path': filePath,
        'original_name': originalName,
        'display_name': displayName,
        'mime_type': mimeType,
        'evidence_type': evidenceType,
        'created_at': createdAt.toIso8601String(),
      };

  factory HealthEvidence.fromMap(Map<String, dynamic> map) {
    return HealthEvidence(
      id: (map['id'] as num).toInt(),
      eventId: (map['event_id'] as num).toInt(),
      filePath: map['file_path'] as String,
      originalName: map['original_name'] as String,
      displayName: map['display_name'] as String,
      mimeType: map['mime_type'] as String,
      evidenceType: map['evidence_type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class HealthEvent {
  final int id;
  final int profileId;
  final int patientId; // Authoritative reference! No duplicate patient name.
  final HealthEventType eventType;
  final String? reportType;
  final String purpose;
  final DateTime eventDate; // Actual date event occurred
  final String eventTime;
  final HealthCompletionStatus completionStatus;
  final HealthSourceType sourceType;
  final HealthEvidenceStatus evidenceStatus;
  final String? payloadJson;
  final String? notes;
  final DateTime createdAt; // When saved in the app
  final DateTime updatedAt;

  // Resolved list of attached evidence files
  final List<HealthEvidence> evidence;

  const HealthEvent({
    required this.id,
    required this.profileId,
    required this.patientId,
    required this.eventType,
    this.reportType,
    required this.purpose,
    required this.eventDate,
    required this.eventTime,
    this.completionStatus = HealthCompletionStatus.captured,
    this.sourceType = HealthSourceType.manual,
    this.evidenceStatus = HealthEvidenceStatus.none,
    this.payloadJson,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.evidence = const [],
  });

  bool get hasEvidence => evidenceStatus == HealthEvidenceStatus.attached || evidence.isNotEmpty;

  // Strongly typed payload accessors
  SugarData? get sugarData {
    if (payloadJson == null) return null;
    try {
      return SugarData.fromMap(jsonDecode(payloadJson!));
    } catch (_) {
      return null;
    }
  }

  BloodPressureData? get bpData {
    if (payloadJson == null) return null;
    try {
      return BloodPressureData.fromMap(jsonDecode(payloadJson!));
    } catch (_) {
      return null;
    }
  }

  WeightData? get weightData {
    if (payloadJson == null) return null;
    try {
      return WeightData.fromMap(jsonDecode(payloadJson!));
    } catch (_) {
      return null;
    }
  }

  TemperatureData? get temperatureData {
    if (payloadJson == null) return null;
    try {
      return TemperatureData.fromMap(jsonDecode(payloadJson!));
    } catch (_) {
      return null;
    }
  }

  SpO2Data? get spo2Data {
    if (payloadJson == null) return null;
    try {
      return SpO2Data.fromMap(jsonDecode(payloadJson!));
    } catch (_) {
      return null;
    }
  }

  PrescriptionData? get prescriptionData {
    if (payloadJson == null) return null;
    try {
      return PrescriptionData.fromMap(jsonDecode(payloadJson!));
    } catch (_) {
      return null;
    }
  }

  LabReportData? get labReportData {
    if (payloadJson == null) return null;
    try {
      return LabReportData.fromMap(jsonDecode(payloadJson!));
    } catch (_) {
      return null;
    }
  }

  String get formattedDate => DateFormat('dd MMM yyyy').format(eventDate);

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'profile_id': profileId,
        'patient_id': patientId,
        'event_type': eventType.name,
        'report_type': reportType,
        'purpose': purpose,
        'event_date': DateFormat('yyyy-MM-dd').format(DateTime(eventDate.year, eventDate.month, eventDate.day)),
        'event_time': eventTime,
        'completion_status': completionStatus.name,
        'source_type': sourceType.name,
        'evidence_status': evidenceStatus.name,
        'payload_json': payloadJson,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory HealthEvent.fromMap(Map<String, dynamic> map, {List<HealthEvidence> evidence = const []}) {
    return HealthEvent(
      id: (map['id'] as num).toInt(),
      profileId: (map['profile_id'] as num).toInt(),
      patientId: (map['patient_id'] as num).toInt(),
      eventType: HealthEventType.values.firstWhere(
        (t) => t.name == map['event_type'],
        orElse: () => HealthEventType.prescription,
      ),
      reportType: map['report_type'] as String?,
      purpose: map['purpose'] as String? ?? '',
      eventDate: parseDateOnly(map['event_date']),
      eventTime: map['event_time'] as String? ?? '12:00 PM',
      completionStatus: HealthCompletionStatus.values.firstWhere(
        (s) => s.name == map['completion_status'],
        orElse: () => HealthCompletionStatus.captured,
      ),
      sourceType: HealthSourceType.values.firstWhere(
        (s) => s.name == map['source_type'],
        orElse: () => HealthSourceType.manual,
      ),
      evidenceStatus: HealthEvidenceStatus.values.firstWhere(
        (e) => e.name == map['evidence_status'],
        orElse: () => HealthEvidenceStatus.none,
      ),
      payloadJson: map['payload_json'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      evidence: evidence,
    );
  }

  HealthEvent copyWith({
    int? patientId,
    HealthEventType? eventType,
    String? reportType,
    String? purpose,
    DateTime? eventDate,
    String? eventTime,
    HealthCompletionStatus? completionStatus,
    HealthSourceType? sourceType,
    HealthEvidenceStatus? evidenceStatus,
    String? payloadJson,
    String? notes,
    List<HealthEvidence>? evidence,
    DateTime? updatedAt,
  }) {
    return HealthEvent(
      id: id,
      profileId: profileId,
      patientId: patientId ?? this.patientId,
      eventType: eventType ?? this.eventType,
      reportType: reportType ?? this.reportType,
      purpose: purpose ?? this.purpose,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      completionStatus: completionStatus ?? this.completionStatus,
      sourceType: sourceType ?? this.sourceType,
      evidenceStatus: evidenceStatus ?? this.evidenceStatus,
      payloadJson: payloadJson ?? this.payloadJson,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      evidence: evidence ?? this.evidence,
    );
  }
}
