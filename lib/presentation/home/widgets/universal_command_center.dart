import 'package:flutter/material.dart';
import 'dart:async';
import '../../../l10n/app_localizations.dart';

class UniversalCommandCenter extends StatefulWidget {
  final VoidCallback onFilterPressed;
  final VoidCallback onSortPressed;
  final Function(String query, String searchType) onSearch;
  final bool hasActiveFilters;

  const UniversalCommandCenter({
    super.key,
    required this.onFilterPressed,
    required this.onSortPressed,
    required this.onSearch,
    this.hasActiveFilters = false,
  });

  @override
  State<UniversalCommandCenter> createState() => _UniversalCommandCenterState();
}

class _UniversalCommandCenterState extends State<UniversalCommandCenter> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSearchType = 'All';
  Timer? _debounce;

  final List<String> _searchTypes = [
    'All',
    'Name',
    'Amount',
    'Category',
    'Date'
  ];

  String _getSearchTypeDisplay(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return type;
    switch (type) {
      case 'All': return l10n.all;
      case 'Name': return l10n.searchTypeName;
      case 'Amount': return l10n.searchTypeAmount;
      case 'Category': return l10n.searchTypeCategory;
      case 'Date': return l10n.searchTypeDate;
      default: return type;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(_searchController.text, _selectedSearchType);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Search Type Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSearchType,
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                isDense: true,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                items: _searchTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(_getSearchTypeDisplay(context, type)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedSearchType = val;
                    });
                    _handleSearch();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Search Bar
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _handleSearch(),
                onSubmitted: (_) => _handleSearch(),
                decoration: InputDecoration(
                  hintText: l10n?.searchHint ?? 'Search...',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Filter Button
          InkWell(
            onTap: widget.onFilterPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.hasActiveFilters ? Colors.blue.shade700 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.hasActiveFilters ? Colors.blue.shade800 : Colors.blue.shade100),
              ),
              child: Icon(
                Icons.filter_list, 
                color: widget.hasActiveFilters ? Colors.white : Colors.blue.shade700, 
                size: 20
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Sort Button
          InkWell(
            onTap: widget.onSortPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Icon(Icons.sort, color: Colors.orange.shade700, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
