import 'package:flutter/material.dart';
import '../../data/database/database.dart';
import '../../data/repositories/sms_repository.dart';
import '../../core/localization/bilingual_text.dart';
import '../../main.dart';

class SmsAccountDiscoverySheet extends StatefulWidget {
  final int profileId;
  const SmsAccountDiscoverySheet({super.key, required this.profileId});

  @override
  State<SmsAccountDiscoverySheet> createState() => _SmsAccountDiscoverySheetState();
}

class _SmsAccountDiscoverySheetState extends State<SmsAccountDiscoverySheet> {
  final SmsRepository _repository = SmsRepository();

  Color _getBankColor(String bankName) {
    final lower = bankName.toLowerCase();
    if (lower.contains('hdfc')) return Colors.blue.shade900;
    if (lower.contains('sbi') || lower.contains('state bank')) return Colors.blue.shade700;
    if (lower.contains('icici')) return Colors.orange.shade800;
    if (lower.contains('axis')) return Colors.purple.shade900;
    if (lower.contains('kotak')) return Colors.red.shade800;
    if (lower.contains('paytm')) return Colors.cyan.shade700;
    return Colors.indigo.shade600;
  }

  IconData _getAccountIcon(String accountType) {
    switch (accountType) {
      case 'CREDIT_CARD':
        return Icons.credit_card;
      case 'WALLET':
        return Icons.account_balance_wallet;
      case 'UPI':
        return Icons.qr_code_2;
      default:
        return Icons.account_balance;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BilingualText(
          english: 'Discovered Accounts & Cards',
          marathi: 'शोधलेली खाती आणि कार्डे',
          languageController: languageController,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<SmsTrackedAccount>>(
        stream: _repository.watchTrackedAccounts(widget.profileId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final accounts = snapshot.data!;
          if (accounts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No bank accounts or credit cards discovered yet.\nTap "Scan Bank & Card SMS" to scan your inbox.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final acc = accounts[index];
              final isPermitted = acc.status == SmsAccountStatus.PERMITTED;
              final bankColor = _getBankColor(acc.bankName);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  onTap: () => _showAccountAnalyticsSheet(context, acc),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: bankColor,
                    radius: 24,
                    child: Icon(_getAccountIcon(acc.accountType), color: Colors.white, size: 22),
                  ),
                  title: Text(
                    '${acc.bankName} •••• ${acc.accountNumberLast4}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPermitted ? Colors.green.shade100 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isPermitted ? 'TRACKING PERMITTED' : 'IGNORED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isPermitted ? Colors.green.shade900 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tap for analytics',
                          style: TextStyle(fontSize: 11, color: Colors.indigo.shade600),
                        ),
                      ],
                    ),
                  ),
                  trailing: Switch(
                    value: isPermitted,
                    activeThumbColor: Colors.green,
                    onChanged: (val) {
                      _repository.updateAccountStatus(
                        acc.id,
                        val ? SmsAccountStatus.PERMITTED : SmsAccountStatus.IGNORED,
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAccountAnalyticsSheet(BuildContext context, SmsTrackedAccount acc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          final bankColor = _getBankColor(acc.bankName);

          return StreamBuilder<List<Transaction>>(
            stream: database.watchTransactionsByProfile(acc.profileId),
            builder: (context, snapshot) {
              final allTxns = snapshot.data ?? [];
              final filteredTxns = allTxns.where((t) {
                final meta = (t.metadata ?? '').toLowerCase();
                final party = (t.partyName).toLowerCase();
                final bank = acc.bankName.toLowerCase();
                final last4 = acc.accountNumberLast4;
                return meta.contains(last4) || party.contains(bank) || meta.contains(bank);
              }).toList();

              double totalExpense = 0;
              double totalIncome = 0;
              for (final t in filteredTxns) {
                if (t.type == 'Expense') totalExpense += t.amount;
                if (t.type == 'Income') totalIncome += t.amount;
              }

              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20.0),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: bankColor,
                        radius: 24,
                        child: Icon(_getAccountIcon(acc.accountType), color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${acc.bankName} •••• ${acc.accountNumberLast4}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              '${acc.accountType} Account Analytics',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Spent', style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                '₹${totalExpense.toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.red.shade700, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Received', style: TextStyle(color: Colors.green.shade900, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                '₹${totalIncome.toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.green.shade700, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Account Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  if (filteredTxns.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'No transactions imported for this account yet.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  else
                    ...filteredTxns.map((txn) {
                      final isExpense = txn.type == 'Expense';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: isExpense ? Colors.red.shade100 : Colors.green.shade100,
                          child: Icon(
                            isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isExpense ? Colors.red.shade700 : Colors.green.shade700,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          txn.partyName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${txn.timestamp.day}/${txn.timestamp.month}/${txn.timestamp.year} • ${txn.categoryName ?? 'General'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          '${isExpense ? '-' : '+'}₹${txn.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isExpense ? Colors.red.shade700 : Colors.green.shade700,
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
