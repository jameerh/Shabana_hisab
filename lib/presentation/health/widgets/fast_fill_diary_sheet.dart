import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../data/models/health_models.dart';
import '../../../main.dart';
import '../dialogs/edit_health_event_dialog.dart';

class FastFillDiarySheet extends StatefulWidget {
  final int profileId;
  final List<HealthPatient> patients;
  final int? initialPatientId;
  final HealthEventType initialType;
  final DateTime? initialDate;
  final VoidCallback onSaved;

  const FastFillDiarySheet({
    super.key,
    required this.profileId,
    required this.patients,
    this.initialPatientId,
    this.initialType = HealthEventType.sugar,
    this.initialDate,
    required this.onSaved,
  });

  /// Retained diary date across modal closures in the same app session
  static DateTime? get retainedDiaryDate => _FastFillDiarySheetState._retainedDiaryDate;
  static set retainedDiaryDate(DateTime? val) => _FastFillDiarySheetState._retainedDiaryDate = val;

  @override
  State<FastFillDiarySheet> createState() => _FastFillDiarySheetState();
}

class _FastFillDiarySheetState extends State<FastFillDiarySheet> {
  late HealthEventType _selectedType;
  late int _selectedPatientId;

  // Retained diary date across modal closures in the same app session
  static DateTime? _retainedDiaryDate;

  // Date and Time (strictly calendar date, separated from measurement time)
  DateTime _entryDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  TimeOfDay _entryTime = const TimeOfDay(hour: 8, minute: 0);

  // Sugar State
  final TextEditingController _sugarValueController = TextEditingController();
  final FocusNode _sugarFocusNode = FocusNode();
  SugarContext _sugarContext = SugarContext.fasting;

  // Blood Pressure State
  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final TextEditingController _pulseController = TextEditingController();
  final FocusNode _systolicFocusNode = FocusNode();

  // Optional Attachments (Lab Report / Diary Page Photo)
  final List<String> _attachedFilePaths = [];

  // Notes (optional)
  final TextEditingController _notesController = TextEditingController();

  // Session Log: Keeps track of entries added in this session
  final List<_SessionEntryItem> _sessionEntries = [];

  // Existing records for the active diary date & patient
  List<HealthEvent> _existingDateRecords = [];
  bool _isLoadingDateRecords = false;

  bool _isSaving = false;
  String? _lastFeedbackMessage;

  @override
  void initState() {
    super.initState();
    _selectedType = (widget.initialType == HealthEventType.bloodPressure)
        ? HealthEventType.bloodPressure
        : HealthEventType.sugar;

    if (widget.initialPatientId != null &&
        widget.patients.any((p) => p.id == widget.initialPatientId)) {
      _selectedPatientId = widget.initialPatientId!;
    } else if (widget.patients.isNotEmpty) {
      _selectedPatientId = widget.patients.first.id;
    } else {
      _selectedPatientId = 1;
    }

    // Initialize diary date with strict calendar-date preservation
    if (widget.initialDate != null) {
      _entryDate = parseDateOnly(widget.initialDate!);
    } else if (_retainedDiaryDate != null) {
      _entryDate = parseDateOnly(_retainedDiaryDate!);
    } else {
      final now = DateTime.now();
      _entryDate = DateTime(now.year, now.month, now.day);
    }
    _retainedDiaryDate = _entryDate;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadExistingDateRecords();
    });
  }

  @override
  void dispose() {
    _sugarValueController.dispose();
    _sugarFocusNode.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
    _systolicFocusNode.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ==========================================
  // DATE STEPPING & SELECTION (CALENDAR DATE ARITHMETIC)
  // ==========================================

  void _stepDate(int days) {
    setState(() {
      _entryDate = addCalendarDays(_entryDate, days);
      _retainedDiaryDate = _entryDate;
      _lastFeedbackMessage = null;
    });
    _loadExistingDateRecords();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'SELECT DIARY RECORD DATE',
    );
    if (picked != null) {
      setState(() {
        _entryDate = parseDateOnly(picked);
        _retainedDiaryDate = _entryDate;
        _lastFeedbackMessage = null;
      });
      _loadExistingDateRecords();
    }
  }

  Future<void> _loadExistingDateRecords() async {
    if (!mounted) return;
    setState(() => _isLoadingDateRecords = true);
    try {
      final records = await healthRepository.getEventsByDate(
        widget.profileId,
        _entryDate,
        patientId: _selectedPatientId,
      );
      if (mounted) {
        setState(() {
          _existingDateRecords = records;
          _isLoadingDateRecords = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingDateRecords = false);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _entryTime,
      helpText: 'SELECT TIME (OPTIONAL)',
    );
    if (picked != null) {
      setState(() {
        _entryTime = picked;
        _lastFeedbackMessage = null;
      });
    }
  }

  void _setPresetTime(int hour, int minute) {
    setState(() {
      _entryTime = TimeOfDay(hour: hour, minute: minute);
      _lastFeedbackMessage = null;
    });
  }

  // ==========================================
  // OPTIONAL EVIDENCE PICKERS
  // ==========================================

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

  // ==========================================
  // SAVE & ADD NEXT (FAST CONTINUOUS LOGGING)
  // ==========================================

  Future<void> _saveRecord({bool closeAfter = false}) async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _lastFeedbackMessage = null;
    });

    final timeStr = _entryTime.format(context);
    final dateStr = DateFormat('dd MMM yyyy').format(_entryDate);

    try {
      int? newEventId;
      String summary = '';

      if (_selectedType == HealthEventType.sugar) {
        final val = double.tryParse(_sugarValueController.text.trim());
        if (val == null || val <= 0) {
          _showError('Please enter a valid sugar reading (e.g. 118)');
          setState(() => _isSaving = false);
          return;
        }

        newEventId = await healthRepository.addDetailedSugar(
          profileId: widget.profileId,
          patientId: _selectedPatientId,
          reading: val,
          context: _sugarContext,
          eventDate: _entryDate,
          eventTime: timeStr,
          filePaths: List<String>.from(_attachedFilePaths),
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );

        summary = 'Sugar: ${val.toStringAsFixed(0)} mg/dL (${_sugarContext.label})';
      } else {
        final sys = int.tryParse(_systolicController.text.trim());
        final dia = int.tryParse(_diastolicController.text.trim());
        final pulse = int.tryParse(_pulseController.text.trim());

        if (sys == null || dia == null || sys <= 0 || dia <= 0) {
          _showError('Please enter valid systolic & diastolic BP (e.g. 120 / 80)');
          setState(() => _isSaving = false);
          return;
        }

        newEventId = await healthRepository.addDetailedBloodPressure(
          profileId: widget.profileId,
          patientId: _selectedPatientId,
          systolic: sys,
          diastolic: dia,
          pulse: pulse,
          eventDate: _entryDate,
          eventTime: timeStr,
          filePaths: List<String>.from(_attachedFilePaths),
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );

        summary = 'BP: $sys/$dia mmHg${pulse != null ? ' (Pulse: $pulse)' : ''}';
      }

      // Notify parent to refresh timeline/charts
      widget.onSaved();

      // Record in session list
      if (newEventId > 0) {
        _sessionEntries.insert(
          0,
          _SessionEntryItem(
            eventId: newEventId,
            summary: summary,
            dateStr: dateStr,
            timeStr: timeStr,
            hasEvidence: _attachedFilePaths.isNotEmpty,
          ),
        );
      }

      // Refresh existing records on this date
      _loadExistingDateRecords();

      HapticFeedback.lightImpact();

      if (closeAfter) {
        if (mounted) Navigator.pop(context);
        return;
      }

      // Keep date unchanged, clear value field, clear optional attachments
      setState(() {
        _isSaving = false;
        _sugarValueController.clear();
        _systolicController.clear();
        _diastolicController.clear();
        _pulseController.clear();
        _attachedFilePaths.clear();
        _notesController.clear();
        _lastFeedbackMessage = '✅ Saved: $summary for $dateStr';
      });

      // Request focus for immediate next entry
      if (_selectedType == HealthEventType.sugar) {
        _sugarFocusNode.requestFocus();
      } else {
        _systolicFocusNode.requestFocus();
      }
    } catch (e) {
      _showError('Failed to save record: $e');
      setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade800),
    );
  }

  String _getEventSummary(HealthEvent ev) {
    if (ev.eventType == HealthEventType.sugar) {
      final s = ev.sugarData;
      if (s == null) return 'Sugar: - mg/dL';
      final valStr = s.value % 1 == 0 ? s.value.toStringAsFixed(0) : s.value.toStringAsFixed(1);
      return 'Sugar: $valStr mg/dL (${s.context.label})';
    } else if (ev.eventType == HealthEventType.bloodPressure) {
      final bp = ev.bpData;
      return 'BP: ${bp?.systolic ?? "-"}/${bp?.diastolic ?? "-"} mmHg${bp?.pulse != null ? ' (Pulse: ${bp!.pulse})' : ''}';
    }
    return ev.purpose;
  }

  Future<void> _openEditSessionEntry(int index) async {
    final item = _sessionEntries[index];
    final ev = await healthRepository.getEventById(item.eventId);
    if (ev == null) {
      _showError('Record not found in database');
      return;
    }
    await _showEditDialog(ev, sessionIndex: index);
  }

  Future<void> _openEditExistingEntry(HealthEvent ev) async {
    await _showEditDialog(ev);
  }

  Future<void> _showEditDialog(HealthEvent ev, {int? sessionIndex}) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => EditHealthEventDialog(
        event: ev,
        patients: widget.patients,
        onUpdated: () {},
      ),
    );

    if (updated == true) {
      widget.onSaved();
      await _loadExistingDateRecords();

      final refreshed = await healthRepository.getEventById(ev.id);
      if (refreshed != null && mounted) {
        final summary = _getEventSummary(refreshed);
        final dateStr = DateFormat('dd MMM yyyy').format(refreshed.eventDate);
        if (sessionIndex != null && sessionIndex < _sessionEntries.length) {
          setState(() {
            _sessionEntries[sessionIndex] = _SessionEntryItem(
              eventId: refreshed.id,
              summary: summary,
              dateStr: dateStr,
              timeStr: refreshed.eventTime,
              hasEvidence: refreshed.hasEvidence,
            );
          });
        }
        setState(() {
          _lastFeedbackMessage = '✅ Updated: $summary for $dateStr';
        });
      }
    }
  }

  Future<void> _confirmAndDeleteSessionEntry(int index) async {
    final item = _sessionEntries[index];
    await _confirmAndDeleteEvent(item.eventId, item.summary, item.dateStr, sessionIndex: index);
  }

  Future<void> _confirmAndDeleteExistingEntry(HealthEvent ev) async {
    final summary = _getEventSummary(ev);
    final dateStr = DateFormat('dd MMM yyyy').format(ev.eventDate);
    await _confirmAndDeleteEvent(ev.id, summary, dateStr);
  }

  Future<void> _confirmAndDeleteEvent(int eventId, String summary, String dateStr, {int? sessionIndex}) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Health Record?'),
        content: Text('Are you sure you want to delete this record?\n\n$summary ($dateStr)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await healthRepository.deleteEvent(eventId);
      widget.onSaved();
      if (mounted) {
        setState(() {
          if (sessionIndex != null && sessionIndex < _sessionEntries.length) {
            _sessionEntries.removeAt(sessionIndex);
          }
          _lastFeedbackMessage = '🗑️ Deleted record: $summary';
        });
      }
      await _loadExistingDateRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // HEADER BAR
            _buildHeader(),
            const Divider(height: 1),

            // MAIN SCROLLABLE BODY
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // MODE SELECTOR (SUGAR vs BP)
                  _buildTypeSelector(),
                  const SizedBox(height: 14),

                  // PATIENT SELECTOR
                  _buildPatientRow(),
                  const SizedBox(height: 14),

                  // DATE STEPPER BAR
                  _buildDateStepper(),
                  const SizedBox(height: 12),

                  // TIME ROW & PRESETS
                  _buildTimeRow(),
                  const SizedBox(height: 16),

                  // INPUT FORM (SUGAR OR BP)
                  if (_selectedType == HealthEventType.sugar)
                    _buildSugarInputSection()
                  else
                    _buildBpInputSection(),

                  const SizedBox(height: 14),

                  // OPTIONAL EVIDENCE / ATTACHMENT SECTION
                  _buildOptionalAttachmentSection(),
                  const SizedBox(height: 14),

                  if (_lastFeedbackMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Text(
                        _lastFeedbackMessage!,
                        style: TextStyle(
                          color: Colors.teal.shade900,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ALREADY RECORDED ON SELECTED DATE
                  _buildExistingDateRecordsSection(),
                  const SizedBox(height: 18),

                  // LIVE SESSION LOG (Entries added in this session)
                  _buildSessionLogSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // PINNED ACTION BAR AT BOTTOM
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    offset: const Offset(0, -2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: _buildActionButtons(),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET BUILDERS
  // ==========================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: const Text('⚡', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paper Diary Fast Fill',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(
                  'फास्ट डायरी एन्ट्री • Enter old written records rapidly',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                _selectedType = HealthEventType.sugar;
                _lastFeedbackMessage = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _selectedType == HealthEventType.sugar
                    ? Colors.red.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _selectedType == HealthEventType.sugar
                      ? Colors.red.shade400
                      : Colors.grey.shade300,
                  width: _selectedType == HealthEventType.sugar ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🩸', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'Blood Sugar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _selectedType == HealthEventType.sugar
                          ? Colors.red.shade900
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                _selectedType = HealthEventType.bloodPressure;
                _lastFeedbackMessage = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _selectedType == HealthEventType.bloodPressure
                    ? Colors.indigo.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _selectedType == HealthEventType.bloodPressure
                      ? Colors.indigo.shade400
                      : Colors.grey.shade300,
                  width: _selectedType == HealthEventType.bloodPressure ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('❤️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'Blood Pressure',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _selectedType == HealthEventType.bloodPressure
                          ? Colors.indigo.shade900
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientRow() {
    return Row(
      children: [
        const Text(
          'Patient: ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
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
                  if (val != null) {
                    setState(() => _selectedPatientId = val);
                    _loadExistingDateRecords();
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateStepper() {
    final formattedDate = DateFormat('EEE, dd MMM yyyy').format(_entryDate);
    final isToday = DateUtils.isSameDay(_entryDate, DateTime.now());

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.teal.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DIARY DATE (Stays fixed between entries)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.teal,
                ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('TODAY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                )
              else
                InkWell(
                  onTap: () {
                    final now = DateTime.now();
                    setState(() {
                      _entryDate = DateTime(now.year, now.month, now.day);
                      _retainedDiaryDate = _entryDate;
                      _lastFeedbackMessage = null;
                    });
                    _loadExistingDateRecords();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.teal.shade300),
                    ),
                    child: const Text('RESET TO TODAY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.teal)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Step Back 1 Day
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _stepDate(-1),
                child: const Text('◀ -1 Day', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),

              // Date Display & Picker
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.teal),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Step Forward 1 Day
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _stepDate(1),
                child: const Text('+1 Day ▶', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow() {
    final timeStr = _entryTime.format(context);

    return Row(
      children: [
        const Text(
          'Time: ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: _pickTime,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTimePresetChip('🌅 8:00 AM', 8, 0),
                const SizedBox(width: 4),
                _buildTimePresetChip('🍽️ 1:30 PM', 13, 30),
                const SizedBox(width: 4),
                _buildTimePresetChip('🌙 8:30 PM', 20, 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePresetChip(String label, int hour, int minute) {
    final isSelected = _entryTime.hour == hour && _entryTime.minute == minute;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      selectedColor: Colors.teal.shade100,
      onSelected: (_) => _setPresetTime(hour, minute),
    );
  }

  // ==========================================
  // SUGAR INPUT
  // ==========================================

  Widget _buildSugarInputSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MEAL CONTEXT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSugarContextChip(
                  SugarContext.fasting,
                  '🌅 Fasting\n(उपाशीपोटी)',
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildSugarContextChip(
                  SugarContext.afterMeal,
                  '🍽️ Post-Meal\n(जेवणानंतर)',
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildSugarContextChip(
                  SugarContext.random,
                  '🎲 Random\n(कधीही)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Sugar Reading Input
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _sugarValueController,
                  focusNode: _sugarFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Sugar Value (रक्तातील साखर)',
                    hintText: 'e.g. 110',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    suffixText: 'mg/dL',
                    suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  onSubmitted: (_) => _saveRecord(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSugarContextChip(SugarContext contextValue, String label) {
    final isSelected = _sugarContext == contextValue;
    return InkWell(
      onTap: () => setState(() => _sugarContext = contextValue),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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

  // ==========================================
  // BP INPUT
  // ==========================================

  Widget _buildBpInputSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BLOOD PRESSURE READINGS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _systolicController,
                  focusNode: _systolicFocusNode,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Systolic',
                    hintText: '120',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('/', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              Expanded(
                child: TextField(
                  controller: _diastolicController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Diastolic',
                    hintText: '80',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _pulseController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Pulse (bpm)',
                    hintText: '72',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // OPTIONAL ATTACHMENTS (LAB REPORT / PAPER)
  // ==========================================

  Widget _buildOptionalAttachmentSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.attach_file, size: 16, color: Colors.teal),
                  SizedBox(width: 4),
                  Text(
                    'Attach Lab Report / Paper Photo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
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
            'Paper records can be saved without attachments. Attach official lab report PDF or photo if available.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.camera_alt, size: 14),
                label: const Text('Photo / Diary Page', style: TextStyle(fontSize: 11)),
                onPressed: _pickPhoto,
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.upload_file, size: 14),
                label: const Text('Lab PDF / Report', style: TextStyle(fontSize: 11)),
                onPressed: _pickFile,
              ),
            ],
          ),
          if (_attachedFilePaths.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _attachedFilePaths.asMap().entries.map((entry) {
                final idx = entry.key;
                final path = entry.value;
                final fileName = path.split(Platform.pathSeparator).last;
                return Chip(
                  avatar: Icon(
                    path.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf : Icons.image,
                    size: 14,
                    color: Colors.teal,
                  ),
                  label: Text(fileName, style: const TextStyle(fontSize: 11)),
                  onDeleted: () => setState(() => _attachedFilePaths.removeAt(idx)),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // ACTION BUTTONS
  // ==========================================

  Widget _buildActionButtons() {
    return Row(
      children: [
        // SAVE & ADD NEXT (PRIMARY CONTINUOUS BUTTON)
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.add_task, size: 18),
            label: Text(
              _isSaving ? 'Saving...' : '💾 Save & Add Next',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            onPressed: _isSaving ? null : () => _saveRecord(closeAfter: false),
          ),
        ),
        const SizedBox(width: 10),

        // FINISH / DONE BUTTON
        Expanded(
          flex: 2,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              _sessionEntries.isEmpty ? 'Close' : 'Done (${_sessionEntries.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // EXISTING RECORDS ON SELECTED DATE (ALREADY RECORDED)
  // ==========================================

  Widget _buildExistingDateRecordsSection() {
    final dateDisplay = DateFormat('dd MMM yyyy').format(_entryDate);
    final priorRecords = _existingDateRecords
        .where((ev) => !_sessionEntries.any((s) => s.eventId == ev.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ALREADY RECORDED ($dateDisplay)',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
                letterSpacing: 0.5,
              ),
            ),
            if (_isLoadingDateRecords)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              )
            else
              Text(
                '${priorRecords.length} recorded',
                style: TextStyle(fontSize: 11, color: Colors.teal.shade800, fontWeight: FontWeight.w600),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (priorRecords.isEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.event_available, size: 15, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No prior records on $dateDisplay. Rapidly enter handwritten log entries above.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blueGrey.shade100),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: priorRecords.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, idx) {
                final ev = priorRecords[idx];
                final summary = _getEventSummary(ev);
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  leading: Text(ev.eventType.emoji, style: const TextStyle(fontSize: 18)),
                  title: Text(summary, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Row(
                    children: [
                      Text(ev.eventTime, style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: ev.hasEvidence ? Colors.green.shade50 : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          ev.hasEvidence ? '🟢 Document Attached' : '🟡 Manual',
                          style: TextStyle(
                            fontSize: 9,
                            color: ev.hasEvidence ? Colors.green.shade900 : Colors.amber.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.teal),
                        tooltip: 'Edit Record',
                        onPressed: () => _openEditExistingEntry(ev),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        tooltip: 'Delete Record',
                        onPressed: () => _confirmAndDeleteExistingEntry(ev),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ==========================================
  // LIVE SESSION LOG (ENTRIES ADDED SO FAR)
  // ==========================================

  Widget _buildSessionLogSection() {
    if (_sessionEntries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Records added during this session will appear here with instant edit & undo.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SESSION LOG (${_sessionEntries.length} RECORDS ADDED)',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Live digital ledger',
              style: TextStyle(fontSize: 11, color: Colors.teal.shade800, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sessionEntries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, idx) {
              final item = _sessionEntries[idx];
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.teal.shade100,
                  child: Text('${_sessionEntries.length - idx}',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                ),
                title: Text(item.summary, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Row(
                  children: [
                    Text('${item.dateStr} • ${item.timeStr}', style: const TextStyle(fontSize: 11)),
                    if (item.hasEvidence) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text('📎 Attached', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.teal),
                      tooltip: 'Edit Record',
                      onPressed: () => _openEditSessionEntry(idx),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      tooltip: 'Delete Record',
                      onPressed: () => _confirmAndDeleteSessionEntry(idx),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SessionEntryItem {
  final int eventId;
  final String summary;
  final String dateStr;
  final String timeStr;
  final bool hasEvidence;

  _SessionEntryItem({
    required this.eventId,
    required this.summary,
    required this.dateStr,
    required this.timeStr,
    required this.hasEvidence,
  });
}
