import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/calculator_repository.dart';
import '../../data/database/database.dart';
import '../../data/services/pdf_service.dart';
import '../../data/services/profile_service.dart';

class CalculatorHistoryView extends StatefulWidget {
  const CalculatorHistoryView({super.key});

  @override
  State<CalculatorHistoryView> createState() => _CalculatorHistoryViewState();
}

class _CalculatorHistoryViewState extends State<CalculatorHistoryView> {
  final CalculatorRepository _repository = CalculatorRepository();
  int? _profileId;
  String _profileName = "Unknown";
  String _sortBy = "DATE_DESC";

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final id = await ProfileService.getActiveProfileId();
    final profiles = await ProfileService.getProfiles();
    final p = profiles.firstWhere((element) => element.id == id, orElse: () => profiles.first);
    setState(() {
      _profileId = id;
      _profileName = p.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_profileId == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return StreamBuilder<List<CalculatorEntry>>(
      stream: _repository.watchHistory(_profileId!),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];
        if (_sortBy == 'DATE_DESC') entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        else if (_sortBy == 'DATE_ASC') entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        else if (_sortBy == 'VAL_DESC') entries.sort((a, b) => b.parsedValue.compareTo(a.parsedValue));
        else if (_sortBy == 'VAL_ASC') entries.sort((a, b) => a.parsedValue.compareTo(b.parsedValue));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Calculation History'),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                onSelected: (val) => setState(() => _sortBy = val),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'DATE_DESC', child: Text('Latest First')),
                  const PopupMenuItem(value: 'DATE_ASC', child: Text('Oldest First')),
                  const PopupMenuItem(value: 'VAL_DESC', child: Text('Highest Amount')),
                  const PopupMenuItem(value: 'VAL_ASC', child: Text('Lowest Amount')),
                ],
              ),
            ],
          ),
          body: entries.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_outlined, size: 80, color: Colors.indigo.withOpacity(0.1)),
                    const SizedBox(height: 16),
                    const Text('No history yet.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  
                  // Parse expression into structured lines for display
                  // e.g. "100 + 200 - 50" -> ["100", "+ 200", "- 50"]
                  final tokens = entry.expression.split(' ');
                  List<String> displayLines = [];
                  if (tokens.isNotEmpty) {
                    displayLines.add(tokens[0]); // First number
                    for (int i = 1; i < tokens.length; i += 2) {
                      if (i + 1 < tokens.length) {
                        displayLines.add('${tokens[i]} ${tokens[i+1]}');
                      } else {
                        displayLines.add(tokens[i]);
                      }
                    }
                  }

                  return Dismissible(
                    key: Key('hist_${entry.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => _repository.deleteEntry(entry),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.receipt_long, size: 16, color: Colors.indigo),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('dd MMM, hh:mm a').format(entry.createdAt),
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share, size: 20, color: Colors.indigo),
                                  onPressed: () => PdfService.generateCalculatorReceiptPdf(entry, _profileName),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            ...displayLines.map((line) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                line,
                                style: const TextStyle(fontSize: 15, fontFamily: 'monospace'),
                              ),
                            )),
                            const Divider(height: 24, thickness: 1.5, color: Colors.indigo),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                                Text(
                                  '₹${entry.parsedValue.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.indigo),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Reload this Hishob'),
                                onPressed: () => Navigator.pop(context, entry),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  foregroundColor: Colors.indigo,
                                  side: BorderSide(color: Colors.indigo.withOpacity(0.3)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
        );
      },
    );
  }
}
