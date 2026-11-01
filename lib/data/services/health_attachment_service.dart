import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

class StoredEvidenceResult {
  final String permanentPath;
  final String originalName;
  final String displayName;
  final String mimeType;
  final String evidenceType; // PHOTO, PDF, SCAN

  const StoredEvidenceResult({
    required this.permanentPath,
    required this.originalName,
    required this.displayName,
    required this.mimeType,
    required this.evidenceType,
  });
}

class HealthAttachmentService {
  static Future<Directory> _getAttachmentDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final healthDir = Directory(p.join(docsDir.path, 'health_attachments'));
    if (!await healthDir.exists()) {
      await healthDir.create(recursive: true);
    }
    return healthDir;
  }

  /// Sanitizes text for safe filename generation
  static String _sanitizeForFilename(String input) {
    return input
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .trim();
  }

  /// Generates a human-readable display name matching user requirement:
  /// e.g. "Prescription_Father_Cold-Fever_04-Sep-2026.jpg" or "CBC_Father_04-Sep-2026.pdf"
  static String generateDisplayName({
    required String eventCategoryOrType,
    required String patientName,
    required String purposeOrReport,
    required DateTime eventDate,
    required String fileExtension,
  }) {
    final dateStr = DateFormat('dd-MMM-yyyy').format(eventDate);
    final cleanCategory = _sanitizeForFilename(eventCategoryOrType);
    final cleanPatient = _sanitizeForFilename(patientName);
    final cleanPurpose = _sanitizeForFilename(purposeOrReport);

    final ext = fileExtension.startsWith('.') ? fileExtension : '.$fileExtension';

    if (cleanPurpose.isEmpty || cleanPurpose.toLowerCase() == cleanCategory.toLowerCase()) {
      return '${cleanCategory}_${cleanPatient}_$dateStr$ext';
    } else {
      return '${cleanCategory}_${cleanPatient}_${cleanPurpose}_$dateStr$ext';
    }
  }

  /// Copies an image or PDF from temporary picker cache into the permanent health directory
  static Future<StoredEvidenceResult> storeEvidenceFile({
    required String sourceFilePath,
    required String eventCategoryOrType,
    required String patientName,
    required String purposeOrReport,
    required DateTime eventDate,
  }) async {
    final sourceFile = File(sourceFilePath);
    if (!await sourceFile.exists()) {
      throw Exception('Source file does not exist: $sourceFilePath');
    }

    final originalName = p.basename(sourceFilePath);
    final ext = p.extension(sourceFilePath).toLowerCase();

    final isPdf = ext == '.pdf';
    final mimeType = isPdf
        ? 'application/pdf'
        : (ext == '.png' ? 'image/png' : 'image/jpeg');
    final evidenceType = isPdf ? 'PDF' : 'PHOTO';

    final displayName = generateDisplayName(
      eventCategoryOrType: eventCategoryOrType,
      patientName: patientName,
      purposeOrReport: purposeOrReport,
      eventDate: eventDate,
      fileExtension: ext.isNotEmpty ? ext : (isPdf ? '.pdf' : '.jpg'),
    );

    final targetDir = await _getAttachmentDirectory();
    final uniqueTimestamp = DateTime.now().millisecondsSinceEpoch;
    final diskFilename = '${uniqueTimestamp}_$displayName';
    final targetPath = p.join(targetDir.path, diskFilename);

    // Copy to permanent app documents
    await sourceFile.copy(targetPath);

    return StoredEvidenceResult(
      permanentPath: targetPath,
      originalName: originalName,
      displayName: displayName,
      mimeType: mimeType,
      evidenceType: evidenceType,
    );
  }

  /// Deletes a stored file if it exists
  static Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
