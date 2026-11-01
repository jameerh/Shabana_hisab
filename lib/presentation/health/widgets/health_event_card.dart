import 'dart:io';
import 'package:flutter/material.dart';
import '../../../data/models/health_models.dart';

class HealthEventCard extends StatelessWidget {
  final HealthEvent event;
  final String patientName;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const HealthEventCard({
    super.key,
    required this.event,
    required this.patientName,
    required this.onTap,
    required this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasFiles = event.evidence.isNotEmpty;
    final firstEvidence = hasFiles ? event.evidence.first : null;

    // Badges
    final evidenceBadgeText = event.hasEvidence ? '🟢 Document Attached' : '🟡 Manual Entry';
    final evidenceBadgeColor = event.hasEvidence ? Colors.green.shade50 : Colors.amber.shade50;
    final evidenceBadgeTextColor = event.hasEvidence ? Colors.green.shade900 : Colors.amber.shade900;

    final isCompleted = event.completionStatus == HealthCompletionStatus.completed;
    final isPartiallyCompleted = event.completionStatus == HealthCompletionStatus.partiallyCompleted;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.15)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Patient Badge + Event Date & Time + Delete
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Patient Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Text(
                          patientName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Date
                      Text(
                        event.formattedDate,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '• ${event.eventTime}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                    padding: EdgeInsets.zero,
                    onSelected: (val) {
                      if (val == 'delete') onDelete();
                      if (val == 'view') onTap();
                      if (val == 'edit') {
                        if (onEdit != null) {
                          onEdit!();
                        } else {
                          onTap();
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16, color: Colors.teal),
                            SizedBox(width: 8),
                            Text('Edit Record'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Record', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: Event Type Icon + Purpose/Reading
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getEventColor(event.eventType).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        event.eventType.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Main Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTitleText(),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 3),
                        _buildSubtitleContent(),
                      ],
                    ),
                  ),

                  // Thumbnail if attached
                  if (hasFiles) ...[
                    const SizedBox(width: 8),
                    _buildAttachmentThumbnail(firstEvidence!),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Row 3: Badges (Evidence Status + Completion Status)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Evidence Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: evidenceBadgeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          evidenceBadgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: evidenceBadgeTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Completion Badge (Attach first, fill later)
                      if (event.eventType == HealthEventType.prescription || event.eventType == HealthEventType.labReport)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.blue.shade50
                                : (isPartiallyCompleted ? Colors.orange.shade50 : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isCompleted ? '✓ Details complete' : '◯ Details incomplete',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isCompleted ? Colors.blue.shade800 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),

                  if (hasFiles)
                    Text(
                      firstEvidence!.displayName,
                      style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitleText() {
    switch (event.eventType) {
      case HealthEventType.prescription:
        return 'Prescription • ${event.purpose}';
      case HealthEventType.labReport:
        return '${event.purpose} Report';
      case HealthEventType.sugar:
        final s = event.sugarData;
        return s != null ? '${s.value.toStringAsFixed(0)} ${s.unit}' : event.purpose;
      case HealthEventType.bloodPressure:
        final b = event.bpData;
        return b != null ? '${b.systolic} / ${b.diastolic} mmHg' : event.purpose;
      case HealthEventType.weight:
      case HealthEventType.temperature:
      case HealthEventType.spo2:
      case HealthEventType.hospitalVisit:
      case HealthEventType.healthNote:
        return event.purpose;
    }
  }

  Widget _buildSubtitleContent() {
    switch (event.eventType) {
      case HealthEventType.sugar:
        final s = event.sugarData;
        final ctxStr = s != null ? s.context.label : '';
        return Text(
          'Blood Sugar ($ctxStr)',
          style: TextStyle(fontSize: 12, color: Colors.teal.shade800, fontWeight: FontWeight.w500),
        );
      case HealthEventType.bloodPressure:
        final b = event.bpData;
        final pulseStr = b?.pulse != null ? 'Pulse: ${b!.pulse} bpm' : 'Blood Pressure';
        return Text(
          pulseStr,
          style: TextStyle(fontSize: 12, color: Colors.red.shade800, fontWeight: FontWeight.w500),
        );
      case HealthEventType.labReport:
        final l = event.labReportData;
        final res = l?.resultSummary;
        return Text(
          res != null && res.isNotEmpty ? 'Result: $res' : 'Tap to view report or add values',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        );
      case HealthEventType.prescription:
        final rx = event.prescriptionData;
        final medCount = rx?.medicines.length ?? 0;
        return Text(
          medCount > 0 ? '$medCount medicines listed' : 'Tap to view photo or add medicines',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        );
      default:
        return Text(
          event.notes?.isNotEmpty == true ? event.notes! : event.eventType.englishLabel,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
    }
  }

  Widget _buildAttachmentThumbnail(HealthEvidence ev) {
    final file = File(ev.filePath);
    final exists = file.existsSync();

    if (ev.isPdf) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: const Center(
          child: Icon(Icons.picture_as_pdf, color: Colors.red, size: 22),
        ),
      );
    }

    if (exists) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          file,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.image, color: Colors.grey, size: 20),
    );
  }

  Color _getEventColor(HealthEventType type) {
    switch (type) {
      case HealthEventType.prescription:
        return Colors.purple;
      case HealthEventType.labReport:
        return Colors.amber;
      case HealthEventType.sugar:
        return Colors.teal;
      case HealthEventType.bloodPressure:
        return Colors.red;
      case HealthEventType.hospitalVisit:
        return Colors.indigo;
      case HealthEventType.healthNote:
        return Colors.blue;
      case HealthEventType.weight:
        return Colors.green;
      case HealthEventType.temperature:
        return Colors.deepOrange;
      case HealthEventType.spo2:
        return Colors.cyan;
    }
  }
}
