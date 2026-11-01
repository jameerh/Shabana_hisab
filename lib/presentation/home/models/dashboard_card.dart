import 'package:flutter/material.dart';

enum CardLifecycle { loading, ready, dismissed, completed, expired, hidden }

class CardExplanation {
  final String reason;
  final double confidence;
  final String source;
  final DateTime lastUpdated;

  const CardExplanation({
    required this.reason,
    required this.confidence,
    required this.source,
    required this.lastUpdated,
  });
}

class DashboardCard {
  final String id;
  final double score; // E.g., 0-100 based on Recommendation Engine
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onAction;
  final String? actionLabel;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onTertiaryAction;
  final String? tertiaryActionLabel;
  final List<PopupMenuItem<String>>? moreActions;
  final Function(String)? onMoreActionSelected;
  final CardLifecycle lifecycle;
  final CardExplanation? explanation;

  const DashboardCard({
    required this.id,
    required this.score,
    required this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.onAction,
    this.actionLabel,
    this.onSecondaryAction,
    this.secondaryActionLabel,
    this.onTertiaryAction,
    this.tertiaryActionLabel,
    this.moreActions,
    this.onMoreActionSelected,
    this.lifecycle = CardLifecycle.ready,
    this.explanation,
  });
}
