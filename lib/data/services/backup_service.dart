import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';
import '../database/database.dart';

class BackupService {
  static const String _lastBackupKey = 'last_backup_timestamp';
  static const int currentFormatVersion = 2;
  static const int currentSchemaVersion = 21;

  /// Creates a complete ZIP archive backup containing:
  /// 1. database/shabanahisaab.sqlite (after WAL checkpoint)
  /// 2. health_attachments/* (all physical medical files/scans)
  /// 3. manifest.json (formatVersion 2, schemaVersion, attachment metadata)
  ///
  /// Returns the created File for easy programmatic or testing access.
  static Future<File> createZipBackup({
    AppDatabase? db,
    Directory? customDocsDir,
    Directory? customTempDir,
  }) async {
    // 1. Flush WAL to main SQLite file before archiving
    if (db != null) {
      try {
        await db.customStatement('PRAGMA wal_checkpoint(FULL)');
      } catch (e) {
        debugPrint('WAL checkpoint warning: $e');
      }
    }

    final docsDir = customDocsDir ?? await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(docsDir.path, 'shabanahisaab.sqlite'));
    final attachmentsDir = Directory(p.join(docsDir.path, 'health_attachments'));
    final gadiAttachmentsDir = Directory(p.join(docsDir.path, 'gadi_attachments'));

    if (!await dbFile.exists()) {
      throw StateError('Database file not found at ${dbFile.path}');
    }

    final archive = Archive();

    // 2. Add database file to archive
    final dbBytes = await dbFile.readAsBytes();
    archive.addFile(ArchiveFile('database/shabanahisaab.sqlite', dbBytes.length, dbBytes));

    // 3. Add health and gadi attachments if directory exists
    int attachmentCount = 0;
    int attachmentBytes = 0;

    if (await attachmentsDir.exists()) {
      final entities = attachmentsDir.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File) {
          final bytes = await entity.readAsBytes();
          final relativePath = p.relative(entity.path, from: attachmentsDir.path);
          archive.addFile(ArchiveFile('health_attachments/$relativePath', bytes.length, bytes));
          attachmentCount++;
          attachmentBytes += bytes.length;
        }
      }
    }

    if (await gadiAttachmentsDir.exists()) {
      final entities = gadiAttachmentsDir.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File) {
          final bytes = await entity.readAsBytes();
          final relativePath = p.relative(entity.path, from: gadiAttachmentsDir.path);
          archive.addFile(ArchiveFile('gadi_attachments/$relativePath', bytes.length, bytes));
          attachmentCount++;
          attachmentBytes += bytes.length;
        }
      }
    }

    // 4. Create and add manifest v2
    final manifestMap = {
      'formatVersion': currentFormatVersion,
      'appVersion': '1.0.0',
      'schemaVersion': currentSchemaVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'databaseFile': 'database/shabanahisaab.sqlite',
      'attachmentCount': attachmentCount,
      'attachmentBytes': attachmentBytes,
    };
    final manifestBytes = utf8.encode(jsonEncode(manifestMap));
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

    // 5. Encode to ZIP
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);
    if (zipBytes == null) {
      throw StateError('Failed to encode ZIP archive');
    }

    // Write to a temporary file
    final tempDir = customTempDir ?? await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipPath = p.join(tempDir.path, 'shabanahisaab_backup_$timestamp.zip');
    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(zipBytes);

    return zipFile;
  }

  /// Shares the ZIP database backup archive.
  static Future<void> performBackup({AppDatabase? db}) async {
    final zipFile = await createZipBackup(db: db);

    await Share.shareXFiles(
      [XFile(zipFile.path)],
      text: '${AppConfig.appName} Full Backup (v$currentFormatVersion) - ${DateTime.now().toIso8601String()}',
    );

    // Update last backup timestamp
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastBackupKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Restores from a specific file path (supports both .zip format v2 and legacy .sqlite format v1).
  /// Implements full rollback strategy so user is never left with a corrupt or half-restored state.
  static Future<bool> restoreFromFile(
    File backupFile, {
    AppDatabase? db,
    Directory? customDocsDir,
    Directory? customTempDir,
  }) async {
    if (!await backupFile.exists()) {
      debugPrint('Restore failed: Backup file does not exist');
      return false;
    }

    final ext = p.extension(backupFile.path).toLowerCase();
    if (ext == '.sqlite' || ext == '.db') {
      return await _restoreLegacySqlite(backupFile, db: db, customDocsDir: customDocsDir);
    } else {
      return await _restoreZipArchive(backupFile, db: db, customDocsDir: customDocsDir, customTempDir: customTempDir);
    }
  }

  /// Legacy restore path for raw .sqlite files
  static Future<bool> _restoreLegacySqlite(
    File sqliteFile, {
    AppDatabase? db,
    Directory? customDocsDir,
  }) async {
    final docsDir = customDocsDir ?? await getApplicationDocumentsDirectory();
    final targetDbFile = File(p.join(docsDir.path, 'shabanahisaab.sqlite'));
    final safetyCopyDb = File(p.join(docsDir.path, 'shabanahisaab.sqlite.safety_copy'));

    try {
      // Validate legacy file is non-empty
      final length = await sqliteFile.length();
      if (length < 100) {
        throw FormatException('Invalid or empty SQLite file ($length bytes)');
      }

      // Create safety copy of current DB if exists
      if (await targetDbFile.exists()) {
        await targetDbFile.copy(safetyCopyDb.path);
      }

      // Close DB connection if provided
      if (db != null) {
        try {
          await db.close();
        } catch (_) {}
      }

      // Overwrite database
      await sqliteFile.copy(targetDbFile.path);

      // Verify restored file exists and has content
      if (!await targetDbFile.exists() || await targetDbFile.length() == 0) {
        throw StateError('Restored file verification failed');
      }

      // Clean up safety copy on success
      if (await safetyCopyDb.exists()) {
        await safetyCopyDb.delete();
      }

      return true;
    } catch (e) {
      debugPrint('Legacy restore failed, initiating rollback: $e');
      // ROLLBACK
      if (await safetyCopyDb.exists()) {
        await safetyCopyDb.copy(targetDbFile.path);
        await safetyCopyDb.delete();
      }
      return false;
    }
  }

  /// RC2 format v2 restore path with transactional rollback
  static Future<bool> _restoreZipArchive(
    File zipFile, {
    AppDatabase? db,
    Directory? customDocsDir,
    Directory? customTempDir,
  }) async {
    final docsDir = customDocsDir ?? await getApplicationDocumentsDirectory();
    final targetDbFile = File(p.join(docsDir.path, 'shabanahisaab.sqlite'));
    final targetAttachmentsDir = Directory(p.join(docsDir.path, 'health_attachments'));
    final targetGadiAttachmentsDir = Directory(p.join(docsDir.path, 'gadi_attachments'));

    final safetyCopyDb = File(p.join(docsDir.path, 'shabanahisaab.sqlite.safety_copy'));
    final safetyAttachmentsDir = Directory(p.join(docsDir.path, 'health_attachments_safety_copy'));
    final safetyGadiAttachmentsDir = Directory(p.join(docsDir.path, 'gadi_attachments_safety_copy'));

    Directory? tempExtractDir;

    try {
      // 1. Extract to TEMP directory
      final tempBaseDir = customTempDir ?? await getTemporaryDirectory();
      tempExtractDir = Directory(p.join(tempBaseDir.path, 'restore_${DateTime.now().millisecondsSinceEpoch}'));
      await tempExtractDir.create(recursive: true);

      final zipBytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      for (final file in archive) {
        final outPath = p.join(tempExtractDir.path, file.name);
        if (file.isFile) {
          final outFile = File(outPath);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(outPath).create(recursive: true);
        }
      }

      // 2. Validate manifest
      final manifestFile = File(p.join(tempExtractDir.path, 'manifest.json'));
      if (!await manifestFile.exists()) {
        throw const FormatException('Missing manifest.json in backup archive');
      }
      final manifestContent = await manifestFile.readAsString();
      final manifest = jsonDecode(manifestContent) as Map<String, dynamic>;
      final formatVersion = manifest['formatVersion'] as int? ?? 1;
      if (formatVersion > currentFormatVersion) {
        throw FormatException('Unsupported backup format version: $formatVersion (Max supported: $currentFormatVersion)');
      }

      // 3. Validate extracted database file
      final extractedDbFile = File(p.join(tempExtractDir.path, 'database', 'shabanahisaab.sqlite'));
      if (!await extractedDbFile.exists() || await extractedDbFile.length() < 100) {
        throw const FormatException('Database file missing or corrupted inside backup');
      }

      // 4. Create safety copies of current state
      if (await targetDbFile.exists()) {
        await targetDbFile.copy(safetyCopyDb.path);
      }
      if (await targetAttachmentsDir.exists()) {
        if (await safetyAttachmentsDir.exists()) {
          await safetyAttachmentsDir.delete(recursive: true);
        }
        await _copyDirectory(targetAttachmentsDir, safetyAttachmentsDir);
      }
      if (await targetGadiAttachmentsDir.exists()) {
        if (await safetyGadiAttachmentsDir.exists()) {
          await safetyGadiAttachmentsDir.delete(recursive: true);
        }
        await _copyDirectory(targetGadiAttachmentsDir, safetyGadiAttachmentsDir);
      }

      // 5. Close active database if supplied
      if (db != null) {
        try {
          await db.close();
        } catch (_) {}
      }

      // 6. Replace database file
      await extractedDbFile.copy(targetDbFile.path);

      // 7. Restore attachments
      final extractedAttachmentsDir = Directory(p.join(tempExtractDir.path, 'health_attachments'));
      if (await extractedAttachmentsDir.exists()) {
        if (!await targetAttachmentsDir.exists()) {
          await targetAttachmentsDir.create(recursive: true);
        }
        await _copyDirectory(extractedAttachmentsDir, targetAttachmentsDir);
      }

      final extractedGadiAttachmentsDir = Directory(p.join(tempExtractDir.path, 'gadi_attachments'));
      if (await extractedGadiAttachmentsDir.exists()) {
        if (!await targetGadiAttachmentsDir.exists()) {
          await targetGadiAttachmentsDir.create(recursive: true);
        }
        await _copyDirectory(extractedGadiAttachmentsDir, targetGadiAttachmentsDir);
      }

      // 8. Integrity check on restored file
      if (!await targetDbFile.exists() || await targetDbFile.length() == 0) {
        throw StateError('Restored database verification failed');
      }

      // 9. Clean up safety copies and temp files on success
      if (await safetyCopyDb.exists()) {
        await safetyCopyDb.delete();
      }
      if (await safetyAttachmentsDir.exists()) {
        await safetyAttachmentsDir.delete(recursive: true);
      }
      if (await safetyGadiAttachmentsDir.exists()) {
        await safetyGadiAttachmentsDir.delete(recursive: true);
      }
      if (await tempExtractDir.exists()) {
        await tempExtractDir.delete(recursive: true);
      }

      return true;
    } catch (e) {
      debugPrint('ZIP Restore failed, rolling back to previous state: $e');

      // ROLLBACK: Restore previous database
      if (await safetyCopyDb.exists()) {
        try {
          await safetyCopyDb.copy(targetDbFile.path);
          await safetyCopyDb.delete();
        } catch (rbError) {
          debugPrint('Critical error restoring DB during rollback: $rbError');
        }
      }

      // ROLLBACK: Restore previous attachments
      if (await safetyAttachmentsDir.exists()) {
        try {
          if (await targetAttachmentsDir.exists()) {
            await targetAttachmentsDir.delete(recursive: true);
          }
          await _copyDirectory(safetyAttachmentsDir, targetAttachmentsDir);
          await safetyAttachmentsDir.delete(recursive: true);
        } catch (rbError) {
          debugPrint('Critical error restoring attachments during rollback: $rbError');
        }
      }

      if (await safetyGadiAttachmentsDir.exists()) {
        try {
          if (await targetGadiAttachmentsDir.exists()) {
            await targetGadiAttachmentsDir.delete(recursive: true);
          }
          await _copyDirectory(safetyGadiAttachmentsDir, targetGadiAttachmentsDir);
          await safetyGadiAttachmentsDir.delete(recursive: true);
        } catch (rbError) {
          debugPrint('Critical error restoring gadi attachments during rollback: $rbError');
        }
      }

      // Clean up temp extraction
      if (tempExtractDir != null && await tempExtractDir.exists()) {
        await tempExtractDir.delete(recursive: true);
      }

      return false;
    }
  }

  /// Copies all contents from source directory to destination directory
  static Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(recursive: false)) {
      if (entity is Directory) {
        final newDir = Directory(p.join(destination.path, p.basename(entity.path)));
        await _copyDirectory(entity, newDir);
      } else if (entity is File) {
        await entity.copy(p.join(destination.path, p.basename(entity.path)));
      }
    }
  }

  /// Restores the database from a file picked by the user.
  static Future<bool> restoreBackup({AppDatabase? db}) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final backupFile = File(result.files.single.path!);
        return await restoreFromFile(backupFile, db: db);
      }
    } catch (e) {
      debugPrint('Restore picker error: $e');
    }
    return false;
  }

  /// Returns the date of the last backup, or null if never backed up.
  static Future<DateTime?> getLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastBackupKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  /// Returns true if a backup is recommended (e.g. more than 7 days ago).
  static Future<bool> isBackupOverdue() async {
    final lastBackup = await getLastBackupDate();
    if (lastBackup == null) return true; // Never backed up
    
    final difference = DateTime.now().difference(lastBackup);
    return difference.inDays >= 7;
  }
}
