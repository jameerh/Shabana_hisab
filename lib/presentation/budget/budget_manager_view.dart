import 'package:flutter/material.dart';
import '../../data/database/database.dart';
import '../../main.dart';
import '../../data/repositories/budget_repository.dart';
import 'package:intl/intl.dart';

class BudgetManagerView extends StatefulWidget {
  final int profileId;

  const BudgetManagerView({super.key, required this.profileId});

  @override
  State<BudgetManagerView> createState() => _BudgetManagerViewState();
}

class _BudgetManagerViewState extends State<BudgetManagerView> {
  String _filter = 'ACTIVE';

  Color _getStatusColor(String status) {
    switch (status) {
      case 'HEALTHY': return Colors.green;
      case 'WARNING': return Colors.orange;
      case 'CRITICAL': return Colors.deepOrange;
      case 'EXCEEDED': return Colors.red;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Engine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Budget Wizard
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Budget Wizard coming soon')),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['ACTIVE', 'PAUSED'].map((f) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(f),
                  selected: _filter == f,
                  onSelected: (val) {
                    if (val) setState(() => _filter = f);
                  },
                ),
              )).toList(),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<BudgetWithState>>(
              stream: budgetRepository.watchBudgetsWithState(widget.profileId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final allBudgets = snapshot.data ?? [];
                // Filtering
                final budgets = allBudgets.where((b) {
                  if (_filter == 'ACTIVE') return b.budget.enabled;
                  if (_filter == 'PAUSED') return !b.budget.enabled;
                  return true;
                }).toList();

                if (budgets.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: budgets.length,
                  itemBuilder: (context, index) {
                    final item = budgets[index];
                    final b = item.budget;
                    final s = item.state;
                    
                    final NumberFormat currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
                    
                    double spent = s?.currentSpent ?? 0.0;
                    double limit = b.limitAmount;
                    double progress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
                    String status = s?.status ?? 'HEALTHY';
                    Color statusColor = _getStatusColor(status);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () {
                          // View Details
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    b.title,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Spent', style: Theme.of(context).textTheme.bodySmall),
                                      Text(currency.format(spent), style: Theme.of(context).textTheme.titleMedium),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Limit', style: Theme.of(context).textTheme.bodySmall),
                                      Text(currency.format(limit), style: Theme.of(context).textTheme.titleMedium),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                ),
                              ),
                              if (s != null) ...[
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Safe Today: ${currency.format(s.safeToSpend)}',
                                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      'Health: ${s.healthScore}',
                                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ]
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Budgets Found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a budget to plan your spending.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Budget Wizard coming soon')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Budget'),
          )
        ],
      ),
    );
  }
}
