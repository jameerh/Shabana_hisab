import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/voice/kirana_import_engine.dart';
import '../../data/repositories/grocery_repository.dart';
import '../../data/database/database.dart';

class GroceryImportDialog extends StatefulWidget {
  final int profileId;
  final int? existingListId; // Null if creating a new list
  final String? existingListName;
  final Function(GroceryList list)? onListCreated;

  const GroceryImportDialog({
    super.key,
    required this.profileId,
    this.existingListId,
    this.existingListName,
    this.onListCreated,
  });

  static Future<void> show(
    BuildContext context, {
    required int profileId,
    int? existingListId,
    String? existingListName,
    Function(GroceryList list)? onListCreated,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GroceryImportDialog(
        profileId: profileId,
        existingListId: existingListId,
        existingListName: existingListName,
        onListCreated: onListCreated,
      ),
    );
  }

  @override
  State<GroceryImportDialog> createState() => _GroceryImportDialogState();
}

class _GroceryImportDialogState extends State<GroceryImportDialog> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _listNameController = TextEditingController();
  final GroceryRepository _repository = GroceryRepository();
  final KiranaRegexImportEngine _engine = KiranaRegexImportEngine();

  List<ImportedParsedItem> _parsedItems = [];
  bool _isParsed = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingListId == null) {
      final now = DateTime.now();
      _listNameController.text = "Kirana_${DateFormat('ddMMM_HHmm').format(now)}";
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      setState(() {
        _inputController.text = data.text!;
      });
      _parseText();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard is empty!')),
      );
    }
  }

  void _parseText() {
    final rawText = _inputController.text;
    if (rawText.trim().isEmpty) {
      setState(() {
        _parsedItems = [];
        _isParsed = false;
      });
      return;
    }

    final items = _engine.parse(rawText);
    setState(() {
      _parsedItems = items;
      _isParsed = true;
    });
  }

  Future<void> _executeImport() async {
    if (_parsedItems.isEmpty) return;

    setState(() => _isImporting = true);

    try {
      int listId;
      GroceryList? newList;

      if (widget.existingListId != null) {
        listId = widget.existingListId!;
      } else {
        final listName = _listNameController.text.trim().isEmpty
            ? "Imported List"
            : _listNameController.text.trim();
        listId = await _repository.createList(widget.profileId, listName);

        final lists = await _repository.watchLists(widget.profileId).first;
        newList = lists.firstWhere((l) => l.id == listId);
      }

      final result = await _repository.importItemsBatch(
        listId: listId,
        items: _parsedItems,
      );

      if (mounted) {
        Navigator.pop(context);

        if (newList != null && widget.onListCreated != null) {
          widget.onListCreated!(newList);
        }

        final summary = result.summary;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 5),
            content: Text(
              'Imported ${summary.totalImported} items (${summary.totalMerged} merged, ${summary.totalUnknown} review)',
            ),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.amber,
              onPressed: () async {
                await _repository.undoImportBatch(
                  createdItemIds: result.createdItemIds,
                  previousStates: result.previousStates,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Import undone successfully.')),
                  );
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _editItemDialog(int index) {
    final item = _parsedItems[index];
    final nameCtrl = TextEditingController(text: item.canonicalName);
    final qtyCtrl = TextEditingController(text: item.quantity.toString());
    final unitCtrl = TextEditingController(text: item.unit);
    final catCtrl = TextEditingController(text: item.category);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Imported Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Item Name')),
              TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
              TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit')),
              TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _parsedItems[index] = item.copyWith(
                  canonicalName: nameCtrl.text.trim(),
                  quantity: double.tryParse(qtyCtrl.text) ?? item.quantity,
                  unit: unitCtrl.text.trim(),
                  category: catCtrl.text.trim(),
                  isUnknown: false,
                  confidence: 100,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _listNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNewListMode = widget.existingListId == null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          title: Text(isNewListMode ? 'Import New Kirana List' : 'Paste & Import Items'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton.icon(
              onPressed: _pasteFromClipboard,
              icon: const Icon(Icons.content_paste, color: Colors.white, size: 18),
              label: const Text('Paste', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (isNewListMode) ...[
                    TextField(
                      controller: _listNameController,
                      decoration: InputDecoration(
                        labelText: 'List Name',
                        prefixIcon: const Icon(Icons.drive_file_rename_outline, color: Colors.teal),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _inputController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Paste WhatsApp message or notes list here...\nExample:\n[12:32] Wifey: Toor dal 1 kg\nMarie biscuit 6 unit\nSukha khobra pavsher',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: (val) => _parseText(),
                  ),
                ],
              ),
            ),

            if (_isParsed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.teal.shade50,
                child: Row(
                  children: [
                    Text(
                      'Parsed ${_parsedItems.length} items',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                    ),
                    const Spacer(),
                    const Icon(Icons.info_outline, size: 16, color: Colors.teal),
                    const SizedBox(width: 4),
                    const Text('Tap item to edit', style: TextStyle(fontSize: 12, color: Colors.teal)),
                  ],
                ),
              ),

            Expanded(
              child: !_isParsed || _parsedItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.teal.withOpacity(0.2)),
                          const SizedBox(height: 12),
                          const Text('Paste text or tap Paste above to parse list', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _parsedItems.length,
                      itemBuilder: (context, index) {
                        final item = _parsedItems[index];

                        Color badgeColor = Colors.green;
                        String badgeText = '${item.confidence}% Match';
                        if (item.isUnknown || item.confidence < 65) {
                          badgeColor = Colors.orange;
                          badgeText = 'Review Needed';
                        } else if (item.confidence < 85) {
                          badgeColor = Colors.amber.shade700;
                        }

                        return Dismissible(
                          key: Key('parsed_${item.id}'),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            setState(() {
                              _parsedItems.removeAt(index);
                            });
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.canonicalName,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: badgeColor, width: 0.8),
                                    ),
                                    child: Text(
                                      badgeText,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  Text('${item.quantity} ${item.unit}', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 12),
                                  Chip(
                                    label: Text(item.category, style: const TextStyle(fontSize: 10)),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: Colors.grey.shade100,
                                  ),
                                  if (item.isDuplicate) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.copy, size: 14, color: Colors.blue),
                                  ]
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                                onPressed: () => _editItemDialog(index),
                              ),
                              onTap: () => _editItemDialog(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            if (_isParsed && _parsedItems.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -3))],
                ),
                child: SafeArea(
                  child: ElevatedButton.icon(
                    onPressed: _isImporting ? null : _executeImport,
                    icon: _isImporting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _isImporting
                          ? 'Importing...'
                          : (isNewListMode
                              ? 'Create List with ${_parsedItems.length} Items'
                              : 'Add ${_parsedItems.length} Items to List'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
