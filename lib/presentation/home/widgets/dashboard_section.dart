import 'package:flutter/material.dart';
import '../models/dashboard_card.dart';
import '../services/dashboard_registry.dart';

class DashboardSection extends StatefulWidget {
  const DashboardSection({Key? key}) : super(key: key);

  @override
  _DashboardSectionState createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection> {
  List<DashboardCard> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await DashboardRegistry().getScoredCards();
    setState(() {
      _cards = cards;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_cards.isEmpty) {
      return const SizedBox.shrink(); // Empty state
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The top scored card gets a prominent full-width display
          _buildHighlightCard(_cards.first),
          const SizedBox(height: 16),
          // Remaining cards go into a horizontal scroll
          if (_cards.length > 1)
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _cards.length - 1,
                itemBuilder: (context, index) {
                  return _buildSmallCard(_cards[index + 1]);
                },
              ),
            )
        ],
      ),
    );
  }

  Widget _buildHighlightCard(DashboardCard card) {
    return Card(
      color: card.color?.withValues(alpha: 0.1) ?? Colors.blue.withValues(alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: card.onAction,
        onLongPress: () {
          if (card.moreActions != null && card.moreActions!.isNotEmpty) {
             final RenderBox button = context.findRenderObject() as RenderBox;
             final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
             final RelativeRect position = RelativeRect.fromRect(
               Rect.fromPoints(
                 button.localToGlobal(Offset.zero, ancestor: overlay),
                 button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
               ),
               Offset.zero & overlay.size,
             );
             showMenu<String>(
               context: context,
               position: position,
               items: card.moreActions!,
             ).then((value) {
               if (value != null && card.onMoreActionSelected != null) {
                 card.onMoreActionSelected!(value);
               }
             });
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(card.icon ?? Icons.info, size: 40, color: card.color ?? Colors.blue),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(card.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        if (card.subtitle != null)
                          Text(card.subtitle!, style: TextStyle(color: Colors.grey[700])),
                      ],
                    ),
                  ),
                ],
              ),
              if (card.actionLabel != null || card.secondaryActionLabel != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (card.actionLabel != null)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: card.color ?? Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: card.onAction,
                        child: Text(card.actionLabel!),
                      ),
                    if (card.secondaryActionLabel != null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: card.color ?? Colors.blue,
                          side: BorderSide(color: card.color ?? Colors.blue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: card.onSecondaryAction,
                        child: Text(card.secondaryActionLabel!),
                      ),
                    ],
                    if (card.tertiaryActionLabel != null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: card.onTertiaryAction,
                        child: Text(card.tertiaryActionLabel!),
                      ),
                    ],
                    if (card.moreActions != null && card.moreActions!.isNotEmpty) ...[
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: card.onMoreActionSelected,
                        itemBuilder: (context) => card.moreActions!,
                      ),
                    ]
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallCard(DashboardCard card) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: card.onAction,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(card.icon ?? Icons.info, color: card.color ?? Colors.blue),
              const Spacer(),
              Text(
                card.title, 
                style: const TextStyle(fontWeight: FontWeight.bold), 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis
              ),
              if (card.subtitle != null)
                 Text(
                   card.subtitle!, 
                   style: TextStyle(color: Colors.grey[600], fontSize: 12), 
                   maxLines: 1, 
                   overflow: TextOverflow.ellipsis
                 ),
            ],
          ),
        ),
      ),
    );
  }
}
