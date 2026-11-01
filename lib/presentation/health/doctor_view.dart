import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/health_models.dart';
import '../../data/services/health_pdf_service.dart';
import '../../main.dart';

class DoctorView extends StatefulWidget {
  final int profileId;
  final List<HealthPatient> patients;
  final int? initialPatientId;

  const DoctorView({
    super.key,
    required this.profileId,
    required this.patients,
    this.initialPatientId,
  });

  @override
  State<DoctorView> createState() => _DoctorViewState();
}

class _DoctorViewState extends State<DoctorView> {
  late int _selectedPatientId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  List<HealthEvent> _filteredEvents = [];
  bool _isLoading = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPatientId != null && widget.patients.any((p) => p.id == widget.initialPatientId)) {
      _selectedPatientId = widget.initialPatientId!;
    } else if (widget.patients.isNotEmpty) {
      _selectedPatientId = widget.patients.first.id;
    } else {
      _selectedPatientId = 1;
    }
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final events = await healthRepository.getEvents(
      widget.profileId,
      patientId: _selectedPatientId,
      startDate: _startDate,
      endDate: _endDate,
    );
    if (mounted) {
      setState(() {
        _filteredEvents = events;
        _isLoading = false;
      });
    }
  }

  Future<void> _exportPdf() async {
    final patient = widget.patients.firstWhere(
      (p) => p.id == _selectedPatientId,
      orElse: () => HealthPatient(
        id: _selectedPatientId,
        profileId: widget.profileId,
        name: 'Patient',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    setState(() => _isExporting = true);
    try {
      await HealthPdfService.shareDoctorReport(
        patient: patient,
        events: _filteredEvents,
        startDate: _startDate,
        endDate: _endDate,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patients.firstWhere(
      (p) => p.id == _selectedPatientId,
      orElse: () => HealthPatient(
        id: _selectedPatientId,
        profileId: widget.profileId,
        name: 'Patient',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    // Grouping
    final prescriptions = _filteredEvents.where((e) => e.eventType == HealthEventType.prescription).toList();
    final labReports = _filteredEvents.where((e) => e.eventType == HealthEventType.labReport).toList();
    final sugars = _filteredEvents.where((e) => e.eventType == HealthEventType.sugar).toList();
    final bps = _filteredEvents.where((e) => e.eventType == HealthEventType.bloodPressure).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('👨‍⚕️', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('Doctor View', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Export Doctor PDF',
            onPressed: _isExporting ? null : _exportPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar (Patient + Period)
          _buildFilterBar(),

          // Body Content: Evidence First -> Measurements Second -> Timeline
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Patient Info Banner
                      _buildPatientBanner(patient),
                      const SizedBox(height: 16),

                      // Metric Highlights
                      _buildMetricSummaryRow(prescriptions.length, labReports.length, sugars.length, bps.length),
                      const SizedBox(height: 20),

                      // SECTION 1: DOCUMENTS FIRST (Original reports visually primary!)
                      _buildSectionHeader('📄 DOCUMENTS & ORIGINAL EVIDENCE', Colors.teal),
                      const SizedBox(height: 8),
                      if (prescriptions.isEmpty && labReports.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No prescriptions or lab reports in this period.', style: TextStyle(color: Colors.grey)),
                        )
                      else ...[
                        if (prescriptions.isNotEmpty) ...[
                          const Text('Prescriptions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple)),
                          const SizedBox(height: 6),
                          ...prescriptions.map((rx) => _buildPrescriptionClinicalCard(rx)),
                          const SizedBox(height: 12),
                        ],
                        if (labReports.isNotEmpty) ...[
                          const Text('Laboratory & Diagnostic Reports:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber)),
                          const SizedBox(height: 6),
                          ...labReports.map((lab) => _buildLabClinicalCard(lab)),
                          const SizedBox(height: 12),
                        ],
                      ],
                      const SizedBox(height: 16),

                      // SECTION 2: MEASUREMENTS SECOND (Sugar table & BP table)
                      _buildSectionHeader('📊 STRUCTURED MEASUREMENTS', Colors.indigo),
                      const SizedBox(height: 8),
                      if (sugars.isNotEmpty) ...[
                        const Text('Blood Sugar Log (mg/dL)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal)),
                        const SizedBox(height: 6),
                        _buildSugarTable(sugars),
                        const SizedBox(height: 14),
                      ],
                      if (bps.isNotEmpty) ...[
                        const Text('Blood Pressure Log (mmHg)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                        const SizedBox(height: 6),
                        _buildBpTable(bps),
                        const SizedBox(height: 14),
                      ],
                      if (sugars.isEmpty && bps.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No home measurements recorded in this period.', style: TextStyle(color: Colors.grey)),
                        ),
                      const SizedBox(height: 24),

                      // PDF Export Call to Action
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: _isExporting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.print_rounded),
                          label: Text(
                            _isExporting ? 'Generating Doctor PDF...' : 'Export 8-Part Doctor Report (PDF)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          onPressed: _isExporting ? null : _exportPdf,
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final periodStr = '${DateFormat('dd MMM').format(_startDate)} → ${DateFormat('dd MMM yyyy').format(_endDate)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        border: Border(bottom: BorderSide(color: Colors.teal.shade100)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Patient Dropdown
              const Text('Patient: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedPatientId,
                      isExpanded: true,
                      items: widget.patients.map((p) {
                        final relStr = p.relationship?.isNotEmpty == true ? ' (${p.relationship})' : '';
                        return DropdownMenuItem<int>(
                          value: p.id,
                          child: Text('${p.name}$relStr', style: const TextStyle(fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedPatientId = val);
                          _loadEvents();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Text('Period:  ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked.start;
                        _endDate = picked.end;
                      });
                      _loadEvents();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.date_range, size: 16, color: Colors.teal),
                            const SizedBox(width: 8),
                            Text(periodStr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          ],
                        ),
                        const Icon(Icons.edit, size: 14, color: Colors.teal),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientBanner(HealthPatient patient) {
    final ageStr = patient.ageInYears != null ? '${patient.ageInYears} Yrs' : 'N/A';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Relation: ${patient.relationship ?? "Self"} • Age: $ageStr',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
          if (patient.bloodGroup?.isNotEmpty == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                'Blood: ${patient.bloodGroup}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red.shade900),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricSummaryRow(int rx, int lab, int sugar, int bp) {
    return Row(
      children: [
        _buildMetricCard('Prescriptions', '$rx', Colors.purple),
        const SizedBox(width: 8),
        _buildMetricCard('Lab Reports', '$lab', Colors.amber.shade900),
        const SizedBox(width: 8),
        _buildMetricCard('Sugar Tests', '$sugar', Colors.teal),
        const SizedBox(width: 8),
        _buildMetricCard('BP Tests', '$bp', Colors.red),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: color.shade800, width: 3)),
      ),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color.shade900),
      ),
    );
  }

  Widget _buildPrescriptionClinicalCard(HealthEvent rx) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('💊 Purpose: ${rx.purpose}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(rx.formattedDate, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            if (rx.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text('Notes: ${rx.notes}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
            ],
            if (rx.evidence.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: rx.evidence.map((ev) {
                  return Chip(
                    avatar: Icon(ev.isPdf ? Icons.picture_as_pdf : Icons.image, size: 14, color: Colors.teal),
                    label: Text(ev.displayName, style: const TextStyle(fontSize: 10)),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLabClinicalCard(HealthEvent lab) {
    final data = lab.labReportData;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('📄 Report: ${lab.purpose}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(lab.formattedDate, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Result: ${data?.resultSummary ?? "Document attached for physician review"}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
            ),
            if (lab.evidence.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: lab.evidence.map((ev) {
                  return Chip(
                    avatar: Icon(ev.isPdf ? Icons.picture_as_pdf : Icons.image, size: 14, color: Colors.amber.shade900),
                    label: Text(ev.displayName, style: const TextStyle(fontSize: 10)),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSugarTable(List<HealthEvent> sugars) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Table(
        border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade200)),
        columnWidths: const {
          0: FlexColumnWidth(2.5),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2.5),
          3: FlexColumnWidth(2),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFE0F2F1)),
            children: [
              Padding(padding: EdgeInsets.all(8), child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Padding(padding: EdgeInsets.all(8), child: Text('Reading', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Padding(padding: EdgeInsets.all(8), child: Text('Context', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Padding(padding: EdgeInsets.all(8), child: Text('Evidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            ],
          ),
          ...sugars.map((s) {
            final data = s.sugarData;
            final val = data != null ? '${data.value.toStringAsFixed(0)} mg/dL' : '-';
            final ctx = data?.context.label ?? '-';
            final evStr = s.hasEvidence ? '🟢 Attached' : '🟡 Manual';

            return TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(8), child: Text(s.formattedDate, style: const TextStyle(fontSize: 11))),
                Padding(padding: const EdgeInsets.all(8), child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.teal))),
                Padding(padding: const EdgeInsets.all(8), child: Text(ctx, style: const TextStyle(fontSize: 11))),
                Padding(padding: const EdgeInsets.all(8), child: Text(evStr, style: const TextStyle(fontSize: 10))),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBpTable(List<HealthEvent> bps) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Table(
        border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade200)),
        columnWidths: const {
          0: FlexColumnWidth(2.5),
          1: FlexColumnWidth(2.5),
          2: FlexColumnWidth(1.5),
          3: FlexColumnWidth(2),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFFFEBEE)),
            children: [
              Padding(padding: EdgeInsets.all(8), child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Padding(padding: EdgeInsets.all(8), child: Text('BP (mmHg)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Padding(padding: EdgeInsets.all(8), child: Text('Pulse', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Padding(padding: EdgeInsets.all(8), child: Text('Evidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            ],
          ),
          ...bps.map((bp) {
            final data = bp.bpData;
            final val = data != null ? '${data.systolic} / ${data.diastolic}' : '-';
            final pulse = data?.pulse != null ? '${data!.pulse}' : '-';
            final evStr = bp.hasEvidence ? '🟢 Attached' : '🟡 Manual';

            return TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(8), child: Text(bp.formattedDate, style: const TextStyle(fontSize: 11))),
                Padding(padding: const EdgeInsets.all(8), child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.red))),
                Padding(padding: const EdgeInsets.all(8), child: Text(pulse, style: const TextStyle(fontSize: 11))),
                Padding(padding: const EdgeInsets.all(8), child: Text(evStr, style: const TextStyle(fontSize: 10))),
              ],
            );
          }),
        ],
      ),
    );
  }
}
