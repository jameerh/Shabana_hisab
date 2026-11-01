import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import '../../data/database/database.dart';
import '../../main.dart';
import '../../l10n/app_localizations.dart';
import '../../core/localization/bilingual_text.dart';

class UnitManagementView extends StatefulWidget {
  final int profileId;
  const UnitManagementView({super.key, required this.profileId});

  @override
  State<UnitManagementView> createState() => _UnitManagementViewState();
}

class _UnitManagementViewState extends State<UnitManagementView> {
  final TextEditingController _unitController = TextEditingController();

  void _addUnit() async {
    if (_unitController.text.isNotEmpty) {
      await database.addUnit(UnitsCompanion.insert(
        name: _unitController.text.trim(),
        normalizedName: _unitController.text.trim().toLowerCase(),
        profileId: Value(widget.profileId),
      ));
      _unitController.clear();
      if (mounted) Navigator.pop(context);
    }
  }

  void _showAddDialog() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.addNewUnit ?? 'Add New Unit'),
        content: TextField(
          controller: _unitController,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n?.unitNameHint ?? 'e.g. box, tray'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n?.cancel ?? 'Cancel')),
          TextButton(onPressed: _addUnit, child: Text(l10n?.add ?? 'Add')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: BilingualText(
          english: 'Manage Units',
          marathi: 'युनिट व्यवस्थापन',
          languageController: languageController,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: StreamBuilder<List<Unit>>(
        stream: database.watchUnits(widget.profileId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final units = snapshot.data!;
          return ListView.builder(
            itemCount: units.length,
            itemBuilder: (context, index) {
              final unit = units[index];
              return ListTile(
                title: Text(unit.name),
                trailing: unit.profileId != null 
                  ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => database.deleteUnit(unit),
                    )
                  : Text(l10n?.systemUnit ?? 'System', style: const TextStyle(color: Colors.grey, fontSize: 10)),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
