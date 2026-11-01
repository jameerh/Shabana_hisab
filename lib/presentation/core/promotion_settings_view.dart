import 'package:flutter/material.dart';
import '../../core/services/promotion_config_service.dart';
import 'widgets/ad_interstitial_modal.dart';

/// Full GUI Screen to configure:
/// 1. Timings (e.g. 500ms, 800ms, 1000ms, etc.)
/// 2. Add, edit, or remove advertisement images
/// 3. Toggle where they appear (Startup Splash vs Share buttons vs Custom triggers)
/// 4. Test preview immediately
class PromotionSettingsView extends StatefulWidget {
  const PromotionSettingsView({super.key});

  @override
  State<PromotionSettingsView> createState() => _PromotionSettingsViewState();
}

class _PromotionSettingsViewState extends State<PromotionSettingsView> {
  final _service = PromotionConfigService.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.init();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddEditDialog({AdItem? existingItem, required bool isStartup, int? editIndex}) {
    final titleController = TextEditingController(text: existingItem?.title ?? '');
    final subtitleController = TextEditingController(text: existingItem?.subtitle ?? '');
    final pathController = TextEditingController(
      text: existingItem?.imagePath ?? 'assets/shabana_multi_service_ad.png',
    );
    int durationMs = existingItem?.durationMs ?? (isStartup ? 500 : 800);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E2230),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
              ),
              title: Text(
                existingItem == null ? 'नवीन जाहिरात / इमेज जोडा' : 'इमेज संपादित करा',
                style: const TextStyle(color: Color(0xFFFFDF73), fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: pathController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'इमेज पाथ (Asset किंवा URL)',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: 'assets/shabana_multi_service_ad.png',
                        hintStyle: TextStyle(color: Colors.white30),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('Gold Emblem', style: TextStyle(fontSize: 11)),
                          onPressed: () => setDlgState(() {
                            pathController.text = 'assets/shabana_multi_service_ad.png';
                          }),
                        ),
                        ActionChip(
                          label: const Text('Final Fix Logo', style: TextStyle(fontSize: 11)),
                          onPressed: () => setDlgState(() {
                            pathController.text = 'assets/shabana_final_fix_logo.png';
                          }),
                        ),
                        ActionChip(
                          label: const Text('Hisab Logo', style: TextStyle(fontSize: 11)),
                          onPressed: () => setDlgState(() {
                            pathController.text = 'assets/shabana Hisab App.png';
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'शीर्षक (Title)',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subtitleController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'उपशीर्षक (Subtitle)',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'प्रदर्शनाचा वेळ (Duration):',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${durationMs}ms (${(durationMs / 1000).toStringAsFixed(1)}s)',
                            style: const TextStyle(
                              color: Color(0xFFFFDF73),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: durationMs.toDouble(),
                      min: 300,
                      max: 3000,
                      divisions: 27,
                      activeColor: const Color(0xFFD4AF37),
                      inactiveColor: Colors.white24,
                      onChanged: (val) {
                        setDlgState(() {
                          durationMs = val.round();
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('रद्द करा', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    final item = AdItem(
                      id: existingItem?.id ?? 'ad_${DateTime.now().millisecondsSinceEpoch}',
                      imagePath: pathController.text.trim(),
                      title: titleController.text.trim(),
                      subtitle: subtitleController.text.trim(),
                      durationMs: durationMs,
                    );

                    if (isStartup) {
                      if (editIndex != null) {
                        _service.updateStartupItemDuration(editIndex, durationMs);
                      } else {
                        await _service.addStartupAd(item);
                      }
                    } else {
                      if (editIndex != null) {
                        _service.updateShareItemDuration(editIndex, durationMs);
                      } else {
                        await _service.addShareAd(item);
                      }
                    }

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  child: const Text('सेव्ह करा', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF10131E),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF10131E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161C2C),
        title: const Text(
          'जाहिरात व इमेज कॉन्फिगरेशन',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore, color: Colors.amberAccent),
            tooltip: 'डिफॉल्ट रिसेट करा (Reset Defaults)',
            onPressed: () async {
              await _service.resetToDefaults();
              if (!context.mounted) return;
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('डिफॉल्ट सेटिंग्ज यशस्वीरित्या रिसेट केल्या!')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: App Launch Splash Sequences
          _buildSectionCard(
            title: '१. ॲप सुरू होताना (App Launch / Splash)',
            subtitle: 'सुरू होताना दिसणाऱ्या इमेजेस आणि प्रत्येकाचा वेळ (उदा. 500ms / 1 सेकंद)',
            icon: Icons.rocket_launch,
            trailing: Switch(
              value: _service.startupEnabled,
              activeThumbColor: const Color(0xFFD4AF37),
              onChanged: (val) async {
                await _service.setStartupEnabled(val);
                setState(() {});
              },
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_service.startupEnabled)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'ॲप सुरू होताना जाहिराती बंद आहेत.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  )
                else ...[
                  ..._service.startupAds.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final ad = entry.value;
                    return _buildAdItemTile(
                      item: ad,
                      index: idx,
                      isStartup: true,
                      onDelete: () async {
                        await _service.removeStartupAd(idx);
                        setState(() {});
                      },
                      onEdit: () {
                        _showAddEditDialog(
                          existingItem: ad,
                          isStartup: true,
                          editIndex: idx,
                        );
                      },
                    );
                  }),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFDF73),
                      side: const BorderSide(color: Color(0xFFD4AF37)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('नवीन इमेज जोडा (Add Splash Image)'),
                    onPressed: () {
                      _showAddEditDialog(isStartup: true);
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 2: Share Button Micro-Ad
          _buildSectionCard(
            title: '२. शेअर बटनावर जाहिरात (On Share Button)',
            subtitle: 'शेअर करण्यापूर्वी दाखवली जाणारी इमेज आणि वेळ (500ms - 1s)',
            icon: Icons.share,
            trailing: Switch(
              value: _service.shareEnabled,
              activeThumbColor: const Color(0xFFD4AF37),
              onChanged: (val) async {
                await _service.setShareEnabled(val);
                setState(() {});
              },
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_service.shareEnabled)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'शेअर बटनावरील जाहिरात बंद आहे.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'प्रदर्शनाचा वेळ (Duration):',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_service.shareDurationMs}ms (${(_service.shareDurationMs / 1000).toStringAsFixed(1)}s)',
                          style: const TextStyle(
                            color: Color(0xFFFFDF73),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _service.shareDurationMs.toDouble().clamp(300, 3000),
                    min: 300,
                    max: 3000,
                    divisions: 27,
                    activeColor: const Color(0xFFD4AF37),
                    inactiveColor: Colors.white24,
                    onChanged: (val) async {
                      await _service.setShareDurationMs(val.round());
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                  ..._service.shareAds.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final ad = entry.value;
                    return _buildAdItemTile(
                      item: ad,
                      index: idx,
                      isStartup: false,
                      onDelete: () async {
                        await _service.removeShareAd(idx);
                        setState(() {});
                      },
                      onEdit: () {
                        _showAddEditDialog(
                          existingItem: ad,
                          isStartup: false,
                          editIndex: idx,
                        );
                      },
                    );
                  }),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFFDF73),
                          side: const BorderSide(color: Color(0xFFD4AF37)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('इमेज जोडा'),
                        onPressed: () {
                          _showAddEditDialog(isStartup: false);
                        },
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('आता टेस्ट करा (Preview)'),
                        onPressed: () {
                          AdInterstitialModal.show(context);
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget trailing,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B29),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFD4AF37), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
          const Divider(color: Colors.white12, height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildAdItemTile({
    required AdItem item,
    required int index,
    required bool isStartup,
    required VoidCallback onDelete,
    required VoidCallback onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2235),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
            ),
            child: ClipOval(
              child: Image.asset(
                item.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.amber),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.isNotEmpty ? item.title : item.imagePath,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'वेळ: ${item.durationMs}ms | ${item.subtitle}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: Colors.blueAccent),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
