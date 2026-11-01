import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../data/database/database.dart';
import '../../../main.dart';
import '../../core/theme/financial_health_theme.dart';
import '../../goals/goal_manager_view.dart';
import '../../budget/budget_manager_view.dart';
import '../../recurring/recurring_manager_view.dart';
import '../../intelligence/financial_intelligence_view.dart';
import '../../predictive/views/predictive_dashboard_view.dart';
import '../../predictive/views/what_if_simulator_view.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/localization/bilingual_text.dart';
import '../../../core/localization/localization_service.dart';

class IntelligenceDashboardSection extends StatefulWidget {
  final int profileId;
  final bool initialExpanded;

  const IntelligenceDashboardSection({
    Key? key,
    required this.profileId,
    this.initialExpanded = false,
  }) : super(key: key);

  @override
  State<IntelligenceDashboardSection> createState() => _IntelligenceDashboardSectionState();
}

class _IntelligenceDashboardSectionState extends State<IntelligenceDashboardSection> {
  late bool _isExpanded;

  int get profileId => widget.profileId;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildExpandableHeader(context),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Recommendation Cards (ADR-014 compliant)
                _buildRecommendationsSection(context),
                const SizedBox(height: 16),

                // 2. Insights Observations Banner (ADR-015 compliant)
                _buildInsightsSection(context),
                const SizedBox(height: 16),

                // 3. Financial Health Hero Metric (0-100)
                _buildFinancialHealthCard(context),
                const SizedBox(height: 16),

                // 4. Cash Position & 5. Safe To Spend Grid
                _buildCashAndSafeToSpendGrid(context),
                const SizedBox(height: 16),

                // 6. Goals Summary Cards
                _buildGoalsSummarySection(context),
                const SizedBox(height: 16),

                // 7. Budgets Summary Cards
                _buildBudgetsSummarySection(context),
                const SizedBox(height: 16),

                // 8. Recurring Commitments Card
                _buildRecurringSummarySection(context),
              ],
            ),
          ),
          crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.easeInOutCubic,
        ),
      ],
    );
  }

  Widget _buildExpandableHeader(BuildContext context) {
    return StreamBuilder<List<Recommendation>>(
      stream: (database.select(database.recommendations)
            ..where((r) => r.profileId.equals(profileId)))
          .watch(),
      builder: (context, snapshot) {
        final recs = (snapshot.hasError || !snapshot.hasData) ? <Recommendation>[] : (snapshot.data ?? []);
        final hasRisk = recs.any((r) => r.category == 'RISK' || r.category == 'CRITICAL');
        final alertCount = recs.length;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey[900]!,
                    const Color(0xFF161B22),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasRisk
                      ? Colors.redAccent.withValues(alpha: 0.4)
                      : Colors.tealAccent.withValues(alpha: 0.25),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: hasRisk
                        ? Colors.redAccent.withValues(alpha: 0.08)
                        : Colors.tealAccent.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasRisk
                          ? Colors.redAccent.withValues(alpha: 0.15)
                          : Colors.tealAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      hasRisk ? Icons.warning_amber_rounded : Icons.auto_awesome_rounded,
                      color: hasRisk ? Colors.redAccent : Colors.tealAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: BilingualText(
                                english: 'Financial Intelligence',
                                marathi: 'आर्थिक विश्लेषण व अंतर्दृष्टी',
                                languageController: languageController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        BilingualText(
                          english: _isExpanded
                              ? 'Tap to collapse'
                              : (hasRisk
                                  ? 'Cash flow alert detected • Tap to view'
                                  : 'Health, risk alerts & insights'),
                          marathi: _isExpanded
                              ? 'लपवण्यासाठी टॅप करा'
                              : (hasRisk
                                  ? 'धोका सूचना आढळली • पाहण्यासाठी टॅप करा'
                                  : 'आरोग्य, सूचना आणि अंतर्दृष्टी'),
                          languageController: languageController,
                          style: TextStyle(
                            color: hasRisk ? Colors.orangeAccent : Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasRisk) ...[
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.circle, color: Colors.redAccent, size: 7),
                          const SizedBox(width: 4),
                          Text(
                            alertCount > 1 ? '$alertCount ALERTS' : 'RISK',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (alertCount > 0) ...[
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.tealAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '$alertCount NEW',
                        style: const TextStyle(
                          color: Colors.tealAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- 1. Recommendation Cards ---
  Widget _buildRecommendationsSection(BuildContext context) {
    return StreamBuilder<List<Recommendation>>(
      stream: (database.select(database.recommendations)
            ..where((r) => r.profileId.equals(profileId))
            ..orderBy([(r) => OrderingTerm.asc(r.priority)]))
          .watch(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final recs = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: recs.map((rec) => _buildRecommendationCard(context, rec)).toList(),
        );
      },
    );
  }

  Widget _buildRecommendationCard(BuildContext context, Recommendation rec) {
    Color cardColor = Colors.blueAccent;
    IconData icon = Icons.lightbulb_outline;

    switch (rec.category) {
      case 'RISK':
        cardColor = FinancialHealthTheme.emergency;
        icon = Icons.warning_amber_rounded;
        break;
      case 'LIQUIDITY':
        cardColor = FinancialHealthTheme.warning;
        icon = Icons.account_balance_wallet_outlined;
        break;
      case 'BUDGET':
        cardColor = FinancialHealthTheme.critical;
        icon = Icons.pie_chart_outline;
        break;
      case 'GOAL':
        cardColor = FinancialHealthTheme.excellent;
        icon = Icons.stars_rounded;
        break;
      default:
        cardColor = Colors.indigoAccent;
        icon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.12),
        border: Border.all(color: cardColor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: cardColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            rec.title,
                            style: TextStyle(color: cardColor, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            rec.category,
                            style: TextStyle(color: cardColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rec.description,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.help_outline, color: Colors.white54, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    rec.whyShown,
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Insights Observations Section ---
  Widget _buildInsightsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return StreamBuilder<List<Insight>>(
      stream: (database.select(database.insights)
            ..where((i) => i.profileId.equals(profileId) & i.status.equals('ACTIVE'))
            ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
          .watch(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        final insights = snapshot.data ?? [];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_graph_rounded, color: Colors.tealAccent, size: 20),
                      const SizedBox(width: 8),
                      BilingualText(
                        english: 'Financial Insights',
                        marathi: 'आर्थिक निरिक्षणे',
                        languageController: languageController,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => FinancialIntelligenceView(profileId: profileId)));
                    },
                    child: Text(
                      '${l10n?.intelligenceHub ?? "Intelligence Hub"} >',
                      style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              if (insights.isEmpty)
                const Text('Analyzing spending patterns...', style: TextStyle(color: Colors.white54, fontSize: 12))
              else
                Column(
                  children: insights.take(2).map((insight) {
                    Color severityColor = Colors.tealAccent;
                    if (insight.severity == 'WARNING') severityColor = Colors.orangeAccent;
                    if (insight.severity == 'CRITICAL') severityColor = Colors.redAccent;
                    if (insight.severity == 'MILESTONE') severityColor = Colors.amberAccent;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(color: severityColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              insight.observation,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PredictiveDashboardView(profileId: profileId))),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.4))),
                      child: Row(
                        children: [
                          Text('🔮 ${l10n?.predictiveHub ?? "Predictive Hub"}', style: const TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WhatIfSimulatorView(profileId: profileId))),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4))),
                      child: Row(
                        children: [
                          Text('✨ ${l10n?.whatIfSimulator ?? "What-If Simulator"}', style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 3. Financial Health Hero Metric ---
  Widget _buildFinancialHealthCard(BuildContext context) {
    return StreamBuilder<List<CashFlowStateData>>(
      stream: (database.select(database.cashFlowState)
            ..where((c) => c.profileId.equals(profileId)))
          .watch(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final state = snapshot.data!.first;
        final score = state.healthScore;
        final color = FinancialHealthTheme.getColor(score);
        final rawLabel = FinancialHealthTheme.getLabel(score);
        final localizedLabel = LocalizationService.getHealthLabel(context, rawLabel);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[900]!, Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_outlined, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        BilingualText(
                          english: 'FINANCIAL HEALTH',
                          marathi: 'आर्थिक आरोग्य',
                          languageController: languageController,
                          style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    BilingualText(
                      english: rawLabel,
                      marathi: localizedLabel,
                      languageController: languageController,
                      style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Integrated FOS Health Index',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: score / 100.0,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.15),
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$score',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        '/100',
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 4. Cash Position & 5. Safe To Spend Grid ---
  Widget _buildCashAndSafeToSpendGrid(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final monthName = DateFormat('MMM').format(now);
    final untilText = '${endOfMonth.day} $monthName';

    return StreamBuilder<List<CashFlowStateData>>(
      stream: (database.select(database.cashFlowState)
            ..where((c) => c.profileId.equals(profileId)))
          .watch(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final state = snapshot.data!.first;
        final dailySafe = (state.safeToSpend / (endOfMonth.day - now.day + 1)).clamp(0, double.infinity);

        return Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('💰', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        BilingualText(
                          english: 'Cash Position',
                          marathi: 'रोख स्थिती',
                          languageController: languageController,
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currency.format(state.cashPosition),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        state.netPosition >= 0 ? (l10n?.healthHealthy ?? 'Healthy') : (l10n?.deficitRisk ?? 'Deficit Risk'),
                        style: TextStyle(
                          color: state.netPosition >= 0 ? Colors.tealAccent : Colors.orangeAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🛡️', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        BilingualText(
                          english: 'Safe To Spend',
                          marathi: 'सुरक्षित खर्च',
                          languageController: languageController,
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${currency.format(dailySafe)}/day',
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${l10n?.safeUntil ?? "Safe Until"} $untilText',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- 6. Goals Summary Section ---
  Widget _buildGoalsSummarySection(BuildContext context) {
    return StreamBuilder<List<Goal>>(
      stream: (database.select(database.goals)
            ..where((g) => g.profileId.equals(profileId) & g.status.equals('ACTIVE')))
          .watch(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final goals = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.flag_rounded, color: Colors.amberAccent, size: 20),
                      SizedBox(width: 8),
                      Text('Active Goals', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GoalManagerView(profileId: profileId)));
                    },
                    child: const Text('View All >', style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Column(
                children: goals.take(3).map((g) => _buildGoalRow(context, g)).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoalRow(BuildContext context, Goal goal) {
    return StreamBuilder<List<GoalStateData>>(
      stream: (database.select(database.goalState)..where((s) => s.goalId.equals(goal.id))).watch(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        final state = snapshot.data?.firstOrNull;
        final health = state?.healthScore ?? 100;
        final healthColor = FinancialHealthTheme.getColor(health);
        final forecastDate = state?.expectedCompletion != null ? DateFormat('MMM yyyy').format(state!.expectedCompletion!) : 'Ongoing';
        final emoji = goal.goalType == 'DEBT' ? '💳' : (goal.goalType == 'PURCHASE' ? '🛍️' : '🎯');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Forecast: $forecastDate', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: healthColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: healthColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Health $health',
                  style: TextStyle(color: healthColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 7. Budgets Summary Section ---
  Widget _buildBudgetsSummarySection(BuildContext context) {
    return StreamBuilder<List<Budget>>(
      stream: (database.select(database.budgets)..where((b) => b.profileId.equals(profileId) & b.enabled.equals(true))).watch(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final budgets = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.pie_chart_rounded, color: Colors.cyanAccent, size: 20),
                      SizedBox(width: 8),
                      Text('Active Budgets', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetManagerView(profileId: profileId)));
                    },
                    child: const Text('View All >', style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Column(
                children: budgets.take(3).map((b) => _buildBudgetRow(context, b)).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBudgetRow(BuildContext context, Budget budget) {
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return StreamBuilder<List<BudgetStateData>>(
      stream: (database.select(database.budgetState)..where((s) => s.budgetId.equals(budget.id))).watch(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        final state = snapshot.data?.firstOrNull;
        final spent = state?.currentSpent ?? 0.0;
        final pct = budget.limitAmount > 0 ? (spent / budget.limitAmount) * 100.0 : 0.0;
        final statusColor = pct > 90 ? Colors.redAccent : (pct > 75 ? Colors.orangeAccent : Colors.cyanAccent);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(budget.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(
                    '${pct.toStringAsFixed(0)}% (${currency.format(spent)})',
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (pct / 100.0).clamp(0.0, 1.0),
                  color: statusColor,
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 8. Recurring Commitments Section ---
  Widget _buildRecurringSummarySection(BuildContext context) {
    return StreamBuilder<List<RecurringRuleData>>(
      stream: (database.select(database.recurringRule)
            ..where((r) => r.profileId.equals(profileId) & r.enabled.equals(true) & r.status.equals('ACTIVE')))
          .watch(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final rules = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_repeat_rounded, color: Colors.purpleAccent, size: 22),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${rules.length} Active Recurring Rules', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      const Text('Automated & Tracked Schedules', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => RecurringManagerView(profileId: profileId)));
                },
                child: const Text('Manage >', style: TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}
