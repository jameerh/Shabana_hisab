import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:snaphisaab/data/models/gadi_models.dart';
import 'package:snaphisaab/data/services/gadi_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testVehicle = GadiVehicle(
    id: 1,
    profileId: 1,
    name: 'Honda Activa 6G',
    vehicleType: GadiVehicleType.bike,
    registrationNumber: 'MH-12-PQ-4444',
    fuelType: GadiFuelType.petrol,
    initialOdometer: 5000.0,
    currentOdometer: 8500.0,
    insurancePolicyNumber: 'BAJAJ-ALLIANZ-889922',
    insuranceExpiryDate: DateTime(2026, 12, 31),
    pucExpiryDate: DateTime(2026, 10, 15),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('Gadi Hisaab - PDF Dossier Tests', () {
    test('1. Service Ledger PDF generates valid non-empty file', () async {
      final events = [
        GadiEvent(
          id: 1,
          profileId: 1,
          vehicleId: 1,
          eventType: GadiEventType.service,
          title: '3rd Free Service',
          eventDate: DateTime(2026, 8, 15),
          eventTime: '10:00',
          odometerKm: 6000.0,
          amount: 850.0,
          payloadJson: '{"service_center_name":"Pashankar Honda","engine_oil_replaced":true,"oil_grade":"10W-30","replaced_parts_list":["Engine Oil","Air Filter"]}',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final file = await GadiPdfService.generateServiceLedgerPdf(
        vehicle: testVehicle,
        serviceEvents: events,
        outputDir: Directory.systemTemp,
        regularFontOverride: pw.Font.helvetica(),
        boldFontOverride: pw.Font.helveticaBold(),
      );

      expect(await file.exists(), isTrue);
      expect(await file.length(), greaterThan(1000));
    });

    test('2. Reimbursement PDF generates valid file with trip rows', () async {
      final trips = [
        GadiTrip(
          id: 1,
          profileId: 1,
          vehicleId: 1,
          tripType: GadiTripType.clientVisit,
          startDateTime: DateTime(2026, 9, 1),
          endDateTime: DateTime(2026, 9, 1),
          startOdometer: 8000.0,
          endOdometer: 8050.0,
          distanceKm: 50.0,
          startLocation: 'Camp',
          endLocation: 'Koregaon Park',
          purpose: 'Client audit',
          reimbursementRatePerKm: 5.0,
          reimbursementAmount: 250.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final file = await GadiPdfService.generateReimbursementPdf(
        vehicle: testVehicle,
        trips: trips,
        expenses: [],
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 10),
        outputDir: Directory.systemTemp,
        regularFontOverride: pw.Font.helvetica(),
        boldFontOverride: pw.Font.helveticaBold(),
      );

      expect(await file.exists(), isTrue);
      expect(await file.length(), greaterThan(1000));
    });

    test('3. Insurance Claim Dossier PDF generates valid file', () async {
      final claimEvent = GadiEvent(
        id: 1,
        profileId: 1,
        vehicleId: 1,
        eventType: GadiEventType.accident,
        title: 'Front Fender Dent and Mirror Breakage',
        eventDate: DateTime(2026, 9, 5),
        eventTime: '16:45',
        odometerKm: 8200.0,
        amount: 3500.0,
        payloadJson: '{"accident_location":"Swargate Chowk","claim_number":"CLM-2026-991","surveyor_name":"R. K. Sharma","estimated_loss_amount":5000.0,"approved_amount":4200.0,"out_of_pocket_amount":800.0,"claim_status":"SETTLED"}',
        notes: 'Claim settled within 4 days',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final file = await GadiPdfService.generateInsuranceClaimPdf(
        vehicle: testVehicle,
        claimEvent: claimEvent,
        outputDir: Directory.systemTemp,
        regularFontOverride: pw.Font.helvetica(),
        boldFontOverride: pw.Font.helveticaBold(),
      );

      expect(await file.exists(), isTrue);
      expect(await file.length(), greaterThan(1000));
    });
  });
}
