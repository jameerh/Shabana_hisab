import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../data/models/health_models.dart';
import '../../../main.dart';

class DetailedEntrySheet extends StatefulWidget {
  final int profileId;
  final List<HealthPatient> patients;
  final int? initialPatientId;
  final VoidCallback onSaved;

  const DetailedEntrySheet({
    super.key,
    required this.profileId,
    required this.patients,
    this.initialPatientId,
    required this.onSaved,
  });

  @override
  State<DetailedEntrySheet> createState() => _DetailedEntrySheetState();
}

class _DetailedEntrySheetState extends State<DetailedEntrySheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _selectedPatientId;

  DateTime _eventDate = DateTime.now();
  TimeOfDay _eventTime = TimeOfDay.now();

  // Selected files
  final List<String> _attachedFilePaths = [];

  // Blood Sugar Form
  final TextEditingController _sugarValueController = TextEditingController();
  SugarContext _sugarContext = SugarContext.afterMeal;
  String _sugarUnit = 'mg/dL';

  // Blood Pressure Form
  final TextEditingController _systolicController = TextEditingController(text: '120');
  final TextEditingController _diastolicController = TextEditingController(text: '80');
  final TextEditingController _pulseController = TextEditingController(text: '72');

  // Other Vitals Form
  HealthEventType _selectedVitalType = HealthEventType.weight;
  final TextEditingController _vitalValueController = TextEditingController();

  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    _sugarValueController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
    _vitalValueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image != null) {
      setState(() => _attachedFilePaths.add(image.path));
    }
  }

  Future<void> _pickFile() async {
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
        // 🩸 Blood Sugar
        final val = double.tryParse(_sugarValueController.text.trim());
        if (val == null || val <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid sugar reading (e.g. 128)')),
          );
          setState(() => _isSaving = false);
          return;
        }

        await healthRepository.addDetailedSugar(
          profileId: widget.profileId,
          patientId: _selectedPatientId,
          reading: val,
          context: _sugarContext,
          unit: _sugarUnit,
          eventDate: _eventDate,
          eventTime: timeStr,
          filePaths: _attachedFilePaths,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        );
      } else if (_tabController.index == 1) {
        // ❤️ Blood Pressure
        final sys = int.tryParse(_systolicController.text.trim());
        final dia = int.tryParse(_diastolicController.text.trim());
        final pulse = int.tryParse(_pulseController.text.trim());

        if (sys == null || dia == null || sys <= 0 || dia <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter valid systolic and diastolic values (e.g. 138 / 86)')),
          );
          setState(() => _isSaving = false);
          return;
        }

        await healthRepository.addDetailedBloodPressure(
          profileId: widget.profileId,
          patientId: _selectedPatientId,
          systolic: sys,
          diastolic: dia,
          pulse: pulse,
          eventDate: _eventDate,
          eventTime: timeStr,
          filePaths: _attachedFilePaths,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        );
      } else {
        // ⚖️ Other Vitals
        final val = double.tryParse(_vitalValueController.text.trim());
        if (val == null || val <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid numeric value')),
          );
          setState(() => _isSaving = false);
          return;
        }

        String unit = 'kg';
        if (_selectedVitalType == HealthEventType.temperature) unit = '°F';
        if (_selectedVitalType == HealthEventType.spo2) unit = '%';

        await healthRepository.addDetailedVital(
          profileId: widget.profileId,
          patientId: _selectedPatientId,
          eventType: _selectedVitalType,
          value: val,
          unit: unit,
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
        SnackBar(content: Text('Error saving reading: $e')),
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
                    Icon(Icons.timeline_rounded, color: Colors.teal, size: 26),
                    SizedBox(width: 8),
                    Text(
                      'Detailed Health Entry',
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

          // Date & Time Bar (Fully customizable for historical diary entries)
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
            labelColor: Colors.teal.shade800,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.teal,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.water_drop_rounded, color: Colors.teal), text: 'Blood Sugar'),
              Tab(icon: Icon(Icons.favorite_rounded, color: Colors.red), text: 'Blood Pressure'),
              Tab(icon: Icon(Icons.monitor_weight_outlined, color: Colors.indigo), text: 'Other Vitals'),
            ],
          ),
          const Divider(height: 1),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSugarTab(),
                _buildBloodPressureTab(),
                _buildVitalsTab(),
              ],
            ),
          ),

          // Bottom Action
          _buildBottomActionSection(),
        ],
      ),
    );
  }

  // 1. BLOOD SUGAR TAB
  Widget _buildSugarTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _sugarValueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal),
                decoration: const InputDecoration(
                  labelText: 'Reading Value *',
                  hintText: 'e.g. 128',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.speed_rounded, color: Colors.teal),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Center(
                  child: Text(
                    'mg/dL',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        const Text(
          'Measurement Context (When was this taken?):',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SugarContext.values.map((ctx) {
            final isSelected = _sugarContext == ctx;
            return ChoiceChip(
              label: Text('${ctx.label} (${ctx.marathiLabel})'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _sugarContext = ctx);
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
        const SizedBox(height: 18),

        _buildOptionalProofPicker('Attach Lab Report / Result (Optional)'),
      ],
    );
  }

  // 2. BLOOD PRESSURE TAB
  Widget _buildBloodPressureTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _systolicController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                decoration: const InputDecoration(
                  labelText: 'Systolic (mmHg) *',
                  hintText: '138',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.arrow_upward_rounded, color: Colors.red),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _diastolicController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                decoration: const InputDecoration(
                  labelText: 'Diastolic (mmHg) *',
                  hintText: '86',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.arrow_downward_rounded, color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _pulseController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(
            labelText: 'Pulse (bpm) - Optional',
            hintText: 'e.g. 74',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.monitor_heart_outlined, color: Colors.purple),
          ),
        ),
        const SizedBox(height: 18),

        _buildOptionalProofPicker('Attach Lab Report / Monitor Photo (Optional)'),
      ],
    );
  }

  // 3. OTHER VITALS TAB
  Widget _buildVitalsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Select Vital Type:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('⚖️ Weight (kg)'),
              selected: _selectedVitalType == HealthEventType.weight,
              onSelected: (selected) {
                if (selected) setState(() => _selectedVitalType = HealthEventType.weight);
              },
            ),
            ChoiceChip(
              label: const Text('🌡️ Temperature (°F)'),
              selected: _selectedVitalType == HealthEventType.temperature,
              onSelected: (selected) {
                if (selected) setState(() => _selectedVitalType = HealthEventType.temperature);
              },
            ),
            ChoiceChip(
              label: const Text('🫁 SpO2 (%)'),
              selected: _selectedVitalType == HealthEventType.spo2,
              onSelected: (selected) {
                if (selected) setState(() => _selectedVitalType = HealthEventType.spo2);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _vitalValueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'Enter Value *',
            hintText: _selectedVitalType == HealthEventType.weight
                ? 'e.g. 72.5'
                : (_selectedVitalType == HealthEventType.temperature ? 'e.g. 98.6' : 'e.g. 98'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 18),

        _buildOptionalProofPicker('Optional Proof Attachment'),
      ],
    );
  }

  Widget _buildOptionalProofPicker(String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('OPTIONAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Paper and home meter readings can be saved without attachments. Attach official lab report PDF or photo if available.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.camera_alt, size: 16),
                label: const Text('Camera', style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file, size: 16),
                label: const Text('File / Gallery', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          if (_attachedFilePaths.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: _attachedFilePaths.asMap().entries.map((entry) {
                return Chip(
                  label: Text(entry.value.split(Platform.pathSeparator).last, style: const TextStyle(fontSize: 10)),
                  deleteIcon: const Icon(Icons.close, size: 12),
                  onDeleted: () => setState(() => _attachedFilePaths.removeAt(entry.key)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

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
                : const Icon(Icons.check_circle_outline),
            label: Text(
              _isSaving ? 'Saving...' : 'Save Reading',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            onPressed: _isSaving ? null : _saveCurrentTab,
          ),
        ),
      ),
    );
  }
}
