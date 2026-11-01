import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/services/promotion_config_service.dart';

/// Fullscreen Dynamic Sequential Splash Screen:
/// - Supports configurable list of AdItems from PromotionConfigService
/// - Each image runs for its configured millisecond duration (e.g. 500ms, 1000ms)
/// - Automatically transitions through all configured images
/// - Gracefully falls back if disabled or empty
class SequentialSplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SequentialSplashScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<SequentialSplashScreen> createState() => _SequentialSplashScreenState();
}

class _SequentialSplashScreenState extends State<SequentialSplashScreen> {
  int _currentIndex = 0;
  Timer? _stepTimer;
  List<AdItem> _ads = [];

  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  Future<void> _startSequence() async {
    final promoService = PromotionConfigService.instance;
    await promoService.init();

    if (!promoService.startupEnabled || promoService.startupAds.isEmpty) {
      widget.onComplete();
      return;
    }

    if (mounted) {
      setState(() {
        _ads = promoService.startupAds;
        _currentIndex = 0;
      });
      _scheduleNextStep();
    }
  }

  void _scheduleNextStep() {
    if (_currentIndex >= _ads.length) {
      widget.onComplete();
      return;
    }

    final currentAd = _ads[_currentIndex];
    final duration = Duration(milliseconds: currentAd.durationMs.clamp(200, 5000));

    _stepTimer?.cancel();
    _stepTimer = Timer(duration, () {
      if (!mounted) return;
      if (_currentIndex + 1 < _ads.length) {
        setState(() {
          _currentIndex++;
        });
        _scheduleNextStep();
      } else {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80, color: Colors.grey),
      );
    } else if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 80, color: Colors.amber),
      );
    } else {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.contain);
      }
      return Image.asset('assets/shabana Hisab App.png', fit: BoxFit.contain);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ads.isEmpty || _currentIndex >= _ads.length) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    final currentAd = _ads[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: Container(
          key: ValueKey('splash_item_${currentAd.id}_$_currentIndex'),
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.1,
              colors: [
                Color(0xFF1E2638),
                Color(0xFF0A0D14),
                Colors.black,
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 250,
                        height: 250,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                              blurRadius: 36,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _buildImage(currentAd.imagePath),
                        ),
                      ),
                      if (currentAd.title.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          currentAd.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFFFDF73),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                      if (currentAd.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          currentAd.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_ads.length, (idx) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: idx == _currentIndex ? 22 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: idx == _currentIndex
                              ? const Color(0xFFD4AF37)
                              : Colors.white.withValues(alpha: 0.25),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
