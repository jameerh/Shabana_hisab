import 'package:flutter/material.dart';
import '../goals/goal_manager_view.dart';
import '../budget/budget_manager_view.dart';
import '../accounts/account_manager_view.dart';
import '../../core/localization/bilingual_text.dart';
import '../../main.dart';

class FinancialPlanningHubView extends StatelessWidget {
  final int profileId;

  const FinancialPlanningHubView({super.key, required this.profileId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: BilingualText(
          english: 'Financial Planning',
          marathi: 'आर्थिक नियोजन',
          languageController: languageController,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHubCard(
            context,
            icon: Icons.flag,
            title: 'Goals & Targets',
            marathiTitle: 'ध्येय आणि उद्दिष्टे',
            subtitle: 'Set financial goals and track progress',
            color: Colors.blue,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => GoalManagerView(profileId: profileId),
              ));
            },
          ),
          _buildHubCard(
            context,
            icon: Icons.account_balance_wallet,
            title: 'Budgets',
            marathiTitle: 'बजेट आणि मर्यादा',
            subtitle: 'Control spending and set limits',
            color: Colors.teal,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => BudgetManagerView(profileId: profileId),
              ));
            },
          ),
          _buildHubCard(
            context,
            icon: Icons.account_balance,
            title: 'Accounts',
            marathiTitle: 'खाते व्यवस्थापन',
            subtitle: 'Manage your balances and liquidity',
            color: Colors.indigo,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => AccountManagerView(profileId: profileId),
              ));
            },
          ),
          _buildHubCard(
            context,
            icon: Icons.insights,
            title: 'Forecast',
            marathiTitle: 'अंदाज',
            subtitle: 'Predict your future cash flow',
            color: Colors.purple,
            onTap: () {
              // TODO: Implement Forecast
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHubCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String marathiTitle,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BilingualText(
                      english: title,
                      marathi: marathiTitle,
                      languageController: languageController,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}
