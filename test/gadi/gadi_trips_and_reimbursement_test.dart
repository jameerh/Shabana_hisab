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
        name: 'Merchant User',
        type: ProfileType.SHOP,
      ),
    );

    vehicleId = await repository.addVehicle(GadiVehicle(
      id: 0,
      profileId: profileId,
      name: 'Maruti WagonR',
      vehicleType: GadiVehicleType.car,
      registrationNumber: 'MH-12-TR-7777',
      fuelType: GadiFuelType.cng,
      initialOdometer: 50000.0,
      currentOdometer: 50000.0,
      defaultReimbursementRate: 8.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });

  tearDown(() async {
    repository.dispose();
    await db.close();
  });

  group('Gadi Hisaab - Trips & Reimbursement Ledger Tests', () {
    test('1. Logging business journey computes distance and reimbursement amount', () async {
      final trip = GadiTrip(
        id: 0,
        profileId: profileId,
        vehicleId: vehicleId,
        tripType: GadiTripType.clientVisit,
        startDateTime: DateTime(2026, 9, 10, 9, 0),
        endDateTime: DateTime(2026, 9, 10, 12, 30),
        startOdometer: 50000.0,
        endOdometer: 50125.0,
        distanceKm: 125.0,
        startLocation: 'Kothrud, Pune',
        endLocation: 'Chakan MIDC',
        purpose: 'Factory spare parts delivery & client meeting',
        reimbursementRatePerKm: 8.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final tripId = await repository.addTrip(trip);
      expect(tripId, greaterThan(0));

      final trips = await repository.getTrips(profileId, vehicleId: vehicleId);
      expect(trips.length, 1);
      final saved = trips.first;
      expect(saved.isBusiness, isTrue);
      expect(saved.distanceKm, 125.0);
      expect(saved.computedReimbursement, 1000.0); // 125 * 8.0 = 1000.0
      expect(saved.isReimbursed, isFalse);

      // Vehicle current odometer should advance to 50,125 km
      final v = await repository.getVehicleById(vehicleId);
      expect(v!.currentOdometer, 50125.0);
    });

    test('2. Distinction between business and personal trips in analytics', () async {
      // Trip 1: Business (100 KM @ ₹8/KM = ₹800)
      await repository.addTrip(GadiTrip(
        id: 0,
        profileId: profileId,
        vehicleId: vehicleId,
        tripType: GadiTripType.business,
        startDateTime: DateTime(2026, 9, 2),
        startOdometer: 50000.0,
        endOdometer: 50100.0,
        distanceKm: 100.0,
        reimbursementRatePerKm: 8.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // Trip 2: Personal (50 KM)
      await repository.addTrip(GadiTrip(
        id: 0,
        profileId: profileId,
        vehicleId: vehicleId,
        tripType: GadiTripType.personal,
        startDateTime: DateTime(2026, 9, 4),
        startOdometer: 50100.0,
        endOdometer: 50150.0,
        distanceKm: 50.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final analytics = await repository.getVehicleAnalytics(vehicleId);
      expect(analytics.businessTripKm, 100.0);
      expect(analytics.totalReimbursementEarned, 800.0);
      expect(analytics.pendingReimbursement, 800.0);
    });

    test('3. Mark trip as reimbursed updates status', () async {
      final tripId = await repository.addTrip(GadiTrip(
        id: 0,
        profileId: profileId,
        vehicleId: vehicleId,
        tripType: GadiTripType.office,
        startDateTime: DateTime.now(),
        startOdometer: 50000.0,
        endOdometer: 50030.0,
        distanceKm: 30.0,
        reimbursementRatePerKm: 7.5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await repository.markTripReimbursed(tripId, true);
      final trips = await repository.getTrips(profileId);
      expect(trips.first.isReimbursed, isTrue);

      final analytics = await repository.getVehicleAnalytics(vehicleId);
      expect(analytics.pendingReimbursement, 0.0);
      expect(analytics.totalReimbursementEarned, 225.0); // 30 * 7.5 = 225
    });
  });
}
