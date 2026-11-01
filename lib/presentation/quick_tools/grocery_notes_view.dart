import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database/database.dart';
import '../../data/repositories/grocery_repository.dart';
import '../../data/services/profile_service.dart';
import '../../data/services/pdf_service.dart';
import 'grocery_detail_view.dart';
import 'grocery_import_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../../core/localization/bilingual_text.dart';
import '../../main.dart';

class GroceryNotesView extends StatefulWidget {
  const GroceryNotesView({super.key});

  @override
  State<GroceryNotesView> createState() => _GroceryNotesViewState();
}

class _GroceryNotesViewState extends State<GroceryNotesView> {
  final GroceryRepository _repository = GroceryRepository();
  int? _profileId;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final id = await ProfileService.getActiveProfileId();
    setState(() => _profileId = id);
  }

  void _createNewList() async {
    if (_profileId == null) return;
    final l10n = AppLocalizations.of(context);
    
    final now = DateTime.now();
    final defaultName = "Grocery_${DateFormat('ddMMyy_HHmm').format(now)}";
    _nameController.text = defaultName;

    _showNameDialog(
      title: l10n?.newList ?? 'New Grocery List',
      buttonLabel: l10n?.add ?? 'Create',
      onConfirm: (name) async {
        final listId = await _repository.createList(_profileId!, name);
        final lists = await _repository.watchLists(_profileId!).first;
        final newList = lists.firstWhere((l) => l.id == listId);
        
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GroceryDetailView(list: newList)),
          );
        }
      },
    );
  }

  void _openImportDialog() {
    if (_profileId == null) return;
    GroceryImportDialog.show(
      context,
      profileId: _profileId!,
      onListCreated: (newList) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GroceryDetailView(list: newList)),
        );
      },
    );
  }

  void _showNameDialog({required String title, required String buttonLabel, required Function(String) onConfirm, String? initialValue}) {
    if (initialValue != null) _nameController.text = initialValue;
    final l10n = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'List Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n?.cancel ?? 'Cancel')),
          ElevatedButton(
            onPressed: () {
              onConfirm(_nameController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  void _shareListPdf(GroceryList list) async {
    final items = await _repository.watchItems(list.id).first;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("List is empty!")));
      return;
    }
    await PdfService.generateGroceryPdf(list: list, items: items);
  }

  @override
  Widget build(BuildContext context) {
    if (_profileId == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: BilingualText(
          english: 'Grocery Notes',
          marathi: 'किराणा यादी',
          languageController: languageController,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.content_paste_go),
            tooltip: l10n?.importPasteList ?? 'Import / Paste List',
            onPressed: _openImportDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<GroceryList>>(
        stream: _repository.watchLists(_profileId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final lists = snapshot.data!;
          if (lists.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.note_add_outlined, size: 80, color: Colors.teal.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  Text(l10n?.noSavedLists ?? 'No saved lists yet', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _createNewList,
                        icon: const Icon(Icons.add),
                        label: Text(l10n?.createList ?? 'Create List'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _openImportDialog,
                        icon: const Icon(Icons.content_paste_go),
                        label: const Text('Paste / Import'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.teal, side: const BorderSide(color: Colors.teal)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              return Dismissible(
                key: Key('list_${list.id}'),
                background: Container(
                  color: Colors.blue,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.share, color: Colors.white),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete List?'),
                        content: Text('Are you sure you want to delete "${list.name}"?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _repository.deleteList(list.id);
                      return true;
                    }
                    return false;
                  } else {
                    _shareListPdf(list);
                    return false;
                  }
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade50,
                      child: const Icon(Icons.shopping_cart_outlined, color: Colors.teal),
                    ),
                    title: Text(list.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(list.createdAt)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.teal),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GroceryDetailView(list: list)),
                    ),
                    onLongPress: () {
                      _showNameDialog(
                        title: 'Edit List Name',
                        buttonLabel: 'Update',
                        initialValue: list.name,
                        onConfirm: (newName) async {
                          await _repository.updateListName(list.id, newName);
                        },
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'fab_import',
            onPressed: _openImportDialog,
            backgroundColor: Colors.teal.shade100,
            foregroundColor: Colors.teal.shade900,
            tooltip: 'Import from Clipboard / WhatsApp',
            child: const Icon(Icons.content_paste_go),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'fab_add',
            onPressed: _createNewList,
            backgroundColor: Colors.teal,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

