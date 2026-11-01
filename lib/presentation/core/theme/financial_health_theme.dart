import 'package:flutter/material.dart';

/// FinancialHealthTheme enforces the frozen FOS Financial Health Score Scale:
/// 95-100: Outstanding
/// 85-94: Excellent
/// 70-84: Healthy
/// 50-69: Warning
/// 30-49: Critical
/// 0-29: Emergency
class FinancialHealthTheme {
  static const Color outstanding = Color(0xFF00E676); // Emerald Green
  static const Color excellent = Color(0xFF34C759);   // Bright Green
  static const Color healthy = Color(0xFF30B0C7);     // Teal
  static const Color warning = Color(0xFFFF9F0A);     // Orange
  static const Color critical = Color(0xFFFF453A);    // Red
  static const Color emergency = Color(0xFF8B0000);   // Dark Red
  
  static Color getColor(int score) {
    if (score >= 95) return outstanding;
    if (score >= 85) return excellent;
    if (score >= 70) return healthy;
    if (score >= 50) return warning;
    if (score >= 30) return critical;
    return emergency;
  }
  
  static String getLabel(int score) {
    if (score >= 95) return 'Outstanding';
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Healthy';
    if (score >= 50) return 'Warning';
    if (score >= 30) return 'Critical';
    return 'Emergency';
  }
}
