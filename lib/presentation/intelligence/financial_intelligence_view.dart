import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import '../../data/database/database.dart';
import '../../main.dart';
import '../core/theme/financial_health_theme.dart';
import 'services/structured_narrative_generator.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../core/localization/bilingual_text.dart';

class FinancialIntelligenceView extends StatefulWidget {
  final int profileId;

  const FinancialIntelligenceView({Key? key, required this.profileId}) : super(key: key);

  @override
  State<FinancialIntelligenceView> createState() => _FinancialIntelligenceViewState();
}

class _FinancialIntelligenceViewState extends State<FinancialIntelligenceView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StructuredNarrative? _narrative;
  bool _isLoadingNarrative = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadNarrative();
  }

  Future<void> _loadNarrative() async {
    final generator = StructuredNarrativeGenerator(database);
    final narrative = await generator.generate(widget.profileId);
    if (mounted) {
      setState(() {
        _narrative = narrative;
        _isLoadingNarrative = false;
      });
    }
  }

  Future<void> _performMonthlyClosing() async {
    final now = DateTime.now();
    final period = DateFormat('yyyy-MM').format(now);

    final cashFlow = await (database.select(database.cashFlowState)..where((c) => c.profileId.equals(widget.profileId))).getSingleOrNull();
    final liquidity = await (database.select(database.liquidityState)..where((l) => l.profileId.equals(widget.profileId))).getSingleOrNull();
    final forecast = await (database.select(database.forecastState)..where((f) => f.profileId.equals(widget.profileId))).getSingleOrNull();

    final existing = await (database.select(database.financialClosing)
          ..where((fc) => fc.profileId.equals(widget.profileId) & fc.period.equals(period)))
        .getSingleOrNull();

    if (existing != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Closing snapshot for $period already finalized.')));
      }
      return;
    }

    final narrative = await StructuredNarrativeGenerator(database).generate(widget.profileId);

    await database.into(database.financialClosing).insert(FinancialClosingCompanion.insert(
      profileId: widget.profileId,
      period: period,
      income: Value(forecast?.expectedIncome ?? 0),
      expense: Value(forecast?.expectedExpense ?? 0),
      recurring: Value(forecast?.expectedRecurring ?? 0),
      netWorth: Value((liquidity?.liquidAssets ?? 0) - (forecast?.expectedExpense ?? 0)),
      liquidityAvailable: Value(liquidity?.available ?? 0),
      healthScore: Value(cashFlow?.healthScore ?? 100),
      narrativeJson: Value(narrative.periodName),
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Monthly Closing Snapshot $period finalized!')));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: BilingualText(
          english: 'Financial Intelligence Hub',
          marathi: 'आर्थिक बुद्धिमत्ता केंद्र',
          languageController: languageController,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined, color: Colors.amberAccent),
            tooltip: 'Finalize Monthly Closing',
            onPressed: _performMonthlyClosing,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.tealAccent,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Narrative'),
            Tab(text: 'Closing'),
            Tab(text: 'Analytics'),
            Tab(text: 'Timeline'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNarrativeTab(),
          _buildMonthlyClosingTab(),
          _buildAnalyticsTab(),
          _buildTimelineTab(),
        ],
      ),
    );
  }

  // --- Tab 1: Structured Narrative ---
  Widget _buildNarrativeTab() {
    if (_isLoadingNarrative) {
      return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
    }
    if (_narrative == null) {
      return const Center(child: Text('No narrative generated.', style: TextStyle(color: Colors.white54)));
    }

    final n = _narrative!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(n.periodName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Rule-Based Structured Intelligence Summary', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 16),

          _buildNarrativeBlock('🏆 Achievements', n.achievements, Colors.greenAccent),
          _buildNarrativeBlock('⚠️ Warnings', n.warnings, Colors.orangeAccent),
          _buildNarrativeBlock('📈 Improvements', n.improvements, Colors.cyanAccent),
          _buildNarrativeBlock('🔮 30-Day Forecast', n.forecast, Colors.purpleAccent),
          _buildNarrativeBlock('🎯 Strategic Recommendations', n.recommendations, Colors.amberAccent),
        ],
      ),
    );
  }

  Widget _buildNarrativeBlock(String title, List<String> items, Color accentColor) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Column(
            children: items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                  Expanded(child: Text(item, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3))),
                ],
              ),
            )).toList(),
          )
        ],
      ),
    );
  }

  // --- Tab 2: Monthly Closing Reports ---
  Widget _buildMonthlyClosingTab() {
    return StreamBuilder<List<FinancialClosingData>>(
      stream: (database.select(database.financialClosing)
            ..where((fc) => fc.profileId.equals(widget.profileId))
            ..orderBy([(fc) => OrderingTerm.desc(fc.generatedAt)]))
          .watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history_toggle_off, color: Colors.white38, size: 48),
                const SizedBox(height: 12),
                const Text('No monthly closing snapshots finalized.', style: TextStyle(color: Colors.white54)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.archive),
                  label: const Text('Finalize Current Month Closing'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: _performMonthlyClosing,
                ),
              ],
            ),
          );
        }
        final list = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Closing Period: ${item.period}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: FinancialHealthTheme.getColor(item.healthScore).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Score: ${item.healthScore}',
                          style: TextStyle(color: FinancialHealthTheme.getColor(item.healthScore), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Income: ${currency.format(item.income)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
                      Text('Expense: ${currency.format(item.expense)}', style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Net Worth: ${currency.format(item.netWorth)}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                      Text('Available: ${currency.format(item.liquidityAvailable)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Tab 3: Analytics (Burn Rate, Net Worth, Liquidity) ---
  Widget _buildAnalyticsTab() {
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return StreamBuilder<List<CashFlowStateData>>(
      stream: (database.select(database.cashFlowState)..where((c) => c.profileId.equals(widget.profileId))).watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Calculating metrics...', style: TextStyle(color: Colors.white54)));
        }
        final cashFlow = snapshot.data!.first;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Burn Rate & Spend Analytics', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildAnalyticsCard('Monthly Burn Rate', currency.format(cashFlow.burnRate), 'Expected 30-Day Expense Pace', Colors.orangeAccent),
              const SizedBox(height: 12),
              _buildAnalyticsCard('Safe Daily Spend Rate', '${currency.format((cashFlow.safeToSpend / 30).clamp(0, double.infinity))}/day', 'Calculated Allocation Threshold', Colors.greenAccent),
              const SizedBox(height: 16),
              const Text('Net Position & Cash Balance', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildAnalyticsCard('Net Cash Position', currency.format(cashFlow.cashPosition), 'Liquid Cash & Bank Reserves', Colors.cyanAccent),
              const SizedBox(height: 12),
              _buildAnalyticsCard('Forecasted Month-End Balance', currency.format(cashFlow.forecastBalance), 'Expected Cash After Obligations', Colors.purpleAccent),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsCard(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          Icon(Icons.analytics_outlined, color: color, size: 28),
        ],
      ),
    );
  }

  // --- Tab 4: Unified Financial Timeline ---
  Widget _buildTimelineTab() {
    return StreamBuilder<List<Transaction>>(
      stream: database.watchTransactionsByProfile(widget.profileId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No activity timeline recorded.', style: TextStyle(color: Colors.white54)));
        }
        final txs = snapshot.data!;
        final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: txs.length,
          itemBuilder: (context, index) {
            final tx = txs[index];
            final isIncome = tx.type == 'Income';
            final color = isIncome ? Colors.greenAccent : Colors.white70;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isIncome ? Colors.greenAccent : Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx.partyName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        Text(DateFormat('dd MMM yyyy, HH:mm').format(tx.timestamp), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(
                    '${isIncome ? '+' : '-'}${currency.format(tx.amount)}',
                    style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
