import 'package:flutter/material.dart';
import '../../data/database/database.dart';
import '../../main.dart';
import 'recurring_assistant_wizard.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:table_calendar/table_calendar.dart';
import '../home/services/recurring_schedule_engine.dart';
import '../../core/utils/date_utils.dart';

import '../../l10n/app_localizations.dart';
import '../../core/localization/bilingual_text.dart';

class RecurringManagerView extends StatefulWidget {
  final int profileId;

  const RecurringManagerView({super.key, required this.profileId});

  @override
  State<RecurringManagerView> createState() => _RecurringManagerViewState();
}

class _RecurringManagerViewState extends State<RecurringManagerView> {
  String _filter = 'ACTIVE';
  bool _isCalendarView = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isSelectionMode = false;
  Set<int> _selectedIds = {};
  String _searchQuery = '';

  Color _getRuleColor(String category) {
    if (category.toLowerCase().contains('rent')) return Colors.blue;
    if (category.toLowerCase().contains('salary')) return Colors.green;
    if (category.toLowerCase().contains('petrol')) return Colors.orange;
    if (category.toLowerCase().contains('milk')) return Colors.purple;
    return Colors.teal;
  }

  IconData _getRuleIcon(String category) {
    if (category.toLowerCase().contains('rent')) return Icons.home;
    if (category.toLowerCase().contains('salary')) return Icons.attach_money;
    if (category.toLowerCase().contains('petrol')) return Icons.local_gas_station;
    if (category.toLowerCase().contains('milk')) return Icons.local_drink;
    return Icons.event_repeat;
  }

  String _getFilterLabel(BuildContext context, String filterKey) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return filterKey;
    switch (filterKey) {
      case 'ACTIVE': return l10n.active;
      case 'PAUSED': return l10n.paused;
      case 'ARCHIVED': return l10n.archived;
      default: return filterKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedIds.length} Selected')
            : BilingualText(
                english: 'Recurring Rules',
                marathi: 'नियमित नियम',
                languageController: languageController,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
        leading: _isSelectionMode 
          ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() { _isSelectionMode = false; _selectedIds.clear(); }))
          : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(icon: const Icon(Icons.pause), onPressed: _bulkPause),
            IconButton(icon: const Icon(Icons.play_arrow), onPressed: _bulkResume),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _bulkDelete),
          ] else ...[
            IconButton(
              icon: Icon(_isCalendarView ? Icons.list : Icons.calendar_month),
              onPressed: () => setState(() => _isCalendarView = !_isCalendarView),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => RecurringAssistantWizard.show(context, widget.profileId),
            )
          ]
        ],
      ),
      body: Column(
        children: [
          // Search & Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n?.searchHint ?? 'Search rules...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(0),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['ACTIVE', 'PAUSED', 'ARCHIVED'].map((f) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(_getFilterLabel(context, f)),
                  selected: _filter == f,
                  onSelected: (val) {
                    if (val) setState(() => _filter = f);
                  },
                ),
              )).toList(),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<RecurringRuleData>>(
              stream: (database.select(database.recurringRule)
                ..where((r) => r.profileId.equals(widget.profileId))
                ..where((r) => r.status.equals(_filter))
                ..orderBy([(t) => OrderingTerm.asc(t.nextDueDate)])
              ).watch(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                var rules = snapshot.data!;
                if (_searchQuery.isNotEmpty) {
                  rules = rules.where((r) => r.title.toLowerCase().contains(_searchQuery)).toList();
                }

                if (rules.isEmpty) return Center(child: Text(l10n?.noRulesFound ?? 'No rules found.'));

                return Column(
                  children: [
                    if (_isCalendarView)
                      TableCalendar(
                        firstDay: DateTime.utc(2020, 10, 16),
                        lastDay: DateTime.utc(2030, 3, 14),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        eventLoader: (day) {
                          return rules.where((r) => isSameDay(r.nextDueDate, day)).toList();
                        },
                      ),
                    
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          await RecurringScheduleEngine(database).processDueSchedules();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: rules.length,
                          itemBuilder: (context, index) {
                            final rule = rules[index];
                            
                            // If calendar view and a day is selected, filter rules for that day
                            if (_isCalendarView && _selectedDay != null && !isSameDay(rule.nextDueDate, _selectedDay)) {
                              return const SizedBox.shrink();
                            }

                            final isSelected = _selectedIds.contains(rule.id);
                            final color = _getRuleColor(rule.title);
                            final icon = _getRuleIcon(rule.title);
                            final today = parseDateOnly(DateTime.now());
                            final isDueToday = isSameCalendarDay(rule.nextDueDate, today);
                            final isOverdue = rule.nextDueDate.isBefore(today);

                            String statusLabel = 'Upcoming';
                            Color statusBadgeColor = Colors.green;
                            if (isDueToday) {
                              statusLabel = 'Due Today';
                              statusBadgeColor = Colors.orange;
                            } else if (isOverdue) {
                              statusLabel = 'Overdue';
                              statusBadgeColor = Colors.red;
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: isSelected ? Colors.teal.withValues(alpha: 0.1) : null,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: color.withValues(alpha: 0.2),
                                  child: Icon(icon, color: color)
                                ),
                                title: Row(
                                  children: [
                                    Expanded(child: Text(rule.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusBadgeColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(color: statusBadgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  '${rule.frequency} • Next: ${DateFormat('dd MMM').format(rule.nextDueDate)}\n₹${rule.defaultAmount.toStringAsFixed(2)}',
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () => _showRuleOptions(rule),
                                ),
                                onLongPress: () {
                                  setState(() {
                                    _isSelectionMode = true;
                                    _selectedIds.add(rule.id);
                                  });
                                },
                                onTap: () {
                                  if (_isSelectionMode) {
                                    setState(() {
                                      if (isSelected) _selectedIds.remove(rule.id);
                                      else _selectedIds.add(rule.id);
                                      if (_selectedIds.isEmpty) _isSelectionMode = false;
                                    });
                                  } else {
                                    _showHistory(rule);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    _buildProgressFooter(rules),
                  ],
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: _isSelectionMode ? null : FloatingActionButton.extended(
        onPressed: () => RecurringAssistantWizard.show(context, widget.profileId),
        label: const Text('New Rule'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProgressFooter(List<RecurringRuleData> rules) {
    int active = rules.where((r) => r.status == 'ACTIVE').length;
    int paused = rules.where((r) => r.status == 'PAUSED').length;
    double expected = rules.fold(0, (sum, r) => sum + r.defaultAmount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'Active', value: active.toString()),
              _StatItem(label: 'Paused', value: paused.toString()),
            ],
          ),
          const SizedBox(height: 8),
          Text('Expected This Month: ₹${expected.toStringAsFixed(0)}', 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
        ],
      ),
    );
  }

  void _bulkPause() async {
    await database.transaction(() async {
      for (var id in _selectedIds) {
        await (database.update(database.recurringRule)..where((r) => r.id.equals(id))).write(
          RecurringRuleCompanion(status: const Value('PAUSED'))
        );
      }
    });
    setState(() { _isSelectionMode = false; _selectedIds.clear(); });
  }

  void _bulkResume() async {
    await database.transaction(() async {
      for (var id in _selectedIds) {
        await (database.update(database.recurringRule)..where((r) => r.id.equals(id))).write(
          RecurringRuleCompanion(status: const Value('ACTIVE'))
        );
      }
    });
    setState(() { _isSelectionMode = false; _selectedIds.clear(); });
  }

  void _bulkDelete() async {
    await database.transaction(() async {
      for (var id in _selectedIds) {
        await (database.update(database.recurringRule)..where((r) => r.id.equals(id))).write(
          RecurringRuleCompanion(status: const Value('DELETED'))
        );
      }
    });
    setState(() { _isSelectionMode = false; _selectedIds.clear(); });
  }

  void _showRuleOptions(RecurringRuleData rule) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('View Statistics'),
              onTap: () {
                Navigator.pop(ctx);
                _showStatistics(rule);
              },
            ),
            ListTile(
              leading: Icon(rule.status == 'ACTIVE' ? Icons.pause : Icons.play_arrow),
              title: Text(rule.status == 'ACTIVE' ? 'Pause Rule' : 'Resume Rule'),
              onTap: () async {
                Navigator.pop(ctx);
                await (database.update(database.recurringRule)..where((r) => r.id.equals(rule.id))).write(
                  RecurringRuleCompanion(status: Value(rule.status == 'ACTIVE' ? 'PAUSED' : 'ACTIVE'))
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('View History'),
              onTap: () {
                Navigator.pop(ctx);
                _showHistory(rule);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Rule', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                await (database.update(database.recurringRule)..where((r) => r.id.equals(rule.id))).write(
                  RecurringRuleCompanion(status: const Value('DELETED'))
                );
              },
            ),
          ],
        ),
      )
    );
  }

  void _showHistory(RecurringRuleData rule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _HistoryBottomSheet(rule: rule),
    );
  }

  void _showStatistics(RecurringRuleData rule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StatisticsBottomSheet(rule: rule),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class _StatisticsBottomSheet extends StatelessWidget {
  final RecurringRuleData rule;

  const _StatisticsBottomSheet({required this.rule});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: FutureBuilder<List<RecurringHistoryData>>(
        future: (database.select(database.recurringHistory)..where((h) => h.ruleId.equals(rule.id))).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final history = snapshot.data!;
          int total = history.length;
          int completed = history.where((h) => h.status == 'PAID').length;
          int skipped = history.where((h) => h.status == 'SKIPPED').length;
          double avg = total > 0 ? history.fold(0.0, (sum, h) => sum + (h.amount ?? 0)) / total : rule.defaultAmount;
          double completionRate = total > 0 ? (completed / total) * 100 : 100;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${rule.title} Statistics', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Completion Rate'),
                  trailing: Text('${completionRate.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                ListTile(
                  leading: const Icon(Icons.skip_next, color: Colors.orange),
                  title: const Text('Skipped'),
                  trailing: Text('$skipped times', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                ListTile(
                  leading: const Icon(Icons.attach_money, color: Colors.blue),
                  title: const Text('Average Amount'),
                  trailing: Text('₹${avg.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const Spacer(),
                Center(
                  child: Text('Rule Created: ${DateFormat('MMM yyyy').format(rule.createdAt)}', style: const TextStyle(color: Colors.grey)),
                )
              ],
            ),
          );
        }
      )
    );
  }
}

class _HistoryBottomSheet extends StatelessWidget {
  final RecurringRuleData rule;

  const _HistoryBottomSheet({required this.rule});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                const Icon(Icons.history, size: 32),
                const SizedBox(width: 16),
                Text('${rule.title} History', style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<RecurringHistoryData>>(
              stream: (database.select(database.recurringHistory)
                ..where((h) => h.ruleId.equals(rule.id))
                ..orderBy([(t) => OrderingTerm.desc(t.dueDate)])
              ).watch(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final history = snapshot.data!;
                if (history.isEmpty) return const Center(child: Text('No history available yet.'));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    Color statusColor = Colors.grey;
                    IconData statusIcon = Icons.help_outline;
                    
                    if (item.status == 'PAID') {
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle;
                    } else if (item.status == 'SKIPPED') {
                      statusColor = Colors.orange;
                      statusIcon = Icons.skip_next;
                    } else if (item.status == 'PENDING') {
                      statusColor = Colors.blue;
                      statusIcon = Icons.schedule;
                    } else if (item.status == 'SNOOZED') {
                      statusColor = Colors.purple;
                      statusIcon = Icons.snooze;
                    }

                    return ListTile(
                      leading: Icon(statusIcon, color: statusColor),
                      title: Text(DateFormat('MMMM yyyy').format(item.dueDate)),
                      subtitle: Text(item.status),
                      trailing: Text('₹${item.amount?.toStringAsFixed(2) ?? rule.defaultAmount.toStringAsFixed(2)}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
