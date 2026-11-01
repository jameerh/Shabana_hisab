import 'package:flutter/material.dart';
import '../models/filter_criteria.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/localization/bilingual_text.dart';
import '../../../main.dart';

class FilterBottomSheet extends StatefulWidget {
  final FilterCriteria initialCriteria;
  final ValueChanged<FilterCriteria> onFilterApplied;

  const FilterBottomSheet({
    super.key,
    required this.initialCriteria,
    required this.onFilterApplied,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String _selectedType;
  late String _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialCriteria.type ?? 'All';
    _selectedDateRange = widget.initialCriteria.dateRange ?? 'ALL_TIME';
  }

  String _getTypeLabel(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return type;
    switch (type) {
      case 'All': return l10n.all;
      case 'Expense': return l10n.expense;
      case 'Income': return l10n.income;
      case 'Transfer': return l10n.transfer;
      default: return type;
    }
  }

  String _getDateRangeLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return key;
    switch (key) {
      case 'ALL_TIME': return l10n.allTime;
      case 'TODAY': return l10n.today;
      case 'THIS_WEEK': return l10n.thisWeek;
      case 'THIS_MONTH': return l10n.thisMonth;
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BilingualText(
                english: 'Filter Transactions',
                marathi: 'व्यवहार फिल्टर करा',
                languageController: languageController,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 16),
          BilingualText(
            english: 'Transaction Type',
            marathi: 'व्यवहाराचा प्रकार',
            languageController: languageController,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['All', 'Expense', 'Income', 'Transfer'].map((type) {
              return ChoiceChip(
                label: Text(_getTypeLabel(context, type)),
                selected: _selectedType == type,
                selectedColor: Colors.blue.shade100,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedType = type);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          BilingualText(
            english: 'Date Range',
            marathi: 'कालावधी',
            languageController: languageController,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['ALL_TIME', 'TODAY', 'THIS_WEEK', 'THIS_MONTH'].map((rangeValue) {
              return ChoiceChip(
                label: Text(_getDateRangeLabel(context, rangeValue)),
                selected: _selectedDateRange == rangeValue,
                selectedColor: Colors.blue.shade100,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedDateRange = rangeValue);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final criteria = FilterCriteria(
                  type: _selectedType,
                  dateRange: _selectedDateRange,
                );
                widget.onFilterApplied(criteria);
                Navigator.pop(context);
              },
              child: Text(l10n?.applyFilters ?? 'Apply Filters', style: const TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
