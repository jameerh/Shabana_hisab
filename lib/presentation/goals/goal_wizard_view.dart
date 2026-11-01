import 'package:flutter/material.dart';
import '../../../data/database/database.dart';
import '../core/theme/financial_health_theme.dart';
import 'models/goal_template.dart';
import 'package:intl/intl.dart';

class GoalWizardView extends StatefulWidget {
  final int profileId;
  const GoalWizardView({super.key, required this.profileId});

  @override
  State<GoalWizardView> createState() => _GoalWizardViewState();
}

class _GoalWizardViewState extends State<GoalWizardView> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
  
  // Wizard State
  GoalTemplate? _selectedTemplate;
  String _title = '';
  double _targetAmount = 0.0;
  DateTime? _deadline;
  String _fundingStrategy = 'MANUAL';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Create Goal', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 1 && !_formKey.currentState!.validate()) return;
          if (_currentStep == 1) _formKey.currentState!.save();
          
          if (_currentStep < 4) {
            setState(() => _currentStep++);
          } else {
            _saveGoal();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        controlsBuilder: (context, details) {
          final isLastStep = _currentStep == 4;
          return Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_currentStep == 0 && _selectedTemplate == null) ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLastStep ? FinancialHealthTheme.excellent : Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isLastStep ? 'Create Goal' : 'Next', style: const TextStyle(fontSize: 16)),
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          _buildTemplateStep(),
          _buildTargetStep(),
          _buildFundingStep(),
          _buildForecastStep(),
          _buildReviewStep(),
        ],
      ),
    );
  }

  Step _buildTemplateStep() {
    return Step(
      title: const Text('Template', style: TextStyle(color: Colors.white)),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: GoalTemplate.all.length,
        itemBuilder: (context, index) {
          final template = GoalTemplate.all[index];
          final isSelected = _selectedTemplate?.id == template.id;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedTemplate = template;
                _title = template.title;
                _fundingStrategy = template.defaultFundingStrategy;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? template.themeColor.withValues(alpha: 0.2) : Colors.grey[900],
                border: Border.all(
                  color: isSelected ? template.themeColor : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(template.icon, size: 32, color: isSelected ? template.themeColor : Colors.white70),
                  const SizedBox(height: 8),
                  Text(
                    template.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Step _buildTargetStep() {
    return Step(
      title: const Text('Target', style: TextStyle(color: Colors.white)),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: _title,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                labelText: 'Goal Title',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => _title = v!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _targetAmount > 0 ? _targetAmount.toStringAsFixed(0) : '',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Target Amount (₹)',
                labelStyle: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.normal),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter valid amount' : null,
              onSaved: (v) => _targetAmount = double.parse(v!),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.grey[900],
              title: const Text('Deadline (Optional)', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                _deadline != null ? DateFormat.yMMMd().format(_deadline!) : 'No deadline set',
                style: TextStyle(color: _deadline != null ? Colors.blueAccent : Colors.white54),
              ),
              trailing: const Icon(Icons.calendar_month, color: Colors.white70),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
                );
                if (date != null) {
                  setState(() => _deadline = date);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Step _buildFundingStep() {
    final strategies = [
      {'id': 'MANUAL', 'title': 'Manual Savings', 'desc': 'I will manually add money to this goal.'},
      {'id': 'SAFE_TO_SPEND', 'title': 'Safe To Spend', 'desc': 'Automatically sweep unused Safe To Spend funds at month end.'},
      {'id': 'RECURRING', 'title': 'Recurring Transfer', 'desc': 'Transfer a fixed amount every month.'},
      {'id': 'SALARY_PERCENT', 'title': 'Salary Percentage', 'desc': 'Deduct a % when salary arrives.'},
      {'id': 'ROUND_OFF', 'title': 'Round Off Change', 'desc': 'Round off every expense to nearest ₹100 and add to goal.'},
    ];

    return Step(
      title: const Text('Funding', style: TextStyle(color: Colors.white)),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      content: Column(
        children: strategies.map((s) {
          final isSelected = _fundingStrategy == s['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: () => setState(() => _fundingStrategy = s['id']!),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blueAccent.withValues(alpha: 0.2) : Colors.grey[900],
                  border: Border.all(color: isSelected ? Colors.blueAccent : Colors.transparent, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? Colors.blueAccent : Colors.white54,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['title']!, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(s['desc']!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Step _buildForecastStep() {
    double monthlyNeeded = 0;
    if (_deadline != null) {
      final months = (_deadline!.year - DateTime.now().year) * 12 + _deadline!.month - DateTime.now().month;
      if (months > 0) monthlyNeeded = _targetAmount / months;
      else monthlyNeeded = _targetAmount;
    }

    return Step(
      title: const Text('Forecast', style: TextStyle(color: Colors.white)),
      isActive: _currentStep >= 3,
      state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      content: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.insights, size: 48, color: Colors.tealAccent),
            const SizedBox(height: 16),
            if (_deadline != null) ...[
              Text('To reach ₹${_targetAmount.toStringAsFixed(0)} by ${DateFormat.yMMM().format(_deadline!)}',
                style: const TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text('You need to save', style: TextStyle(color: Colors.white54)),
              Text(_currencyFormat.format(monthlyNeeded), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const Text('every month', style: TextStyle(color: Colors.white54)),
            ] else ...[
              const Text('No deadline set', style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 16),
              const Text('Suggested savings pace', style: TextStyle(color: Colors.white54)),
              Text(_currencyFormat.format(_targetAmount * 0.1), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const Text('every month (10 months)', style: TextStyle(color: Colors.white54)),
            ],
          ],
        ),
      ),
    );
  }

  Step _buildReviewStep() {
    double monthlyNeeded = 0;
    if (_deadline != null) {
      final months = (_deadline!.year - DateTime.now().year) * 12 + _deadline!.month - DateTime.now().month;
      if (months > 0) monthlyNeeded = _targetAmount / months;
      else monthlyNeeded = _targetAmount;
    }

    return Step(
      title: const Text('Review', style: TextStyle(color: Colors.white)),
      isActive: _currentStep >= 4,
      content: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FinancialHealthTheme.excellent.withValues(alpha: 0.5), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_selectedTemplate?.icon ?? Icons.star, size: 32, color: _selectedTemplate?.themeColor ?? Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Goal', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(_title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 32),
            _buildReviewRow('Target', _currencyFormat.format(_targetAmount)),
            if (_deadline != null) ...[
              const SizedBox(height: 12),
              _buildReviewRow('Deadline', DateFormat.yMMMd().format(_deadline!)),
              const SizedBox(height: 12),
              _buildReviewRow('Monthly Needed', _currencyFormat.format(monthlyNeeded)),
            ],
            const SizedBox(height: 12),
            _buildReviewRow('Funding', _fundingStrategy.replaceAll('_', ' ')),
            const SizedBox(height: 12),
            _buildReviewRow('Risk', 'LOW', valueColor: FinancialHealthTheme.excellent),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewRow(String label, String value, {Color valueColor = Colors.white}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _saveGoal() {
    // In a real implementation, we would write to GoalRepository here
    Navigator.pop(context, {
      'title': _title,
      'targetAmount': _targetAmount,
      'deadline': _deadline,
      'fundingStrategy': _fundingStrategy,
      'templateId': _selectedTemplate?.id,
      'priority': _selectedTemplate?.basePriority ?? 50,
    });
  }
}
