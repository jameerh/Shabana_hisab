import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../data/models/health_models.dart';
import '../../../main.dart';

class QuickCaptureSheet extends StatefulWidget {
  final int profileId;
  final List<HealthPatient> patients;
  final int? initialPatientId;
  final VoidCallback onSaved;

  const QuickCaptureSheet({
    super.key,
    required this.profileId,
    required this.patients,
    this.initialPatientId,
    required this.onSaved,
  });

  @override
  State<QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends State<QuickCaptureSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _selectedPatientId;

  DateTime _eventDate = DateTime.now();
  TimeOfDay _eventTime = TimeOfDay.now();

  // Selected files
  final List<String> _attachedFilePaths = [];

  // Prescription Form State
  String _selectedPrescriptionPurpose = 'Cold / Fever';
  final TextEditingController _customPurposeController = TextEditingController();

  // Lab Report Form State
  LabReportType _selectedLabType = LabReportType.cbc;
  final TextEditingController _customLabNameController = TextEditingController();
  final TextEditingController _labResultController = TextEditingController();

  // Hospital Paper / Note State
  final TextEditingController _generalPurposeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isSaving = false;

  final List<String> _commonPurposes = [
    'Cold / Fever',
    'Cold',
    'Fever',
    'Cough',
    'Headache',
    'Body Pain',
    'Stomach Problem',
    'Infection',
    'Skin Problem',
    'Follow-up',
    'Regular Check-up',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (widget.initialPatientId != null && widget.patients.any((p) => p.id == widget.initialPatientId)) {
      _selectedPatientId = widget.initialPatientId!;
    } else if (widget.patients.isNotEmpty) {
      _selectedPatientId = widget.patients.first.id;
    } else {
      _selectedPatientId = 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customPurposeController.dispose();
    _customLabNameController.dispose();
    _labResultController.dispose();
    _generalPurposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickCameraPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image != null) {
      setState(() => _attachedFilePaths.add(image.path));
    }
  }

  Future<void> _pickGalleryPhoto() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 85);
    if (images.isNotEmpty) {
      setState(() => _attachedFilePaths.addAll(images.map((i) => i.path)));
    }
  }

  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        setState(() => _attachedFilePaths.add(result.files.first.path!));
      }
    } catch (_) {}
  }

  Future<void> _saveCurrentTab() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final timeStr = _eventTime.format(context);

    try {
      if (_tabController.index == 0) {
        // 💊 Prescription
        final purpose = _selectedPrescriptionPurpose == 'Other'
            ? (_customPurposeController.text.trim().isNotEmpty ? _customPurposeController.text.trim() : 'Prescription')
            : _selectedPrescriptionPurpose;

        await healthRepository.addQuickPrescription(
          profileId: widget.profileId,
          patientId: _selectedPatientId,
          purpose: purpose,
          eventDate: _eventDate,
          eventTime: timeStr,
          filePaths: _attachedFilePaths,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        );
      } else if (_tabController.index == 1) {
        // 📄 Lab Report
        final customName = _selectedLabType == LabReportType.other
            ? (_customLabNameController.text.trim().isNotEmpty ? _customLabNameController.text.trim() : 'Lab Report')
            : null;

        await healthRepository.addQuickLabReport(
          profileId: widget.profileId,
          patientId: _selectedPatientId,
          reportType: _selectedLabType,
          customReportName: customName,
          resultSummary: _labResultController.text.trim().isNotEmpty ? _labResultController.text.trim() : null,
          eventDate: _eventDate,
          eventTime: timeStr,
          filePaths: _attachedFilePaths,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        );
      } else if (_tabController.index == 2) {
        // 🏥 Hospital Paper
        final purpose = _generalPurposeController.text.trim().isNotEmpty
            ? _generalPurposeController.text.trim()
            : 'Hospital Paper';

        await healthRepository.addQuickDocument(
          profileId: widget.profileId,
          patientId: _selectedPatientId,
          eventType: HealthEventType.hospitalVisit,
          purpose: purpose,
          eventDate: _eventDate,
          eventTime: timeStr,
          filePaths: _attachedFilePaths,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        );
      } else {
        // 📝 Health Note
        final purpose = _generalPurposeController.text.trim().isNotEmpty
            ? _generalPurposeController.text.trim()
            : 'Health Note';

        await healthRepository.addQuickDocument(
          profileId: widget.profileId,
          patientId: _selectedPatientId,
          eventType: HealthEventType.healthNote,
          purpose: purpose,
          eventDate: _eventDate,
          eventTime: timeStr,
          filePaths: _attachedFilePaths,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        );
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Colors.amber, size: 26),
                    SizedBox(width: 8),
                    Text(
                      'Quick Capture',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Patient Selector Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Text('Patient: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedPatientId,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.teal),
                        items: widget.patients.map((p) {
                          final relStr = p.relationship?.isNotEmpty == true ? ' (${p.relationship})' : '';
                          return DropdownMenuItem<int>(
                            value: p.id,
                            child: Text(
                              '${p.name}$relStr',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.teal),
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
          ),

          // Date & Time Bar (Auto today/now, editable)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _eventDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _eventDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM yyyy').format(_eventDate),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _eventTime,
                      );
                      if (picked != null) setState(() => _eventTime = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            _eventTime.format(context),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.teal.shade800,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.teal,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.medication_liquid_rounded), text: 'Prescription'),
              Tab(icon: Icon(Icons.assignment_outlined), text: 'Lab Report'),
              Tab(icon: Icon(Icons.local_hospital_outlined), text: 'Hospital Paper'),
              Tab(icon: Icon(Icons.note_alt_outlined), text: 'Health Note'),
            ],
          ),
          const Divider(height: 1),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPrescriptionTab(),
                _buildLabReportTab(),
                _buildHospitalPaperTab(),
                _buildHealthNoteTab(),
              ],
            ),
          ),

          // Common Attachment Bar & Instant Save Action
          _buildBottomActionSection(),
        ],
      ),
    );
  }

  // 1. PRESCRIPTION TAB
  Widget _buildPrescriptionTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Select Purpose (What was this for?):',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _commonPurposes.map((p) {
            final isSelected = _selectedPrescriptionPurpose == p;
            return ChoiceChip(
              label: Text(p),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedPrescriptionPurpose = p);
              },
              selectedColor: Colors.teal.shade100,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.teal.shade900 : Colors.black87,
              ),
            );
          }).toList(),
        ),
        if (_selectedPrescriptionPurpose == 'Other') ...[
          const SizedBox(height: 10),
          TextField(
            controller: _customPurposeController,
            decoration: const InputDecoration(
              hintText: 'e.g. fever since yesterday, knee pain...',
              labelText: 'Write Purpose / Symptoms',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildAttachmentPickerBox('Prescription Photo / PDF'),
      ],
    );
  }

  // 2. LAB REPORT TAB
  Widget _buildLabReportTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Select Report Type:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LabReportType.values.map((t) {
            final isSelected = _selectedLabType == t;
            return ChoiceChip(
              label: Text('${t.emoji} ${t.name}'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedLabType = t);
              },
              selectedColor: Colors.amber.shade100,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.brown.shade900 : Colors.black87,
              ),
            );
          }).toList(),
        ),
        if (_selectedLabType == LabReportType.other) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _customLabNameController,
            decoration: const InputDecoration(
              hintText: 'e.g. Vitamin D, Calcium, Allergy test...',
              labelText: 'Type Report Name',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
        const SizedBox(height: 14),
        TextField(
          controller: _labResultController,
          decoration: const InputDecoration(
            labelText: 'Result (Optional)',
            hintText: 'e.g. Positive / Negative / Normal (Optional)',
            border: OutlineInputBorder(),
            isDense: true,
            prefixIcon: Icon(Icons.check_circle_outline, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        _buildAttachmentPickerBox('Lab Report Photo or PDF'),
      ],
    );
  }

  // 3. HOSPITAL PAPER TAB
  Widget _buildHospitalPaperTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _generalPurposeController,
          decoration: const InputDecoration(
            labelText: 'Description / Purpose',
            hintText: 'e.g. Emergency visit, Discharge summary, OPD slip',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _buildAttachmentPickerBox('Hospital Paper / Slip Photo or PDF'),
      ],
    );
  }

  // 4. HEALTH NOTE TAB
  Widget _buildHealthNoteTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _generalPurposeController,
          decoration: const InputDecoration(
            labelText: 'Title / Subject',
            hintText: 'e.g. Doctor advice, Diet instructions, BP note',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Note Content',
            hintText: 'Write doctor advice or health observations...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _buildAttachmentPickerBox('Optional Supporting Photo'),
      ],
    );
  }

  // ATTACHMENT BOX
  Widget _buildAttachmentPickerBox(String promptLabel) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                promptLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
              ),
              if (_attachedFilePaths.isNotEmpty)
                Text(
                  '${_attachedFilePaths.length} attached',
                  style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Action Buttons: Camera, Gallery, PDF
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal.shade900,
                    side: BorderSide(color: Colors.teal.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: _pickCameraPhoto,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Camera', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo.shade900,
                    side: BorderSide(color: Colors.indigo.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: _pickGalleryPhoto,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Gallery', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade900,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: _pickPdfFile,
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('PDF', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),

          // File List Preview
          if (_attachedFilePaths.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _attachedFilePaths.asMap().entries.map((entry) {
                final idx = entry.key;
                final path = entry.value;
                final isPdf = path.toLowerCase().endsWith('.pdf');
                return Chip(
                  avatar: Icon(isPdf ? Icons.picture_as_pdf : Icons.image, size: 16, color: isPdf ? Colors.red : Colors.teal),
                  label: Text(
                    path.split(Platform.pathSeparator).last,
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    setState(() => _attachedFilePaths.removeAt(idx));
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // BOTTOM ACTION
  Widget _buildBottomActionSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_rounded),
            label: Text(
              _isSaving ? 'Saving...' : 'Save Health Record',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            onPressed: _isSaving ? null : _saveCurrentTab,
          ),
        ),
      ),
    );
  }
}
