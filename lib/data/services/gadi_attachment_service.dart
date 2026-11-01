import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

class StoredGadiEvidenceResult {
  final String permanentPath;
  final String originalName;
  final String displayName;
  final String mimeType;
  final String evidenceType;

  const StoredGadiEvidenceResult({
    required this.permanentPath,
    required this.originalName,
    required this.displayName,
    required this.mimeType,
    required this.evidenceType,
  });
}

class GadiAttachmentService {
  static Future<Directory> getAttachmentDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final gadiDir = Directory(p.join(docsDir.path, 'gadi_attachments'));
    if (!await gadiDir.exists()) {
      await gadiDir.create(recursive: true);
    }
    return gadiDir;
  }

  static String _sanitizeForFilename(String input) {
    return input
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .trim();
  }

  /// Generates a human-readable display name:
  /// e.g. "PetrolPumpMeter_MH12AB1234_10-Sep-2026.jpg" or "GarageBill_MH12AB1234_SaiService_10-Sep-2026.pdf"
  static String generateDisplayName({
    required String evidenceTypeOrTitle,
    required String registrationNumber,
    String? remarkOrVendor,
    required DateTime eventDate,
    required String fileExtension,
  }) {
    final dateStr = DateFormat('dd-MMM-yyyy').format(eventDate);
    final cleanType = _sanitizeForFilename(evidenceTypeOrTitle);
    final cleanReg = _sanitizeForFilename(registrationNumber);
    final cleanRemark = remarkOrVendor != null ? _sanitizeForFilename(remarkOrVendor) : '';

    final ext = fileExtension.startsWith('.') ? fileExtension : '.$fileExtension';

    if (cleanRemark.isEmpty || cleanRemark.toLowerCase() == cleanType.toLowerCase()) {
      return '${cleanType}_${cleanReg}_$dateStr$ext';
    } else {
      return '${cleanType}_${cleanReg}_${cleanRemark}_$dateStr$ext';
    }
  }

  /// Stores an image or document in the permanent gadi_attachments folder
  static Future<StoredGadiEvidenceResult> storeEvidenceFile({
    required String sourceFilePath,
    required String evidenceTypeOrTitle,
    required String registrationNumber,
    String? remarkOrVendor,
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

    String evidenceType = 'OTHER';
    final typeLower = evidenceTypeOrTitle.toLowerCase();
    if (typeLower.contains('petrol') || typeLower.contains('fuel') || typeLower.contains('meter')) {
      evidenceType = 'PETROL_METER';
    } else if (typeLower.contains('bill') || typeLower.contains('receipt') || typeLower.contains('gpay')) {
      evidenceType = 'BILL_RECEIPT';
    } else if (typeLower.contains('claim') || typeLower.contains('insurance')) {
      evidenceType = 'CLAIM_DOC';
    } else if (typeLower.contains('fir') || typeLower.contains('police')) {
      evidenceType = 'POLICE_FIR';
    } else if (typeLower.contains('rc') || typeLower.contains('puc')) {
      evidenceType = 'RC_BOOK';
    } else if (typeLower.contains('problem') || typeLower.contains('damage')) {
      evidenceType = 'PROBLEM_PHOTO';
    }

    final displayName = generateDisplayName(
      evidenceTypeOrTitle: evidenceTypeOrTitle,
      registrationNumber: registrationNumber,
      remarkOrVendor: remarkOrVendor,
      eventDate: eventDate,
      fileExtension: ext.isNotEmpty ? ext : (isPdf ? '.pdf' : '.jpg'),
    );

    final targetDir = await getAttachmentDirectory();
    final uniqueTimestamp = DateTime.now().millisecondsSinceEpoch;
    final diskFilename = '${uniqueTimestamp}_$displayName';
    final targetPath = p.join(targetDir.path, diskFilename);

    await sourceFile.copy(targetPath);

    return StoredGadiEvidenceResult(
      permanentPath: targetPath,
      originalName: originalName,
      displayName: displayName,
      mimeType: mimeType,
      evidenceType: evidenceType,
    );
  }

  /// Deletes a file from the disk
  static Future<void> deleteEvidenceFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
