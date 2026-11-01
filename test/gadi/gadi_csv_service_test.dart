import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/data/models/gadi_models.dart';
import 'package:snaphisaab/data/repositories/gadi_repository.dart';
import 'package:snaphisaab/data/services/gadi_csv_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late GadiRepository repository;
  late int profileId;
  late GadiVehicle testVehicle;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = GadiRepository(db);

    profileId = await db.into(db.profiles).insert(
      ProfilesCompanion.insert(
        name: 'CSV Test User',
        type: ProfileType.PERSONAL,
      ),
    );

    testVehicle = GadiVehicle(
      id: 1,
      profileId: profileId,
      name: 'Tata Nexon EV',
      vehicleType: GadiVehicleType.car,
      registrationNumber: 'MH-14-EV-2026',
      fuelType: GadiFuelType.electric,
      initialOdometer: 5000.0,
      currentOdometer: 5000.0,
      defaultReimbursementRate: 9.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repository.addVehicle(testVehicle);
  });

  tearDown(() async {
    repository.dispose();
    await db.close();
  });

  group('Gadi Hisaab - CSV Export & Import Pipeline Tests', () {
    test('1. Export Trips to CSV produces valid formatted rows', () {
      final trips = [
        GadiTrip(
          id: 1,
          profileId: profileId,
          vehicleId: testVehicle.id,
          tripType: GadiTripType.clientVisit,
          startDateTime: DateTime(2026, 9, 10, 10, 0),
          endDateTime: DateTime(2026, 9, 10, 12, 0),
          startOdometer: 5000.0,
          endOdometer: 5080.0,
          distanceKm: 80.0,
          startLocation: 'Bavdhan',
          endLocation: 'Magarpatta',
          purpose: 'Consulting meeting',
          reimbursementRatePerKm: 9.0,
          reimbursementAmount: 720.0,
          isReimbursed: false,
          notes: 'Fastag paid separate',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final csv = GadiCsvService.exportTripsCsv(vehicle: testVehicle, trips: trips);
      expect(csv, contains('Trip ID'));
      expect(csv, contains('Start Date & Time'));
      expect(csv, contains('MH-14-EV-2026'));
      expect(csv, contains('Magarpatta'));
      expect(csv, contains('720'));
    });

    test('2. Export Fuel Logs and Expenses produces comprehensive CSV', () {
      final fuelEvents = [
        GadiEvent(
          id: 1,
          profileId: profileId,
          vehicleId: testVehicle.id,
          eventType: GadiEventType.fuel,
          title: 'Fast Charger 50kW',
          eventDate: DateTime(2026, 9, 8),
          eventTime: '14:30',
          odometerKm: 5200.0,
          amount: 450.0,
          payloadJson: '{"quantity":22.5,"rate_per_unit":20.0,"is_full_tank":true,"fuel_station_name":"Tata Power Fast Charger"}',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final csv = GadiCsvService.exportFuelLogsCsv(vehicle: testVehicle, fuelEvents: fuelEvents);
      expect(csv, contains('Event ID'));
      expect(csv, contains('Date'));
      expect(csv, contains('Tata Power Fast Charger'));
      expect(csv, contains('450'));
    });

    test('3. Historical CSV import creates events and updates odometer', () async {
      const csvInput = '''
Date,Odometer,Liters,Cost,Type,Notes
10/09/2026,5300,15.5,1550,Fuel,Petrol bunk refill
12/09/2026,5500,0,850,Service,Chain lubing and brake check
''';

      final result = await GadiCsvService.importPastHistoryCsv(
        repository: repository,
        vehicle: testVehicle,
        csvContent: csvInput,
      );

      expect(result.importedCount, 2);
      expect(result.failedCount, 0);

      final events = await repository.getEvents(profileId, vehicleId: testVehicle.id);
      expect(events.length, 2);
      expect(events.any((e) => e.eventType == GadiEventType.fuel && e.amount == 1550.0), isTrue);
      expect(events.any((e) => e.eventType == GadiEventType.service && e.amount == 850.0), isTrue);

      // Vehicle odometer should have advanced to latest imported value (5500)
      final v = await repository.getVehicleById(testVehicle.id);
      expect(v!.currentOdometer, 5500.0);
    });
  });
}
