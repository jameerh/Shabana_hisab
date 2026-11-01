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
        name: 'Test Family',
        type: ProfileType.PERSONAL,
      ),
    );
  });

  tearDown(() async {
    repository.dispose();
    await db.close();
  });

  group('Gadi Hisaab - Database & CRUD Tests', () {
    test('1. Vehicle creation and retrieval with custom fields', () async {
      final vehicle = GadiVehicle(
        id: 0,
        profileId: profileId,
        name: 'Hero Splendor Plus',
        vehicleType: GadiVehicleType.bike,
        registrationNumber: 'MH-12-AB-1234',
        fuelType: GadiFuelType.petrol,
        initialOdometer: 15000.0,
        currentOdometer: 15000.0,
        purchaseDate: DateTime(2022, 1, 15),
        purchasePrice: 75000.0,
        defaultReimbursementRate: 4.5,
        pucExpiryDate: DateTime(2026, 12, 31),
        insuranceExpiryDate: DateTime(2026, 11, 30),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final vehicleId = await repository.addVehicle(vehicle);
      expect(vehicleId, greaterThan(0));

      final fetched = await repository.getVehicleById(vehicleId);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Hero Splendor Plus');
      expect(fetched.vehicleType, GadiVehicleType.bike);
      expect(fetched.registrationNumber, 'MH-12-AB-1234');
      expect(fetched.currentOdometer, 15000.0);
      expect(fetched.defaultReimbursementRate, 4.5);
    });

    test('2. Multi-vehicle management and filtering by profile', () async {
      await repository.addVehicle(GadiVehicle(
        id: 0,
        profileId: profileId,
        name: 'Activa 6G',
        vehicleType: GadiVehicleType.bike,
        registrationNumber: 'MH-12-CD-5678',
        fuelType: GadiFuelType.petrol,
        currentOdometer: 8500.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await repository.addVehicle(GadiVehicle(
        id: 0,
        profileId: profileId,
        name: 'Maruti Swift',
        vehicleType: GadiVehicleType.car,
        registrationNumber: 'MH-12-EF-9012',
        fuelType: GadiFuelType.diesel,
        currentOdometer: 45000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final vehicles = await repository.getVehicles(profileId);
      expect(vehicles.length, 2);
      expect(vehicles.any((v) => v.name == 'Activa 6G'), isTrue);
      expect(vehicles.any((v) => v.name == 'Maruti Swift'), isTrue);
    });

    test('3. Event creation with typed JSON payload and query by type', () async {
      final vId = await repository.addVehicle(GadiVehicle(
        id: 0,
        profileId: profileId,
        name: 'Honda City',
        vehicleType: GadiVehicleType.car,
        registrationNumber: 'MH-14-GH-3456',
        fuelType: GadiFuelType.petrol,
        currentOdometer: 30000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final fuelPayload = FuelPayload(
        quantity: 35.5,
        ratePerUnit: 104.5,
        isFullTank: true,
        fuelStationName: 'HPCL Hinjewadi',
        fuelType: 'petrol',
      );

      final event = GadiEvent(
        id: 0,
        profileId: profileId,
        vehicleId: vId,
        eventType: GadiEventType.fuel,
        title: 'Full Tank Petrol',
        eventDate: DateTime(2026, 9, 10),
        eventTime: '10:30',
        odometerKm: 30450.0,
        amount: 3709.75,
        payloadJson: '{"quantity":35.5,"rate_per_unit":104.5,"is_full_tank":true,"fuel_station_name":"HPCL Hinjewadi"}',
        notes: 'Paid via GPay',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final eventId = await repository.addEvent(event);
      expect(eventId, greaterThan(0));

      final fetched = await repository.getEventById(eventId);
      expect(fetched, isNotNull);
      expect(fetched!.amount, 3709.75);
      expect(fetched.fuelPayload, isNotNull);
      expect(fetched.fuelPayload!.quantity, 35.5);
      expect(fetched.fuelPayload!.isFullTank, isTrue);
      expect(fetched.notes, 'Paid via GPay');

      // Verify that vehicle current odometer auto-advanced
      final vehicle = await repository.getVehicleById(vId);
      expect(vehicle!.currentOdometer, 30450.0);
    });

    test('4. Evidence attachment to event and cascade deletion', () async {
      final vId = await repository.addVehicle(GadiVehicle(
        id: 0,
        profileId: profileId,
        name: 'Hyundai Creta',
        vehicleType: GadiVehicleType.car,
        registrationNumber: 'MH-12-XY-9999',
        fuelType: GadiFuelType.petrol,
        currentOdometer: 10000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final evId = await repository.addEvent(GadiEvent(
        id: 0,
        profileId: profileId,
        vehicleId: vId,
        eventType: GadiEventType.repair,
        title: 'Brake Pad Replacement',
        eventDate: DateTime.now(),
        eventTime: '15:00',
        amount: 3200.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final evidenceId = await repository.attachEvidence(
        evId,
        GadiEvidence(
          id: 0,
          eventId: evId,
          filePath: '/app/docs/gadi_attachments/receipt.jpg',
          originalName: 'receipt.jpg',
          displayName: 'GarageBill_MH12XY9999_SaiService.jpg',
          mimeType: 'image/jpeg',
          evidenceType: 'BILL_RECEIPT',
          createdAt: DateTime.now(),
        ),
      );
      expect(evidenceId, greaterThan(0));

      final eventWithEv = await repository.getEventById(evId);
      expect(eventWithEv!.evidence.length, 1);
      expect(eventWithEv.evidence.first.displayName, 'GarageBill_MH12XY9999_SaiService.jpg');
      expect(eventWithEv.evidenceStatus, 'ATTACHED');

      // Delete vehicle and ensure cascade delete clears events and evidence
      await repository.deleteVehicle(vId);
      final remainingEvents = await repository.getEvents(profileId, vehicleId: vId);
      expect(remainingEvents.isEmpty, isTrue);
    });
  });
}
