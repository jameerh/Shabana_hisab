import 'package:flutter/material.dart';
import '../../core/theme/financial_health_theme.dart';

class HealthRing extends StatelessWidget {
  final double completionPercent;
  final int healthScore;
  final double size;
  final double strokeWidth;

  const HealthRing({
    super.key,
    required this.completionPercent,
    required this.healthScore,
    this.size = 100.0,
    this.strokeWidth = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    final color = FinancialHealthTheme.getColor(healthScore);
    
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.2)),
          ),
          CircularProgressIndicator(
            value: (completionPercent / 100).clamp(0.0, 1.0),
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${completionPercent.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
