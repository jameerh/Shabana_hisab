import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import '../../../data/database/database.dart'; // Drift generated Database and Transaction classes
import '../../../core/localization/localization_service.dart';

class TransactionTile extends StatelessWidget {
  final Transaction tx;
  final bool isSelected;
  final bool isSelectionMode;
  final Future<bool> Function(DismissDirection) onConfirmDismiss;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final Function(String) onImageTap;

  const TransactionTile({
    Key? key,
    required this.tx,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onConfirmDismiss,
    required this.onLongPress,
    required this.onTap,
    required this.onImageTap,
  }) : super(key: key);

  Color _getTypeColor(String type) {
    if (type == 'Income') return Colors.green;
    if (type == 'Expense') return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor(tx.type);

    return Dismissible(
      key: Key('tx_${tx.id}'),
      background: Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.share, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: onConfirmDismiss,
      child: ListTile(
        selected: isSelected,
        selectedTileColor: Colors.teal.withOpacity(0.1),
        leading: isSelected
            ? const CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(Icons.check, color: Colors.white))
            : CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(
                  tx.type == 'Income'
                      ? Icons.arrow_downward
                      : (tx.type == 'Expense'
                          ? Icons.arrow_upward
                          : Icons.account_balance_wallet),
                  color: color,
                ),
              ),
        title: Text(tx.partyName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Text('₹${tx.amount}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            if (tx.categoryName != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  LocalizationService.getCategoryName(context, tx.categoryName!),
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ),
            if (tx.images != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onImageTap(jsonDecode(tx.images!).first),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(
                    File(jsonDecode(tx.images!).first),
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image, size: 24, color: Colors.grey),
                  ),
                ),
              ),
            ],
            if (tx.metadata != null) ...[
              Builder(builder: (context) {
                try {
                  final meta = jsonDecode(tx.metadata!);
                  if (meta['vehicleKm'] != null) {
                    return Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('⛽ ${meta['vehicleKm']} KM',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold)),
                    );
                  }
                } catch (_) {}
                return const SizedBox();
              }),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${tx.timestamp.day}/${tx.timestamp.month}',
                style: const TextStyle(fontSize: 12)),
            Text(
                '${tx.timestamp.hour}:${tx.timestamp.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        onLongPress: onLongPress,
        onTap: onTap,
      ),
    );
  }
}
