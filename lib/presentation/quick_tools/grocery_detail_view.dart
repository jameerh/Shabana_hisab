import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/database/database.dart';
import '../../data/services/voice_service.dart';
import '../../data/repositories/grocery_repository.dart';
import '../../core/voice/grocery_parser.dart';
import '../../data/services/profile_service.dart';
import '../../data/services/pdf_service.dart';
import '../../core/voice_ai/voice_understanding_engine.dart';
import '../../core/voice_ai/grocery_dictionary.dart';
import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'grocery_import_dialog.dart';

class GroceryDetailView extends StatefulWidget {
  final GroceryList list;
  const GroceryDetailView({super.key, required this.list});

  @override
  State<GroceryDetailView> createState() => _GroceryDetailViewState();
}

class _GroceryDetailViewState extends State<GroceryDetailView> {
  final VoiceService _voiceService = VoiceService();
  final GroceryRepository _repository = GroceryRepository();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _editNameController = TextEditingController();
  final TextEditingController _editQtyController = TextEditingController();
  final TextEditingController _editUnitController = TextEditingController();
  final TextEditingController _editPriceController = TextEditingController();
  
  late VoiceUnderstandingEngine _engine;
  late GroceryParser _parser;
  
  int? _profileId;
  bool _isListening = false;
  StreamSubscription? _voiceSubscription;
  String _searchQuery = "";

  bool _isSelectionMode = false;
  bool _isContinuousMode = false;
  final Set<int> _selectedIds = {};
  String _processedTextInSession = ""; // To prevent duplicates in continuous mode
  String _currentTranscript = ""; // For live feedback
  List<String> _suggestedItems = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final id = await ProfileService.getActiveProfileId();
    setState(() {
      _profileId = id;
      _engine = VoiceUnderstandingEngine(profileId: id);
      _parser = GroceryParser(engine: _engine);
    });
    
    _loadSuggestedItems();
    _initVoice();
  }

  Future<void> _loadSuggestedItems() async {
    if (_profileId == null) return;
    final suggestions = await _repository.getSuggestedItems(_profileId!, widget.list.id);
    if (mounted) setState(() => _suggestedItems = suggestions);
  }

  void _initVoice() async {
    _voiceSubscription = _voiceService.onTextResult.listen((text) {
      if (text.startsWith("STATUS:")) {
        if (text.contains("notListening")) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _currentTranscript = "";
            });
          }
        }
        return;
      }
      
      if (text.startsWith("ERROR:")) {
        if (mounted) setState(() => _currentTranscript = text);
        return;
      }

      if (text.startsWith("PARTIAL:")) {
        final words = text.replaceFirst("PARTIAL:", "");
        if (mounted) setState(() => _currentTranscript = words);
        return;
      }

      if (text.startsWith("RAW:")) return;
      
      // If we got here, it's a FINAL result
      if (mounted) setState(() => _currentTranscript = "");
      _handleVoiceResult(text);
    });
  }

  void _handleVoiceResult(String text) async {
    if (text.isEmpty) return;

    String textToParse = text;
    
    if (_isContinuousMode) {
      // In continuous mode, the engine often returns the full transcript so far.
      // We only want to parse the NEW words since the last result.
      if (_processedTextInSession.isNotEmpty && text.startsWith(_processedTextInSession)) {
        textToParse = text.substring(_processedTextInSession.length).trim();
      } else if (text == _processedTextInSession) {
        return; // Already processed
      }
      
      if (textToParse.isEmpty) return;
      _processedTextInSession = text; // Update the "seen" transcript
    }

    final parsedItems = await _parser.parse(textToParse);
    if (!mounted || parsedItems.isEmpty) return;

    for (var item in parsedItems) {
      final lastPrice = await _repository.getLastKnownPrice(item.itemName);
      if (!mounted) return;
      await _repository.addItem(
        listId: widget.list.id,
        name: item.itemName,
        quantity: item.quantity,
        unit: item.unit,
        category: item.category,
        estimatedPrice: lastPrice,
      );
    }
    
    if (mounted) {
      HapticFeedback.mediumImpact();
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      await _voiceService.stopListening();
      if (mounted) setState(() => _currentTranscript = "");
    } else {
      _processedTextInSession = ""; // Reset session tracker for new start
      if (mounted) setState(() => _currentTranscript = "Listening...");
      if (_isContinuousMode) {
        await _voiceService.startListening();
      } else {
        await _voiceService.startNativeGoogleVoice();
      }
    }
    if (mounted) {
      setState(() {
        _isListening = _voiceService.isListening;
      });
    }
  }

  Future<void> _listenForField(TextEditingController controller) async {
    final result = await _voiceService.startNativeGoogleVoice(addToStream: false);
    if (result != null && mounted) {
      setState(() {
        controller.text = result;
      });
    }
  }

  void _exportPdf() async {
    final items = await _repository.watchItems(widget.list.id).first;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("List is empty!")));
      return;
    }
    await PdfService.generateGroceryPdf(list: widget.list, items: items);
  }

  void _copyAllItems(List<GroceryItem> allItems) {
    if (allItems.isEmpty) return;

    String content = "🛒 *${widget.list.name}*\n\n";
    for (var item in allItems) {
      final status = item.isChecked ? "✅ [DONE]" : "⭕ [PENDING]";
      content += "$status ${item.itemName} (${item.quantity} ${item.unit})\n";
    }
    
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All items copied to clipboard")));
  }

  void _copySelected(List<GroceryItem> allItems) {
    final selected = allItems.where((i) => _selectedIds.contains(i.id)).toList();
    if (selected.isEmpty) return;

    String content = "🛒 *Selected Items*\n\n";
    for (var item in selected) {
      content += "- ${item.itemName} (${item.quantity} ${item.unit})\n";
    }
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied to clipboard")));
    
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _shareSelected(List<GroceryItem> allItems) async {
    final selected = allItems.where((i) => _selectedIds.contains(i.id)).toList();
    if (selected.isEmpty) return;
    
    if (selected.length == 1) {
      await PdfService.generateGroceryItemReceiptPdf(widget.list, selected.first);
    } else {
      await PdfService.generateGroceryPdf(list: widget.list, items: selected);
    }
    
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _deleteSelected(List<GroceryItem> allItems) async {
    final selected = allItems.where((i) => _selectedIds.contains(i.id)).toList();
    for (var i in selected) {
      await _repository.deleteItem(i);
    }
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _showEditDialog(GroceryItem item) {
    String originalHeardName = item.itemName;
    _editNameController.text = item.itemName;
    _editQtyController.text = item.quantity.toString();
    _editUnitController.text = item.unit ?? '';
    _editPriceController.text = item.estimatedPrice?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: TextField(controller: _editNameController, decoration: const InputDecoration(labelText: 'Item Name'))),
                  IconButton(icon: const Icon(Icons.mic, color: Colors.teal), onPressed: () => _listenForField(_editNameController)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: TextField(controller: _editQtyController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number)),
                  IconButton(icon: const Icon(Icons.mic, color: Colors.teal), onPressed: () => _listenForField(_editQtyController)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: TextField(controller: _editUnitController, decoration: const InputDecoration(labelText: 'Unit'))),
                  IconButton(icon: const Icon(Icons.mic, color: Colors.teal), onPressed: () => _listenForField(_editUnitController)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: TextField(controller: _editPriceController, decoration: const InputDecoration(labelText: 'Est. Price (per unit)'), keyboardType: TextInputType.number)),
                  IconButton(icon: const Icon(Icons.mic, color: Colors.teal), onPressed: () => _listenForField(_editPriceController)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (_editNameController.text != originalHeardName) {
                await _engine.learnCorrection(originalHeardName, _editNameController.text, 'grocery');
              }

              await _repository.toggleItemStatus(
                item.copyWith(
                  itemName: _editNameController.text,
                  quantity: double.tryParse(_editQtyController.text) ?? item.quantity,
                  unit: drift.Value(_editUnitController.text),
                  estimatedPrice: drift.Value(double.tryParse(_editPriceController.text)),
                ),
                item.isChecked,
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save & Learn'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _voiceSubscription?.cancel();
    _voiceService.dispose();
    _searchController.dispose();
    _editNameController.dispose();
    _editQtyController.dispose();
    _editUnitController.dispose();
    _editPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_profileId == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return StreamBuilder<List<GroceryItem>>(
      stream: _repository.watchItems(widget.list.id),
      builder: (context, snapshot) {
        var items = snapshot.data ?? [];
        if (_searchQuery.isNotEmpty) {
          items = items.where((i) => i.itemName.toLowerCase().contains(_searchQuery)).toList();
        }

        // Sort items by category
        items.sort((a, b) => (a.category ?? 'Other').compareTo(b.category ?? 'Other'));

        // Calculate total estimated
        double totalEstimated = 0.0;
        for (var item in items) {
          if (item.estimatedPrice != null) {
            totalEstimated += (item.estimatedPrice! * item.quantity);
          }
        }

        // Build list with headers
        List<dynamic> listItems = [];
        String? currentCategory;
        for (var item in items) {
          final cat = item.category ?? 'Other';
          if (cat != currentCategory) {
            listItems.add(cat);
            currentCategory = cat;
          }
          listItems.add(item);
        }

        return Scaffold(
          appBar: _isSelectionMode
            ? AppBar(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                title: Text('${_selectedIds.length} Selected'),
                actions: [
                  IconButton(icon: const Icon(Icons.copy), onPressed: () => _copySelected(items)),
                  IconButton(icon: const Icon(Icons.share), onPressed: () => _shareSelected(items)),
                  IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteSelected(items)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() { _isSelectionMode = false; _selectedIds.clear(); })),
                ],
              )
            : AppBar(
                title: Text(widget.list.name),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.content_paste_go),
                    tooltip: 'Paste / Import Text',
                    onPressed: () {
                      if (_profileId != null) {
                        GroceryImportDialog.show(
                          context,
                          profileId: _profileId!,
                          existingListId: widget.list.id,
                          existingListName: widget.list.name,
                        );
                      }
                    },
                  ),
                  IconButton(icon: const Icon(Icons.copy_all), onPressed: () => _copyAllItems(items), tooltip: 'Copy All Items'),
                  IconButton(icon: const Icon(Icons.picture_as_pdf_outlined), onPressed: _exportPdf),
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'import') {
                        if (_profileId != null) {
                          GroceryImportDialog.show(
                            context,
                            profileId: _profileId!,
                            existingListId: widget.list.id,
                            existingListName: widget.list.name,
                          );
                        }
                      } else if (val == 'clear') {
                        _repository.clearList(widget.list.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'import',
                        child: Row(
                          children: [
                            Icon(Icons.content_paste_go, color: Colors.teal),
                            SizedBox(width: 12),
                            Text('Paste / Import Text'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(value: 'clear', child: Text('Clear All Items')),
                    ],
                  ),
                ],

              ),
          body: Column(
            children: [
              // Voice Hint Row
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.teal.shade700,
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 16, color: Colors.white70),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'असे बोला (Example): "साखर ५ किलो" (Sugar 5 kg) किंवा "दूध २ लिटर"',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  ),
                ),

              if (!_isSelectionMode && _suggestedItems.isNotEmpty && _searchQuery.isEmpty)
                Container(
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _suggestedItems.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestedItems[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text('+ $suggestion', style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.teal.shade50,
                          onPressed: () async {
                            final lastPrice = await _repository.getLastKnownPrice(suggestion);
                            final cat = GroceryDictionary.getCategory(suggestion);
                            await _repository.addItem(
                              listId: widget.list.id,
                              name: suggestion,
                              quantity: 1,
                              unit: 'nos',
                              category: cat,
                              estimatedPrice: lastPrice,
                            );
                            _loadSuggestedItems(); // Refresh suggestions
                          },
                        ),
                      );
                    },
                  ),
                ),

              Expanded(
                child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.teal.withOpacity(0.1)),
                          const SizedBox(height: 16),
                          Text(_searchQuery.isEmpty ? 'Say "Milk 2 liters" to add' : 'No items found', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: listItems.length,
                      itemBuilder: (context, index) {
                        final dynamic itemOrHeader = listItems[index];
                        
                        if (itemOrHeader is String) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
                            child: Text(
                              itemOrHeader.toUpperCase(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          );
                        }

                        final item = itemOrHeader as GroceryItem;
                        final isSelected = _selectedIds.contains(item.id);
                        return Dismissible(
                          key: Key('grocery_${item.id}'),
                          direction: _isSelectionMode ? DismissDirection.none : DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.endToStart) {
                              _repository.deleteItem(item);
                              return true;
                            }
                            return false;
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.teal.shade50 : (item.isChecked ? Colors.grey.shade50 : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected ? Border.all(color: Colors.teal, width: 2) : null,
                              boxShadow: [
                                if (!item.isChecked && !isSelected) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                              ],
                            ),
                            child: ListTile(
                              leading: _isSelectionMode
                                ? Checkbox(
                                    value: isSelected,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) _selectedIds.add(item.id);
                                        else {
                                          _selectedIds.remove(item.id);
                                          if (_selectedIds.isEmpty) _isSelectionMode = false;
                                        }
                                      });
                                    }
                                  )
                                : Checkbox(
                                    value: item.isChecked,
                                    activeColor: Colors.teal,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (val) => _repository.toggleItemStatus(item, val!),
                                  ),
                              title: Text(item.itemName, style: TextStyle(
                                decoration: item.isChecked ? TextDecoration.lineThrough : null,
                                color: item.isChecked ? Colors.grey : Colors.black87,
                                fontWeight: FontWeight.w600,
                              )),
                              subtitle: Row(
                                children: [
                                  Text('${item.quantity} ${item.unit}', style: TextStyle(color: item.isChecked ? Colors.grey : Colors.teal.shade700, fontWeight: FontWeight.bold)),
                                  if (item.estimatedPrice != null) ...[
                                    const SizedBox(width: 8),
                                    Text('• Est: ₹${item.estimatedPrice!.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  ]
                                ],
                              ),
                              trailing: _isSelectionMode ? null : IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                                onPressed: () => _showEditDialog(item),
                              ),
                              onLongPress: () {
                                setState(() {
                                  _isSelectionMode = true;
                                  _selectedIds.add(item.id);
                                });
                                HapticFeedback.heavyImpact();
                              },
                              onTap: () {
                                if (_isSelectionMode) {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedIds.remove(item.id);
                                      if (_selectedIds.isEmpty) _isSelectionMode = false;
                                    } else {
                                      _selectedIds.add(item.id);
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
              ),

              if (_isListening && _currentTranscript.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hearing, size: 18, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _currentTranscript,
                          style: TextStyle(color: Colors.amber.shade900, fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),

              if (!_isSelectionMode)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (totalEstimated > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Estimated Bill:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                                Text('₹${totalEstimated.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal.shade900)),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  if (_profileId != null) {
                                    GroceryImportDialog.show(
                                      context,
                                      profileId: _profileId!,
                                      existingListId: widget.list.id,
                                      existingListName: widget.list.name,
                                    );
                                  }
                                },
                                icon: const Icon(Icons.content_paste_go, size: 18),
                                label: const Text('Paste Text', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.teal,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: Colors.teal),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                   showDialog(
                                     context: context,
                                     builder: (context) {
                                       _editNameController.clear();
                                       _editQtyController.text = '1';
                                       _editUnitController.text = 'nos';
                                       _editPriceController.clear();
                                       return AlertDialog(
                                       title: const Text('Add Item'),
                                       content: SingleChildScrollView(
                                         child: Column(
                                           mainAxisSize: MainAxisSize.min,
                                           children: [
                                             Row(
                                               children: [
                                                 Expanded(child: TextField(controller: _editNameController, decoration: const InputDecoration(labelText: 'Item Name'))),
                                                 IconButton(icon: const Icon(Icons.mic, color: Colors.teal), onPressed: () => _listenForField(_editNameController)),
                                               ],
                                             ),
                                             Row(
                                               children: [
                                                 Expanded(child: TextField(controller: _editQtyController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number)),
                                                 IconButton(icon: const Icon(Icons.mic, color: Colors.teal), onPressed: () => _listenForField(_editQtyController)),
                                               ],
                                             ),
                                             Row(
                                               children: [
                                                 Expanded(child: TextField(controller: _editUnitController, decoration: const InputDecoration(labelText: 'Unit'))),
                                                 IconButton(icon: const Icon(Icons.mic, color: Colors.teal), onPressed: () => _listenForField(_editUnitController)),
                                               ],
                                             ),
                                             Row(
                                               children: [
                                                 Expanded(child: TextField(controller: _editPriceController, decoration: const InputDecoration(labelText: 'Est. Price (per unit)'), keyboardType: TextInputType.number)),
                                                 IconButton(icon: const Icon(Icons.mic, color: Colors.teal), onPressed: () => _listenForField(_editPriceController)),
                                               ],
                                             ),
                                           ],
                                         ),
                                       ),
                                       actions: [
                                         TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                         TextButton(
                                           onPressed: () async {
                                             if (_editNameController.text.trim().isEmpty) {
                                               Navigator.pop(context);
                                               return;
                                             }
                                             await _repository.addItem(
                                               listId: widget.list.id,
                                               name: _editNameController.text.trim(),
                                               quantity: double.tryParse(_editQtyController.text) ?? 1.0,
                                               unit: _editUnitController.text.trim(),
                                               category: GroceryDictionary.getCategory(_editNameController.text.trim()),
                                               estimatedPrice: double.tryParse(_editPriceController.text),
                                             );
                                             _loadSuggestedItems();
                                             if (mounted) Navigator.pop(context);
                                           },
                                           child: const Text('Add'),
                                         ),
                                       ],
                                     );
                                     },
                                   );
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Item', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.teal,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: Colors.teal),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FloatingActionButton.large(
                              onPressed: _toggleListening,
                              backgroundColor: _isListening ? Colors.red : Colors.teal,
                              child: Icon(_isListening ? Icons.stop : Icons.mic, size: 36, color: Colors.white),
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
