import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/data/models/gadi_models.dart';
import 'package:snaphisaab/data/repositories/gadi_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late GadiRepository repository;
  late int profileId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = GadiRepository(db);

    profileId = await db.into(db.profiles).insert(
      ProfilesCompanion.insert(
        name: 'Compliance Test Profile',
        type: ProfileType.PERSONAL,
      ),
    );
  });

  tearDown(() async {
    repository.dispose();
    await db.close();
  });

  group('Gadi Hisaab - Compliance & Due Engine Tests', () {
    test('1. Adding vehicle auto-synchronizes PUC, Insurance and Service dues', () async {
      final now = DateTime.now();
      final pucDate = now.add(const Duration(days: 30));
      final insDate = now.add(const Duration(days: 60));

      final vehicleId = await repository.addVehicle(GadiVehicle(
        id: 0,
        profileId: profileId,
        name: 'Royal Enfield Classic 350',
        vehicleType: GadiVehicleType.bike,
        registrationNumber: 'MH-12-RE-3500',
        fuelType: GadiFuelType.petrol,
        currentOdometer: 5000.0,
        pucExpiryDate: pucDate,
        insuranceExpiryDate: insDate,
        serviceDueKm: 6000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final dues = await repository.getDues(profileId, vehicleId: vehicleId);
      expect(dues.length, 3);
      expect(dues.any((d) => d.dueType == GadiDueType.puc), isTrue);
      expect(dues.any((d) => d.dueType == GadiDueType.insurance), isTrue);
      expect(dues.any((d) => d.dueType == GadiDueType.serviceKm && d.dueKm == 6000.0), isTrue);
    });

    test('2. Overdue and Due Soon status detection', () async {
      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(days: 5));
      final soonDate = now.add(const Duration(days: 3));

      final overdueDue = GadiDue(
        id: 1,
        profileId: profileId,
        vehicleId: 1,
        dueType: GadiDueType.puc,
        title: 'Expired PUC',
        dueDate: pastDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(overdueDue.isOverdue(null), isTrue);

      final soonDue = GadiDue(
        id: 2,
        profileId: profileId,
        vehicleId: 1,
        dueType: GadiDueType.insurance,
        title: 'Insurance expiring soon',
        dueDate: soonDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(soonDue.isOverdue(null), isFalse);
      expect(soonDue.isDueSoon(daysThreshold: 7), isTrue);
      expect(soonDue.isDueSoon(daysThreshold: 1), isFalse);

      // KM-based Service Due Soon
      final kmDue = GadiDue(
        id: 3,
        profileId: profileId,
        vehicleId: 1,
        dueType: GadiDueType.serviceKm,
        title: 'Service at 10,000 km',
        dueKm: 10000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(kmDue.isOverdue(9800.0), isFalse);
      expect(kmDue.isDueSoon(daysThreshold: 10, currentVehicleOdometer: 9850.0, kmThreshold: 200.0), isTrue);
      expect(kmDue.isOverdue(10050.0), isTrue);
    });

    test('3. Marking due as completed updates status and snoozing sets snooze date', () async {
      final vId = await repository.addVehicle(GadiVehicle(
        id: 0,
        profileId: profileId,
        name: 'Scooter',
        vehicleType: GadiVehicleType.bike,
        registrationNumber: 'MH-14-ZZ-0001',
        fuelType: GadiFuelType.petrol,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final dueId = await repository.addDue(GadiDue(
        id: 0,
        profileId: profileId,
        vehicleId: vId,
        dueType: GadiDueType.roadTax,
        title: 'Road Tax Payment',
        dueDate: DateTime(2026, 9, 20),
        amount: 2500.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // Mark completed
      await repository.markDueCompleted(dueId);
      var dues = await repository.getDues(profileId, vehicleId: vId, includeCompleted: false);
      expect(dues.isEmpty, isTrue);

      dues = await repository.getDues(profileId, vehicleId: vId, includeCompleted: true);
      expect(dues.first.status, GadiDueStatus.completed);

      // Snooze another due
      final due2Id = await repository.addDue(GadiDue(
        id: 0,
        profileId: profileId,
        vehicleId: vId,
        dueType: GadiDueType.serviceDate,
        title: 'Oil Change',
        dueDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final snoozeTarget = DateTime.now().add(const Duration(days: 7));
      await repository.snoozeDue(due2Id, snoozeTarget);

      final duesWithSnooze = await repository.getDues(profileId, vehicleId: vId);
      final snoozed = duesWithSnooze.firstWhere((d) => d.id == due2Id);
      expect(snoozed.status, GadiDueStatus.snoozed);
      expect(snoozed.snoozedUntil, isNotNull);
    });
  });
}
