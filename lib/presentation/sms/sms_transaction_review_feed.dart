import 'package:flutter/material.dart';
import '../../core/sms/sms_parsed_result.dart';
import '../../data/repositories/sms_repository.dart';
import '../../core/localization/bilingual_text.dart';
import '../../main.dart';

class SmsTransactionReviewFeed extends StatefulWidget {
  final int profileId;
  final List<SmsParsedResult> candidates;
  const SmsTransactionReviewFeed({
    super.key,
    required this.profileId,
    required this.candidates,
  });

  @override
  State<SmsTransactionReviewFeed> createState() => _SmsTransactionReviewFeedState();
}

class _SmsTransactionReviewFeedState extends State<SmsTransactionReviewFeed> {
  final SmsRepository _repository = SmsRepository();
  late Set<int> _selectedIndices;

  @override
  void initState() {
    super.initState();
    // Pre-select high confidence candidates (score >= 0.90)
    _selectedIndices = {};
    for (int i = 0; i < widget.candidates.length; i++) {
      if (widget.candidates[i].confidence.isHighConfidence) {
        _selectedIndices.add(i);
      }
    }
  }

  Future<void> _commitSelected() async {
    final selectedList = _selectedIndices.map((i) => widget.candidates[i]).toList();
    if (selectedList.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final count = await _repository.commitApprovedTransactions(
      profileId: widget.profileId,
      approvedResults: selectedList,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully imported $count transactions into Hisaab')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BilingualText(
          english: 'Review Transactions',
          marathi: 'व्यवहार तपासा',
          languageController: languageController,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: widget.candidates.length,
              itemBuilder: (context, index) {
                final item = widget.candidates[index];
                final isSelected = _selectedIndices.contains(index);
                final isExpense = item.transactionType == 'Expense';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedIndices.add(index);
                        } else {
                          _selectedIndices.remove(index);
                        }
                      });
                    },
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.partyName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${isExpense ? '-' : '+'}₹${item.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isExpense ? Colors.red.shade700 : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Row(
                        children: [
                          Text(
                            '${item.bankName} •••• ${item.accountNumberLast4}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.confidence.isHighConfidence
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${(item.confidence.overallScore * 100).toStringAsFixed(0)}% Confidence',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: item.confidence.isHighConfidence
                                    ? Colors.green.shade900
                                    : Colors.orange.shade900,
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
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedIndices.isEmpty ? null : _commitSelected,
                icon: const Icon(Icons.add_task),
                label: Text('Add Selected (${_selectedIndices.length})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
