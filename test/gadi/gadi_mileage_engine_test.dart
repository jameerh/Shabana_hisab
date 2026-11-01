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
  late int vehicleId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = GadiRepository(db);

    profileId = await db.into(db.profiles).insert(
      ProfilesCompanion.insert(
        name: 'Mileage Test User',
        type: ProfileType.PERSONAL,
      ),
    );

    vehicleId = await repository.addVehicle(GadiVehicle(
      id: 0,
      profileId: profileId,
      name: 'Hyundai i20',
      vehicleType: GadiVehicleType.car,
      registrationNumber: 'MH-12-JJ-1111',
      fuelType: GadiFuelType.petrol,
      initialOdometer: 10000.0,
      currentOdometer: 10000.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });

  tearDown(() async {
    repository.dispose();
    await db.close();
  });

  group('Gadi Hisaab - Mileage & CPKM Engine Tests', () {
    test('1. Consecutive Full-Tank fills calculate exact KM/L and ₹/KM', () async {
      // 1st Fill: Full Tank at 10,000 km (Anchor)
      await repository.addEvent(GadiEvent(
        id: 0,
        profileId: profileId,
        vehicleId: vehicleId,
        eventType: GadiEventType.fuel,
        title: 'Full Tank Refill 1',
        eventDate: DateTime(2026, 9, 1),
        eventTime: '08:00',
        odometerKm: 10000.0,
        amount: 3500.0,
        payloadJson: '{"quantity":35.0,"rate_per_unit":100.0,"is_full_tank":true}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // 2nd Fill: Full Tank at 10,500 km (Traveled 500 km on 25 Liters)
      // Mileage = 500 km / 25 L = 20.0 KM/L. Cost = 25 * 100 = ₹2500 -> ₹5.00/KM
      await repository.addEvent(GadiEvent(
        id: 0,
        profileId: profileId,
        vehicleId: vehicleId,
        eventType: GadiEventType.fuel,
        title: 'Full Tank Refill 2',
        eventDate: DateTime(2026, 9, 5),
        eventTime: '09:00',
        odometerKm: 10500.0,
        amount: 2500.0,
        payloadJson: '{"quantity":25.0,"rate_per_unit":100.0,"is_full_tank":true}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final result = await repository.calculateVehicleMileage(vehicleId);
      expect(result.intervals.length, 1);
      expect(result.intervals.first.distanceKm, 500.0);
      expect(result.intervals.first.fuelUnits, 25.0);
      expect(result.intervals.first.mileage, 20.0);
      expect(result.intervals.first.costPerKm, 5.0);
      expect(result.averageMileage, 20.0);
      expect(result.latestMileage, 20.0);
    });

    test('2. Multi-stage partial fills accumulate correctly until next full tank', () async {
      // Anchor: Full Tank at 20,000 km
      await repository.addEvent(GadiEvent(
        id: 0,
        profileId: profileId,
        vehicleId: vehicleId,
        eventType: GadiEventType.fuel,
        title: 'Anchor Full Tank',
        eventDate: DateTime(2026, 9, 1),
        eventTime: '08:00',
        odometerKm: 20000.0,
        amount: 4000.0,
        payloadJson: '{"quantity":40.0,"rate_per_unit":100.0,"is_full_tank":true}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // Partial Fill 1: at 20,200 km (10 Liters added, NOT full tank)
      await repository.addEvent(GadiEvent(
        id: 0,
        profileId: profileId,
        vehicleId: vehicleId,
        eventType: GadiEventType.fuel,
        title: 'Partial Refill 1',
        eventDate: DateTime(2026, 9, 3),
        eventTime: '12:00',
        odometerKm: 20200.0,
        amount: 1000.0,
        payloadJson: '{"quantity":10.0,"rate_per_unit":100.0,"is_full_tank":false}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // Partial Fill 2: at 20,400 km (10 Liters added, NOT full tank)
      await repository.addEvent(GadiEvent(
        id: 0,
        profileId: profileId,
        vehicleId: vehicleId,
        eventType: GadiEventType.fuel,
        title: 'Partial Refill 2',
        eventDate: DateTime(2026, 9, 6),
        eventTime: '14:00',
        odometerKm: 20400.0,
        amount: 1000.0,
        payloadJson: '{"quantity":10.0,"rate_per_unit":100.0,"is_full_tank":false}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // Full Tank 3: at 20,600 km (10 Liters added, Full Tank reached!)
      // Total Distance = 20,600 - 20,000 = 600 km
      // Total Fuel consumed across period = 10 + 10 + 10 = 30 Liters
      // Mileage = 600 / 30 = 20.0 KM/L
      await repository.addEvent(GadiEvent(
        id: 0,
        profileId: profileId,
        vehicleId: vehicleId,
        eventType: GadiEventType.fuel,
        title: 'Closing Full Tank',
        eventDate: DateTime(2026, 9, 8),
        eventTime: '18:00',
        odometerKm: 20600.0,
        amount: 1000.0,
        payloadJson: '{"quantity":10.0,"rate_per_unit":100.0,"is_full_tank":true}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final result = await repository.calculateVehicleMileage(vehicleId);
      expect(result.intervals.length, 1);
      expect(result.intervals.first.distanceKm, 600.0);
      expect(result.intervals.first.fuelUnits, 30.0);
      expect(result.intervals.first.mileage, 20.0);
      expect(result.averageMileage, 20.0);
    });

    test('3. Returns empty calculation gracefully when insufficient full fills exist', () async {
      // Only 1 fill
      await repository.addEvent(GadiEvent(
        id: 0,
        profileId: profileId,
        vehicleId: vehicleId,
        eventType: GadiEventType.fuel,
        title: 'Solo Fill',
        eventDate: DateTime.now(),
        eventTime: '08:00',
        odometerKm: 12000.0,
        amount: 2000.0,
        payloadJson: '{"quantity":20.0,"is_full_tank":true}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final result = await repository.calculateVehicleMileage(vehicleId);
      expect(result.intervals.isEmpty, isTrue);
      expect(result.averageMileage, 0.0);
    });
  });
}
