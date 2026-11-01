import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Professional Review & Google Rating Prompt Manager
/// Handles Monday recurring prompts, external rating navigations,
/// and map viewing.
class ReviewPromptService {
  static const String reviewUrl = "https://g.page/r/CalrZ9X7G7UOEBM/review";
  static const String mapUrl = "https://share.google/gz5PgcFdb5YTIheVz";

  static const String _keyAlreadyReviewed = "SHABANA_ALREADY_REVIEWED";
  static const String _keyLastPromptDate = "SHABANA_LAST_PROMPT_DATE";

  /// Checks if today is Monday and if review prompt should be displayed
  static Future<bool> shouldShowMondayPrompt() async {
    final prefs = await SharedPreferences.getInstance();

    final alreadyReviewed = prefs.getBool(_keyAlreadyReviewed) ?? false;
    if (alreadyReviewed) return false;

    final now = DateTime.now();
    // Monday is weekday 1 in Dart DateTime
    if (now.weekday != DateTime.monday) return false;

    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final lastPromptDate = prefs.getString(_keyLastPromptDate) ?? '';

    // Only prompt once per Monday
    if (lastPromptDate == todayStr) return false;

    return true;
  }

  /// Records that the prompt was shown today
  static Future<void> markPromptShownToday() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    await prefs.setString(_keyLastPromptDate, todayStr);
  }

  /// Marks that the user has already shared/reviewed
  static Future<void> markAlreadyReviewed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAlreadyReviewed, true);
  }

  /// Opens Google 5-Star Review Page
  static Future<void> openReviewPage() async {
    final uri = Uri.parse(reviewUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(uri);
    }
  }

  /// Opens Google Maps location
  static Future<void> openMapLocation() async {
    final uri = Uri.parse(mapUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(uri);
    }
  }

  /// Shows the Monday 5-Star Review Modal dialog
  static Future<void> showReviewModal(BuildContext context) async {
    await markPromptShownToday();

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const _ReviewDialog(),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog();

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  bool _hasAttemptedReview = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Image/Badge
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0D1B2A),
                border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/shabana_multi_service_ad.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.star, color: Colors.amber, size: 40),
              ),
            ),
            const SizedBox(height: 14),

            // 5-Star Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 28),
                ),
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              "आपला अभिप्राय महत्त्वाचा आहे!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              "शबाना मल्टी सर्व्हिस आणि शबाना हिसाब ॲप आवडले असल्यास गुगलवर 5-स्टार रेटिंग देऊन आम्हाला पाठिंबा द्या.",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Primary 5-Star Review Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              icon: const Icon(Icons.rate_review, size: 18),
              label: const Text(
                "⭐ गुगलवर 5-स्टार रेटिंग द्या",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                setState(() {
                  _hasAttemptedReview = true;
                });
                await ReviewPromptService.openReviewPage();
              },
            ),

            const SizedBox(height: 10),

            // View on Google Maps Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                minimumSize: const Size.fromHeight(42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              icon: const Icon(Icons.location_on, color: Colors.redAccent, size: 18),
              label: const Text(
                "गुगल मॅपवर केंद्र पहा (Show on Map)",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              onPressed: () async {
                await ReviewPromptService.openMapLocation();
              },
            ),

            // "Already Shared / Reviewed" option (appears after user tries to navigate or available directly)
            if (_hasAttemptedReview) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "धन्यवाद! जर आपण रेटिंग दिले असेल तर खाली क्लिक करा:",
                        style: TextStyle(fontSize: 11, color: Color(0xFF15803D)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF16A34A),
                ),
                onPressed: () async {
                  await ReviewPromptService.markAlreadyReviewed();
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(
                  "मी आधीच रिव्ह्यू दिला आहे (Already Shared / Rated)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _hasAttemptedReview = true;
                  });
                },
                child: const Text(
                  "मी आधीच शेअर/रेटिंग दिले आहे",
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
