import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/security/subscription_manager.dart';

class SubscriptionModal extends StatefulWidget {
  final bool isLockout;

  const SubscriptionModal({
    super.key,
    this.isLockout = false,
  });

  static Future<void> show(BuildContext context, {bool isLockout = false}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: !isLockout,
      isDismissible: !isLockout,
      builder: (ctx) => SubscriptionModal(isLockout: isLockout),
    );
  }

  @override
  State<SubscriptionModal> createState() => _SubscriptionModalState();
}

class _SubscriptionModalState extends State<SubscriptionModal> {
  final SubscriptionManager _subMgr = SubscriptionManager.instance;
  final TextEditingController _licenseInputController = TextEditingController();

  late LicensePlan _selectedPlan;
  bool _isActivating = false;
  String _activationStatus = '';
  bool _isError = false;

  static const String upiId = "8975131571@okbizaxis";
  static const String payeeName = "Shabana Multi Service";
  static const String supportPhone = "8975131571";

  @override
  void initState() {
    super.initState();
    _selectedPlan = SubscriptionManager.availablePlans[2]; // 1 Year default
    _subMgr.addListener(_onSubChange);
  }

  @override
  void dispose() {
    _subMgr.removeListener(_onSubChange);
    _licenseInputController.dispose();
    super.dispose();
  }

  void _onSubChange() {
    if (mounted) setState(() {});
  }

  void _copyHwid() {
    Clipboard.setData(ClipboardData(text: _subMgr.hardwareId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Hardware ID copied to clipboard"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _pasteLicenseKey() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      _licenseInputController.text = data.text!.trim();
    }
  }

  Future<void> _activate() async {
    final key = _licenseInputController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _isError = true;
        _activationStatus = "कृपया लायसन्स की प्रविष्ट करा किंवा पेस्ट करा.";
      });
      return;
    }

    setState(() {
      _isActivating = true;
      _activationStatus = "लायसन्स तपासत आहे...";
      _isError = false;
    });

    final success = await _subMgr.activateLicense(key);

    if (!mounted) return;

    setState(() {
      _isActivating = false;
      if (success) {
        _isError = false;
        _activationStatus = "अभिनंदन! प्रो सबस्क्रिप्शन यशस्वीरीत्या सक्रिय झाले आहे 🎉";
      } else {
        _isError = true;
        _activationStatus = _subMgr.lastActivationError.isNotEmpty
            ? _subMgr.lastActivationError
            : "अवैध लायसन्स की. कृपया तपासणी करा.";
      }
    });

    if (success) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  Future<void> _shareOnWhatsApp() async {
    final reqString = _subMgr.generateActivationRequest(planId: _selectedPlan.id);
    final msg = """
*👑 शबाना हिसाब (SnapHisaab) - सबस्क्रिप्शन परवाना विनंती*

- *उत्पादन:* ShabanaHisaab
- *Device Hardware ID:* ${_subMgr.hardwareId}
- *निवडलेली योजना:* ${_selectedPlan.name} (₹${_selectedPlan.price} - ${_selectedPlan.durationText})

*Activation Request Code:*
$reqString

मी UPI द्वारे ₹${_selectedPlan.price} भरले आहेत. कृपया CSC Studio द्वारे माझे डिजिटल स्वाक्षरी असलेले लायसन्स पाठवावे.
""".trim();

    final encoded = Uri.encodeComponent(msg);
    final url = Uri.parse("whatsapp://send?phone=91$supportPhone&text=$encoded");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        await launchUrl(Uri.parse("https://wa.me/91$supportPhone?text=$encoded"), mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("WhatsApp उघडता आले नाही. की कॉपी करून पाठवा.")),
        );
      }
    }
  }

  void _showRequestQrDialog() {
    final reqString = _subMgr.generateActivationRequest(planId: _selectedPlan.id);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Color(0xFF1E88E5)),
            SizedBox(width: 8),
            Text("CSC Studio स्कॅनर", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "शबाना CSC Studio ॲप मधील टूल उघडून खालील QR कोड स्कॅन करा किंवा कोड कॉपी करा:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                data: reqString,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "योजना: ${_selectedPlan.name} (₹${_selectedPlan.price})",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            SelectableText(
              _subMgr.hardwareId,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text("कोड कॉपी करा"),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: reqString));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Activation Request कोड कॉपी झाला")),
              );
            },
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("बंद करा"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPro = _subMgr.isPro;
    final remainingStr = _subMgr.getRemainingTimeStr();
    final upiUri = "upi://pay?pa=$upiId&pn=${Uri.encodeComponent(payeeName)}&am=${_selectedPlan.price}&cu=INR";

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle & Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E88E5).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.workspace_premium, color: Color(0xFF1E88E5), size: 24),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "सबस्क्रिप्शन व परवाना",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isPro ? "PRO सक्रिय ($remainingStr)" : "स्थिती: $remainingStr",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isPro ? Colors.green.shade700 : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (!widget.isLockout)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
            const Divider(height: 24),

            // Step 1: Select Plan
            const Text(
              "१. सबस्क्रिप्शन योजना निवडा",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: SubscriptionManager.availablePlans.map((plan) {
                final isSelected = plan.id == _selectedPlan.id;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPlan = plan),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1E88E5).withValues(alpha: 0.1) : theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF1E88E5) : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          if (plan.badge.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF1E88E5) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                plan.badge,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          Text(
                            plan.nameMr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "₹${plan.price}",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFF1E88E5) : Colors.black87,
                            ),
                          ),
                          Text(
                            plan.durationText,
                            style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // Hardware ID Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Device Hardware ID (कायमस्वरूपी)",
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        Text(
                          _subMgr.hardwareId,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20, color: Color(0xFF1E88E5)),
                    onPressed: _copyHwid,
                    tooltip: "HWID कॉपी करा",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Step 2: Pay & Scan Request
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.qr_code, size: 18),
                    label: const Text("CSC Activation QR"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _showRequestQrDialog,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send, size: 18, color: Colors.white),
                    label: const Text("WhatsApp वर पाठवा", style: TextStyle(color: Colors.white, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _shareOnWhatsApp,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Optional UPI Payment Accordion
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                "UPI द्वारे ₹${_selectedPlan.price} भरा (स्कॅन करा)",
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                "$upiId ($payeeName)",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: QrImageView(
                      data: upiUri,
                      version: QrVersions.auto,
                      size: 160.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Step 3: Enter Activation Key
            const Text(
              "३. प्राप्त झालेली डिजिटल लायसन्स की प्रविष्ट करा",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _licenseInputController,
              maxLines: 2,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: "SHABANA-LIC:... येथे पेस्ट करा",
                hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste),
                  onPressed: _pasteLicenseKey,
                  tooltip: "क्लिपबोर्डवरून पेस्ट करा",
                ),
              ),
            ),

            if (_activationStatus.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _activationStatus,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _isError ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Activate Button
            ElevatedButton.icon(
              onPressed: _isActivating ? null : _activate,
              icon: _isActivating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.verified, color: Colors.white),
              label: Text(
                _isActivating ? "सक्रिय करत आहे..." : "ऑफलाइन परवाना सक्रिय करा",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
