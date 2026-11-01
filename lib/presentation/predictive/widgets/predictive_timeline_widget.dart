import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';

class PredictiveTimelineWidget extends StatelessWidget {
  final double currentCash;
  final double dailyVelocity;

  const PredictiveTimelineWidget({
    Key? key,
    required this.currentCash,
    required this.dailyVelocity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    final horizons = [
      {'label': l10n?.horizonToday ?? 'Today', 'days': 0, 'balance': currentCash},
      {'label': l10n?.horizonTomorrow ?? 'Tomorrow', 'days': 1, 'balance': currentCash + dailyVelocity},
      {'label': l10n?.horizon7Days ?? '7 Days', 'days': 7, 'balance': currentCash + (dailyVelocity * 7)},
      {'label': l10n?.horizon30Days ?? '30 Days', 'days': 30, 'balance': currentCash + (dailyVelocity * 30)},
      {'label': l10n?.horizon90Days ?? '90 Days', 'days': 90, 'balance': currentCash + (dailyVelocity * 90)},
      {'label': l10n?.horizon1Year ?? '1 Year', 'days': 365, 'balance': currentCash + (dailyVelocity * 365)},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: horizons.length,
        itemBuilder: (context, index) {
          final item = horizons[index];
          final bal = item['balance'] as double;
          final isDeficit = bal < 0;

          return Container(
            width: 110,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDeficit ? Colors.redAccent.withValues(alpha: 0.15) : Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDeficit ? Colors.redAccent : Colors.tealAccent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    color: isDeficit ? Colors.redAccent : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  currency.format(bal),
                  style: TextStyle(
                    color: isDeficit ? Colors.redAccent : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
