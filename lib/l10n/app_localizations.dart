import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('mr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Shabana Hisaab'**
  String get appTitle;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @netBalance.
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get netBalance;

  /// No description provided for @credit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get credit;

  /// No description provided for @creditShort.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get creditShort;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @ifRecovered.
  ///
  /// In en, this message translates to:
  /// **'If Recovered'**
  String get ifRecovered;

  /// No description provided for @totalPotential.
  ///
  /// In en, this message translates to:
  /// **'Total Potential'**
  String get totalPotential;

  /// No description provided for @safeToSpend.
  ///
  /// In en, this message translates to:
  /// **'Safe to Spend'**
  String get safeToSpend;

  /// No description provided for @safeToSpendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Per day balance available'**
  String get safeToSpendSubtitle;

  /// No description provided for @financialHealth.
  ///
  /// In en, this message translates to:
  /// **'Financial Health'**
  String get financialHealth;

  /// No description provided for @financialHealthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Overall stability index'**
  String get financialHealthSubtitle;

  /// No description provided for @recommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendations;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @recurringPayments.
  ///
  /// In en, this message translates to:
  /// **'Recurring Payments'**
  String get recurringPayments;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @inputOptions.
  ///
  /// In en, this message translates to:
  /// **'Input Options'**
  String get inputOptions;

  /// No description provided for @speakCommand.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get speakCommand;

  /// No description provided for @typeCommand.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeCommand;

  /// No description provided for @scanReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan Receipt'**
  String get scanReceipt;

  /// No description provided for @pasteText.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get pasteText;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurring;

  /// No description provided for @budgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgets;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals & Targets'**
  String get goals;

  /// No description provided for @intelligence.
  ///
  /// In en, this message translates to:
  /// **'Intelligence'**
  String get intelligence;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @financialPlanning.
  ///
  /// In en, this message translates to:
  /// **'Financial Planning'**
  String get financialPlanning;

  /// No description provided for @recurringAssistant.
  ///
  /// In en, this message translates to:
  /// **'Recurring Assistant'**
  String get recurringAssistant;

  /// No description provided for @utilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get utilities;

  /// No description provided for @voiceCalculator.
  ///
  /// In en, this message translates to:
  /// **'Voice Calculator'**
  String get voiceCalculator;

  /// No description provided for @kiranaGrocery.
  ///
  /// In en, this message translates to:
  /// **'Kirana & Grocery'**
  String get kiranaGrocery;

  /// No description provided for @mileageCalculator.
  ///
  /// In en, this message translates to:
  /// **'Mileage Calculator'**
  String get mileageCalculator;

  /// No description provided for @fillFuelDetails.
  ///
  /// In en, this message translates to:
  /// **'Fill Fuel Details'**
  String get fillFuelDetails;

  /// No description provided for @currentFuelPrice.
  ///
  /// In en, this message translates to:
  /// **'Current Fuel Price (₹/L)'**
  String get currentFuelPrice;

  /// No description provided for @lastKm.
  ///
  /// In en, this message translates to:
  /// **'Last KM'**
  String get lastKm;

  /// No description provided for @presentKm.
  ///
  /// In en, this message translates to:
  /// **'Present KM'**
  String get presentKm;

  /// No description provided for @fuelAmount.
  ///
  /// In en, this message translates to:
  /// **'Fuel Amount'**
  String get fuelAmount;

  /// No description provided for @calculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculate;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @mileageResult.
  ///
  /// In en, this message translates to:
  /// **'Mileage'**
  String get mileageResult;

  /// No description provided for @costPerKm.
  ///
  /// In en, this message translates to:
  /// **'Cost per KM'**
  String get costPerKm;

  /// No description provided for @enterKmPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please enter KM'**
  String get enterKmPrompt;

  /// No description provided for @presentKmGreaterPrompt.
  ///
  /// In en, this message translates to:
  /// **'Present KM must be greater than Last KM'**
  String get presentKmGreaterPrompt;

  /// No description provided for @enterFuelPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please enter Fuel Amount or Liters'**
  String get enterFuelPrompt;

  /// No description provided for @groceryNotes.
  ///
  /// In en, this message translates to:
  /// **'Grocery Notes'**
  String get groceryNotes;

  /// No description provided for @newList.
  ///
  /// In en, this message translates to:
  /// **'New List'**
  String get newList;

  /// No description provided for @importPasteList.
  ///
  /// In en, this message translates to:
  /// **'Import / Paste List'**
  String get importPasteList;

  /// No description provided for @noSavedLists.
  ///
  /// In en, this message translates to:
  /// **'No saved lists yet'**
  String get noSavedLists;

  /// No description provided for @createList.
  ///
  /// In en, this message translates to:
  /// **'Create List'**
  String get createList;

  /// No description provided for @quickCalculator.
  ///
  /// In en, this message translates to:
  /// **'Quick Calculator'**
  String get quickCalculator;

  /// No description provided for @calculatorHistory.
  ///
  /// In en, this message translates to:
  /// **'Calculator History'**
  String get calculatorHistory;

  /// No description provided for @clearSheet.
  ///
  /// In en, this message translates to:
  /// **'Clear Sheet'**
  String get clearSheet;

  /// No description provided for @manageUnits.
  ///
  /// In en, this message translates to:
  /// **'Manage Units'**
  String get manageUnits;

  /// No description provided for @addNewUnit.
  ///
  /// In en, this message translates to:
  /// **'Add New Unit'**
  String get addNewUnit;

  /// No description provided for @unitNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. box, tray'**
  String get unitNameHint;

  /// No description provided for @systemUnit.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemUnit;

  /// No description provided for @smsImport.
  ///
  /// In en, this message translates to:
  /// **'Bank & Card SMS Import'**
  String get smsImport;

  /// No description provided for @scanSmsInbox.
  ///
  /// In en, this message translates to:
  /// **'Scan Bank & Card SMS'**
  String get scanSmsInbox;

  /// No description provided for @scanHorizon30.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days (Recommended)'**
  String get scanHorizon30;

  /// No description provided for @scanHorizon90.
  ///
  /// In en, this message translates to:
  /// **'Last 90 Days'**
  String get scanHorizon90;

  /// No description provided for @scanHorizonAll.
  ///
  /// In en, this message translates to:
  /// **'Full Inbox'**
  String get scanHorizonAll;

  /// No description provided for @privacyNotice.
  ///
  /// In en, this message translates to:
  /// **'SMS scanning happens 100% on your device. Raw SMS text is never saved or uploaded.'**
  String get privacyNotice;

  /// No description provided for @addSelected.
  ///
  /// In en, this message translates to:
  /// **'Add Selected'**
  String get addSelected;

  /// No description provided for @smsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'SMS Privacy & Transparency'**
  String get smsPrivacy;

  /// No description provided for @deleteImportHistory.
  ///
  /// In en, this message translates to:
  /// **'Delete Import History'**
  String get deleteImportHistory;

  /// No description provided for @unableToSave.
  ///
  /// In en, this message translates to:
  /// **'Unable to save transaction'**
  String get unableToSave;

  /// No description provided for @unitManagement.
  ///
  /// In en, this message translates to:
  /// **'Unit Management'**
  String get unitManagement;

  /// No description provided for @management.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get management;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @profiles.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get profiles;

  /// No description provided for @voiceLab.
  ///
  /// In en, this message translates to:
  /// **'Voice Lab'**
  String get voiceLab;

  /// No description provided for @voiceExercise.
  ///
  /// In en, this message translates to:
  /// **'Voice Calibration Exercise'**
  String get voiceExercise;

  /// No description provided for @voiceExerciseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Improve voice recognition accuracy'**
  String get voiceExerciseSubtitle;

  /// No description provided for @voiceLogs.
  ///
  /// In en, this message translates to:
  /// **'Voice Logs'**
  String get voiceLogs;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// No description provided for @searchTypeName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get searchTypeName;

  /// No description provided for @searchTypeAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get searchTypeAmount;

  /// No description provided for @searchTypeCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get searchTypeCategory;

  /// No description provided for @searchTypeDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get searchTypeDate;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @filterTransactions.
  ///
  /// In en, this message translates to:
  /// **'Filter Transactions'**
  String get filterTransactions;

  /// No description provided for @transactionType.
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get transactionType;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @accountManager.
  ///
  /// In en, this message translates to:
  /// **'Account Manager'**
  String get accountManager;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get addAccount;

  /// No description provided for @editAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit Account'**
  String get editAccount;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get accountName;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @initialBalance.
  ///
  /// In en, this message translates to:
  /// **'Initial Balance'**
  String get initialBalance;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// No description provided for @transferMoney.
  ///
  /// In en, this message translates to:
  /// **'Transfer Money'**
  String get transferMoney;

  /// No description provided for @fromAccount.
  ///
  /// In en, this message translates to:
  /// **'From Account'**
  String get fromAccount;

  /// No description provided for @toAccount.
  ///
  /// In en, this message translates to:
  /// **'To Account'**
  String get toAccount;

  /// No description provided for @transferAmount.
  ///
  /// In en, this message translates to:
  /// **'Transfer Amount'**
  String get transferAmount;

  /// No description provided for @noAccountsFound.
  ///
  /// In en, this message translates to:
  /// **'No accounts found'**
  String get noAccountsFound;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this account?'**
  String get deleteAccountConfirm;

  /// No description provided for @accountTypeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get accountTypeBank;

  /// No description provided for @accountTypeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountTypeCash;

  /// No description provided for @accountTypeSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings Account'**
  String get accountTypeSavings;

  /// No description provided for @accountTypeCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get accountTypeCredit;

  /// No description provided for @accountTypeWallet.
  ///
  /// In en, this message translates to:
  /// **'Digital Wallet'**
  String get accountTypeWallet;

  /// No description provided for @editTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get editTransaction;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @nameOptional.
  ///
  /// In en, this message translates to:
  /// **'Party Name (Optional)'**
  String get nameOptional;

  /// No description provided for @changeDate.
  ///
  /// In en, this message translates to:
  /// **'Change Date'**
  String get changeDate;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @unknownCategory.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownCategory;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @confirmTransaction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Transaction'**
  String get confirmTransaction;

  /// No description provided for @nameDetails.
  ///
  /// In en, this message translates to:
  /// **'Party Name / Details'**
  String get nameDetails;

  /// No description provided for @fuelTracking.
  ///
  /// In en, this message translates to:
  /// **'Fuel Tracking'**
  String get fuelTracking;

  /// No description provided for @odometerKm.
  ///
  /// In en, this message translates to:
  /// **'Odometer (KM)'**
  String get odometerKm;

  /// No description provided for @fuelLiters.
  ///
  /// In en, this message translates to:
  /// **'Fuel (Liters)'**
  String get fuelLiters;

  /// No description provided for @attachPhotos.
  ///
  /// In en, this message translates to:
  /// **'Attach Photos'**
  String get attachPhotos;

  /// No description provided for @makeRecurring.
  ///
  /// In en, this message translates to:
  /// **'Make this recurring'**
  String get makeRecurring;

  /// No description provided for @recurringRules.
  ///
  /// In en, this message translates to:
  /// **'Recurring Rules'**
  String get recurringRules;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @noRulesFound.
  ///
  /// In en, this message translates to:
  /// **'No rules found'**
  String get noRulesFound;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @snooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get snooze;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @frequencyDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get frequencyDaily;

  /// No description provided for @frequencyWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get frequencyWeekly;

  /// No description provided for @frequencyMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get frequencyMonthly;

  /// No description provided for @frequencyYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get frequencyYearly;

  /// No description provided for @newGoal.
  ///
  /// In en, this message translates to:
  /// **'New Goal'**
  String get newGoal;

  /// No description provided for @noGoalsFound.
  ///
  /// In en, this message translates to:
  /// **'No goals set yet'**
  String get noGoalsFound;

  /// No description provided for @totalSavingsGoal.
  ///
  /// In en, this message translates to:
  /// **'Total Target'**
  String get totalSavingsGoal;

  /// No description provided for @currentProgress.
  ///
  /// In en, this message translates to:
  /// **'Current Progress'**
  String get currentProgress;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @sortTransactions.
  ///
  /// In en, this message translates to:
  /// **'Sort Transactions'**
  String get sortTransactions;

  /// No description provided for @sortByDate.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get sortByDate;

  /// No description provided for @sortByAmountDesc.
  ///
  /// In en, this message translates to:
  /// **'Amount: High to Low'**
  String get sortByAmountDesc;

  /// No description provided for @sortByAmountAsc.
  ///
  /// In en, this message translates to:
  /// **'Amount: Low to High'**
  String get sortByAmountAsc;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Party Name: A to Z'**
  String get sortByName;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @riskLow.
  ///
  /// In en, this message translates to:
  /// **'Low Risk'**
  String get riskLow;

  /// No description provided for @riskMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium Risk'**
  String get riskMedium;

  /// No description provided for @riskHigh.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get riskHigh;

  /// No description provided for @riskCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical Risk'**
  String get riskCritical;

  /// No description provided for @healthExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get healthExcellent;

  /// No description provided for @healthHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get healthHealthy;

  /// No description provided for @healthWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get healthWarning;

  /// No description provided for @healthCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get healthCritical;

  /// No description provided for @healthEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get healthEmergency;

  /// No description provided for @healthScore.
  ///
  /// In en, this message translates to:
  /// **'Health Score'**
  String get healthScore;

  /// No description provided for @cashPosition.
  ///
  /// In en, this message translates to:
  /// **'Cash Position'**
  String get cashPosition;

  /// No description provided for @safeToSpendDaily.
  ///
  /// In en, this message translates to:
  /// **'Safe To Spend'**
  String get safeToSpendDaily;

  /// No description provided for @safeUntil.
  ///
  /// In en, this message translates to:
  /// **'Safe Until'**
  String get safeUntil;

  /// No description provided for @burnRate.
  ///
  /// In en, this message translates to:
  /// **'Burn Rate'**
  String get burnRate;

  /// No description provided for @netPosition.
  ///
  /// In en, this message translates to:
  /// **'Net Position'**
  String get netPosition;

  /// No description provided for @liquidity.
  ///
  /// In en, this message translates to:
  /// **'Liquidity'**
  String get liquidity;

  /// No description provided for @forecastBalance.
  ///
  /// In en, this message translates to:
  /// **'Forecast Balance'**
  String get forecastBalance;

  /// No description provided for @whyThisIsShown.
  ///
  /// In en, this message translates to:
  /// **'Why this is shown'**
  String get whyThisIsShown;

  /// No description provided for @financialInsights.
  ///
  /// In en, this message translates to:
  /// **'Financial Insights'**
  String get financialInsights;

  /// No description provided for @intelligenceHub.
  ///
  /// In en, this message translates to:
  /// **'Intelligence Hub'**
  String get intelligenceHub;

  /// No description provided for @predictiveHub.
  ///
  /// In en, this message translates to:
  /// **'Predictive Hub'**
  String get predictiveHub;

  /// No description provided for @whatIfSimulator.
  ///
  /// In en, this message translates to:
  /// **'What-If Simulator'**
  String get whatIfSimulator;

  /// No description provided for @riskAlerts.
  ///
  /// In en, this message translates to:
  /// **'Risk Alerts'**
  String get riskAlerts;

  /// No description provided for @deficitRisk.
  ///
  /// In en, this message translates to:
  /// **'Deficit Risk'**
  String get deficitRisk;

  /// No description provided for @predictiveIntelligence.
  ///
  /// In en, this message translates to:
  /// **'Predictive Intelligence'**
  String get predictiveIntelligence;

  /// No description provided for @todaysPrediction.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Prediction'**
  String get todaysPrediction;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// No description provided for @topOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Top Opportunity'**
  String get topOpportunity;

  /// No description provided for @predictiveRiskAlert.
  ///
  /// In en, this message translates to:
  /// **'Predictive Risk Alert'**
  String get predictiveRiskAlert;

  /// No description provided for @multiHorizonCashFlowForecast.
  ///
  /// In en, this message translates to:
  /// **'Multi-Horizon Cash Flow Forecast'**
  String get multiHorizonCashFlowForecast;

  /// No description provided for @whatIfSimulatorSandbox.
  ///
  /// In en, this message translates to:
  /// **'What-If Simulator Sandbox'**
  String get whatIfSimulatorSandbox;

  /// No description provided for @simulatePurchasesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Simulate purchases, rent & income changes'**
  String get simulatePurchasesSubtitle;

  /// No description provided for @openSandbox.
  ///
  /// In en, this message translates to:
  /// **'Open Sandbox'**
  String get openSandbox;

  /// No description provided for @actionableCostOptimizations.
  ///
  /// In en, this message translates to:
  /// **'Actionable Cost Optimizations'**
  String get actionableCostOptimizations;

  /// No description provided for @upcomingSeasonalSpikes.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Seasonal Spikes'**
  String get upcomingSeasonalSpikes;

  /// No description provided for @detectedAnomalies.
  ///
  /// In en, this message translates to:
  /// **'Detected Anomalies'**
  String get detectedAnomalies;

  /// No description provided for @isolatedSandboxNotice.
  ///
  /// In en, this message translates to:
  /// **'Isolated Sandbox: Simulations run in memory and never mutate active live financial records or budgets.'**
  String get isolatedSandboxNotice;

  /// No description provided for @scenarioTitle.
  ///
  /// In en, this message translates to:
  /// **'Scenario Title'**
  String get scenarioTitle;

  /// No description provided for @lumpSumOutflow.
  ///
  /// In en, this message translates to:
  /// **'Lump Sum Outflow'**
  String get lumpSumOutflow;

  /// No description provided for @monthlyDeltaExpense.
  ///
  /// In en, this message translates to:
  /// **'Monthly Delta Expense'**
  String get monthlyDeltaExpense;

  /// No description provided for @monthlyDeltaIncome.
  ///
  /// In en, this message translates to:
  /// **'Monthly Delta Income'**
  String get monthlyDeltaIncome;

  /// No description provided for @runWhatIfSimulation.
  ///
  /// In en, this message translates to:
  /// **'Run What-If Simulation'**
  String get runWhatIfSimulation;

  /// No description provided for @simulationPredictions.
  ///
  /// In en, this message translates to:
  /// **'Simulation Predictions'**
  String get simulationPredictions;

  /// No description provided for @simulatedHealthIndex.
  ///
  /// In en, this message translates to:
  /// **'Simulated Health Index'**
  String get simulatedHealthIndex;

  /// No description provided for @activeGoalDelayImpact.
  ///
  /// In en, this message translates to:
  /// **'Active Goal Delay Impact'**
  String get activeGoalDelayImpact;

  /// No description provided for @monthlyCashFlowDelta.
  ///
  /// In en, this message translates to:
  /// **'Monthly Cash Flow Delta'**
  String get monthlyCashFlowDelta;

  /// No description provided for @safeToSpendShift.
  ///
  /// In en, this message translates to:
  /// **'Safe To Spend Shift'**
  String get safeToSpendShift;

  /// No description provided for @categoryPurchase.
  ///
  /// In en, this message translates to:
  /// **'Major Purchase (Bike, Gadget)'**
  String get categoryPurchase;

  /// No description provided for @categorySalaryScenario.
  ///
  /// In en, this message translates to:
  /// **'Salary Hike / Job Change'**
  String get categorySalaryScenario;

  /// No description provided for @categoryRentScenario.
  ///
  /// In en, this message translates to:
  /// **'Rent Adjustment'**
  String get categoryRentScenario;

  /// No description provided for @categorySavingsScenario.
  ///
  /// In en, this message translates to:
  /// **'Daily Savings Target'**
  String get categorySavingsScenario;

  /// No description provided for @categoryLoanScenario.
  ///
  /// In en, this message translates to:
  /// **'Loan / EMI Commitment'**
  String get categoryLoanScenario;

  /// No description provided for @categoryInvestmentScenario.
  ///
  /// In en, this message translates to:
  /// **'Investment / SIP'**
  String get categoryInvestmentScenario;

  /// No description provided for @categoryEducationScenario.
  ///
  /// In en, this message translates to:
  /// **'Child Education / Course'**
  String get categoryEducationScenario;

  /// No description provided for @categoryVacationScenario.
  ///
  /// In en, this message translates to:
  /// **'Vacation / Travel Trip'**
  String get categoryVacationScenario;

  /// No description provided for @categoryMedicalScenario.
  ///
  /// In en, this message translates to:
  /// **'Medical Expense'**
  String get categoryMedicalScenario;

  /// No description provided for @categoryHouseScenario.
  ///
  /// In en, this message translates to:
  /// **'House Down Payment'**
  String get categoryHouseScenario;

  /// No description provided for @categoryBusinessScenario.
  ///
  /// In en, this message translates to:
  /// **'Business Expansion'**
  String get categoryBusinessScenario;

  /// No description provided for @horizonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get horizonToday;

  /// No description provided for @horizonTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get horizonTomorrow;

  /// No description provided for @horizon7Days.
  ///
  /// In en, this message translates to:
  /// **'7 Days'**
  String get horizon7Days;

  /// No description provided for @horizon30Days.
  ///
  /// In en, this message translates to:
  /// **'30 Days'**
  String get horizon30Days;

  /// No description provided for @horizon90Days.
  ///
  /// In en, this message translates to:
  /// **'90 Days'**
  String get horizon90Days;

  /// No description provided for @horizon1Year.
  ///
  /// In en, this message translates to:
  /// **'1 Year'**
  String get horizon1Year;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryPetrol.
  ///
  /// In en, this message translates to:
  /// **'Petrol'**
  String get categoryPetrol;

  /// No description provided for @categoryRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get categoryRent;

  /// No description provided for @categoryMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get categoryMedical;

  /// No description provided for @categorySalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get categorySalary;

  /// No description provided for @categoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// No description provided for @categoryEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get categoryEducation;

  /// No description provided for @categoryKirana.
  ///
  /// In en, this message translates to:
  /// **'Kirana'**
  String get categoryKirana;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @goalBike.
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get goalBike;

  /// No description provided for @goalCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get goalCar;

  /// No description provided for @goalHouse.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get goalHouse;

  /// No description provided for @goalPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get goalPhone;

  /// No description provided for @goalEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get goalEducation;

  /// No description provided for @goalChildEducation.
  ///
  /// In en, this message translates to:
  /// **'Child Education'**
  String get goalChildEducation;

  /// No description provided for @goalVacation.
  ///
  /// In en, this message translates to:
  /// **'Vacation'**
  String get goalVacation;

  /// No description provided for @goalWedding.
  ///
  /// In en, this message translates to:
  /// **'Wedding'**
  String get goalWedding;

  /// No description provided for @goalEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency Fund'**
  String get goalEmergency;

  /// No description provided for @goalInvestment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get goalInvestment;

  /// No description provided for @goalMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical Fund'**
  String get goalMedical;

  /// No description provided for @goalBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get goalBusiness;

  /// No description provided for @goalRetirement.
  ///
  /// In en, this message translates to:
  /// **'Retirement'**
  String get goalRetirement;

  /// No description provided for @goalHomeRenovation.
  ///
  /// In en, this message translates to:
  /// **'Home Renovation'**
  String get goalHomeRenovation;

  /// No description provided for @goalFestival.
  ///
  /// In en, this message translates to:
  /// **'Festival'**
  String get goalFestival;

  /// No description provided for @goalCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom Goal'**
  String get goalCustom;

  /// No description provided for @recurringRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get recurringRent;

  /// No description provided for @recurringPetrol.
  ///
  /// In en, this message translates to:
  /// **'Petrol'**
  String get recurringPetrol;

  /// No description provided for @recurringMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk'**
  String get recurringMilk;

  /// No description provided for @recurringElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get recurringElectricity;

  /// No description provided for @recurringMobileRecharge.
  ///
  /// In en, this message translates to:
  /// **'Mobile Recharge'**
  String get recurringMobileRecharge;

  /// No description provided for @recurringInternet.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get recurringInternet;

  /// No description provided for @recurringSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get recurringSalary;

  /// No description provided for @recurringCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom Recurring'**
  String get recurringCustom;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// No description provided for @speakNow.
  ///
  /// In en, this message translates to:
  /// **'Speak now'**
  String get speakNow;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @couldNotUnderstand.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t understand'**
  String get couldNotUnderstand;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @followDevice.
  ///
  /// In en, this message translates to:
  /// **'Follow Device'**
  String get followDevice;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @marathi.
  ///
  /// In en, this message translates to:
  /// **'मराठी'**
  String get marathi;

  /// No description provided for @englishMarathi.
  ///
  /// In en, this message translates to:
  /// **'English + मराठी'**
  String get englishMarathi;

  /// No description provided for @voiceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Voice Language'**
  String get voiceLanguage;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get appLock;

  /// No description provided for @developerDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Developer Diagnostics'**
  String get developerDiagnostics;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings Saved!'**
  String get settingsSaved;

  /// No description provided for @backupCompleted.
  ///
  /// In en, this message translates to:
  /// **'Backup Completed!'**
  String get backupCompleted;

  /// No description provided for @restoreData.
  ///
  /// In en, this message translates to:
  /// **'Restore Data?'**
  String get restoreData;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data restored successfully.'**
  String get restoreSuccess;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
