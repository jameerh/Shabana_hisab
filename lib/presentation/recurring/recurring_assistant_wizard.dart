import 'package:flutter/material.dart';
import '../../data/database/database.dart';
import '../../main.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;
import '../home/services/recurring_schedule_engine.dart';
import '../../core/utils/date_utils.dart';

class RecurringAssistantWizard extends StatefulWidget {
  final int profileId;
  final String? initialTitle;
  final double? initialAmount;
  final String? initialType;

  const RecurringAssistantWizard({
    super.key, 
    required this.profileId,
    this.initialTitle,
    this.initialAmount,
    this.initialType,
  });

  static Future<void> show(BuildContext context, int profileId, {String? initialTitle, double? initialAmount, String? initialType}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecurringAssistantWizard(
        profileId: profileId,
        initialTitle: initialTitle,
        initialAmount: initialAmount,
        initialType: initialType,
      ),
    );
  }

  @override
  State<RecurringAssistantWizard> createState() => _RecurringAssistantWizardState();
}

class _RecurringAssistantWizardState extends State<RecurringAssistantWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Form State
  String? _title;
  String? _type; // Expense, Income, Transfer
  String? _frequency; // DAILY, WEEKLY, MONTHLY, QUARTERLY, YEARLY
  int _interval = 1;
  String? _amountStrategy = 'FIXED';
  double? _amount;
  DateTime _startDate = parseDateOnly(DateTime.now());
  late final TextEditingController _amountController;
  late final TextEditingController _customTitleController;
  bool _isCustom = false;
  String? _customError;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    _title = widget.initialTitle;
    _amount = widget.initialAmount;
    _type = widget.initialType;
    if (_title != null) _title = _title == 'अज्ञात' ? null : _title;
    _amountController = TextEditingController(
      text: _amount != null && _amount! > 0 ? _amount!.toStringAsFixed(0) : '',
    );
    _customTitleController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customTitleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _templates = [
    {'title': 'Rent', 'icon': Icons.home, 'type': 'Expense', 'frequency': 'MONTHLY'},
    {'title': 'Petrol', 'icon': Icons.local_gas_station, 'type': 'Expense', 'frequency': 'WEEKLY'},
    {'title': 'Milk', 'icon': Icons.local_drink, 'type': 'Expense', 'frequency': 'DAILY'},
    {'title': 'Electricity', 'icon': Icons.lightbulb, 'type': 'Expense', 'frequency': 'MONTHLY'},
    {'title': 'Mobile Recharge', 'icon': Icons.phone_android, 'type': 'Expense', 'frequency': 'MONTHLY'},
    {'title': 'Internet', 'icon': Icons.wifi, 'type': 'Expense', 'frequency': 'MONTHLY'},
    {'title': 'Salary', 'icon': Icons.account_balance_wallet, 'type': 'Income', 'frequency': 'MONTHLY'},
    {'title': 'Custom', 'icon': Icons.add, 'type': null, 'frequency': null},
  ];

  void _nextStep() {
    if (_currentStep < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveRule();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveRule() async {
    // Save to database
    if (_title == null || _frequency == null || _amount == null) return;

    final now = DateTime.now();
    final today = parseDateOnly(now);
    final start = parseDateOnly(_startDate);

    DateTime nextDue;
    if (isSameCalendarDay(start, today)) {
      nextDue = today;
    } else if (start.isAfter(today)) {
      nextDue = start;
    } else {
      // Newly created rule with startDate < today: compute earliest recurrence date >= today
      nextDue = start;
      while (nextDue.isBefore(today)) {
        nextDue = RecurringScheduleEngine.calculateNextDueDate(
          nextDue,
          _frequency!,
          _interval,
          requestedDay: start.day,
        );
      }
    }

    await database.into(database.recurringRule).insert(
      RecurringRuleCompanion.insert(
        title: _title!,
        defaultAmount: _amount!,
        amountStrategy: _amountStrategy ?? 'FIXED',
        profileId: widget.profileId,
        frequency: _frequency!,
        interval: _interval,
        status: 'ACTIVE',
        startDate: start,
        nextDueDate: nextDue,
        createdAt: Value(now),
        updatedAt: Value(now),
      )
    );

    // Immediately run schedule engine to process due items if nextDueDate <= today
    await RecurringScheduleEngine(database).processDueSchedules();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recurring rule "$_title" created!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  IconButton(icon: const Icon(Icons.arrow_back), onPressed: _previousStep)
                else
                  const SizedBox(width: 48),
                Text(
                  'Recurring Assistant',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          
          // Progress Bar
          LinearProgressIndicator(
            value: (_currentStep + 1) / 6,
            backgroundColor: Colors.grey.withAlpha(50),
            color: Theme.of(context).colorScheme.primary,
          ),
          
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (idx) => setState(() => _currentStep = idx),
              children: [
                _buildStep1What(),
                _buildStep2Type(),
                _buildStep3Frequency(),
                _buildStep4Schedule(),
                _buildStep5Amount(),
                _buildStep6Preview(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1What() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('What is this for?', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _templates.map((tpl) {
            final isCustomTpl = tpl['title'] == 'Custom';
            final isSelected = (_isCustom && isCustomTpl) || (!_isCustom && _title == tpl['title']);
            return InkWell(
              onTap: () {
                if (isCustomTpl) {
                  setState(() {
                    _isCustom = true;
                    _title = 'Custom';
                    _customError = null;
                  });
                } else {
                  setState(() {
                    _isCustom = false;
                    _title = tpl['title'] as String;
                    if (tpl['type'] != null) _type = tpl['type'] as String;
                    if (tpl['frequency'] != null) _frequency = tpl['frequency'] as String;
                  });
                  _nextStep();
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: (MediaQuery.of(context).size.width - 60) / 2,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).cardColor,
                  border: Border.all(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withAlpha(50),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(tpl['icon'] as IconData, size: 32, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
                    const SizedBox(height: 8),
                    Text(tpl['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (_isCustom) ...[
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Theme.of(context).colorScheme.primary.withAlpha(120), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Custom Recurring Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customTitleController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'e.g. Gym Membership, Tuition Fee, Maid',
                      errorText: _customError,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) {
                      if (_customError != null && val.trim().isNotEmpty) {
                        setState(() => _customError = null);
                      }
                    },
                    onSubmitted: (val) {
                      final enteredTitle = val.trim();
                      if (enteredTitle.isEmpty) {
                        setState(() {
                          _customError = 'Please enter a title for your custom rule';
                        });
                      } else {
                        setState(() {
                          _title = enteredTitle;
                          _customError = null;
                        });
                        _nextStep();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Continue'),
                      onPressed: () {
                        final enteredTitle = _customTitleController.text.trim();
                        if (enteredTitle.isEmpty) {
                          setState(() {
                            _customError = 'Please enter a title for your custom rule';
                          });
                        } else {
                          setState(() {
                            _title = enteredTitle;
                            _customError = null;
                          });
                          _nextStep();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep2Type() {
    return _buildSelectionList(
      title: 'Is this an Expense or Income?',
      options: ['Expense', 'Income', 'Transfer'],
      currentSelection: _type,
      onSelect: (val) {
        setState(() => _type = val);
        _nextStep();
      },
    );
  }

  Widget _buildStep3Frequency() {
    return _buildSelectionList(
      title: 'How often?',
      options: ['DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'YEARLY'],
      currentSelection: _frequency,
      onSelect: (val) {
        setState(() => _frequency = val);
        _nextStep();
      },
    );
  }

  Widget _buildStep4Schedule() {
    // Simplified for MVP. In reality, you'd configure "1st of month" vs "Last working day" here.
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Schedule Details', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          Text('Repeat every $_interval ${_frequency?.toLowerCase() ?? "month"}.'),
          Slider(
            value: _interval.toDouble(),
            min: 1,
            max: 12,
            divisions: 11,
            label: _interval.toString(),
            onChanged: (val) => setState(() => _interval = val.toInt()),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _nextStep, child: const Text('Continue')),
          )
        ],
      ),
    );
  }

  Widget _buildStep5Amount() {
    final hasValidAmount = _amount != null && _amount! > 0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amount', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            _amountStrategy == 'VARIABLE'
                ? 'Estimated average amount for $_title (Optional)'
                : 'Enter the recurring amount for $_title',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _amountError != null
                    ? Colors.red
                    : (_amount != null && _amount! > 0
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.withAlpha(80)),
                width: _amountError != null || hasValidAmount ? 2 : 1,
              ),
            ),
            child: TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                border: InputBorder.none,
                hintText: _amountStrategy == 'VARIABLE' ? '0.00 (Optional)' : '0.00',
                hintStyle: TextStyle(color: Colors.grey.shade400),
              ),
              onChanged: (val) {
                final parsed = double.tryParse(val.trim());
                setState(() {
                  _amount = parsed;
                  if (_amountStrategy == 'VARIABLE' || (parsed != null && parsed > 0)) {
                    _amountError = null;
                  }
                });
              },
            ),
          ),
          if (_amountStrategy == 'VARIABLE') ...[
            const SizedBox(height: 6),
            Text(
              'Leave 0.00 if exact bill is unknown; you will enter it when paying.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
          if (_amountError != null) ...[
            const SizedBox(height: 8),
            Text(
              _amountError!,
              style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 24),
          _buildSelectionList(
            title: 'Is this amount fixed?',
            options: ['FIXED', 'VARIABLE'],
            currentSelection: _amountStrategy,
            onSelect: (val) => setState(() {
              _amountStrategy = val;
              if (val == 'VARIABLE') {
                _amountError = null;
              }
            }),
            embed: true,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final parsed = double.tryParse(_amountController.text.trim()) ?? _amount;
                if (_amountStrategy == 'VARIABLE') {
                  // Amount is optional for VARIABLE bills: defaults to 0.0 if not specified
                  _amount = (parsed != null && parsed > 0) ? parsed : 0.0;
                  _amountError = null;
                  _nextStep();
                } else {
                  // FIXED bills require an amount > 0
                  if (parsed == null || parsed <= 0) {
                    setState(() {
                      _amountError = 'Please enter an amount greater than ₹0';
                    });
                  } else {
                    _amount = parsed;
                    _amountError = null;
                    _nextStep();
                  }
                }
              },
              child: const Text('Preview Schedule'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStep6Preview() {
    // Generate next 4 dates
    List<DateTime> dates = [];
    DateTime pointer = DateTime.now();
    for (int i = 0; i < 4; i++) {
      if (_frequency == 'QUARTERLY') {
        pointer = shiftCalendarMonth(pointer, 3 * _interval, preferredDay: pointer.day);
      } else if (_frequency == 'MONTHLY') {
        pointer = shiftCalendarMonth(pointer, _interval, preferredDay: pointer.day);
      } else if (_frequency == 'WEEKLY') {
        pointer = pointer.add(Duration(days: 7 * _interval));
      } else if (_frequency == 'DAILY') {
        pointer = pointer.add(Duration(days: _interval));
      } else if (_frequency == 'YEARLY') {
        pointer = shiftCalendarMonth(pointer, 12 * _interval, preferredDay: pointer.day);
      }
      dates.add(pointer);
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review & Save', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(_title ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(
                    _amountStrategy == 'VARIABLE' && (_amount == null || _amount == 0.0)
                        ? 'Variable • Entered at payment'
                        : '₹${_amount?.toStringAsFixed(2)} • ${_amountStrategy == 'VARIABLE' ? "Usually changes" : "Fixed"}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Next 4 Occurrences', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...dates.map((d) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(DateFormat('dd MMM yyyy').format(d), style: const TextStyle(fontSize: 16)),
              ],
            ),
          )),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _nextStep,
              child: const Text('Create Rule'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSelectionList({
    required String title,
    required List<String> options,
    required String? currentSelection,
    required Function(String) onSelect,
    bool embed = false,
  }) {
    Widget list = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!embed) Text(title, style: Theme.of(context).textTheme.headlineSmall),
        if (!embed) const SizedBox(height: 24),
        ...options.map((opt) {
          final isSelected = opt == currentSelection;
          return ListTile(
            title: Text(opt),
            trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
            onTap: () => onSelect(opt),
          );
        }),
      ],
    );
    
    return embed ? list : ListView(padding: const EdgeInsets.all(24), children: [list]);
  }
}
