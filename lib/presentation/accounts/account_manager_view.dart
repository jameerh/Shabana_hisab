import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/database.dart';
import '../../data/repositories/account_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../core/localization/bilingual_text.dart';
import '../../main.dart';

class AccountManagerView extends StatefulWidget {
  final int profileId;
  final AccountRepository? repository;

  const AccountManagerView({super.key, required this.profileId, this.repository});

  @override
  State<AccountManagerView> createState() => _AccountManagerViewState();
}

class _AccountManagerViewState extends State<AccountManagerView> {
  late final AccountRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? AccountRepository(database);
  }

  String _getAccountTypeDisplay(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return type;
    switch (type) {
      case 'Bank':
      case 'BANK':
        return l10n.accountTypeBank;
      case 'Cash':
      case 'CASH':
        return l10n.accountTypeCash;
      case 'Savings':
      case 'SAVINGS':
        return l10n.accountTypeSavings;
      case 'Credit':
      case 'CREDIT':
        return l10n.accountTypeCredit;
      case 'Wallet':
      case 'WALLET':
        return l10n.accountTypeWallet;
      default:
        return type;
    }
  }

  IconData _getAccountIcon(String type) {
    switch (type.toUpperCase()) {
      case 'BANK':
      case 'SAVINGS':
        return Icons.account_balance;
      case 'CASH':
        return Icons.money;
      case 'CREDIT':
        return Icons.credit_card;
      case 'WALLET':
        return Icons.account_balance_wallet;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  void _showAddEditAccountDialog([Account? account]) {
    final l10n = AppLocalizations.of(context);
    final isEdit = account != null;
    final nameCtrl = TextEditingController(text: account?.name ?? '');
    final balanceCtrl = TextEditingController(
      text: isEdit ? account.currentBalance.toStringAsFixed(0) : '0',
    );
    String selectedType = account?.type ?? 'Bank';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: BilingualText(
                english: isEdit ? 'Edit Account' : 'Add Account',
                marathi: isEdit ? 'खात्यात बदल करा' : 'नवीन खाते जोडा',
                languageController: languageController,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: l10n?.accountName ?? 'Account Name',
                        hintText: 'e.g. SBI Savings',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: InputDecoration(
                        labelText: l10n?.accountType ?? 'Account Type',
                      ),
                      items: ['Bank', 'Cash', 'Savings', 'Credit', 'Wallet']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(_getAccountTypeDisplay(context, type)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: balanceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isEdit
                            ? (l10n?.currentBalance ?? 'Current Balance')
                            : (l10n?.initialBalance ?? 'Initial Balance'),
                        prefixText: '₹ ',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n?.cancel ?? 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final balance = double.tryParse(balanceCtrl.text) ?? 0;
                    if (name.isEmpty) return;

                    if (isEdit) {
                      await _repo.updateAccount(
                        AccountsCompanion(
                          id: drift.Value(account.id),
                          profileId: drift.Value(account.profileId),
                          name: drift.Value(name),
                          type: drift.Value(selectedType),
                          currentBalance: drift.Value(balance),
                          updatedAt: drift.Value(DateTime.now()),
                        ),
                      );
                    } else {
                      await _repo.insertAccount(
                        AccountsCompanion.insert(
                          profileId: widget.profileId,
                          name: name,
                          type: selectedType,
                          openingBalance: drift.Value(balance),
                          currentBalance: drift.Value(balance),
                        ),
                      );
                    }
                    if (mounted) Navigator.pop(ctx);
                  },
                  child: Text(l10n?.save ?? 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTransferDialog(List<Account> accounts) {
    if (accounts.length < 2) return;
    final l10n = AppLocalizations.of(context);
    int fromId = accounts.first.id;
    int toId = accounts.length > 1 ? accounts[1].id : accounts.first.id;
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: BilingualText(
                english: 'Transfer Money',
                marathi: 'पैसे हस्तांतरित करा',
                languageController: languageController,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: fromId,
                      decoration: InputDecoration(
                        labelText: l10n?.fromAccount ?? 'From Account',
                      ),
                      items: accounts
                          .map((acc) => DropdownMenuItem(
                                value: acc.id,
                                child: Text('${acc.name} (₹${acc.currentBalance.toStringAsFixed(0)})'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => fromId = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: toId,
                      decoration: InputDecoration(
                        labelText: l10n?.toAccount ?? 'To Account',
                      ),
                      items: accounts
                          .map((acc) => DropdownMenuItem(
                                value: acc.id,
                                child: Text('${acc.name} (₹${acc.currentBalance.toStringAsFixed(0)})'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => toId = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n?.transferAmount ?? 'Transfer Amount',
                        prefixText: '₹ ',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n?.cancel ?? 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amt = double.tryParse(amountCtrl.text) ?? 0;
                    if (amt <= 0 || fromId == toId) return;

                    await _repo.transferFunds(fromId, toId, amt);
                    if (mounted) Navigator.pop(ctx);
                  },
                  child: Text(l10n?.transfer ?? 'Transfer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteAccount(Account account) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: BilingualText(
          english: 'Delete Account',
          marathi: 'खाते हटवा',
          languageController: languageController,
        ),
        content: Text(l10n?.deleteAccountConfirm ?? 'Are you sure you want to delete this account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _repo.softDeleteAccount(account.id);
              if (mounted) Navigator.pop(ctx);
            },
            child: Text(l10n?.delete ?? 'Delete', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: BilingualText(
          english: 'Account Manager',
          marathi: 'खाते व्यवस्थापक',
          languageController: languageController,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: l10n?.transferMoney ?? 'Transfer Money',
            onPressed: () async {
              final list = await _repo.getAccounts(widget.profileId);
              _showTransferDialog(list);
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Account>>(
        stream: _repo.watchAccounts(widget.profileId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final accounts = snapshot.data ?? [];
          if (accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.noAccountsFound ?? 'No accounts found',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditAccountDialog(),
                    icon: const Icon(Icons.add),
                    label: Text(l10n?.addAccount ?? 'Add Account'),
                  ),
                ],
              ),
            );
          }

          double totalBalance = accounts.fold(0, (sum, a) => sum + a.currentBalance);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Total Balance Header Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.indigo.shade900,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BilingualText(
                        english: 'Total Current Balance',
                        marathi: 'एकूण सध्याची शिल्लक',
                        languageController: languageController,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${totalBalance.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Accounts List
              ...accounts.map((acc) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Icon(_getAccountIcon(acc.type), color: Colors.blue.shade800),
                    ),
                    title: Text(acc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(_getAccountTypeDisplay(context, acc.type)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${acc.currentBalance.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: acc.currentBalance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _showAddEditAccountDialog(acc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          onPressed: () => _confirmDeleteAccount(acc),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditAccountDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
