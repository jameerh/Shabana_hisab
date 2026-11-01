import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:snaphisaab/data/models/gadi_models.dart';
import 'package:snaphisaab/data/services/gadi_attachment_service.dart';
import 'package:snaphisaab/data/services/backup_service.dart';
import 'package:drift/native.dart';
import 'package:snaphisaab/data/database/database.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempTestDir;
  late Directory mockDocsDir;
  late Directory mockTempDir;
  late AppDatabase db;

  setUp(() async {
    tempTestDir = await Directory.systemTemp.createTemp('gadi_backup_test_');
    mockDocsDir = Directory(p.join(tempTestDir.path, 'docs'))..createSync(recursive: true);
    mockTempDir = Directory(p.join(tempTestDir.path, 'temp'))..createSync(recursive: true);

    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    if (await tempTestDir.exists()) {
      await tempTestDir.delete(recursive: true);
    }
  });

  group('Gadi Hisaab - Attachment & Backup Tests', () {
    test('1. Human-readable evidence file name generation', () {
      final name1 = GadiAttachmentService.generateDisplayName(
        evidenceTypeOrTitle: 'PetrolPumpMeter',
        registrationNumber: 'MH-12-AB-1234',
        eventDate: DateTime(2026, 9, 10),
        fileExtension: '.jpg',
      );
      expect(name1, contains('PetrolPumpMeter_MH-12-AB-1234_10-Sep-2026.jpg'));

      final name2 = GadiAttachmentService.generateDisplayName(
        evidenceTypeOrTitle: 'GarageBill',
        registrationNumber: 'MH-12-AB-1234',
        remarkOrVendor: 'Sai Service',
        eventDate: DateTime(2026, 9, 10),
        fileExtension: '.pdf',
      );
      expect(name2, contains('GarageBill_MH-12-AB-1234_Sai-Service_10-Sep-2026.pdf'));
    });

    test('2. Backup includes gadi_attachments folder and restore unpacks it successfully', () async {
      // 1. Create a dummy sqlite file
      final dbFile = File(p.join(mockDocsDir.path, 'shabanahisaab.sqlite'));
      await dbFile.writeAsString('SQLite format 3 dummy header content with sufficient padding to simulate a valid file - additional padding for 100 bytes check');

      // 2. Create dummy gadi attachment
      final gadiDir = Directory(p.join(mockDocsDir.path, 'gadi_attachments'))..createSync(recursive: true);
      final sampleReceipt = File(p.join(gadiDir.path, 'test_meter.jpg'));
      await sampleReceipt.writeAsString('sample-meter-photo-bytes');

      // 3. Create ZIP backup
      final zipBackup = await BackupService.createZipBackup(
        customDocsDir: mockDocsDir,
        customTempDir: mockTempDir,
      );

      expect(await zipBackup.exists(), isTrue);
      expect(await zipBackup.length(), greaterThan(100));

      // 4. Delete the original gadi attachment to test restore
      await sampleReceipt.delete();
      expect(await sampleReceipt.exists(), isFalse);

      // 5. Restore from ZIP backup
      final restoreSuccess = await BackupService.restoreFromFile(
        zipBackup,
        customDocsDir: mockDocsDir,
        customTempDir: mockTempDir,
      );

      expect(restoreSuccess, isTrue);
      // Verify attachment was restored
      expect(await sampleReceipt.exists(), isTrue);
      expect(await sampleReceipt.readAsString(), 'sample-meter-photo-bytes');
    });
  });
}
