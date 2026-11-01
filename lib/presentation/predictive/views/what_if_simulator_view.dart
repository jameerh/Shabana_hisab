import 'package:flutter/material.dart';
import '../../../data/database/database.dart';
import '../../../main.dart';
import '../sandbox/simulation_sandbox.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/localization/bilingual_text.dart';

class WhatIfSimulatorView extends StatefulWidget {
  final int profileId;

  const WhatIfSimulatorView({Key? key, required this.profileId}) : super(key: key);

  @override
  State<WhatIfSimulatorView> createState() => _WhatIfSimulatorViewState();
}

class _WhatIfSimulatorViewState extends State<WhatIfSimulatorView> {
  final _titleController = TextEditingController(text: 'Buy New Bike');
  String _category = 'PURCHASE';
  double _lumpSum = 150000;
  double _monthlyCost = 3000;
  double _monthlyIncome = 0;

  SimulationResult? _result;
  bool _isSimulating = false;

  void _runSimulation() async {
    setState(() => _isSimulating = true);

    final sandbox = SimulationSandbox(database);
    final res = await sandbox.runScenario(
      profileId: widget.profileId,
      input: SimulationScenarioInput(
        scenarioTitle: _titleController.text.isEmpty ? 'Custom Scenario' : _titleController.text,
        scenarioCategory: _category,
        lumpSumCost: _lumpSum,
        monthlyDeltaCost: _monthlyCost,
        monthlyDeltaIncome: _monthlyIncome,
      ),
    );

    if (!mounted) return;
    setState(() {
      _result = res;
      _isSimulating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: BilingualText(
          english: 'What-If Simulator Sandbox 🔮',
          marathi: 'व्हाॉट-इफ सिम्युलेटर 🔮',
          languageController: languageController,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Colors.blueAccent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n?.isolatedSandboxNotice ?? 'Isolated Sandbox: Simulations run in memory and never mutate active live financial records or budgets.',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: l10n?.scenarioTitle ?? 'Scenario Title',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: l10n?.category ?? 'Category',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                DropdownMenuItem(value: 'PURCHASE', child: Text(l10n?.categoryPurchase ?? 'Major Purchase (Bike, Gadget)')),
                DropdownMenuItem(value: 'SALARY', child: Text(l10n?.categorySalaryScenario ?? 'Salary Hike / Job Change')),
                DropdownMenuItem(value: 'RENT', child: Text(l10n?.categoryRentScenario ?? 'Rent Adjustment')),
                DropdownMenuItem(value: 'SAVINGS', child: Text(l10n?.categorySavingsScenario ?? 'Daily Savings Target')),
                DropdownMenuItem(value: 'LOAN', child: Text(l10n?.categoryLoanScenario ?? 'Loan / EMI Commitment')),
                DropdownMenuItem(value: 'INVESTMENT', child: Text(l10n?.categoryInvestmentScenario ?? 'Investment / SIP')),
                DropdownMenuItem(value: 'EDUCATION', child: Text(l10n?.categoryEducationScenario ?? 'Child Education / Course')),
                DropdownMenuItem(value: 'VACATION', child: Text(l10n?.categoryVacationScenario ?? 'Vacation / Travel Trip')),
                DropdownMenuItem(value: 'MEDICAL', child: Text(l10n?.categoryMedicalScenario ?? 'Medical Expense')),
                DropdownMenuItem(value: 'HOUSE', child: Text(l10n?.categoryHouseScenario ?? 'House Down Payment')),
                DropdownMenuItem(value: 'BUSINESS', child: Text(l10n?.categoryBusinessScenario ?? 'Business Expansion')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),
            const SizedBox(height: 16),
            Text('${l10n?.lumpSumOutflow ?? "Lump Sum Outflow"}: ${currency.format(_lumpSum)}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            Slider(
              value: _lumpSum,
              min: 0,
              max: 1000000,
              divisions: 100,
              activeColor: Colors.purpleAccent,
              onChanged: (val) => setState(() => _lumpSum = val),
            ),
            Text('${l10n?.monthlyDeltaExpense ?? "Monthly Delta Expense"}: ${currency.format(_monthlyCost)}/mo', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            Slider(
              value: _monthlyCost,
              min: 0,
              max: 50000,
              divisions: 50,
              activeColor: Colors.orangeAccent,
              onChanged: (val) => setState(() => _monthlyCost = val),
            ),
            Text('${l10n?.monthlyDeltaIncome ?? "Monthly Delta Income"}: ${currency.format(_monthlyIncome)}/mo', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            Slider(
              value: _monthlyIncome,
              min: 0,
              max: 100000,
              divisions: 50,
              activeColor: Colors.greenAccent,
              onChanged: (val) => setState(() => _monthlyIncome = val),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSimulating ? null : _runSimulation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isSimulating ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.psychology_rounded, color: Colors.white),
              label: Text(l10n?.runWhatIfSimulation ?? 'Run What-If Simulation', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            if (_result != null) ...[
              BilingualText(
                english: 'Simulation Predictions 📊',
                marathi: 'सिम्युलेशन अंदाज 📊',
                languageController: languageController,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    _buildResultRow(l10n?.simulatedHealthIndex ?? 'Simulated Health Index', '${_result!.simulatedHealthScore}/100', Colors.tealAccent),
                    const Divider(color: Colors.white24),
                    _buildResultRow(l10n?.activeGoalDelayImpact ?? 'Active Goal Delay Impact', '+${_result!.impactGoalDelayMonths.toStringAsFixed(1)} Months', Colors.amberAccent),
                    const Divider(color: Colors.white24),
                    _buildResultRow(l10n?.monthlyCashFlowDelta ?? 'Monthly Cash Flow Delta', currency.format(_result!.impactCashFlowDelta), _result!.impactCashFlowDelta >= 0 ? Colors.greenAccent : Colors.redAccent),
                    const Divider(color: Colors.white24),
                    _buildResultRow(l10n?.safeToSpendShift ?? 'Safe To Spend Shift', currency.format(_result!.impactSafeToSpendDelta), _result!.impactSafeToSpendDelta >= 0 ? Colors.greenAccent : Colors.orangeAccent),
                  ],
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String val, Color valColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(val, style: TextStyle(color: valColor, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
