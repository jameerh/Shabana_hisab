import 'package:flutter/material.dart';
import '../../data/database/database.dart';
import '../../main.dart';
import '../../data/services/backup_service.dart';
import '../../data/services/security_service.dart';
import 'engine_monitor_view.dart';
import 'predictive_quality_view.dart';
import '../sms/sms_import_view.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/localization/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/security/subscription_manager.dart';
import '../subscription/subscription_modal.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  ShopSetting? _currentSettings;

  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();
  final _upiController = TextEditingController();
  final _prefixController = TextEditingController();

  bool _isLoading = true;
  bool _appLockEnabled = false;
  final _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await database.getShopSettings();
    _currentSettings = settings;
    if (settings != null) {
      _shopNameController.text = settings.shopName ?? '';
      _ownerNameController.text = settings.ownerName ?? '';
      _mobileController.text = settings.mobileNumber ?? '';
      _addressController.text = settings.address ?? '';
      _gstController.text = settings.gstNumber ?? '';
      _upiController.text = settings.upiId ?? '';
      _prefixController.text = settings.invoicePrefix ?? '';
    }
    
    final lockEnabled = await SecurityService.isLockEnabled();
    setState(() {
      _appLockEnabled = lockEnabled;
      _isLoading = false;
    });
  }

  void _saveSettings() async {
    setState(() => _isLoading = true);
    await database.addOrUpdateSettings(ShopSettingsCompanion(
      id: _currentSettings != null ? drift.Value(_currentSettings!.id) : const drift.Value.absent(),
      shopName: drift.Value(_shopNameController.text),
      ownerName: drift.Value(_ownerNameController.text),
      mobileNumber: drift.Value(_mobileController.text),
      address: drift.Value(_addressController.text),
      gstNumber: drift.Value(_gstController.text),
      upiId: drift.Value(_upiController.text),
      invoicePrefix: drift.Value(_prefixController.text),
      updatedAt: drift.Value(DateTime.now()),
    ));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings Saved!')));
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Store Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _shopNameController, decoration: const InputDecoration(labelText: 'Store Name')),
            const SizedBox(height: 10),
            TextField(controller: _ownerNameController, decoration: const InputDecoration(labelText: 'Owner Name')),
            const SizedBox(height: 10),
            TextField(controller: _mobileController, decoration: const InputDecoration(labelText: 'Mobile Number')),
            const SizedBox(height: 10),
            TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: 10),
            TextField(controller: _gstController, decoration: const InputDecoration(labelText: 'GST Number')),
            const SizedBox(height: 10),
            TextField(controller: _upiController, decoration: const InputDecoration(labelText: 'UPI ID')),
            const SizedBox(height: 10),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Save Settings'),
            ),
            const Divider(height: 40),
            const Text('Data Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Back up your data regularly to prevent data loss. This will export your database as a file.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
              onPressed: () async {
                await BackupService.performBackup();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup Completed!')));
              },
              icon: const Icon(Icons.backup),
              label: const Text('Perform Local Backup'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('डेटा रिस्टोर करा? (Restore Data?)'),
                    content: const Text('रिस्टोर केल्यावर तुमचा सध्याचा सर्व डेटा डिलीट होईल आणि बॅकअप फाईल मधील डेटा येईल. तुम्ही खात्रीशीर आहात का?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('रद्द करा (Cancel)')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('रिस्टोर करा', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );

                if (confirm == true) {
                  final success = await BackupService.restoreBackup();
                  if (!mounted) return;
                  if (success) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => AlertDialog(
                        title: const Text('यशस्वी! (Success!)'),
                        content: const Text('डेटा आणि हेल्थ डॉक्युमेंट्स रिस्टोर झाले आहेत. बदल पाहण्यासाठी कृपया ॲप बंद करून पुन्हा चालू करा (Data and attachments restored successfully. Please restart the app).'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                        ],
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('बॅकअप रिस्टोर रद्द झाला किंवा त्रुटी आली (Restore cancelled or failed)')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.restore),
              label: const Text('Restore from Backup'),
            ),
            const Divider(height: 40),
            const Text('Language & Region (भाषा आणि प्रदेश)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListTile(
              title: const Text('Application UI Language'),
              subtitle: Text(languageController.currentLanguage.displayName),
              leading: const Icon(Icons.language, color: Colors.blue),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguageSelectionDialog(context),
            ),
            ListTile(
              title: const Text('Voice Input Language (आवाज भाषा)'),
              subtitle: const Text('Independent speech-to-text recognition language'),
              leading: const Icon(Icons.mic, color: Colors.green),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showVoiceLanguageSelectionDialog(context),
            ),
            const Divider(height: 40),
            const Text('Data & Automation (डेटा आणि ऑटोमेशन)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListTile(
              title: const Text('Bank & Card SMS Import'),
              subtitle: const Text('Scan bank/card debit SMS on-device with account approval'),
              leading: const Icon(Icons.sms, color: Colors.indigo),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SmsImportView()));
              },
            ),
            const Divider(height: 40),
            const Text('Subscription & Licensing (परवाना)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListTile(
              title: const Text('शबाना हिसाब सबस्क्रिप्शन (Pro License)'),
              subtitle: Text(
                SubscriptionManager.instance.isPro
                    ? 'PRO सक्रिय (${SubscriptionManager.instance.getRemainingTimeStr()})'
                    : 'CSC Studio स्कॅन द्वारे सक्रिय करा',
              ),
              leading: const Icon(Icons.workspace_premium, color: Color(0xFFD97706)),
              trailing: const Icon(Icons.qr_code_scanner, color: Colors.blue),
              onTap: () {
                SubscriptionModal.show(context);
              },
            ),
            const Divider(height: 40),
            const Text('Security (सुरक्षा)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('ॲप लॉक (App Lock)'),
              subtitle: const Text('ॲप उघडण्यासाठी बायोमेट्रिक किंवा पिन वापरा'),
              value: _appLockEnabled,
              onChanged: (val) async {
                if (val) {
                  final hasPin = await SecurityService.hasPinSet();
                  if (!hasPin) {
                    _showSetPinDialog();
                    return;
                  }
                }
                await SecurityService.setLockEnabled(val);
                setState(() => _appLockEnabled = val);
              },
            ),
            if (_appLockEnabled)
              ListTile(
                title: const Text('पिन बदला (Change PIN)'),
                leading: const Icon(Icons.lock_reset),
                onTap: _showSetPinDialog,
              ),
            const Divider(height: 40),
            const Text('Developer Diagnostics (FOS Core)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListTile(
              title: const Text('FOS Engine Telemetry Monitor'),
              subtitle: const Text('Real-time execution duration (ms) & health telemetry'),
              leading: const Icon(Icons.monitor_heart, color: Colors.teal),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EngineMonitorView()));
              },
            ),
            ListTile(
              title: const Text('Predictive Quality Telemetry'),
              subtitle: const Text('Cache hit rates, engine runtimes & prediction accuracy'),
              leading: const Icon(Icons.psychology_rounded, color: Colors.purpleAccent),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PredictiveQualityView()));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select UI Language'),
        children: AppLanguage.values.map((lang) {
          final isSelected = languageController.currentLanguage == lang;
          return RadioListTile<AppLanguage>(
            title: Text(lang.displayName),
            value: lang,
            groupValue: languageController.currentLanguage,
            selected: isSelected,
            onChanged: (val) {
              if (val != null) {
                languageController.setLanguage(val);
                Navigator.pop(ctx);
                setState(() {});
              }
            },
          );
        }).toList(),
      ),
    );
  }

  void _showVoiceLanguageSelectionDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final currentVoice = prefs.getString('voice_language') ?? 'mr_IN';

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Voice Input Language'),
        children: [
          RadioListTile<String>(
            title: const Text('मराठी (Marathi - mr_IN)'),
            value: 'mr_IN',
            groupValue: currentVoice,
            onChanged: (val) async {
              if (val != null) {
                await prefs.setString('voice_language', val);
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
              }
            },
          ),
          RadioListTile<String>(
            title: const Text('English (en_IN)'),
            value: 'en_IN',
            groupValue: currentVoice,
            onChanged: (val) async {
              if (val != null) {
                await prefs.setString('voice_language', val);
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
              }
            },
          ),
          RadioListTile<String>(
            title: const Text('हिंदी (Hindi - hi_IN)'),
            value: 'hi_IN',
            groupValue: currentVoice,
            onChanged: (val) async {
              if (val != null) {
                await prefs.setString('voice_language', val);
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSetPinDialog() {
    _pinController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('नवीन पिन सेट करा'),
        content: TextField(
          controller: _pinController,
          decoration: const InputDecoration(labelText: '४ अंकी पिन (4 digit PIN)'),
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('कॅन्सल')),
          ElevatedButton(
            onPressed: () async {
              if (_pinController.text.length == 4) {
                await SecurityService.setPin(_pinController.text);
                await SecurityService.setLockEnabled(true);
                setState(() => _appLockEnabled = true);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('पिन यशस्वीरित्या सेट झाला!')));
              }
            },
            child: const Text('सेव्ह करा'),
          )
        ],
      ),
    );
  }
}
