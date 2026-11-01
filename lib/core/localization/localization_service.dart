import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class LocalizationService {
  /// Resolves localized name for standard category keys.
  static String getCategoryName(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return key;

    switch (key.toUpperCase()) {
      case 'FOOD':
        return l10n.categoryFood;
      case 'PETROL':
        return l10n.categoryPetrol;
      case 'RENT':
        return l10n.categoryRent;
      case 'MEDICAL':
        return l10n.categoryMedical;
      case 'SALARY':
        return l10n.categorySalary;
      case 'SHOPPING':
        return l10n.categoryShopping;
      case 'EDUCATION':
        return l10n.categoryEducation;
      case 'KIRANA':
        return l10n.categoryKirana;
      default:
        return key;
    }
  }

  /// Resolves localized title for system goal template IDs.
  static String getGoalTemplateTitle(BuildContext context, String templateId) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return templateId;

    switch (templateId.toLowerCase()) {
      case 'bike':
        return l10n.goalBike;
      case 'car':
        return l10n.goalCar;
      case 'house':
        return l10n.goalHouse;
      case 'phone':
        return l10n.goalPhone;
      case 'education':
        return l10n.goalEducation;
      case 'child_education':
        return l10n.goalChildEducation;
      case 'vacation':
        return l10n.goalVacation;
      case 'wedding':
        return l10n.goalWedding;
      case 'emergency':
        return l10n.goalEmergency;
      case 'investment':
        return l10n.goalInvestment;
      case 'medical':
        return l10n.goalMedical;
      case 'business':
        return l10n.goalBusiness;
      case 'retirement':
        return l10n.goalRetirement;
      case 'home_renovation':
        return l10n.goalHomeRenovation;
      case 'festival':
        return l10n.goalFestival;
      case 'custom':
      default:
        return l10n.goalCustom;
    }
  }

  /// Resolves localized title for system recurring templates.
  static String getRecurringTemplateTitle(BuildContext context, String titleKey) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return titleKey;

    switch (titleKey.toLowerCase()) {
      case 'rent':
        return l10n.recurringRent;
      case 'petrol':
        return l10n.recurringPetrol;
      case 'milk':
        return l10n.recurringMilk;
      case 'electricity':
        return l10n.recurringElectricity;
      case 'mobile recharge':
        return l10n.recurringMobileRecharge;
      case 'internet':
        return l10n.recurringInternet;
      case 'salary':
        return l10n.recurringSalary;
      default:
        return titleKey;
    }
  }

  /// Resolves localized risk level label.
  static String getRiskLabel(BuildContext context, String riskLevel) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return riskLevel;

    switch (riskLevel.toUpperCase()) {
      case 'LOW':
        return l10n.riskLow;
      case 'MEDIUM':
        return l10n.riskMedium;
      case 'HIGH':
        return l10n.riskHigh;
      case 'CRITICAL':
        return l10n.riskCritical;
      default:
        return riskLevel;
    }
  }

  /// Resolves localized health status label.
  static String getHealthLabel(BuildContext context, String healthStatus) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return healthStatus;

    switch (healthStatus.toUpperCase()) {
      case 'EXCELLENT':
        return l10n.healthExcellent;
      case 'HEALTHY':
        return l10n.healthHealthy;
      case 'WARNING':
        return l10n.healthWarning;
      case 'CRITICAL':
        return l10n.healthCritical;
      case 'EMERGENCY':
        return l10n.healthEmergency;
      default:
        return healthStatus;
    }
  }
}
