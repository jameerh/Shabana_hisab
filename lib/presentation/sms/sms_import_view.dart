import 'package:flutter/material.dart';
import '../../data/services/profile_service.dart';
import '../../data/services/sms_service.dart';
import '../../data/repositories/sms_repository.dart';
import 'sms_account_discovery_sheet.dart';
import 'sms_transaction_review_feed.dart';
import 'sms_privacy_view.dart';
import '../../l10n/app_localizations.dart';
import '../../core/localization/bilingual_text.dart';
import '../../main.dart';

class SmsImportView extends StatefulWidget {
  const SmsImportView({super.key});

  @override
  State<SmsImportView> createState() => _SmsImportViewState();
}

class _SmsImportViewState extends State<SmsImportView> {
  final SmsRepository _repository = SmsRepository();
  int? _profileId;
  bool _isScanning = false;
  SmsScanSummary? _lastSummary;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final id = await ProfileService.getActiveProfileId();
    setState(() => _profileId = id);
  }

  void _showHorizonDialog() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n?.scanSmsInbox ?? 'Scan Bank & Card SMS'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _performScan(SmsScanHorizon.days30);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(l10n?.scanHorizon30 ?? 'Last 30 Days (Recommended)'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _performScan(SmsScanHorizon.days90);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(l10n?.scanHorizon90 ?? 'Last 90 Days'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _performScan(SmsScanHorizon.fullInbox);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(l10n?.scanHorizonAll ?? 'Full Inbox'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performScan(SmsScanHorizon horizon) async {
    if (_profileId == null) return;
    setState(() => _isScanning = true);

    try {
      final summary = await SmsService.scanInbox(horizon: horizon);
      final candidates = await _repository.processScanResults(
        profileId: _profileId!,
        rawResults: summary.parsedResults,
      );

      setState(() {
        _isScanning = false;
        _lastSummary = summary;
      });

      if (mounted) {
        if (candidates.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SmsTransactionReviewFeed(
                profileId: _profileId!,
                candidates: candidates,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Scanned ${summary.scannedCount} SMS messages (${summary.financialCount} financial). No new transactions found.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isScanning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SMS Scan completed: ${e.toString()}')),
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
          english: 'Bank & Card SMS Import',
          marathi: 'बँक आणि कार्ड SMS आयात',
          languageController: languageController,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Privacy',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SmsPrivacyView()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.indigo,
                      child: Icon(Icons.sms, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 16),
                    BilingualText(
                      english: 'Manual Bank & Card SMS Import',
                      marathi: 'मॅन्युअल बँक आणि कार्ड SMS आयात',
                      languageController: languageController,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n?.privacyNotice ??
                          'SMS scanning happens 100% on your device. Raw SMS text is never saved or uploaded.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    _isScanning
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showHorizonDialog,
                              icon: const Icon(Icons.phonelink_ring),
                              label: Text(l10n?.scanSmsInbox ?? 'Scan Bank & Card SMS'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_profileId != null) ...[
              ListTile(
                leading: const Icon(Icons.account_balance, color: Colors.indigo),
                title: BilingualText(
                  english: 'Discovered Accounts & Cards',
                  marathi: 'शोधलेली खाती आणि कार्डे',
                  languageController: languageController,
                ),
                subtitle: const Text('Manage track/ignore permissions per account'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SmsAccountDiscoverySheet(profileId: _profileId!),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, color: Colors.indigo),
                title: BilingualText(
                  english: 'SMS Privacy & Transparency',
                  marathi: 'SMS गोपनीयता आणि पारदर्शकता',
                  languageController: languageController,
                ),
                subtitle: const Text('View guarantees or delete import history'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SmsPrivacyView()),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
