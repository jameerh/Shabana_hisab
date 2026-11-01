import 'package:flutter/material.dart';
import '../../data/models/health_models.dart';
import '../../main.dart';
import '../../core/localization/bilingual_text.dart';
import 'widgets/patient_selector.dart';
import 'widgets/health_timeline.dart';
import 'widgets/health_document_gallery.dart';
import 'widgets/health_chart_view.dart';
import 'widgets/quick_capture_sheet.dart';
import 'widgets/detailed_entry_sheet.dart';
import 'widgets/fast_fill_diary_sheet.dart';
import 'doctor_view.dart';

class HealthHomeView extends StatefulWidget {
  final int profileId;

  const HealthHomeView({super.key, required this.profileId});

  @override
  State<HealthHomeView> createState() => _HealthHomeViewState();
}

class _HealthHomeViewState extends State<HealthHomeView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<HealthPatient> _patients = [];
  List<HealthEvent> _events = [];
  int? _selectedPatientId; // null means 'All Family'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final patients = await healthRepository.getPatients(widget.profileId);
    final events = await healthRepository.getEvents(
      widget.profileId,
      patientId: _selectedPatientId,
    );

    if (mounted) {
      setState(() {
        _patients = patients;
        _events = events;
        _isLoading = false;
      });
    }
  }

  void _showAddRecordOptionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Health Record',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Option 1: Quick Capture
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.amber.shade200),
                ),
                color: Colors.amber.shade50.withOpacity(0.5),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.amber.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.bolt_rounded, color: Colors.amber, size: 26),
                  ),
                  title: const Text('Quick Capture', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: const Text('Preserve proof in 5-10s. Prescription, Lab report, Hospital paper.', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openQuickCaptureSheet();
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Option 2: Detailed Health Entry
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.teal.shade200),
                ),
                color: Colors.teal.shade50.withOpacity(0.5),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.teal.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.timeline_rounded, color: Colors.teal, size: 26),
                  ),
                  title: const Text('Detailed Health Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: const Text('Track structured readings: Blood Sugar, BP, Weight, Vitals.', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openDetailedEntrySheet();
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Option 3: Paper Diary Fast Fill
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.indigo.shade200),
                ),
                color: Colors.indigo.shade50.withOpacity(0.5),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.indigo.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.flash_on_rounded, color: Colors.indigo, size: 26),
                  ),
                  title: const Text('Paper Diary Fast Fill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: const Text('Rapidly log old handwritten paper records (Sugar & BP). Attachments optional.', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openFastFillDiarySheet();
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _openQuickCaptureSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickCaptureSheet(
        profileId: widget.profileId,
        patients: _patients,
        initialPatientId: _selectedPatientId,
        onSaved: _loadData,
      ),
    );
  }

  void _openDetailedEntrySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DetailedEntrySheet(
        profileId: widget.profileId,
        patients: _patients,
        initialPatientId: _selectedPatientId,
        onSaved: _loadData,
      ),
    );
  }

  void _openFastFillDiarySheet({HealthEventType initialType = HealthEventType.sugar}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FastFillDiarySheet(
        profileId: widget.profileId,
        patients: _patients,
        initialPatientId: _selectedPatientId,
        initialType: initialType,
        onSaved: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientMap = {for (var p in _patients) p.id: p};
    final eventsWithEvidence = _events.where((e) => e.hasEvidence).toList();

    return Scaffold(
      appBar: AppBar(
        title: BilingualText(
          english: 'Health Hisaab',
          marathi: 'आरोग्य हिशोब',
          languageController: languageController,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        actions: [
          // Doctor View Mode Button
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.teal.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Text('👨‍⚕️', style: TextStyle(fontSize: 16)),
            label: const Text(
              'Doctor View',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorView(
                    profileId: widget.profileId,
                    patients: _patients,
                    initialPatientId: _selectedPatientId,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.view_timeline_rounded), text: 'Timeline'),
            Tab(icon: Icon(Icons.photo_library_rounded), text: 'Documents'),
            Tab(icon: Icon(Icons.analytics_rounded), text: 'Analysis'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Patient Selector Bar
                PatientSelector(
                  patients: _patients,
                  selectedPatientId: _selectedPatientId,
                  onPatientSelected: (id) {
                    setState(() => _selectedPatientId = id);
                    _loadData();
                  },
                  onPatientListUpdated: _loadData,
                  profileId: widget.profileId,
                ),

                // Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Timeline
                      HealthTimeline(
                        events: _events,
                        patientMap: patientMap,
                        onRefresh: _loadData,
                        onAddPressed: _showAddRecordOptionsSheet,
                      ),

                      // Tab 2: Documents Gallery
                      HealthDocumentGallery(
                        eventsWithEvidence: eventsWithEvidence,
                        patientMap: patientMap,
                        onRefresh: _loadData,
                      ),

                      // Tab 3: Analysis & Charts
                      HealthChartView(
                        events: _events,
                        onOpenFastFill: (type) => _openFastFillDiarySheet(initialType: type),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Health Record', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _showAddRecordOptionsSheet,
      ),
    );
  }
}
