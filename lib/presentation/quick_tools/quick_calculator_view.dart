import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../data/services/voice_service.dart';
import '../../data/repositories/calculator_repository.dart';
import '../../core/voice/number_parser.dart';
import '../../core/voice/arithmetic_parser.dart';
import '../../data/database/database.dart';
import '../../data/services/profile_service.dart';
import '../../domain/entities/calculation_line.dart';
import 'calculator_history_view.dart';
import 'dart:async';
import '../../l10n/app_localizations.dart';
import '../../core/localization/bilingual_text.dart';
import '../../main.dart';

class QuickCalculatorView extends StatefulWidget {
  const QuickCalculatorView({super.key});

  @override
  State<QuickCalculatorView> createState() => _QuickCalculatorViewState();
}

class _QuickCalculatorViewState extends State<QuickCalculatorView> {
  final VoiceService _voiceService = VoiceService();
  final CalculatorRepository _repository = CalculatorRepository();
  
  int? _profileId;
  String _profileName = "Unknown";
  bool _isListening = false;
  String _selectedLanguage = 'mr-IN'; // Default to Marathi
  StreamSubscription? _voiceSubscription;
  final ScrollController _scrollController = ScrollController();

  final List<CalculationLine> _lines = [];
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _initVoice();
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

  void _initVoice() async {
    _voiceSubscription = _voiceService.onTextResult.listen((text) {
      if (text.startsWith("STATUS:") || text.startsWith("ERROR:") || text.startsWith("PARTIAL:") || text.startsWith("RAW:")) {
        return;
      }
      
      _handleVoiceResult(text);
    });
  }

  void _handleVoiceResult(String text) {
    if (text.isEmpty) return;

    String lower = text.toLowerCase().trim();
    if (lower == 'undo' || lower == 'delete last' || lower == 'magcha khoda' || lower == 'cancel' || lower == 'clear last' || lower == 'मागे घ्या' || lower == 'डिलीट') {
      if (_lines.isNotEmpty) {
        setState(() {
          _lines.removeLast();
          if (_lines.isNotEmpty) {
            _lines[0] = CalculationLine(value: _lines[0].value); // Remove operator from first
          }
          _updateTotal();
        });
        HapticFeedback.lightImpact();
      }
      return;
    }
    if (lower == 'clear all' || lower == 'delete all' || lower == 'sagle khoda' || lower == 'clear' || lower == 'सगळे खोडा' || lower == 'क्लिअर') {
      _clearSheet();
      HapticFeedback.lightImpact();
      return;
    }

    // 1. Try to parse as a full arithmetic expression (e.g., "100 + 200")
    final result = ArithmeticParser.parse(text);
    if (result != null) {
      _addLinesFromExpression(result.expression);
      HapticFeedback.mediumImpact();
      return;
    } 

    // 2. Fallback to sequence of numbers (e.g., "100 200")
    final results = NumberParser.parseSequence(text);
    if (results.isNotEmpty) {
      setState(() {
        for (var val in results) {
          _lines.add(CalculationLine(
            operator: _lines.isEmpty ? null : '+', 
            value: val
          ));
        }
        _updateTotal();
      });
      _scrollToBottom();
      HapticFeedback.mediumImpact();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Could not understand calculation: '$text'"),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _addLinesFromExpression(String expression) {
    // Split into tokens (numbers and operators)
    final tokens = expression.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    String? nextOp;
    
    setState(() {
      for (int i = 0; i < tokens.length; i++) {
        final token = tokens[i];
        
        if (['+', '-', '*', '/'].contains(token)) {
          nextOp = token;
        } else {
          double? val = double.tryParse(token);
          if (val != null) {
            if (_lines.isEmpty && (nextOp == null || nextOp == '+')) {
              // First line of a fresh sheet (ignore leading '+')
              _lines.add(CalculationLine(value: val));
            } else {
              // Subsequent lines or adding to existing sheet
              // Use explicit operator if found, otherwise default to '+' for implicit addition
              _lines.add(CalculationLine(operator: nextOp ?? '+', value: val));
            }
            nextOp = null; // Reset for next number
          }
        }
      }
      _updateTotal();
    });
    _scrollToBottom();
  }

  void _updateTotal() {
    if (_lines.isEmpty) {
      _total = 0;
      return;
    }
    double result = _lines.first.value;
    for (int i = 1; i < _lines.length; i++) {
      final line = _lines[i];
      switch (line.operator) {
        case '+': result += line.value; break;
        case '-': result -= line.value; break;
        case '*': result *= line.value; break;
        case '/': if (line.value != 0) result /= line.value; break;
        default: result += line.value;
      }
    }
    _total = result;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _toggleListening() async {
    await _voiceService.startNativeGoogleVoice(language: _selectedLanguage);
    if (mounted) {
      setState(() {
        _isListening = _voiceService.isListening;
      });
    }
  }

  void _saveToHistory() async {
    if (_lines.isEmpty || _profileId == null) return;

    String expression = _lines.map((l) {
      String s = l.value.toString().replaceAll('.0', '');
      return l.operator != null ? '${l.operator} $s' : s;
    }).join(' ');

    await _repository.saveEntry(
      profileId: _profileId!,
      expression: expression,
      value: _total,
      source: 'form',
      isCurrency: false,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Calculation saved to history")));
    setState(() {
      _lines.clear();
      _total = 0;
    });
  }

  void _clearSheet() {
    setState(() {
      _lines.clear();
      _total = 0;
    });
  }

  void _editLine(int index) {
    final line = _lines[index];
    final valueController = TextEditingController(text: line.value.toString().replaceAll('.0', ''));
    String? selectedOp = line.operator;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Edit Line'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index > 0)
                DropdownButtonFormField<String>(
                  value: selectedOp,
                  items: ['+', '-', '*', '/'].map((op) => DropdownMenuItem(value: op, child: Text(op))).toList(),
                  onChanged: (val) => setStateDialog(() => selectedOp = val),
                  decoration: const InputDecoration(labelText: 'Operator'),
                ),
              TextField(
                controller: valueController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Value'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                double? newVal = double.tryParse(valueController.text);
                if (newVal != null) {
                  setState(() {
                    _lines[index] = CalculationLine(operator: selectedOp, value: newVal);
                    _updateTotal();
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String label, {Color? color, VoidCallback? onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: ElevatedButton(
          onPressed: onTap ?? () {
            if (['+', '-', '*', '/'].contains(label)) {
              setState(() {
                if (_lines.isNotEmpty) {
                  _lines.add(CalculationLine(operator: label, value: 0));
                  _scrollToBottom();
                  _editLine(_lines.length - 1); // Open edit for the new line
                }
              });
            } else {
               _addLineManually(initialValue: label);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.grey[200],
            foregroundColor: color != null ? Colors.white : Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _addLineManually({String? initialValue}) {
    final valueController = TextEditingController(text: initialValue);
    String selectedOp = '+';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Add Line'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_lines.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: selectedOp,
                  items: ['+', '-', '*', '/'].map((op) => DropdownMenuItem(value: op, child: Text(op))).toList(),
                  onChanged: (val) => setStateDialog(() => selectedOp = val!),
                  decoration: const InputDecoration(labelText: 'Operator'),
                ),
              TextField(
                controller: valueController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Value'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                double? val = double.tryParse(valueController.text);
                if (val != null) {
                  setState(() {
                    _lines.add(CalculationLine(operator: _lines.isEmpty ? null : selectedOp, value: val));
                    _updateTotal();
                  });
                  _scrollToBottom();
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _voiceSubscription?.cancel();
    _voiceSubscription = null;
    _voiceService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: BilingualText(
          english: 'Voice Calculator',
          marathi: 'व्हॉईस कॅल्क्युलेटर',
          languageController: languageController,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Voice Hint Row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.indigo.shade700,
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Speak: "100 + 200" or "500 - 100"',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
          // Toolbar Row (Second Row)
          Container(
            color: Colors.indigo,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Language Switcher
                ToggleButtons(
                  isSelected: [_selectedLanguage == 'mr-IN', _selectedLanguage == 'en-IN'],
                  onPressed: (index) {
                    setState(() => _selectedLanguage = index == 0 ? 'mr-IN' : 'en-IN');
                  },
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: Colors.white,
                  fillColor: Colors.white24,
                  color: Colors.white70,
                  constraints: const BoxConstraints(minHeight: 32, minWidth: 45),
                  children: const [
                    Text('MR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('EN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                
                // Voice Button
                IconButton(
                  icon: CircleAvatar(
                    backgroundColor: _isListening ? Colors.red : Colors.white24,
                    child: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white, size: 20),
                  ),
                  onPressed: _toggleListening,
                  tooltip: 'Speak',
                ),

                // History Button
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.white),
                  onPressed: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CalculatorHistoryView()));
                    if (result is CalculatorEntry) {
                      _clearSheet();
                      _addLinesFromExpression(result.expression);
                    }
                  },
                  tooltip: 'History',
                ),

                // Clear/Delete Button
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
                  onPressed: _clearSheet,
                  tooltip: 'Clear',
                ),
              ],
            ),
          ),

          // Usage Hint Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              border: Border(bottom: BorderSide(color: Colors.indigo.shade100)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "कसे बोलायचे (How to say):",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
                Text(
                  "• शंभर अधिक दोनशे (100 + 200)",
                  style: TextStyle(fontSize: 12, color: Colors.indigo),
                ),
                Text(
                  "• पाचशे वजा पन्नास (500 - 50)",
                  style: TextStyle(fontSize: 12, color: Colors.indigo),
                ),
              ],
            ),
          ),
          
          // Manual Keyboard Calculator Section (Top of Content)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildKeypadButton('7'), _buildKeypadButton('8'), _buildKeypadButton('9'), _buildKeypadButton('/', color: Colors.orange),
                  ],
                ),
                Row(
                  children: [
                    _buildKeypadButton('4'), _buildKeypadButton('5'), _buildKeypadButton('6'), _buildKeypadButton('*', color: Colors.orange),
                  ],
                ),
                Row(
                  children: [
                    _buildKeypadButton('1'), _buildKeypadButton('2'), _buildKeypadButton('3'), _buildKeypadButton('-', color: Colors.orange),
                  ],
                ),
                Row(
                  children: [
                    _buildKeypadButton('0'), _buildKeypadButton('.'), _buildKeypadButton('C', onTap: _clearSheet), _buildKeypadButton('+', color: Colors.orange),
                  ],
                ),
              ],
            ),
          ),
          
          if (_isListening)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Text("Listening...", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          // Live Total Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              border: Border(bottom: BorderSide(color: Colors.indigo.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                Text(
                  _total.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), ''),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _lines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic_none_outlined, size: 64, color: Colors.indigo.withOpacity(0.2)),
                      const SizedBox(height: 12),
                      const Text('बोलून किंवा कीबोर्डने आकडे टाका', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _lines.length,
                  itemBuilder: (context, index) {
                    final line = _lines[index];
                    return Dismissible(
                      key: Key('line_$index'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        setState(() {
                          _lines.removeAt(index);
                          if (_lines.isNotEmpty && index == 0) _lines[0] = CalculationLine(value: _lines[0].value);
                          _updateTotal();
                        });
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.shade50,
                            radius: 18,
                            child: Text(line.operator ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                          ),
                          title: Text(line.value.toString().replaceAll('.0', ''), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                          trailing: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                          onTap: () => _editLine(index),
                        ),
                      ),
                    );
                  },
                ),
          ),
          
          // Save Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveToHistory,
                icon: const Icon(Icons.save),
                label: const Text('सेव्ह करा (Save History)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.large(
        onPressed: _toggleListening,
        backgroundColor: _isListening ? Colors.red : Colors.indigo,
        child: Icon(_isListening ? Icons.stop : Icons.mic, size: 40, color: Colors.white),
      ),
    );
  }
}
