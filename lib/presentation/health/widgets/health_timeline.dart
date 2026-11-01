import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/health_models.dart';
import '../../../main.dart';
import 'health_event_card.dart';
import '../dialogs/health_event_detail_dialog.dart';
import '../dialogs/edit_health_event_dialog.dart';

class HealthTimeline extends StatefulWidget {
  final List<HealthEvent> events;
  final Map<int, HealthPatient> patientMap;
  final VoidCallback onRefresh;
  final VoidCallback onAddPressed;

  const HealthTimeline({
    super.key,
    required this.events,
    required this.patientMap,
    required this.onRefresh,
    required this.onAddPressed,
  });

  @override
  State<HealthTimeline> createState() => _HealthTimelineState();
}

class _HealthTimelineState extends State<HealthTimeline> {
  String _searchQuery = '';
  HealthEventType? _selectedTypeFilter;
  HealthEvidenceStatus? _selectedEvidenceFilter;

  @override
  Widget build(BuildContext context) {
    // Apply filters
    var filtered = widget.events.where((e) {
      if (_selectedTypeFilter != null && e.eventType != _selectedTypeFilter) {
        return false;
      }
      if (_selectedEvidenceFilter != null && e.evidenceStatus != _selectedEvidenceFilter) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final pName = widget.patientMap[e.patientId]?.name.toLowerCase() ?? '';
        final matchesPurpose = e.purpose.toLowerCase().contains(query);
        final matchesNotes = e.notes?.toLowerCase().contains(query) ?? false;
        final matchesReport = e.reportType?.toLowerCase().contains(query) ?? false;
        final matchesPatient = pName.contains(query);
        return matchesPurpose || matchesNotes || matchesReport || matchesPatient;
      }
      return true;
    }).toList();

    // Group by date (Date -> List<HealthEvent>)
    final Map<String, List<HealthEvent>> grouped = {};
    for (final e in filtered) {
      final key = DateFormat('dd MMM yyyy').format(e.eventDate);
      grouped.putIfAbsent(key, () => []).add(e);
    }

    return Column(
      children: [
        // Search & Filter Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              // Search Input
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search purpose, medicines, report, fever...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 8),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All Records'),
                      selected: _selectedTypeFilter == null && _selectedEvidenceFilter == null,
                      onSelected: (_) {
                        setState(() {
                          _selectedTypeFilter = null;
                          _selectedEvidenceFilter = null;
                        });
                      },
                      selectedColor: Colors.teal.shade100,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('💊 Prescriptions'),
                      selected: _selectedTypeFilter == HealthEventType.prescription,
                      onSelected: (selected) {
                        setState(() => _selectedTypeFilter = selected ? HealthEventType.prescription : null);
                      },
                      selectedColor: Colors.purple.shade100,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('📄 Lab Reports'),
                      selected: _selectedTypeFilter == HealthEventType.labReport,
                      onSelected: (selected) {
                        setState(() => _selectedTypeFilter = selected ? HealthEventType.labReport : null);
                      },
                      selectedColor: Colors.amber.shade100,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('🩸 Sugar'),
                      selected: _selectedTypeFilter == HealthEventType.sugar,
                      onSelected: (selected) {
                        setState(() => _selectedTypeFilter = selected ? HealthEventType.sugar : null);
                      },
                      selectedColor: Colors.teal.shade100,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('❤️ BP'),
                      selected: _selectedTypeFilter == HealthEventType.bloodPressure,
                      onSelected: (selected) {
                        setState(() => _selectedTypeFilter = selected ? HealthEventType.bloodPressure : null);
                      },
                      selectedColor: Colors.red.shade100,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('🟢 Docs Attached'),
                      selected: _selectedEvidenceFilter == HealthEvidenceStatus.attached,
                      onSelected: (selected) {
                        setState(() => _selectedEvidenceFilter = selected ? HealthEvidenceStatus.attached : null);
                      },
                      selectedColor: Colors.green.shade100,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Timeline Feed
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final dateKey = grouped.keys.elementAt(index);
                    final dayEvents = grouped[dateKey]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Header
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.teal,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                dateKey,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Events for this Date
                        ...dayEvents.map((event) {
                          final pName = widget.patientMap[event.patientId]?.name ?? 'Patient';
                          return HealthEventCard(
                            event: event,
                            patientName: pName,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => HealthEventDetailDialog(
                                  event: event,
                                  patientName: pName,
                                  onUpdated: widget.onRefresh,
                                ),
                              );
                            },
                            onEdit: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => EditHealthEventDialog(
                                  event: event,
                                  patients: widget.patientMap.values.toList(),
                                  onUpdated: widget.onRefresh,
                                ),
                              );
                            },
                            onDelete: () async {
                              await healthRepository.deleteEvent(event.id);
                              widget.onRefresh();
                            },
                          );
                        }),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.health_and_safety_rounded, size: 44, color: Colors.teal),
            ),
            const SizedBox(height: 12),
            const Text(
              'No Health Records Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Snap a prescription photo or enter Sugar/BP to build your family health history.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              icon: const Icon(Icons.add),
              label: const Text('Add Health Record'),
              onPressed: widget.onAddPressed,
            ),
          ],
        ),
      ),
    );
  }
}
