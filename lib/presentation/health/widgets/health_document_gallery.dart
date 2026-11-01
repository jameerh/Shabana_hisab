import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/health_models.dart';

class HealthDocumentGallery extends StatelessWidget {
  final List<HealthEvent> eventsWithEvidence;
  final Map<int, HealthPatient> patientMap;
  final VoidCallback onRefresh;

  const HealthDocumentGallery({
    super.key,
    required this.eventsWithEvidence,
    required this.patientMap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // Flatten evidence items with their associated event
    final List<MapEntry<HealthEvent, HealthEvidence>> items = [];
    for (final ev in eventsWithEvidence) {
      for (final doc in ev.evidence) {
        items.add(MapEntry(ev, doc));
      }
    }

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No Documents or Proof Attached',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Photos and PDFs attached via Quick Capture or Detailed Entry will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final entry = items[index];
        final event = entry.key;
        final doc = entry.value;
        final pName = patientMap[event.patientId]?.name ?? 'Patient';

        return _buildGalleryTile(context, event, doc, pName);
      },
    );
  }

  Widget _buildGalleryTile(
    BuildContext context,
    HealthEvent event,
    HealthEvidence doc,
    String patientName,
  ) {
    final file = File(doc.filePath);
    final exists = file.existsSync();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openPreviewModal(context, doc, event, patientName),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail container
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (doc.isPdf)
                    Container(
                      color: Colors.red.shade50,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                            SizedBox(height: 4),
                            Text('PDF Document', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    )
                  else if (exists)
                    Image.file(
                      file,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  else
                    _buildPlaceholder(),

                  // Patient chip overlay
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        patientName,
                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // Share button overlay
                  Positioned(
                    top: 2,
                    right: 2,
                    child: IconButton(
                      icon: const Icon(Icons.share, size: 16, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.4),
                        padding: const EdgeInsets.all(4),
                        minimumSize: const Size(26, 26),
                      ),
                      onPressed: () {
                        if (exists) {
                          Share.shareXFiles([XFile(doc.filePath)], text: doc.displayName);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Metadata Below Thumbnail
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy').format(event.eventDate),
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                      Text(
                        event.eventType.emoji,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(Icons.image, size: 36, color: Colors.grey),
      ),
    );
  }

  void _openPreviewModal(
    BuildContext context,
    HealthEvidence doc,
    HealthEvent event,
    String patientName,
  ) {
    final file = File(doc.filePath);
    final exists = file.existsSync();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(doc.isPdf ? Icons.picture_as_pdf : Icons.image, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('$patientName • ${DateFormat('dd MMM yyyy').format(event.eventDate)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Image Preview / PDF Button
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: doc.isPdf
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.red, size: 60),
                          const SizedBox(height: 12),
                          const Text('PDF Document Attached', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                            icon: const Icon(Icons.share),
                            label: const Text('Share / Open PDF'),
                            onPressed: () {
                              if (exists) {
                                Share.shareXFiles([XFile(doc.filePath)], text: doc.displayName);
                              }
                            },
                          ),
                        ],
                      ),
                    )
                  : exists
                      ? InteractiveViewer(
                          child: Image.file(file, fit: BoxFit.contain),
                        )
                      : const Center(child: Text('File not found')),
            ),

            // Share Actions Bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Share Document'),
                    onPressed: () {
                      if (exists) {
                        Share.shareXFiles([XFile(doc.filePath)], text: doc.displayName);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
