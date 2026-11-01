import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/health_models.dart';
import '../../../main.dart';

class EditHealthEventDialog extends StatefulWidget {
  final HealthEvent event;
  final List<HealthPatient> patients;
  final VoidCallback onUpdated;

  const EditHealthEventDialog({
    super.key,
    required this.event,
    required this.patients,
    required this.onUpdated,
  });

  @override
  State<EditHealthEventDialog> createState() => _EditHealthEventDialogState();
}

class _EditHealthEventDialogState extends State<EditHealthEventDialog> {
  late int _selectedPatientId;
  late DateTime _editDate;
  late TimeOfDay _editTime;

  // Sugar controllers
  late TextEditingController _sugarValueController;
  SugarContext _sugarContext = SugarContext.fasting;

  // BP controllers
  late TextEditingController _systolicController;
  late TextEditingController _diastolicController;
  late TextEditingController _pulseController;

  // Notes controller
  late TextEditingController _notesController;

  // Evidence state
  final List<HealthEvidence> _activeExistingEvidence = [];
  final List<int> _removeEvidenceIds = [];
  final List<String> _newFilePaths = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final ev = widget.event;
    _selectedPatientId = ev.patientId;
    _editDate = parseDateOnly(ev.eventDate);
    _editTime = _parseTimeOfDay(ev.eventTime);

    _notesController = TextEditingController(text: ev.notes ?? '');

    // Sugar initialization
    final sugar = ev.sugarData;
    _sugarValueController = TextEditingController(
      text: sugar != null ? sugar.value.toStringAsFixed(sugar.value % 1 == 0 ? 0 : 1) : '',
    );
    if (sugar != null) {
      _sugarContext = sugar.context;
    }

    // BP initialization
    final bp = ev.bpData;
    _systolicController = TextEditingController(text: bp?.systolic.toString() ?? '');
    _diastolicController = TextEditingController(text: bp?.diastolic.toString() ?? '');
    _pulseController = TextEditingController(text: bp?.pulse?.toString() ?? '');

    // Evidence initialization
    _activeExistingEvidence.addAll(ev.evidence);
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final trimmed = timeStr.trim();
      final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$', caseSensitive: false).firstMatch(trimmed);
      if (match != null) {
        int h = int.parse(match.group(1)!);
        final m = int.parse(match.group(2)!);
        final period = match.group(3)?.toUpperCase();
        if (period == 'PM' && h < 12) h += 12;
        if (period == 'AM' && h == 12) h = 0;
        return TimeOfDay(hour: h, minute: m);
      }
    } catch (_) {}
    return const TimeOfDay(hour: 8, minute: 0);
  }

  @override
  void dispose() {
    _sugarValueController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _editDate,
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'SELECT MEASUREMENT DATE',
    );
    if (picked != null) {
      setState(() => _editDate = parseDateOnly(picked));
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _editTime,
      helpText: 'SELECT MEASUREMENT TIME',
    );
    if (picked != null) {
      setState(() => _editTime = picked);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image != null) {
      setState(() => _newFilePaths.add(image.path));
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        setState(() => _newFilePaths.add(result.files.first.path!));
      }
    } catch (_) {}
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final timeStr = _editTime.format(context);
    final notes = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null;

    try {
      if (widget.event.eventType == HealthEventType.sugar) {
        final val = double.tryParse(_sugarValueController.text.trim());
        if (val == null || val <= 0) {
          _showError('Please enter a valid sugar reading (e.g. 118)');
          setState(() => _isSaving = false);
          return;
        }

        await healthRepository.updateSugarEvent(
          eventId: widget.event.id,
          patientId: _selectedPatientId,
          reading: val,
          context: _sugarContext,
          eventDate: _editDate,
          eventTime: timeStr,
          notes: notes,
          newFilePaths: _newFilePaths,
          removeEvidenceIds: _removeEvidenceIds,
        );
      } else if (widget.event.eventType == HealthEventType.bloodPressure) {
        final sys = int.tryParse(_systolicController.text.trim());
        final dia = int.tryParse(_diastolicController.text.trim());
        final pulse = int.tryParse(_pulseController.text.trim());

        if (sys == null || dia == null || sys <= 0 || dia <= 0) {
          _showError('Please enter valid systolic & diastolic BP (e.g. 120 / 80)');
          setState(() => _isSaving = false);
          return;
        }

        await healthRepository.updateBloodPressureEvent(
          eventId: widget.event.id,
          patientId: _selectedPatientId,
          systolic: sys,
          diastolic: dia,
          pulse: pulse,
          eventDate: _editDate,
          eventTime: timeStr,
          notes: notes,
          newFilePaths: _newFilePaths,
          removeEvidenceIds: _removeEvidenceIds,
        );
      } else {
        await healthRepository.updateEvent(
          eventId: widget.event.id,
          patientId: _selectedPatientId,
          eventDate: _editDate,
          eventTime: timeStr,
          notes: notes,
          newFilePaths: _newFilePaths,
          removeEvidenceIds: _removeEvidenceIds,
        );
      }

      HapticFeedback.mediumImpact();
      widget.onUpdated();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showError('Failed to update record: $e');
      setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade800),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSugar = widget.event.eventType == HealthEventType.sugar;
    final isBP = widget.event.eventType == HealthEventType.bloodPressure;
    final formattedDate = DateFormat('EEE, dd MMM yyyy').format(_editDate);
    final timeStr = _editTime.format(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
          maxWidth: 580,
        ),
        child: Column(
          children: [
            // Title Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSugar ? Colors.red.shade800 : Colors.teal.shade800,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Text(widget.event.eventType.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit ${widget.event.eventType.englishLabel} Record',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'Update historical entry • Changes preserved accurately',
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
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

            // Form Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Patient Selector
                  Row(
                    children: [
                      const Text('Patient:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedPatientId,
                              isExpanded: true,
                              items: widget.patients.map((p) {
                                return DropdownMenuItem<int>(
                                  value: p.id,
                                  child: Text(
                                    '${p.name}${p.relationship != null ? ' (${p.relationship})' : ''}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedPatientId = val);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Date and Time Row
                  Row(
                    children: [
                      // Date Selector
                      Expanded(
                        flex: 3,
                        child: InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade50,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.teal),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('DATE', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                                      Text(formattedDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Time Selector
                      Expanded(
                        flex: 2,
                        child: InkWell(
                          onTap: _pickTime,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade50,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: Colors.teal),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('TIME', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                                      Text(timeStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Measurement Fields
                  if (isSugar) ...[
                    // Sugar Context Selector
                    const Text('MEAL CONTEXT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _buildContextChip(SugarContext.fasting, '🌅 Fasting')),
                        const SizedBox(width: 6),
                        Expanded(child: _buildContextChip(SugarContext.afterMeal, '🍽️ Post-Meal')),
                        const SizedBox(width: 6),
                        Expanded(child: _buildContextChip(SugarContext.random, '🎲 Random')),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Sugar Value TextField
                    TextField(
                      controller: _sugarValueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Blood Sugar Value',
                        hintText: 'e.g. 118',
                        suffixText: 'mg/dL',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ] else if (isBP) ...[
                    // BP Fields
                    const Text('BLOOD PRESSURE & PULSE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _systolicController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Systolic',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('/', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _diastolicController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Diastolic',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _pulseController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Pulse (bpm)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Notes TextField
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'e.g. After morning walk, felt normal',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Evidence Attachments Management (Refinement #5)
                  _buildEvidenceManagementSection(),
                ],
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSugar ? Colors.red.shade800 : Colors.teal.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(
                        _isSaving ? 'Saving...' : '💾 Save Changes',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isSaving ? null : _saveChanges,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextChip(SugarContext ctx, String label) {
    final isSelected = _sugarContext == ctx;
    return InkWell(
      onTap: () => setState(() => _sugarContext = ctx),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.red.shade400 : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.red.shade900 : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildEvidenceManagementSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.attach_file, size: 16, color: Colors.teal),
              SizedBox(width: 6),
              Text(
                'Attachments (Documents & Proof)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Existing attachments are kept untouched unless explicitly removed.',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 8),

          // Existing attachments list
          if (_activeExistingEvidence.isNotEmpty) ...[
            const Text('Current Attachments:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ..._activeExistingEvidence.map((ev) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(ev.isPdf ? Icons.picture_as_pdf : Icons.image, size: 16, color: Colors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ev.displayName,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, size: 16, color: Colors.blueGrey),
                      tooltip: 'View / Share',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        if (File(ev.filePath).existsSync()) {
                          // ignore: deprecated_member_use
                          Share.shareXFiles([XFile(ev.filePath)], text: ev.displayName);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.red),
                      tooltip: 'Remove',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _activeExistingEvidence.removeWhere((e) => e.id == ev.id);
                          _removeEvidenceIds.add(ev.id);
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],

          // Newly added attachments
          if (_newFilePaths.isNotEmpty) ...[
            const Text('New Files to Add:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _newFilePaths.asMap().entries.map((entry) {
                final idx = entry.key;
                final path = entry.value;
                final fileName = path.split(Platform.pathSeparator).last;
                return Chip(
                  avatar: const Icon(Icons.add_photo_alternate, size: 14, color: Colors.teal),
                  label: Text(fileName, style: const TextStyle(fontSize: 10)),
                  onDeleted: () => setState(() => _newFilePaths.removeAt(idx)),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],

          // Add Buttons
          Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.camera_alt, size: 13),
                label: const Text('+ Photo', style: TextStyle(fontSize: 11)),
                onPressed: _pickPhoto,
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.upload_file, size: 13),
                label: const Text('+ PDF / Report', style: TextStyle(fontSize: 11)),
                onPressed: _pickFile,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
