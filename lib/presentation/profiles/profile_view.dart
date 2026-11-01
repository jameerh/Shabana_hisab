import 'package:flutter/material.dart';
import '../../main.dart';
import '../../data/database/database.dart';
import '../../data/services/pdf_service.dart';
import '../../data/services/profile_service.dart';
import 'package:drift/drift.dart' as drift;

class ProfileView extends StatefulWidget {
  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  
  Future<void> _handleDelete(Profile profile) async {
    final transactions = await database.getTransactionsByProfile(profile.id);
    
    if (transactions.isNotEmpty) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('सावधान (Warning)'),
          content: Text('या प्रोफाइलमध्ये ${transactions.length} व्यवहार आहेत. डिलीट करण्यापूर्वी काय करायचे आहे?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), 
              child: const Text('कॅन्सल')
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () async {
                Navigator.pop(context);
                await PdfService.generateListPdf(
                  transactions: transactions, 
                  profileName: profile.name, 
                  filterDesc: "पूर्ण बॅकअप (Full Backup)"
                );
                // Re-ask for deletion
                _confirmFinalDelete(profile);
              }, 
              child: const Text('बॅकअप आणि शेअर (Backup)')
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _confirmFinalDelete(profile);
              }, 
              child: const Text('थेट डिलीट करा (Delete Anyway)')
            ),
          ],
        ),
      );
    } else {
      _confirmFinalDelete(profile);
    }
  }

  void _confirmFinalDelete(Profile profile) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('खात्री करा (Confirm)'),
        content: Text('तुम्हाला नक्की "${profile.name}" आणि त्यातील सर्व माहिती डिलीट करायची आहे का?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('नाही')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('हो, डिलीट करा')
          ),
        ],
      )
    );

    if (result == true) {
      await database.deleteTransactionsByProfile(profile.id);
      await database.deleteProfile(profile);
      
      // If active profile was deleted, switch to another one
      final activeId = await ProfileService.getActiveProfileId();
      if (activeId == profile.id) {
        final remaining = await database.select(database.profiles).get();
        if (remaining.isNotEmpty) {
          await ProfileService.setActiveProfileId(remaining.first.id);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('प्रोफाइल डिलीट केली'))
      );
    }
  }

  void _showProfileDialog({Profile? existingProfile}) {
    TextEditingController nameCtrl = TextEditingController(text: existingProfile?.name ?? '');
    ProfileType selectedType = existingProfile?.type ?? ProfileType.SHOP;

    showDialog(context: context, builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(existingProfile == null ? 'नवीन प्रोफाइल' : 'प्रोफाइल एडिट करा'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl, 
                  decoration: const InputDecoration(labelText: 'प्रोफाइलचे नाव (उदा. माझे दुकान)')
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<ProfileType>(
                  value: selectedType,
                  items: ProfileType.values.map((t) {
                    return DropdownMenuItem(value: t, child: Text(t.name));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setStateDialog(() => selectedType = val);
                  },
                  decoration: const InputDecoration(labelText: 'प्रकार (Type)'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('कॅन्सल')),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;

                  if (existingProfile == null) {
                    await database.addProfile(ProfilesCompanion.insert(
                      name: nameCtrl.text.trim(),
                      type: selectedType,
                    ));
                  } else {
                    await database.updateProfile(existingProfile.copyWith(
                      name: nameCtrl.text.trim(),
                      type: selectedType,
                    ));
                  }
                  Navigator.pop(context);
                },
                child: Text(existingProfile == null ? 'तयार करा' : 'अपडेट करा'),
              )
            ],
          );
        }
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('प्रोफाइल व्यवस्थापन (Profiles)'),
      ),
      body: StreamBuilder<List<Profile>>(
        stream: database.watchAllProfiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final profiles = snapshot.data ?? [];
          
          if (profiles.isEmpty) {
            return const Center(
              child: Text('अद्याप कोणतीही प्रोफाइल नाही.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.15), 
                    child: const Icon(Icons.person, color: Colors.green)
                  ),
                  title: Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text('प्रकार: ${profile.type.name}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.grey),
                        onPressed: () => _showProfileDialog(existingProfile: profile),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _handleDelete(profile),
                      ),
                    ],
                  ),
                  onTap: () async {
                    await ProfileService.setActiveProfileId(profile.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('प्रोफाइल बदलली: ${profile.name}'))
                    );
                    Navigator.pop(context); // Go back after switching if desired
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProfileDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
