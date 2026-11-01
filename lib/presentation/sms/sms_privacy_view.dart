import 'package:flutter/material.dart';
import '../../data/repositories/sms_repository.dart';
import '../../data/services/profile_service.dart';
import '../../l10n/app_localizations.dart';
import '../../core/localization/bilingual_text.dart';
import '../../main.dart';

class SmsPrivacyView extends StatefulWidget {
  const SmsPrivacyView({super.key});

  @override
  State<SmsPrivacyView> createState() => _SmsPrivacyViewState();
}

class _SmsPrivacyViewState extends State<SmsPrivacyView> {
  final SmsRepository _repository = SmsRepository();
  int? _profileId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final id = await ProfileService.getActiveProfileId();
    setState(() => _profileId = id);
  }

  Future<void> _deleteHistory() async {
    if (_profileId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Scan Fingerprints?'),
        content: const Text('This will clear stored scan memory and fingerprints, allowing you to re-scan SMS from scratch.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repository.deleteImportHistory(_profileId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS scan fingerprints cleared successfully')),
        );
      }
    }
  }

  Future<void> _deleteAllSmsSetup() async {
    if (_profileId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset SMS Setup & Accounts?'),
        content: const Text('This will remove all discovered SMS bank accounts, tracking permissions, and scan history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repository.deleteAllSmsData(_profileId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS setup and discovered accounts reset successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: BilingualText(
          english: 'SMS Privacy & Transparency',
          marathi: 'SMS गोपनीयता आणि पारदर्शकता',
          languageController: languageController,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_outlined, color: Colors.green, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Privacy Guarantees',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildBullet('Scanning starts ONLY when you tap "Scan Bank & Card SMS".'),
                    _buildBullet('100% Local On-Device processing. Zero server uploads.'),
                    _buildBullet('Raw SMS text is NEVER stored in the database or disk.'),
                    _buildBullet('Only bank accounts you explicitly PERMIT are tracked.'),
                    _buildBullet('Deduplication uses non-reversible SHA-256 hashes.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _deleteHistory,
              icon: const Icon(Icons.cleaning_services_outlined),
              label: Text(l10n?.deleteImportHistory ?? 'Clear Scan Fingerprints & History'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _deleteAllSmsSetup,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Reset SMS Setup & Accounts'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade700),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.indigo, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
