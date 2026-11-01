import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/health_models.dart';
import '../../../main.dart';
import 'edit_health_event_dialog.dart';

class HealthEventDetailDialog extends StatefulWidget {
  final HealthEvent event;
  final String patientName;
  final VoidCallback onUpdated;

  const HealthEventDetailDialog({
    super.key,
    required this.event,
    required this.patientName,
    required this.onUpdated,
  });

  @override
  State<HealthEventDetailDialog> createState() => _HealthEventDetailDialogState();
}

class _HealthEventDetailDialogState extends State<HealthEventDetailDialog> {
  late HealthEvent _currentEvent;
  bool _isEditingDetails = false;

  // Form controllers for completing details
  final TextEditingController _doctorNameController = TextEditingController();
  final TextEditingController _clinicController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _medicinesController = TextEditingController();

  final TextEditingController _labResultController = TextEditingController();
  final TextEditingController _labParametersController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _initFormValues();
  }

  void _initFormValues() {
    _notesController.text = _currentEvent.notes ?? '';

    if (_currentEvent.eventType == HealthEventType.prescription) {
      final rx = _currentEvent.prescriptionData;
      if (rx != null) {
        _doctorNameController.text = rx.doctorName ?? '';
        _clinicController.text = rx.clinic ?? '';
        _instructionsController.text = rx.instructions ?? '';
        _medicinesController.text = rx.medicines.join('\n');
      }
    } else if (_currentEvent.eventType == HealthEventType.labReport) {
      final lab = _currentEvent.labReportData;
      if (lab != null) {
        _labResultController.text = lab.resultSummary ?? '';
        if (lab.extractedParameters.isNotEmpty) {
          _labParametersController.text = lab.extractedParameters.entries
              .map((e) => '${e.key}: ${e.value}')
              .join('\n');
        }
      }
    }
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _clinicController.dispose();
    _instructionsController.dispose();
    _medicinesController.dispose();
    _labResultController.dispose();
    _labParametersController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCompletedDetails() async {
    String payloadJson = _currentEvent.payloadJson ?? '';

    if (_currentEvent.eventType == HealthEventType.prescription) {
      final rawMeds = _medicinesController.text
          .split('\n')
          .map((m) => m.trim())
          .where((m) => m.isNotEmpty)
          .toList();

      final rx = PrescriptionData(
        purpose: _currentEvent.purpose,
        doctorName: _doctorNameController.text.trim().isNotEmpty ? _doctorNameController.text.trim() : null,
        clinic: _clinicController.text.trim().isNotEmpty ? _clinicController.text.trim() : null,
        instructions: _instructionsController.text.trim().isNotEmpty ? _instructionsController.text.trim() : null,
        medicines: rawMeds,
      );
      payloadJson = jsonEncode(rx.toMap());
    } else if (_currentEvent.eventType == HealthEventType.labReport) {
      final paramLines = _labParametersController.text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.contains(':'));

      final extracted = <String, String>{};
      for (final line in paramLines) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          extracted[parts[0].trim()] = parts.sublist(1).join(':').trim();
        }
      }

      final lab = LabReportData(
        reportType: _currentEvent.reportType ?? _currentEvent.purpose,
        resultSummary: _labResultController.text.trim().isNotEmpty ? _labResultController.text.trim() : null,
        extractedParameters: extracted,
      );
      payloadJson = jsonEncode(lab.toMap());
    }

    await healthRepository.completeEventDetails(
      eventId: _currentEvent.id,
      payloadJson: payloadJson,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    final refreshed = await healthRepository.getEventById(_currentEvent.id);
    if (mounted) {
      setState(() {
        if (refreshed != null) _currentEvent = refreshed;
        _isEditingDetails = false;
      });
      widget.onUpdated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasEvidence = _currentEvent.evidence.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 600,
        ),
        child: Column(
          children: [
            // Title Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade700,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Text(_currentEvent.eventType.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentEvent.purpose,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '${widget.patientName} • ${_currentEvent.formattedDate}',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Badges Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _currentEvent.hasEvidence ? Colors.green.shade50 : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _currentEvent.hasEvidence ? Colors.green.shade200 : Colors.amber.shade200),
                        ),
                        child: Text(
                          _currentEvent.hasEvidence ? '🟢 Document Attached' : '🟡 Manual Entry',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _currentEvent.hasEvidence ? Colors.green.shade900 : Colors.amber.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _currentEvent.completionStatus == HealthCompletionStatus.completed
                              ? '✓ Details Completed'
                              : '◯ Details Incomplete',
                          style: TextStyle(
                            fontSize: 11,
                            color: _currentEvent.completionStatus == HealthCompletionStatus.completed
                                ? Colors.blue.shade900
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Evidence Attachments Preview
                  if (hasEvidence) ...[
                    const Text('Attached Documents / Proof:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    ..._currentEvent.evidence.map((ev) => _buildEvidenceCard(ev)),
                    const SizedBox(height: 14),
                  ],

                  // Structured Values / Summary View
                  if (!_isEditingDetails) ...[
                    _buildStructuredDataView(),
                    const SizedBox(height: 16),

                    // "Complete Details / Add Values Later" Action
                    if (_currentEvent.eventType == HealthEventType.prescription ||
                        _currentEvent.eventType == HealthEventType.labReport)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.teal.shade900,
                          side: BorderSide(color: Colors.teal.shade400),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.edit_note_rounded),
                        label: Text(
                          _currentEvent.completionStatus == HealthCompletionStatus.completed
                              ? 'Edit Structured Details'
                              : 'Complete Details / Enter Values Now',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => setState(() => _isEditingDetails = true),
                      )
                    else if (_currentEvent.eventType == HealthEventType.sugar ||
                        _currentEvent.eventType == HealthEventType.bloodPressure)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.teal.shade900,
                          side: BorderSide(color: Colors.teal.shade400),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text(
                          'Edit Record Values',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () async {
                          final patients = await healthRepository.getPatients(_currentEvent.profileId);
                          if (!context.mounted) return;
                          final updated = await showDialog<bool>(
                            context: context,
                            builder: (c) => EditHealthEventDialog(
                              event: _currentEvent,
                              patients: patients,
                              onUpdated: widget.onUpdated,
                            ),
                          );
                          if (updated == true && mounted) {
                            final refreshed = await healthRepository.getEventById(_currentEvent.id);
                            if (refreshed != null) {
                              setState(() => _currentEvent = refreshed);
                            }
                          }
                        },
                      ),
                  ] else ...[
                    // Edit Mode for Completing Details
                    _buildEditDetailsForm(),
                  ],
                ],
              ),
            ),

            // Footer / Delete
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete Record'),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Delete Health Record?'),
                          content: const Text('This will delete the record and its attached documents.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await healthRepository.deleteEvent(_currentEvent.id);
                        widget.onUpdated();
                        if (mounted) Navigator.pop(context);
                      }
                    },
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceCard(HealthEvidence ev) {
    final file = File(ev.filePath);
    final exists = file.existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ev.isPdf ? Icons.picture_as_pdf : Icons.image, size: 20, color: ev.isPdf ? Colors.red : Colors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ev.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share, size: 18, color: Colors.grey),
                tooltip: 'Share File',
                onPressed: () {
                  if (exists) {
                    Share.shareXFiles([XFile(ev.filePath)], text: ev.displayName);
                  }
                },
              ),
            ],
          ),
          if (!ev.isPdf && exists) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                file,
                height: 180,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStructuredDataView() {
    switch (_currentEvent.eventType) {
      case HealthEventType.sugar:
        final s = _currentEvent.sugarData;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Blood Sugar Reading', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
              const SizedBox(height: 4),
              Text(
                '${s?.value.toStringAsFixed(0) ?? '-'} ${s?.unit ?? "mg/dL"}',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              Text('Context: ${s?.context.label ?? "-"} (${s?.context.marathiLabel ?? "-"})'),
            ],
          ),
        );

      case HealthEventType.bloodPressure:
        final b = _currentEvent.bpData;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Blood Pressure Reading', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900)),
              const SizedBox(height: 4),
              Text(
                '${b?.systolic ?? "-"} / ${b?.diastolic ?? "-"} mmHg',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              if (b?.pulse != null) Text('Pulse: ${b!.pulse} bpm'),
            ],
          ),
        );

      case HealthEventType.prescription:
        final rx = _currentEvent.prescriptionData;
        final meds = rx?.medicines ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (rx?.doctorName?.isNotEmpty == true) Text('Doctor: ${rx!.doctorName}'),
            if (rx?.clinic?.isNotEmpty == true) Text('Clinic: ${rx!.clinic}'),
            if (rx?.instructions?.isNotEmpty == true) Text('Instructions: ${rx!.instructions}'),
            if (meds.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Medicines:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...meds.map((m) => Text('• $m')),
            ],
          ],
        );

      case HealthEventType.labReport:
        final lab = _currentEvent.labReportData;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lab?.resultSummary?.isNotEmpty == true)
              Text('Result: ${lab!.resultSummary}', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (lab?.extractedParameters.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              const Text('Clinical Parameters:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...lab!.extractedParameters.entries.map((e) => Text('• ${e.key}: ${e.value}')),
            ],
          ],
        );

      default:
        return Text(_currentEvent.notes ?? 'No additional notes');
    }
  }

  Widget _buildEditDetailsForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter Detailed Clinical Information:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),

          if (_currentEvent.eventType == HealthEventType.prescription) ...[
            TextField(
              controller: _doctorNameController,
              decoration: const InputDecoration(labelText: 'Doctor Name (Optional)', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _clinicController,
              decoration: const InputDecoration(labelText: 'Clinic / Hospital (Optional)', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _medicinesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Medicines List (One per line)',
                hintText: 'e.g. Paracetamol 650mg 1-0-1 (3 days)\nAzithromycin 500mg 1-0-0 (5 days)',
                border: OutlineInputBorder(),
              ),
            ),
          ] else if (_currentEvent.eventType == HealthEventType.labReport) ...[
            TextField(
              controller: _labResultController,
              decoration: const InputDecoration(
                labelText: 'Result Summary (e.g. Positive / Normal)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _labParametersController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Parameter Values (Parameter: Value per line)',
                hintText: 'Hemoglobin: 11.8\nWBC: 7200\nPlatelets: 240000',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Additional Notes', border: OutlineInputBorder(), isDense: true),
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _isEditingDetails = false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                icon: const Icon(Icons.check),
                label: const Text('Save Details'),
                onPressed: _saveCompletedDetails,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
