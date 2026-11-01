import 'package:flutter/material.dart';
import '../../../data/database/database.dart'; // Drift Database
import '../../../l10n/app_localizations.dart';
import '../../../core/localization/bilingual_text.dart';
import '../../../main.dart';

class BalanceSummary extends StatefulWidget {
  final List<Transaction> transactions;

  const BalanceSummary({super.key, required this.transactions});

  @override
  State<BalanceSummary> createState() => _BalanceSummaryState();
}

class _BalanceSummaryState extends State<BalanceSummary> {
  bool _isBalanceExpanded = false;

  Widget _buildSummaryItem(String englishLabel, String marathiLabel, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BilingualText(
          english: englishLabel,
          marathi: marathiLabel,
          languageController: languageController,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    double income = 0;
    double expense = 0;
    double udhaari = 0;

    for (var tx in widget.transactions) {
      if (tx.type == 'Income') income += tx.amount;
      else if (tx.type == 'Expense') expense += tx.amount;
      else if (tx.type == 'Udhaari') udhaari += tx.amount;
    }

    final balance = income - expense;
    final balanceColor = balance >= 0 ? Colors.green.shade700 : Colors.red.shade700;
    final projectedBalance = balance + udhaari;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: balance >= 0
              ? [Colors.green.shade50.withOpacity(0.8), Colors.white]
              : [Colors.red.shade50.withOpacity(0.8), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: balance >= 0 ? Colors.green.shade100 : Colors.red.shade100,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Net Balance & Toggle Arrow
          InkWell(
            onTap: () {
              setState(() {
                _isBalanceExpanded = !_isBalanceExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              balance >= 0 ? Icons.account_balance_wallet_outlined : Icons.warning_amber_rounded,
                              color: balance >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            BilingualText(
                              english: 'Net Balance',
                              marathi: 'एकूण शिल्लक',
                              languageController: languageController,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₹${balance.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: balanceColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: balance >= 0 ? Colors.green.shade100.withOpacity(0.5) : Colors.red.shade100.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isBalanceExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: balance >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Collapsed summary preview
          if (!_isBalanceExpanded) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BilingualText(
                  english: 'Income: ₹${income.toStringAsFixed(0)}  |  Expense: ₹${expense.toStringAsFixed(0)}',
                  marathi: 'जमा: ₹${income.toStringAsFixed(0)}  |  खर्च: ₹${expense.toStringAsFixed(0)}',
                  languageController: languageController,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
                if (udhaari > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade100),
                    ),
                    child: Text(
                      '${l10n?.creditShort ?? "Credit"}: ₹${udhaari.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],

          // Expanded Details
          if (_isBalanceExpanded) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Income', 'एकूण जमा', '₹${income.toStringAsFixed(0)}', Colors.green.shade700),
                _buildSummaryItem('Expense', 'एकूण खर्च', '₹${expense.toStringAsFixed(0)}', Colors.red.shade700),
              ],
            ),
            if (udhaari > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem('Credit', 'एकूण उधारी', '₹${udhaari.toStringAsFixed(0)}', Colors.orange.shade800),
                  const SizedBox(),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 14),
                            const SizedBox(width: 4),
                            BilingualText(
                              english: 'If Recovered',
                              marathi: 'उधारी वसुली नंतर',
                              languageController: languageController,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        BilingualText(
                          english: 'Total Potential',
                          marathi: 'एकूण संभाव्य शिल्लक',
                          languageController: languageController,
                          style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade600),
                        ),
                      ],
                    ),
                    Text(
                      '₹${projectedBalance.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
