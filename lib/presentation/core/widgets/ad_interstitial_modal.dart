import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/services/promotion_config_service.dart';

/// Professional Interstitial Micro-Ad Modal
/// Displays configured promotional ad item(s) for a configurable duration (e.g. 500ms to 1s)
/// without irritating the user, then smoothly dismisses.
class AdInterstitialModal extends StatefulWidget {
  final Duration? duration;
  final AdItem? adItem;
  final VoidCallback? onDismissed;

  const AdInterstitialModal({
    super.key,
    this.duration,
    this.adItem,
    this.onDismissed,
  });

  /// Shows the brief interstitial modal if enabled in PromotionConfigService
  static Future<void> show(
    BuildContext context, {
    Duration? duration,
    AdItem? adItem,
  }) async {
    final promoService = PromotionConfigService.instance;
    await promoService.init();

    // Check if share ads are enabled
    if (!promoService.shareEnabled) return;

    // Pick ad item from config if not provided
    final item = adItem ??
        (promoService.shareAds.isNotEmpty
            ? promoService.shareAds.first
            : const AdItem(
                id: 'default_share',
                imagePath: 'assets/shabana_multi_service_ad.png',
                title: 'Shabana Multi Service',
                subtitle: 'विश्वसनीय आर्थिक आणि डिजिटल सेवा केंद्र',
                durationMs: 800,
              ));

    final effectiveDuration = duration ?? Duration(milliseconds: promoService.shareDurationMs);
    if (!context.mounted) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return AdInterstitialModal(
          duration: effectiveDuration,
          adItem: item,
        );
      },
    );
  }

  @override
  State<AdInterstitialModal> createState() => _AdInterstitialModalState();
}

class _AdInterstitialModalState extends State<AdInterstitialModal> with SingleTickerProviderStateMixin {
  Timer? _dismissTimer;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();

    final time = widget.duration ?? Duration(milliseconds: widget.adItem?.durationMs ?? 800);
    _dismissTimer = Timer(time, () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        widget.onDismissed?.call();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Widget _buildAdImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 64, color: Colors.grey),
      );
    } else if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.campaign, size: 64, color: Color(0xFFD4AF37)),
      );
    } else {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.contain);
      }
      return Image.asset('assets/shabana_multi_service_ad.png', fit: BoxFit.contain);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.adItem ??
        const AdItem(
          id: 'default',
          imagePath: 'assets/shabana_multi_service_ad.png',
          title: 'Shabana Multi Service',
          subtitle: 'विश्वसनीय आर्थिक आणि डिजिटल सेवा केंद्र',
        );

    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF161C2E),
                      Color(0xFF0F121C),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFD4AF37),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 170,
                      height: 170,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _buildAdImage(ad.imagePath),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      ad.title.isNotEmpty ? ad.title : 'Shabana Multi Service',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFDF73),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ad.subtitle.isNotEmpty
                          ? ad.subtitle
                          : 'विश्वसनीय आर्थिक आणि डिजिटल सेवा केंद्र',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFFD4AF37).withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'लोड होत आहे...',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
