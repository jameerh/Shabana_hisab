import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/gadi_models.dart';
import '../repositories/gadi_repository.dart';

class CsvImportResult {
  final int totalRows;
  final int importedCount;
  final int failedCount;
  final List<String> errors;

  const CsvImportResult({
    required this.totalRows,
    required this.importedCount,
    required this.failedCount,
    required this.errors,
  });
}

class GadiCsvService {
  /// Converts a list of values into a valid CSV line
  static String _toCsvRow(List<dynamic> values) {
    return values.map((v) {
      if (v == null) return '""';
      final str = v.toString();
      if (str.contains(',') || str.contains('"') || str.contains('\n')) {
        return '"${str.replaceAll('"', '""')}"';
      }
      return '"$str"';
    }).join(',');
  }

  /// Exports Trips into CSV format
  static String exportTripsCsv({
    required GadiVehicle vehicle,
    required List<GadiTrip> trips,
  }) {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln(_toCsvRow([
      'Trip ID',
      'Start Date & Time',
      'End Date & Time',
      'Vehicle Name',
      'Registration Number',
      'Trip Type',
      'Purpose',
      'From Location',
      'To Location',
      'Start Odometer (KM)',
      'End Odometer (KM)',
      'Distance (KM)',
      'Reimbursement Rate (₹/KM)',
      'Reimbursement Claim (₹)',
      'Status',
      'Notes',
    ]));

    for (final trip in trips) {
      buffer.writeln(_toCsvRow([
        trip.id,
        DateFormat('dd-MMM-yyyy HH:mm').format(trip.startDateTime),
        trip.endDateTime != null ? DateFormat('dd-MMM-yyyy HH:mm').format(trip.endDateTime!) : '',
        vehicle.name,
        vehicle.registrationNumber,
        trip.tripType.englishLabel,
        trip.purpose ?? '',
        trip.startLocation ?? '',
        trip.endLocation ?? '',
        trip.startOdometer,
        trip.endOdometer,
        trip.distanceKm,
        trip.reimbursementRatePerKm ?? 0.0,
        trip.computedReimbursement,
        trip.isReimbursed ? 'Reimbursed' : 'Pending',
        trip.notes ?? '',
      ]));
    }

    return buffer.toString();
  }

  /// Exports Fuel Entries into CSV format
  static String exportFuelLogsCsv({
    required GadiVehicle vehicle,
    required List<GadiEvent> fuelEvents,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(_toCsvRow([
      'Event ID',
      'Date',
      'Time',
      'Vehicle Name',
      'Registration Number',
      'Fuel Type',
      'Quantity (${vehicle.fuelType.unit})',
      'Rate (₹/${vehicle.fuelType.unit})',
      'Total Amount (₹)',
      'Odometer (KM)',
      'Full Tank',
      'Fuel Station',
      'Notes',
    ]));

    for (final ev in fuelEvents) {
      final payload = ev.fuelPayload;
      buffer.writeln(_toCsvRow([
        ev.id,
        formatDateOnly(ev.eventDate),
        ev.eventTime,
        vehicle.name,
        vehicle.registrationNumber,
        payload?.fuelType ?? vehicle.fuelType.englishLabel,
        payload?.quantity ?? 0.0,
        payload?.ratePerUnit ?? 0.0,
        ev.amount,
        ev.odometerKm ?? '',
        (payload?.isFullTank ?? true) ? 'Yes' : 'No',
        payload?.fuelStationName ?? '',
        ev.notes ?? '',
      ]));
    }

    return buffer.toString();
  }

  /// Exports All Vehicle Expenses & Diary entries into CSV format
  static String exportExpensesCsv({
    required GadiVehicle vehicle,
    required List<GadiEvent> events,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(_toCsvRow([
      'Event ID',
      'Date',
      'Time',
      'Vehicle Name',
      'Registration Number',
      'Category',
      'Title',
      'Odometer (KM)',
      'Amount (₹)',
      'Evidence Attached',
      'Source',
      'Remarks',
    ]));

    for (final ev in events) {
      buffer.writeln(_toCsvRow([
        ev.id,
        formatDateOnly(ev.eventDate),
        ev.eventTime,
        vehicle.name,
        vehicle.registrationNumber,
        ev.eventType.englishLabel,
        ev.title,
        ev.odometerKm ?? '',
        ev.amount,
        ev.hasEvidence ? 'Yes' : 'No',
        ev.sourceType,
        ev.notes ?? '',
      ]));
    }

    return buffer.toString();
  }

  /// Imports historical records from a generic or Fuelio CSV file
  static Future<CsvImportResult> importPastHistoryCsv({
    required GadiRepository repository,
    required GadiVehicle vehicle,
    required String csvContent,
  }) async {
    final lines = const LineSplitter().convert(csvContent);
    if (lines.isEmpty) {
      return const CsvImportResult(totalRows: 0, importedCount: 0, failedCount: 0, errors: ['CSV content is empty']);
    }

    int imported = 0;
    int failed = 0;
    final errors = <String>[];

    // Find header indices
    final headerRow = _parseCsvLine(lines.first).map((e) => e.trim().toLowerCase()).toList();

    int dateIdx = headerRow.indexWhere((h) => h.contains('date'));
    int odoIdx = headerRow.indexWhere((h) => h.contains('odo') || h.contains('km') || h.contains('mileage'));
    int amountIdx = headerRow.indexWhere((h) => h.contains('cost') || h.contains('amount') || h.contains('total') || h.contains('price'));
    int qtyIdx = headerRow.indexWhere((h) => h.contains('liter') || h.contains('litre') || h.contains('qty') || h.contains('volume') || h.contains('quantity'));
    int typeIdx = headerRow.indexWhere((h) => h.contains('type') || h.contains('category') || h.contains('event'));
    int notesIdx = headerRow.indexWhere((h) => h.contains('note') || h.contains('remark') || h.contains('comment') || h.contains('description'));

    if (dateIdx == -1 && odoIdx == -1 && amountIdx == -1) {
      return const CsvImportResult(
        totalRows: 0,
        importedCount: 0,
        failedCount: 0,
        errors: ['Could not detect valid CSV headers (missing date, odometer, or amount columns).'],
      );
    }

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final cols = _parseCsvLine(line);
        if (cols.isEmpty) continue;

        DateTime eventDate = DateTime.now();
        if (dateIdx != -1 && dateIdx < cols.length) {
          final rawDate = cols[dateIdx].trim();
          final parsed = _tryParseFlexibleDate(rawDate);
          if (parsed != null) eventDate = parsed;
        }

        double? odometer;
        if (odoIdx != -1 && odoIdx < cols.length) {
          odometer = double.tryParse(cols[odoIdx].replaceAll(RegExp(r'[^0-9.]'), ''));
        }

        double amount = 0.0;
        if (amountIdx != -1 && amountIdx < cols.length) {
          amount = double.tryParse(cols[amountIdx].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        }

        double quantity = 0.0;
        if (qtyIdx != -1 && qtyIdx < cols.length) {
          quantity = double.tryParse(cols[qtyIdx].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        }

        String rawType = '';
        if (typeIdx != -1 && typeIdx < cols.length) {
          rawType = cols[typeIdx].trim().toLowerCase();
        }

        String notes = '';
        if (notesIdx != -1 && notesIdx < cols.length) {
          notes = cols[notesIdx].trim();
        }

        // Determine event type
        GadiEventType eventType = GadiEventType.other;
        if (rawType.contains('fuel') || rawType.contains('petrol') || rawType.contains('diesel') || quantity > 0) {
          eventType = GadiEventType.fuel;
        } else if (rawType.contains('service') || rawType.contains('oil') || rawType.contains('maint')) {
          eventType = GadiEventType.service;
        } else if (rawType.contains('repair') || rawType.contains('garage') || rawType.contains('part')) {
          eventType = GadiEventType.repair;
        } else if (rawType.contains('toll') || rawType.contains('fastag')) {
          eventType = GadiEventType.toll;
        } else if (rawType.contains('challan') || rawType.contains('fine')) {
          eventType = GadiEventType.challan;
        }

        String? payloadJson;
        if (eventType == GadiEventType.fuel) {
          final rate = quantity > 0 && amount > 0 ? (amount / quantity) : 0.0;
          final payload = FuelPayload(
            quantity: quantity,
            ratePerUnit: rate,
            isFullTank: true,
            fuelType: vehicle.fuelType.name,
          );
          payloadJson = jsonEncode(payload.toMap());
        }

        final event = GadiEvent(
          id: 0,
          profileId: vehicle.profileId,
          vehicleId: vehicle.id,
          eventType: eventType,
          title: '${eventType.englishLabel} (Imported)',
          eventDate: eventDate,
          eventTime: '12:00',
          odometerKm: odometer,
          amount: amount,
          sourceType: 'CSV_IMPORT',
          payloadJson: payloadJson,
          notes: notes.isNotEmpty ? notes : 'Imported via CSV',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.addEvent(event);
        imported++;
      } catch (e) {
        failed++;
        errors.add('Row $i: $e');
      }
    }

    return CsvImportResult(
      totalRows: lines.length - 1,
      importedCount: imported,
      failedCount: failed,
      errors: errors,
    );
  }

  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool insideQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (insideQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++; // Skip escaped quote
        } else {
          insideQuotes = !insideQuotes;
        }
      } else if (char == ',' && !insideQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());
    return result;
  }

  static DateTime? _tryParseFlexibleDate(String input) {
    if (input.isEmpty) return null;
    // Common formats: YYYY-MM-DD, DD/MM/YYYY, DD-MM-YYYY, MM/DD/YYYY
    final direct = DateTime.tryParse(input);
    if (direct != null) return direct;

    final formats = [
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'dd.MM.yyyy',
      'yyyy/MM/dd',
      'MM/dd/yyyy',
      'dd-MMM-yyyy',
      'dd MMM yyyy',
    ];

    for (final fmt in formats) {
      try {
        return DateFormat(fmt).parseLoose(input);
      } catch (_) {}
    }
    return null;
  }
}
