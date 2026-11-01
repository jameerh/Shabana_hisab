import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:snaphisaab/data/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Health Backup and Durability Restore Gate (ADR-021)', () {
    late Directory testEnvDir;
    late Directory docsDir;
    late Directory attachmentsDir;
    late File dbFile;

    setUp(() async {
      // Create isolated test environment directory
      final systemTemp = Directory.systemTemp;
      testEnvDir = Directory(p.join(systemTemp.path, 'shabana_test_${DateTime.now().microsecondsSinceEpoch}'));
      await testEnvDir.create(recursive: true);

      docsDir = Directory(p.join(testEnvDir.path, 'app_docs'));
      attachmentsDir = Directory(p.join(docsDir.path, 'health_attachments'));
      await attachmentsDir.create(recursive: true);

      // Create a mock SQLite database file with valid header
      dbFile = File(p.join(docsDir.path, 'shabanahisaab.sqlite'));
      final header = utf8.encode('SQLite format 3\x00' + ('\x00' * 500));
      await dbFile.writeAsBytes(header);

      // Create dummy health attachment file
      final dummyPdf = File(p.join(attachmentsDir.path, 'CBC_Father_08-Sep-2026.pdf'));
      await dummyPdf.writeAsString('Mock PDF content for CBC report');
    });

    tearDown(() async {
      if (await testEnvDir.exists()) {
        try {
          await testEnvDir.delete(recursive: true);
        } catch (_) {}
      }
    });

    test('Creates valid ZIP backup with database, attachments, and manifest v2', () async {
      final zipFile = await BackupService.createZipBackup(
        customDocsDir: docsDir,
        customTempDir: testEnvDir,
      );
      expect(await zipFile.exists(), isTrue);

      // Inspect ZIP contents
      final zipBytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      final fileNames = archive.map((f) => f.name).toSet();
      expect(fileNames.contains('database/shabanahisaab.sqlite'), isTrue);
      expect(fileNames.contains('manifest.json'), isTrue);
      expect(fileNames.any((n) => n.contains('CBC_Father_08-Sep-2026.pdf')), isTrue);

      // Verify manifest v2
      final manifestFile = archive.firstWhere((f) => f.name == 'manifest.json');
      final manifest = jsonDecode(utf8.decode(manifestFile.content as List<int>)) as Map<String, dynamic>;
      expect(manifest['formatVersion'], 2);
      expect(manifest['schemaVersion'], 21);
      expect(manifest['attachmentCount'], 1);
      expect(manifest['attachmentBytes'], greaterThan(0));

      await zipFile.delete();
    });

    test('Restores ZIP backup preserving database and physical health attachments', () async {
      final zipFile = await BackupService.createZipBackup(
        customDocsDir: docsDir,
        customTempDir: testEnvDir,
      );

      // Create a new empty target docs directory to simulate restore on a new device
      final restoreTargetDir = Directory(p.join(testEnvDir.path, 'restore_target'));
      await restoreTargetDir.create(recursive: true);

      final success = await BackupService.restoreFromFile(
        zipFile,
        customDocsDir: restoreTargetDir,
        customTempDir: testEnvDir,
      );
      expect(success, isTrue);

      // Verify database restored
      final restoredDb = File(p.join(restoreTargetDir.path, 'shabanahisaab.sqlite'));
      expect(await restoredDb.exists(), isTrue);
      expect(await restoredDb.length(), greaterThan(100));

      // Verify physical attachment restored
      final restoredAttachment = File(p.join(restoreTargetDir.path, 'health_attachments', 'CBC_Father_08-Sep-2026.pdf'));
      expect(await restoredAttachment.exists(), isTrue);
      expect(await restoredAttachment.readAsString(), 'Mock PDF content for CBC report');

      await zipFile.delete();
    });

    test('Rollback safety: Corrupted archive leaves existing database and attachments intact', () async {
      // 1. Initial known good state in docsDir
      final initialDbBytes = await dbFile.readAsBytes();
      final initialPdfContent = await File(p.join(attachmentsDir.path, 'CBC_Father_08-Sep-2026.pdf')).readAsString();

      // 2. Create an invalid ZIP missing manifest or database
      final badArchive = Archive();
      badArchive.addFile(ArchiveFile('corrupt.txt', 7, utf8.encode('invalid')));
      final badZipBytes = ZipEncoder().encode(badArchive)!;
      final badZipFile = File(p.join(testEnvDir.path, 'bad_backup.zip'));
      await badZipFile.writeAsBytes(badZipBytes);

      // 3. Attempt restore into docsDir
      final result = await BackupService.restoreFromFile(
        badZipFile,
        customDocsDir: docsDir,
        customTempDir: testEnvDir,
      );
      expect(result, isFalse, reason: 'Corrupt archive restore must fail');

      // 4. Assert original database and attachments were 100% restored via rollback
      expect(await dbFile.exists(), isTrue);
      expect(await dbFile.readAsBytes(), equals(initialDbBytes));

      final checkPdf = File(p.join(attachmentsDir.path, 'CBC_Father_08-Sep-2026.pdf'));
      expect(await checkPdf.exists(), isTrue);
      expect(await checkPdf.readAsString(), equals(initialPdfContent));
    });

    test('Legacy compatibility: Supports restoring older raw .sqlite backup files', () async {
      final legacySqlite = File(p.join(testEnvDir.path, 'legacy_backup.sqlite'));
      final legacyContent = utf8.encode('SQLite format 3\x00' + ('\x42' * 500));
      await legacySqlite.writeAsBytes(legacyContent);

      final legacyTargetDir = Directory(p.join(testEnvDir.path, 'legacy_target'));
      await legacyTargetDir.create(recursive: true);

      final success = await BackupService.restoreFromFile(
        legacySqlite,
        customDocsDir: legacyTargetDir,
        customTempDir: testEnvDir,
      );
      expect(success, isTrue);

      final restored = File(p.join(legacyTargetDir.path, 'shabanahisaab.sqlite'));
      expect(await restored.exists(), isTrue);
      expect(await restored.readAsBytes(), equals(legacyContent));
    });
  });
}
