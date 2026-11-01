import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import '../models/gadi_models.dart';

class GadiMileageInterval {
  final double startOdometer;
  final double endOdometer;
  final double distanceKm;
  final double fuelUnits; // Liters, kg, or kWh
  final double mileage; // KM per unit
  final double totalCost;
  final double costPerKm;
  final DateTime date;

  const GadiMileageInterval({
    required this.startOdometer,
    required this.endOdometer,
    required this.distanceKm,
    required this.fuelUnits,
    required this.mileage,
    required this.totalCost,
    required this.costPerKm,
    required this.date,
  });
}

class GadiMileageCalculationResult {
  final double averageMileage;
  final double latestMileage;
  final double totalDistanceTracked;
  final double totalFuelConsumed;
  final double averageFuelCostPerKm;
  final List<GadiMileageInterval> intervals;

  const GadiMileageCalculationResult({
    required this.averageMileage,
    required this.latestMileage,
    required this.totalDistanceTracked,
    required this.totalFuelConsumed,
    required this.averageFuelCostPerKm,
    required this.intervals,
  });

  factory GadiMileageCalculationResult.empty() {
    return const GadiMileageCalculationResult(
      averageMileage: 0.0,
      latestMileage: 0.0,
      totalDistanceTracked: 0.0,
      totalFuelConsumed: 0.0,
      averageFuelCostPerKm: 0.0,
      intervals: [],
    );
  }
}

class GadiAnalyticsSummary {
  final double totalSpend;
  final double fuelSpend;
  final double serviceSpend;
  final double repairSpend;
  final double emiSpend;
  final double tollAndFineSpend;
  final double otherSpend;
  final double totalDistanceKm;
  final double fuelCostPerKm;
  final double totalCostPerKm;
  final double averageMileage;
  final double businessTripKm;
  final double totalReimbursementEarned;
  final double pendingReimbursement;

  const GadiAnalyticsSummary({
    required this.totalSpend,
    required this.fuelSpend,
    required this.serviceSpend,
    required this.repairSpend,
    required this.emiSpend,
    required this.tollAndFineSpend,
    required this.otherSpend,
    required this.totalDistanceKm,
    required this.fuelCostPerKm,
    required this.totalCostPerKm,
    required this.averageMileage,
    required this.businessTripKm,
    required this.totalReimbursementEarned,
    required this.pendingReimbursement,
  });

  factory GadiAnalyticsSummary.empty() {
    return const GadiAnalyticsSummary(
      totalSpend: 0.0,
      fuelSpend: 0.0,
      serviceSpend: 0.0,
      repairSpend: 0.0,
      emiSpend: 0.0,
      tollAndFineSpend: 0.0,
      otherSpend: 0.0,
      totalDistanceKm: 0.0,
      fuelCostPerKm: 0.0,
      totalCostPerKm: 0.0,
      averageMileage: 0.0,
      businessTripKm: 0.0,
      totalReimbursementEarned: 0.0,
      pendingReimbursement: 0.0,
    );
  }
}

class GadiRepository {
  final AppDatabase _database;

  // Broadcast stream controllers for responsive UI updates
  final StreamController<void> _vehicleChangeNotifier = StreamController<void>.broadcast();
  final StreamController<void> _eventChangeNotifier = StreamController<void>.broadcast();
  final StreamController<void> _tripChangeNotifier = StreamController<void>.broadcast();
  final StreamController<void> _dueChangeNotifier = StreamController<void>.broadcast();

  GadiRepository(this._database);

  void _notifyVehicles() {
    if (!_vehicleChangeNotifier.isClosed) _vehicleChangeNotifier.add(null);
  }

  void _notifyEvents() {
    if (!_eventChangeNotifier.isClosed) _eventChangeNotifier.add(null);
  }

  void _notifyTrips() {
    if (!_tripChangeNotifier.isClosed) _tripChangeNotifier.add(null);
  }

  void _notifyDues() {
    if (!_dueChangeNotifier.isClosed) _dueChangeNotifier.add(null);
  }

  void dispose() {
    _vehicleChangeNotifier.close();
    _eventChangeNotifier.close();
    _tripChangeNotifier.close();
    _dueChangeNotifier.close();
  }

  /// Internal generic helper to insert a map into any table and return last_insert_rowid
  Future<int> _insertRaw(String table, Map<String, dynamic> map) async {
    map.remove('id');
    final columns = map.keys.join(', ');
    final placeholders = List.filled(map.length, '?').join(', ');
    final values = map.values.toList();

    await _database.customStatement(
      'INSERT INTO $table ($columns) VALUES ($placeholders)',
      values,
    );
    final res = await _database.customSelect('SELECT last_insert_rowid() AS id').getSingle();
    return (res.data['id'] as num).toInt();
  }

  // ==========================================
  // 1. VEHICLE OPERATIONS
  // ==========================================

  Stream<List<GadiVehicle>> watchVehicles(int profileId) async* {
    yield await getVehicles(profileId);
    await for (final _ in _vehicleChangeNotifier.stream) {
      yield await getVehicles(profileId);
    }
  }

  Future<List<GadiVehicle>> getVehicles(int profileId, {bool activeOnly = true}) async {
    final sql = activeOnly
        ? 'SELECT * FROM gadi_vehicles WHERE profile_id = ? AND is_active = 1 ORDER BY id ASC'
        : 'SELECT * FROM gadi_vehicles WHERE profile_id = ? ORDER BY id ASC';

    final rows = await _database.customSelect(
      sql,
      variables: [Variable.withInt(profileId)],
    ).get();

    return rows.map((r) => GadiVehicle.fromMap(r.data)).toList();
  }

  Future<GadiVehicle?> getVehicleById(int vehicleId) async {
    final rows = await _database.customSelect(
      'SELECT * FROM gadi_vehicles WHERE id = ?',
      variables: [Variable.withInt(vehicleId)],
    ).get();
    if (rows.isEmpty) return null;
    return GadiVehicle.fromMap(rows.first.data);
  }

  Future<int> addVehicle(GadiVehicle vehicle) async {
    final now = DateTime.now().toIso8601String();
    final map = vehicle.toMap();
    map['created_at'] = now;
    map['updated_at'] = now;

    final id = await _insertRaw('gadi_vehicles', map);

    // Record initial odometer log
    if (vehicle.currentOdometer > 0) {
      await _insertRaw('gadi_odometer_logs', {
        'vehicle_id': id,
        'odometer_km': vehicle.currentOdometer,
        'recorded_date': formatDateOnly(DateTime.now()),
        'recorded_time': DateFormat('HH:mm').format(DateTime.now()),
        'source_type': 'INITIAL',
        'is_manual_calibration': 0,
        'calibration_reason': 'Vehicle Profile Created',
        'created_at': now,
      });
    }

    // Auto-sync initial statutory dues if dates are present
    final savedVehicle = vehicle.copyWith(
      initialOdometer: vehicle.initialOdometer,
      currentOdometer: vehicle.currentOdometer,
    );
    await syncDuesFromVehicle(savedVehicle, vehicleIdOverride: id);

    _notifyVehicles();
    return id;
  }

  Future<void> updateVehicle(GadiVehicle vehicle) async {
    final now = DateTime.now().toIso8601String();
    final map = vehicle.toMap();
    map['updated_at'] = now;
    final id = vehicle.id;
    map.remove('id');

    final setClauses = map.keys.map((k) => '$k = ?').join(', ');
    final values = map.values.toList();
    values.add(id);

    await _database.customStatement(
      'UPDATE gadi_vehicles SET $setClauses WHERE id = ?',
      values,
    );

    // Sync dues if dates were changed
    await syncDuesFromVehicle(vehicle);

    _notifyVehicles();
  }

  Future<void> deleteVehicle(int vehicleId) async {
    await _database.customStatement(
      'DELETE FROM gadi_vehicles WHERE id = ?',
      [vehicleId],
    );
    _notifyVehicles();
    _notifyEvents();
    _notifyTrips();
    _notifyDues();
  }

  /// Updates odometer reading with strict monotonic check
  Future<void> updateVehicleOdometer(
    int vehicleId,
    double newOdometerKm, {
    bool isCalibration = false,
    String? reason,
    int? sourceEventId,
    int? sourceTripId,
  }) async {
    final current = await getVehicleById(vehicleId);
    if (current == null) return;

    // Strict monotonic rule: cannot silently decrease odometer
    if (!isCalibration && newOdometerKm < current.currentOdometer) {
      throw ArgumentError(
        'New odometer ($newOdometerKm km) cannot be less than current odometer (${current.currentOdometer} km). '
        'Use calibration mode to correct an erroneous reading.',
      );
    }

    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final dateStr = formatDateOnly(now);
    final timeStr = DateFormat('HH:mm').format(now);

    // 1. Update vehicle record
    await _database.customStatement(
      'UPDATE gadi_vehicles SET current_odometer = ?, updated_at = ? WHERE id = ?',
      [newOdometerKm, nowIso, vehicleId],
    );

    // 2. Audit log
    final sourceType = isCalibration ? 'CALIBRATION' : (sourceTripId != null ? 'TRIP' : 'EVENT');
    final sourceId = sourceTripId ?? sourceEventId;

    await _insertRaw('gadi_odometer_logs', {
      'vehicle_id': vehicleId,
      'odometer_km': newOdometerKm,
      'recorded_date': dateStr,
      'recorded_time': timeStr,
      'source_type': sourceType,
      'source_id': sourceId,
      'is_manual_calibration': isCalibration ? 1 : 0,
      'calibration_reason': reason ?? '',
      'created_at': nowIso,
    });

    _notifyVehicles();
  }

  // ==========================================
  // 2. EVENT & DIARY OPERATIONS
  // ==========================================

  Stream<List<GadiEvent>> watchEvents(int profileId, {int? vehicleId}) async* {
    yield await getEvents(profileId, vehicleId: vehicleId);
    await for (final _ in _eventChangeNotifier.stream) {
      yield await getEvents(profileId, vehicleId: vehicleId);
    }
  }

  Future<List<GadiEvent>> getEvents(
    int profileId, {
    int? vehicleId,
    GadiEventType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final whereClauses = <String>['profile_id = ?'];
    final variables = <Variable>[Variable.withInt(profileId)];

    if (vehicleId != null) {
      whereClauses.add('vehicle_id = ?');
      variables.add(Variable.withInt(vehicleId));
    }
    if (type != null) {
      whereClauses.add('event_type = ?');
      variables.add(Variable.withString(type.name));
    }
    if (startDate != null) {
      whereClauses.add('event_date >= ?');
      variables.add(Variable.withString(formatDateOnly(startDate)));
    }
    if (endDate != null) {
      whereClauses.add('event_date <= ?');
      variables.add(Variable.withString(formatDateOnly(endDate)));
    }

    final sql = 'SELECT * FROM gadi_events WHERE ${whereClauses.join(' AND ')} ORDER BY event_date DESC, event_time DESC, id DESC';
    final rows = await _database.customSelect(sql, variables: variables).get();

    final events = <GadiEvent>[];
    for (final row in rows) {
      final eventId = (row.data['id'] as num).toInt();
      final evidence = await getEvidenceForEvent(eventId);
      events.add(GadiEvent.fromMap(row.data, evidence: evidence));
    }
    return events;
  }

  Future<GadiEvent?> getEventById(int eventId) async {
    final rows = await _database.customSelect(
      'SELECT * FROM gadi_events WHERE id = ?',
      variables: [Variable.withInt(eventId)],
    ).get();
    if (rows.isEmpty) return null;
    final evidence = await getEvidenceForEvent(eventId);
    return GadiEvent.fromMap(rows.first.data, evidence: evidence);
  }

  Future<int> addEvent(GadiEvent event, {List<GadiEvidence> initialEvidence = const []}) async {
    final now = DateTime.now().toIso8601String();
    final map = event.toMap();
    map['created_at'] = now;
    map['updated_at'] = now;
    map['evidence_status'] = initialEvidence.isNotEmpty ? 'ATTACHED' : event.evidenceStatus;

    final eventId = await _insertRaw('gadi_events', map);

    // Save initial evidence if provided
    for (final ev in initialEvidence) {
      await attachEvidence(eventId, ev);
    }

    // Advance odometer if odometer was specified and is greater than current
    if (event.odometerKm != null && event.odometerKm! > 0) {
      final vehicle = await getVehicleById(event.vehicleId);
      if (vehicle != null && event.odometerKm! >= vehicle.currentOdometer) {
        await updateVehicleOdometer(
          event.vehicleId,
          event.odometerKm!,
          isCalibration: false,
          sourceEventId: eventId,
        );
      }
    }

    // Auto-update service due KM / Date if service payload contains targets
    if (event.eventType == GadiEventType.service && event.servicePayload != null) {
      final payload = event.servicePayload!;
      final vehicle = await getVehicleById(event.vehicleId);
      if (vehicle != null) {
        GadiVehicle updatedVehicle = vehicle;
        if (payload.nextServiceKmDue != null) {
          updatedVehicle = updatedVehicle.copyWith(serviceDueKm: payload.nextServiceKmDue);
        }
        if (payload.nextServiceDateDue != null && payload.nextServiceDateDue!.isNotEmpty) {
          updatedVehicle = updatedVehicle.copyWith(serviceDueDate: parseDateOnly(payload.nextServiceDateDue!));
        }
        await updateVehicle(updatedVehicle);
      }
    }

    _notifyEvents();
    return eventId;
  }

  Future<void> updateEvent(GadiEvent event) async {
    final now = DateTime.now().toIso8601String();
    final map = event.toMap();
    map['updated_at'] = now;
    final id = event.id;
    map.remove('id');

    final setClauses = map.keys.map((k) => '$k = ?').join(', ');
    final values = map.values.toList();
    values.add(id);

    await _database.customStatement(
      'UPDATE gadi_events SET $setClauses WHERE id = ?',
      values,
    );
    _notifyEvents();
  }

  Future<void> deleteEvent(int eventId) async {
    await _database.customStatement('DELETE FROM gadi_events WHERE id = ?', [eventId]);
    _notifyEvents();
  }

  // ==========================================
  // 3. EVIDENCE ATTACHMENTS
  // ==========================================

  Future<List<GadiEvidence>> getEvidenceForEvent(int eventId) async {
    final rows = await _database.customSelect(
      'SELECT * FROM gadi_evidence WHERE event_id = ? ORDER BY id ASC',
      variables: [Variable.withInt(eventId)],
    ).get();
    return rows.map((r) => GadiEvidence.fromMap(r.data)).toList();
  }

  Future<int> attachEvidence(int eventId, GadiEvidence evidence) async {
    final now = DateTime.now().toIso8601String();
    final id = await _insertRaw('gadi_evidence', {
      'event_id': eventId,
      'file_path': evidence.filePath,
      'original_name': evidence.originalName,
      'display_name': evidence.displayName,
      'mime_type': evidence.mimeType,
      'evidence_type': evidence.evidenceType,
      'created_at': now,
    });

    // Update event evidence_status
    await _database.customStatement(
      "UPDATE gadi_events SET evidence_status = 'ATTACHED' WHERE id = ?",
      [eventId],
    );

    _notifyEvents();
    return id;
  }

  Future<void> deleteEvidence(int evidenceId, int eventId) async {
    await _database.customStatement('DELETE FROM gadi_evidence WHERE id = ?', [evidenceId]);
    final remaining = await getEvidenceForEvent(eventId);
    if (remaining.isEmpty) {
      await _database.customStatement(
        "UPDATE gadi_events SET evidence_status = 'NONE' WHERE id = ?",
        [eventId],
      );
    }
    _notifyEvents();
  }

  // ==========================================
  // 4. TRIPS & JOURNEYS OPERATIONS
  // ==========================================

  Stream<List<GadiTrip>> watchTrips(int profileId, {int? vehicleId}) async* {
    yield await getTrips(profileId, vehicleId: vehicleId);
    await for (final _ in _tripChangeNotifier.stream) {
      yield await getTrips(profileId, vehicleId: vehicleId);
    }
  }

  Future<List<GadiTrip>> getTrips(
    int profileId, {
    int? vehicleId,
    GadiTripType? tripType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final whereClauses = <String>['profile_id = ?'];
    final variables = <Variable>[Variable.withInt(profileId)];

    if (vehicleId != null) {
      whereClauses.add('vehicle_id = ?');
      variables.add(Variable.withInt(vehicleId));
    }
    if (tripType != null) {
      whereClauses.add('trip_type = ?');
      variables.add(Variable.withString(tripType.name));
    }
    if (startDate != null) {
      whereClauses.add('start_date_time >= ?');
      variables.add(Variable.withString(startDate.toIso8601String()));
    }
    if (endDate != null) {
      whereClauses.add('start_date_time <= ?');
      variables.add(Variable.withString(endDate.toIso8601String()));
    }

    final sql = 'SELECT * FROM gadi_trips WHERE ${whereClauses.join(' AND ')} ORDER BY start_date_time DESC, id DESC';
    final rows = await _database.customSelect(sql, variables: variables).get();
    return rows.map((r) => GadiTrip.fromMap(r.data)).toList();
  }

  Future<int> addTrip(GadiTrip trip) async {
    final now = DateTime.now().toIso8601String();
    final map = trip.toMap();
    map['created_at'] = now;
    map['updated_at'] = now;

    final tripId = await _insertRaw('gadi_trips', map);

    // Update vehicle odometer to end_odometer if end_odometer > current
    final vehicle = await getVehicleById(trip.vehicleId);
    if (vehicle != null && trip.endOdometer >= vehicle.currentOdometer) {
      await updateVehicleOdometer(
        trip.vehicleId,
        trip.endOdometer,
        isCalibration: false,
        sourceTripId: tripId,
      );
    }

    _notifyTrips();
    return tripId;
  }

  Future<void> updateTrip(GadiTrip trip) async {
    final now = DateTime.now().toIso8601String();
    final map = trip.toMap();
    map['updated_at'] = now;
    final id = trip.id;
    map.remove('id');

    final setClauses = map.keys.map((k) => '$k = ?').join(', ');
    final values = map.values.toList();
    values.add(id);

    await _database.customStatement(
      'UPDATE gadi_trips SET $setClauses WHERE id = ?',
      values,
    );
    _notifyTrips();
  }

  Future<void> deleteTrip(int tripId) async {
    await _database.customStatement('DELETE FROM gadi_trips WHERE id = ?', [tripId]);
    _notifyTrips();
  }

  Future<void> markTripReimbursed(int tripId, bool isReimbursed) async {
    final now = DateTime.now().toIso8601String();
    await _database.customStatement(
      'UPDATE gadi_trips SET is_reimbursed = ?, updated_at = ? WHERE id = ?',
      [isReimbursed ? 1 : 0, now, tripId],
    );
    _notifyTrips();
  }

  // ==========================================
  // 5. STATUTORY & COMPLIANCE DUES
  // ==========================================

  Stream<List<GadiDue>> watchDues(int profileId, {int? vehicleId}) async* {
    yield await getDues(profileId, vehicleId: vehicleId);
    await for (final _ in _dueChangeNotifier.stream) {
      yield await getDues(profileId, vehicleId: vehicleId);
    }
  }

  Future<List<GadiDue>> getDues(int profileId, {int? vehicleId, bool includeCompleted = false}) async {
    final whereClauses = <String>['profile_id = ?'];
    final variables = <Variable>[Variable.withInt(profileId)];

    if (vehicleId != null) {
      whereClauses.add('vehicle_id = ?');
      variables.add(Variable.withInt(vehicleId));
    }
    if (!includeCompleted) {
      whereClauses.add("status != 'COMPLETED'");
    }

    final sql = 'SELECT * FROM gadi_dues WHERE ${whereClauses.join(' AND ')} ORDER BY due_date ASC, id ASC';
    final rows = await _database.customSelect(sql, variables: variables).get();
    return rows.map((r) => GadiDue.fromMap(r.data)).toList();
  }

  Future<int> addDue(GadiDue due) async {
    final now = DateTime.now().toIso8601String();
    final map = due.toMap();
    map['created_at'] = now;
    map['updated_at'] = now;

    final id = await _insertRaw('gadi_dues', map);
    _notifyDues();
    return id;
  }

  Future<void> updateDue(GadiDue due) async {
    final now = DateTime.now().toIso8601String();
    final map = due.toMap();
    map['updated_at'] = now;
    final id = due.id;
    map.remove('id');

    final setClauses = map.keys.map((k) => '$k = ?').join(', ');
    final values = map.values.toList();
    values.add(id);

    await _database.customStatement(
      'UPDATE gadi_dues SET $setClauses WHERE id = ?',
      values,
    );
    _notifyDues();
  }

  Future<void> markDueCompleted(int dueId, {int? resolvedEventId}) async {
    final now = DateTime.now().toIso8601String();
    await _database.customStatement(
      "UPDATE gadi_dues SET status = 'COMPLETED', resolved_event_id = ?, updated_at = ? WHERE id = ?",
      [resolvedEventId, now, dueId],
    );
    _notifyDues();
  }

  Future<void> snoozeDue(int dueId, DateTime snoozeUntil) async {
    final now = DateTime.now().toIso8601String();
    await _database.customStatement(
      "UPDATE gadi_dues SET status = 'SNOOZED', snoozed_until = ?, updated_at = ? WHERE id = ?",
      [snoozeUntil.toIso8601String(), now, dueId],
    );
    _notifyDues();
  }

  /// Automatically synchronizes PUC, Insurance, and Service dues from vehicle profile dates
  Future<void> syncDuesFromVehicle(GadiVehicle vehicle, {int? vehicleIdOverride}) async {
    final vId = vehicleIdOverride ?? vehicle.id;
    if (vId <= 0) return;

    final existingDues = await getDues(vehicle.profileId, vehicleId: vId, includeCompleted: true);

    // 1. PUC Due
    if (vehicle.pucExpiryDate != null) {
      final existingPuc = existingDues.where((d) => d.dueType == GadiDueType.puc).firstOrNull;
      if (existingPuc == null) {
        await addDue(GadiDue(
          id: 0,
          profileId: vehicle.profileId,
          vehicleId: vId,
          dueType: GadiDueType.puc,
          title: 'PUC Expiry (${vehicle.name})',
          dueDate: vehicle.pucExpiryDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      } else if (existingPuc.dueDate != vehicle.pucExpiryDate) {
        await updateDue(GadiDue(
          id: existingPuc.id,
          profileId: vehicle.profileId,
          vehicleId: vId,
          dueType: GadiDueType.puc,
          title: existingPuc.title,
          dueDate: vehicle.pucExpiryDate,
          dueKm: existingPuc.dueKm,
          amount: existingPuc.amount,
          status: GadiDueStatus.pending,
          createdAt: existingPuc.createdAt,
          updatedAt: DateTime.now(),
        ));
      }
    }

    // 2. Insurance Due
    if (vehicle.insuranceExpiryDate != null) {
      final existingIns = existingDues.where((d) => d.dueType == GadiDueType.insurance).firstOrNull;
      if (existingIns == null) {
        await addDue(GadiDue(
          id: 0,
          profileId: vehicle.profileId,
          vehicleId: vId,
          dueType: GadiDueType.insurance,
          title: 'Insurance Renewal (${vehicle.name})',
          dueDate: vehicle.insuranceExpiryDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      } else if (existingIns.dueDate != vehicle.insuranceExpiryDate) {
        await updateDue(GadiDue(
          id: existingIns.id,
          profileId: vehicle.profileId,
          vehicleId: vId,
          dueType: GadiDueType.insurance,
          title: existingIns.title,
          dueDate: vehicle.insuranceExpiryDate,
          dueKm: existingIns.dueKm,
          amount: existingIns.amount,
          status: GadiDueStatus.pending,
          createdAt: existingIns.createdAt,
          updatedAt: DateTime.now(),
        ));
      }
    }

    // 3. Service Due (Date or KM)
    if (vehicle.serviceDueDate != null || vehicle.serviceDueKm != null) {
      final existingServ = existingDues
          .where((d) => d.dueType == GadiDueType.serviceDate || d.dueType == GadiDueType.serviceKm)
          .firstOrNull;
      if (existingServ == null) {
        await addDue(GadiDue(
          id: 0,
          profileId: vehicle.profileId,
          vehicleId: vId,
          dueType: vehicle.serviceDueKm != null ? GadiDueType.serviceKm : GadiDueType.serviceDate,
          title: 'Scheduled Service (${vehicle.name})',
          dueDate: vehicle.serviceDueDate,
          dueKm: vehicle.serviceDueKm,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    }
  }

  // ==========================================
  // 6. MILEAGE & CPKM CALCULATION ENGINE
  // ==========================================

  /// Robust tank-to-tank mileage calculation algorithm
  Future<GadiMileageCalculationResult> calculateVehicleMileage(int vehicleId) async {
    final vehicle = await getVehicleById(vehicleId);
    if (vehicle == null) return GadiMileageCalculationResult.empty();

    // Fetch all fuel entries sorted ascending by odometer
    final rows = await _database.customSelect(
      '''
      SELECT * FROM gadi_events 
      WHERE vehicle_id = ? AND event_type = 'fuel' AND odometer_km IS NOT NULL 
      ORDER BY odometer_km ASC, event_date ASC, id ASC
      ''',
      variables: [Variable.withInt(vehicleId)],
    ).get();

    if (rows.length < 2) {
      return GadiMileageCalculationResult.empty();
    }

    final fuelEvents = rows.map((r) => GadiEvent.fromMap(r.data)).toList();
    final intervals = <GadiMileageInterval>[];

    double accumulatedLiters = 0.0;
    double accumulatedFuelCost = 0.0;
    GadiEvent? lastFullTankEvent;

    for (int i = 0; i < fuelEvents.length; i++) {
      final current = fuelEvents[i];
      final payload = current.fuelPayload;
      final liters = payload?.quantity ?? 0.0;
      final cost = current.amount;
      final isFull = payload?.isFullTank ?? true;

      if (lastFullTankEvent == null) {
        // First anchor point
        if (isFull) {
          lastFullTankEvent = current;
          accumulatedLiters = 0.0;
          accumulatedFuelCost = 0.0;
        }
        continue;
      }

      // Add this refill to the accumulation
      accumulatedLiters += liters;
      accumulatedFuelCost += cost;

      if (isFull) {
        final distance = current.odometerKm! - lastFullTankEvent.odometerKm!;
        if (distance > 0 && accumulatedLiters > 0) {
          final mileage = distance / accumulatedLiters;
          final cpkm = accumulatedFuelCost / distance;

          intervals.add(GadiMileageInterval(
            startOdometer: lastFullTankEvent.odometerKm!,
            endOdometer: current.odometerKm!,
            distanceKm: distance,
            fuelUnits: accumulatedLiters,
            mileage: mileage,
            totalCost: accumulatedFuelCost,
            costPerKm: cpkm,
            date: current.eventDate,
          ));
        }

        // Reset accumulation and anchor to current
        lastFullTankEvent = current;
        accumulatedLiters = 0.0;
        accumulatedFuelCost = 0.0;
      }
    }

    if (intervals.isEmpty) {
      return GadiMileageCalculationResult.empty();
    }

    double totalDistance = 0.0;
    double totalFuel = 0.0;
    double totalCost = 0.0;

    for (final interval in intervals) {
      totalDistance += interval.distanceKm;
      totalFuel += interval.fuelUnits;
      totalCost += interval.totalCost;
    }

    final avgMileage = totalFuel > 0 ? (totalDistance / totalFuel) : 0.0;
    final latestMileage = intervals.last.mileage;
    final avgCostPerKm = totalDistance > 0 ? (totalCost / totalDistance) : 0.0;

    return GadiMileageCalculationResult(
      averageMileage: avgMileage,
      latestMileage: latestMileage,
      totalDistanceTracked: totalDistance,
      totalFuelConsumed: totalFuel,
      averageFuelCostPerKm: avgCostPerKm,
      intervals: intervals,
    );
  }

  /// Calculates comprehensive analytics summary
  Future<GadiAnalyticsSummary> getVehicleAnalytics(
    int vehicleId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final vehicle = await getVehicleById(vehicleId);
    if (vehicle == null) return GadiAnalyticsSummary.empty();

    final events = await getEvents(
      vehicle.profileId,
      vehicleId: vehicleId,
      startDate: startDate,
      endDate: endDate,
    );

    double fuelSpend = 0.0;
    double serviceSpend = 0.0;
    double repairSpend = 0.0;
    double emiSpend = 0.0;
    double tollAndFineSpend = 0.0;
    double otherSpend = 0.0;

    for (final e in events) {
      switch (e.eventType) {
        case GadiEventType.fuel:
          fuelSpend += e.amount;
          break;
        case GadiEventType.service:
          serviceSpend += e.amount;
          break;
        case GadiEventType.repair:
          repairSpend += e.amount;
          break;
        case GadiEventType.emi:
          emiSpend += e.amount;
          break;
        case GadiEventType.toll:
        case GadiEventType.challan:
        case GadiEventType.parking:
          tollAndFineSpend += e.amount;
          break;
        default:
          otherSpend += e.amount;
          break;
      }
    }

    final totalSpend = fuelSpend + serviceSpend + repairSpend + emiSpend + tollAndFineSpend + otherSpend;

    // Calculate distance
    final totalDistanceKm = vehicle.currentOdometer > vehicle.initialOdometer
        ? (vehicle.currentOdometer - vehicle.initialOdometer)
        : 0.0;

    final fuelCostPerKm = totalDistanceKm > 0 ? (fuelSpend / totalDistanceKm) : 0.0;
    final totalCostPerKm = totalDistanceKm > 0 ? (totalSpend / totalDistanceKm) : 0.0;

    // Mileage
    final mileageResult = await calculateVehicleMileage(vehicleId);

    // Business trip reimbursement
    final trips = await getTrips(
      vehicle.profileId,
      vehicleId: vehicleId,
      startDate: startDate,
      endDate: endDate,
    );

    double businessTripKm = 0.0;
    double totalReimbursementEarned = 0.0;
    double pendingReimbursement = 0.0;

    for (final t in trips) {
      if (t.isBusiness) {
        businessTripKm += t.distanceKm;
        final amount = t.computedReimbursement;
        totalReimbursementEarned += amount;
        if (!t.isReimbursed) {
          pendingReimbursement += amount;
        }
      }
    }

    return GadiAnalyticsSummary(
      totalSpend: totalSpend,
      fuelSpend: fuelSpend,
      serviceSpend: serviceSpend,
      repairSpend: repairSpend,
      emiSpend: emiSpend,
      tollAndFineSpend: tollAndFineSpend,
      otherSpend: otherSpend,
      totalDistanceKm: totalDistanceKm,
      fuelCostPerKm: fuelCostPerKm,
      totalCostPerKm: totalCostPerKm,
      averageMileage: mileageResult.averageMileage,
      businessTripKm: businessTripKm,
      totalReimbursementEarned: totalReimbursementEarned,
      pendingReimbursement: pendingReimbursement,
    );
  }

  // ==========================================
  // 7. PRE-TRIP DIGITAL INSPECTION LOGS
  // ==========================================

  Future<List<GadiInspectionLog>> getInspectionLogs(int vehicleId) async {
    final rows = await _database.customSelect(
      'SELECT * FROM gadi_inspection_logs WHERE vehicle_id = ? ORDER BY inspection_date DESC, id DESC',
      variables: [Variable.withInt(vehicleId)],
    ).get();
    return rows.map((r) => GadiInspectionLog.fromMap(r.data)).toList();
  }

  Future<int> logInspection({
    required int vehicleId,
    required List<InspectionItem> items,
    double? odometerKm,
    String? notes,
  }) async {
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final overallStatus = items.any((i) => !i.passed) ? 'ATTENTION_NEEDED' : 'ALL_GOOD';

    final id = await _insertRaw('gadi_inspection_logs', {
      'vehicle_id': vehicleId,
      'inspection_date': nowIso,
      'odometer_km': odometerKm,
      'items_json': jsonEncode(items.map((e) => e.toMap()).toList()),
      'overall_status': overallStatus,
      'notes': notes ?? '',
      'created_at': nowIso,
    });

    return id;
  }

  // ==========================================
  // 8. ODOMETER AUDIT LOGS
  // ==========================================

  Future<List<GadiOdometerLog>> getOdometerLogs(int vehicleId) async {
    final rows = await _database.customSelect(
      'SELECT * FROM gadi_odometer_logs WHERE vehicle_id = ? ORDER BY id DESC',
      variables: [Variable.withInt(vehicleId)],
    ).get();
    return rows.map((r) => GadiOdometerLog.fromMap(r.data)).toList();
  }

  Future<void> calibrateOdometer(int vehicleId, double newOdometerKm, String reason) async {
    await updateVehicleOdometer(
      vehicleId,
      newOdometerKm,
      isCalibration: true,
      reason: reason,
    );
  }
}
