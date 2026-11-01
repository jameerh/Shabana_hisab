import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/localization/bilingual_text.dart';
import '../../../main.dart';

class SortBottomSheet extends StatefulWidget {
  final String initialSort;
  final ValueChanged<String> onSortApplied;

  const SortBottomSheet({
    super.key,
    required this.initialSort,
    required this.onSortApplied,
  });

  @override
  State<SortBottomSheet> createState() => _SortBottomSheetState();
}

class _SortBottomSheetState extends State<SortBottomSheet> {
  late String _selectedSort;

  @override
  void initState() {
    super.initState();
    _selectedSort = widget.initialSort;
  }

  String _getSortOptionLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return key;
    switch (key) {
      case 'DATE_DESC': return l10n.sortByDate;
      case 'DATE_ASC': return '${l10n.sortByDate} (Oldest)';
      case 'AMOUNT_DESC': return l10n.sortByAmountDesc;
      case 'AMOUNT_ASC': return l10n.sortByAmountAsc;
      case 'NAME_ASC': return l10n.sortByName;
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sortKeys = ['DATE_DESC', 'DATE_ASC', 'AMOUNT_DESC', 'AMOUNT_ASC', 'NAME_ASC'];

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
                english: 'Sort Transactions',
                marathi: 'व्यवहारांची क्रमवारी',
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
          ...sortKeys.map((key) {
            return RadioListTile<String>(
              title: Text(_getSortOptionLabel(context, key)),
              value: key,
              groupValue: _selectedSort,
              activeColor: Colors.blue.shade700,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedSort = val;
                  });
                }
              },
            );
          }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                widget.onSortApplied(_selectedSort);
                Navigator.pop(context);
              },
              child: Text(l10n?.sort ?? 'Apply Sort', style: const TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
