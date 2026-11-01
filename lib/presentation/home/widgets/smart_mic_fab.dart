import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/localization/bilingual_text.dart';
import '../../../main.dart';
import '../../sms/sms_import_view.dart';

class SmartMicFab extends StatelessWidget {
  final bool isListening;
  final VoidCallback onTap;
  final VoidCallback onTypePressed;
  final VoidCallback onScanPressed;
  final VoidCallback onPastePressed;

  const SmartMicFab({
    super.key,
    required this.isListening,
    required this.onTap,
    required this.onTypePressed,
    required this.onScanPressed,
    required this.onPastePressed,
  });

  void _showCommandSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BilingualText(
                english: 'Input Options',
                marathi: 'इतर पर्याय',
                languageController: languageController,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.mic, color: Colors.green),
                title: BilingualText(
                  english: 'Speak',
                  marathi: 'व्हॉईस कमांड',
                  languageController: languageController,
                ),
                onTap: () {
                  Navigator.pop(context);
                  onTap();
                },
              ),
              ListTile(
                leading: const Icon(Icons.keyboard, color: Colors.blue),
                title: BilingualText(
                  english: 'Type',
                  marathi: 'टाइप करा',
                  languageController: languageController,
                ),
                onTap: () {
                  Navigator.pop(context);
                  onTypePressed();
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.orange),
                title: BilingualText(
                  english: 'Scan Receipt',
                  marathi: 'पावती स्कॅन करा',
                  languageController: languageController,
                ),
                onTap: () {
                  Navigator.pop(context);
                  onScanPressed();
                },
              ),
              ListTile(
                leading: const Icon(Icons.content_paste, color: Colors.purple),
                title: BilingualText(
                  english: 'Paste',
                  marathi: 'पेस्ट करा',
                  languageController: languageController,
                ),
                onTap: () {
                  Navigator.pop(context);
                  onPastePressed();
                },
              ),
              ListTile(
                leading: const Icon(Icons.sms, color: Colors.indigo),
                title: BilingualText(
                  english: 'Scan Bank SMS',
                  marathi: 'बँक SMS स्कॅन करा',
                  languageController: languageController,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SmsImportView()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showCommandSheet(context),
      child: FloatingActionButton(
        onPressed: onTap,
        backgroundColor: isListening ? Colors.red : Colors.green,
        elevation: 4,
        child: Icon(
          isListening ? Icons.stop : Icons.mic,
          size: 32,
          color: Colors.white,
        ),
      ),
    );
  }
}
