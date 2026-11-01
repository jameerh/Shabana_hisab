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
        name: 'Odometer Test User',
        type: ProfileType.PERSONAL,
      ),
    );

    vehicleId = await repository.addVehicle(GadiVehicle(
      id: 0,
      profileId: profileId,
      name: 'Pulsar 150',
      vehicleType: GadiVehicleType.bike,
      registrationNumber: 'MH-14-BA-4321',
      fuelType: GadiFuelType.petrol,
      initialOdometer: 25000.0,
      currentOdometer: 25000.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });

  tearDown(() async {
    repository.dispose();
    await db.close();
  });

  group('Gadi Hisaab - Odometer Integrity & Audit Tests', () {
    test('1. Monotonic odometer advancement succeeds for valid higher reading', () async {
      await repository.updateVehicleOdometer(vehicleId, 25300.0);
      final v = await repository.getVehicleById(vehicleId);
      expect(v!.currentOdometer, 25300.0);

      final logs = await repository.getOdometerLogs(vehicleId);
      expect(logs.any((l) => l.odometerKm == 25300.0), isTrue);
    });

    test('2. Strict rejection: Decreasing odometer throws ArgumentError without calibration flag', () async {
      await repository.updateVehicleOdometer(vehicleId, 26000.0);

      // Attempting to record 24000 km should throw ArgumentError
      expect(
        () async => await repository.updateVehicleOdometer(vehicleId, 24000.0),
        throwsArgumentError,
      );

      // Verify that odometer was NOT modified
      final v = await repository.getVehicleById(vehicleId);
      expect(v!.currentOdometer, 26000.0);
    });

    test('3. Explicit calibration workflow allows correction with audit remark', () async {
      await repository.updateVehicleOdometer(vehicleId, 30000.0);

      // User replaces meter or corrects typo via explicit calibration
      await repository.calibrateOdometer(
        vehicleId,
        1500.0,
        'Speedometer console replaced under warranty by Bajaj showroom',
      );

      final v = await repository.getVehicleById(vehicleId);
      expect(v!.currentOdometer, 1500.0);

      final logs = await repository.getOdometerLogs(vehicleId);
      final calibrationLog = logs.firstWhere((l) => l.isManualCalibration);
      expect(calibrationLog.odometerKm, 1500.0);
      expect(calibrationLog.calibrationReason, contains('Speedometer console replaced'));
    });

    test('4. Auto-advancement of odometer from Trips and Events', () async {
      // Add trip ending at 25600 km
      await repository.addTrip(GadiTrip(
        id: 0,
        profileId: profileId,
        vehicleId: vehicleId,
        tripType: GadiTripType.personal,
        startDateTime: DateTime.now().subtract(const Duration(hours: 2)),
        endDateTime: DateTime.now(),
        startOdometer: 25000.0,
        endOdometer: 25600.0,
        distanceKm: 600.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      var v = await repository.getVehicleById(vehicleId);
      expect(v!.currentOdometer, 25600.0);

      // Add service event at 26200 km
      await repository.addEvent(GadiEvent(
        id: 0,
        profileId: profileId,
        vehicleId: vehicleId,
        eventType: GadiEventType.service,
        title: 'Paid Periodic Service',
        eventDate: DateTime.now(),
        eventTime: '11:00',
        odometerKm: 26200.0,
        amount: 1450.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      v = await repository.getVehicleById(vehicleId);
      expect(v!.currentOdometer, 26200.0);
    });
  });
}
