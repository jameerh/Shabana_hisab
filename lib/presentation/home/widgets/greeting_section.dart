import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/localization/bilingual_text.dart';
import '../../../main.dart';

class GreetingSection extends StatelessWidget {
  final String profileName;
  final VoidCallback? onAvatarPressed;
  final String? netBalance;
  final String? todayActivity;

  const GreetingSection({
    super.key,
    required this.profileName,
    this.onAvatarPressed,
    this.netBalance,
    this.todayActivity,
  });

  String _getTimeGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return 'Good Morning';

    if (hour < 12) return l10n.goodMorning;
    if (hour < 17) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: IconButton(
              icon: const Icon(Icons.menu, size: 28, color: Colors.black87),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          const SizedBox(width: 8),
          const Padding(
            padding: EdgeInsets.only(top: 14.0),
            child: Icon(Icons.waving_hand, color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  profileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (netBalance != null) ...[
                  const SizedBox(height: 12),
                  BilingualText(
                    english: 'Net Balance',
                    marathi: 'एकूण शिल्लक',
                    languageController: languageController,
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    netBalance!,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: (netBalance!.startsWith('-') || netBalance!.contains('-')) ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                  ),
                  if (todayActivity != null)
                    Text(
                      todayActivity!,
                      style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                    ),
                ]
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: GestureDetector(
              onTap: onAvatarPressed,
              child: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.person, color: Colors.green),
              ),
            ),
          )
        ],
      ),
    );
  }
}
