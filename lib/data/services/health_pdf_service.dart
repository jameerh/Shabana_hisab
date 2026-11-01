import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/health_models.dart';

class HealthPdfService {
  /// Generates a comprehensive clinical Doctor Report matching the exact 8-part hierarchy
  static Future<File> generateDoctorReportPdf({
    required HealthPatient patient,
    required List<HealthEvent> events,
    required DateTime startDate,
    required DateTime endDate,
    String? clinicOrDoctorName,
  }) async {
    final pdf = pw.Document();

    final regularFont = await PdfGoogleFonts.notoSansDevanagariRegular();
    final boldFont = await PdfGoogleFonts.notoSansDevanagariBold();

    final startStr = DateFormat('dd MMM yyyy').format(startDate);
    final endStr = DateFormat('dd MMM yyyy').format(endDate);
    final generatedAtStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    // Separate records by category
    final prescriptions = events.where((e) => e.eventType == HealthEventType.prescription).toList();
    final labReports = events.where((e) => e.eventType == HealthEventType.labReport).toList();
    final sugars = events.where((e) => e.eventType == HealthEventType.sugar).toList();
    final bps = events.where((e) => e.eventType == HealthEventType.bloodPressure).toList();
    final others = events.where((e) =>
        e.eventType != HealthEventType.prescription &&
        e.eventType != HealthEventType.labReport &&
        e.eventType != HealthEventType.sugar &&
        e.eventType != HealthEventType.bloodPressure).toList();

    // Flatten all attached evidence
    final allEvidence = <HealthEvidence>[];
    for (final e in events) {
      allEvidence.addAll(e.evidence);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
        ),
        header: (context) => _buildHeader(
          patient: patient,
          startStr: startStr,
          endStr: endStr,
          boldFont: boldFont,
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 12),

          // 01 PATIENT INFORMATION
          _buildSectionTitle('01 PATIENT INFORMATION', boldFont),
          _buildPatientInfoCard(patient, boldFont),
          pw.SizedBox(height: 16),

          // 02 PERIOD & HEALTH SUMMARY
          _buildSectionTitle('02 PERIOD & HEALTH SUMMARY', boldFont),
          _buildSummaryGrid(
            startStr: startStr,
            endStr: endStr,
            totalEvents: events.length,
            rxCount: prescriptions.length,
            labCount: labReports.length,
            sugarCount: sugars.length,
            bpCount: bps.length,
            boldFont: boldFont,
          ),
          pw.SizedBox(height: 16),

          // 03 RECENT / IMPORTANT EVENTS
          _buildSectionTitle('03 RECENT / IMPORTANT EVENTS', boldFont),
          _buildRecentEvents(events.take(5).toList(), boldFont),
          pw.SizedBox(height: 16),

          // 04 PRESCRIPTIONS
          _buildSectionTitle('04 PRESCRIPTIONS', boldFont),
          if (prescriptions.isEmpty)
            _buildEmptyNotice('No prescriptions recorded in this period.')
          else
            ...prescriptions.map((rx) => _buildPrescriptionCard(rx, boldFont)),
          pw.SizedBox(height: 16),

          // 05 LABORATORY & DIAGNOSTIC REPORTS
          _buildSectionTitle('05 LABORATORY & DIAGNOSTIC REPORTS', boldFont),
          if (labReports.isEmpty)
            _buildEmptyNotice('No laboratory reports recorded in this period.')
          else
            ...labReports.map((lab) => _buildLabReportCard(lab, boldFont)),
          pw.SizedBox(height: 16),

          // 06 HOME MEASUREMENTS
          _buildSectionTitle('06 HOME MEASUREMENTS (SUGAR & BLOOD PRESSURE)', boldFont),
          if (sugars.isEmpty && bps.isEmpty)
            _buildEmptyNotice('No home sugar or blood pressure readings in this period.')
          else ...[
            if (sugars.isNotEmpty) ...[
              pw.Text('Blood Sugar Readings', style: pw.TextStyle(font: boldFont, fontSize: 11, color: PdfColors.teal800)),
              pw.SizedBox(height: 6),
              _buildSugarTable(sugars, boldFont),
              pw.SizedBox(height: 12),
            ],
            if (bps.isNotEmpty) ...[
              pw.Text('Blood Pressure Readings', style: pw.TextStyle(font: boldFont, fontSize: 11, color: PdfColors.red800)),
              pw.SizedBox(height: 6),
              _buildBpTable(bps, boldFont),
              pw.SizedBox(height: 12),
            ],
          ],
          pw.SizedBox(height: 16),

          // 07 OTHER HEALTH RECORDS
          _buildSectionTitle('07 OTHER HEALTH RECORDS & CLINICAL NOTES', boldFont),
          if (others.isEmpty)
            _buildEmptyNotice('No additional health records recorded.')
          else
            ...others.map((oth) => _buildGenericEventCard(oth, boldFont)),
          pw.SizedBox(height: 16),

          // 08 ORIGINAL EVIDENCE APPENDIX
          _buildSectionTitle('08 ORIGINAL EVIDENCE APPENDIX', boldFont),
          if (allEvidence.isEmpty)
            _buildEmptyNotice('No external files or image evidence attached.')
          else
            _buildEvidenceAppendix(allEvidence, boldFont),
          pw.SizedBox(height: 20),

          // Notice
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Clinical Notice & Provenance Note:', style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.grey800)),
                pw.SizedBox(height: 2),
                pw.Text(
                  'This summary is prepared by Shabana Health from records, prescriptions, and laboratory reports provided by the patient. Manually entered values are marked as "Manual Entry". Records with supporting documents are marked "Document Attached". Medical correctness remains subject to authoritative clinical review by the treating physician.',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final tempDir = await getApplicationDocumentsDirectory();
    final cleanPatient = patient.name.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
    final filePath = '${tempDir.path}/Doctor_Report_${cleanPatient}_${DateFormat('dd-MMM-yyyy').format(DateTime.now())}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return file;
  }

  /// Shares the generated doctor PDF report
  static Future<void> shareDoctorReport({
    required HealthPatient patient,
    required List<HealthEvent> events,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final file = await generateDoctorReportPdf(
      patient: patient,
      events: events,
      startDate: startDate,
      endDate: endDate,
    );
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Doctor Health Summary: ${patient.name} (${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)})',
    );
  }

  // ==========================================
  // PDF COMPONENT BUILDERS
  // ==========================================

  static pw.Widget _buildHeader({
    required HealthPatient patient,
    required String startStr,
    required String endStr,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.teal700, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('SHABANA HEALTH / हेल्थ हिशोब', style: pw.TextStyle(font: boldFont, fontSize: 15, color: PdfColors.teal900)),
              pw.Text('Comprehensive Clinical Patient Health Summary', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Report Period: $startStr - $endStr', style: pw.TextStyle(font: boldFont, fontSize: 8.5, color: PdfColors.grey900)),
              pw.Text('Generated: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Shabana Health Hisaab • Confidential Medical Summary', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title, pw.Font boldFont) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: const pw.BoxDecoration(
        color: PdfColors.teal50,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border(left: pw.BorderSide(color: PdfColors.teal800, width: 3)),
      ),
      child: pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 9.5, color: PdfColors.teal900)),
    );
  }

  static pw.Widget _buildPatientInfoCard(HealthPatient patient, pw.Font boldFont) {
    final ageStr = patient.ageInYears != null ? '${patient.ageInYears} Yrs' : 'Not specified';
    final dobStr = patient.dateOfBirth != null ? DateFormat('dd/MM/yyyy').format(patient.dateOfBirth!) : 'N/A';

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoItem('PATIENT NAME', patient.name, boldFont),
          _buildInfoItem('RELATIONSHIP', patient.relationship ?? 'Self', boldFont),
          _buildInfoItem('AGE / DOB', '$ageStr ($dobStr)', boldFont),
          _buildInfoItem('GENDER', patient.gender?.isNotEmpty == true ? patient.gender! : 'N/A', boldFont),
          _buildInfoItem('BLOOD GROUP', patient.bloodGroup?.isNotEmpty == true ? patient.bloodGroup! : 'N/A', boldFont),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoItem(String label, String value, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(font: boldFont, fontSize: 8.5, color: PdfColors.grey900)),
      ],
    );
  }

  static pw.Widget _buildSummaryGrid({
    required String startStr,
    required String endStr,
    required int totalEvents,
    required int rxCount,
    required int labCount,
    required int sugarCount,
    required int bpCount,
    required pw.Font boldFont,
  }) {
    return pw.Row(
      children: [
        _buildMetricBox('Total Events', '$totalEvents', PdfColors.blue50, PdfColors.blue900, boldFont),
        pw.SizedBox(width: 8),
        _buildMetricBox('Prescriptions', '$rxCount', PdfColors.purple50, PdfColors.purple900, boldFont),
        pw.SizedBox(width: 8),
        _buildMetricBox('Lab Reports', '$labCount', PdfColors.amber50, PdfColors.amber900, boldFont),
        pw.SizedBox(width: 8),
        _buildMetricBox('Sugar Tests', '$sugarCount', PdfColors.teal50, PdfColors.teal900, boldFont),
        pw.SizedBox(width: 8),
        _buildMetricBox('BP Readings', '$bpCount', PdfColors.red50, PdfColors.red900, boldFont),
      ],
    );
  }

  static pw.Widget _buildMetricBox(String label, String count, PdfColor bg, PdfColor textCol, pw.Font boldFont) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          children: [
            pw.Text(count, style: pw.TextStyle(font: boldFont, fontSize: 13, color: textCol)),
            pw.SizedBox(height: 2),
            pw.Text(label, style: pw.TextStyle(font: boldFont, fontSize: 7, color: textCol)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildRecentEvents(List<HealthEvent> recents, pw.Font boldFont) {
    if (recents.isEmpty) return _buildEmptyNotice('No recent events recorded.');
    return pw.Column(
      children: recents.map((e) {
        final badgeText = e.hasEvidence ? '🟢 Document Attached' : '🟡 Manual Entry';
        final badgeBg = e.hasEvidence ? PdfColors.green50 : PdfColors.amber50;
        final badgeCol = e.hasEvidence ? PdfColors.green900 : PdfColors.amber900;

        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 4),
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            border: pw.Border.all(color: PdfColors.grey200),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Text(e.formattedDate, style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.grey700)),
                  pw.SizedBox(width: 8),
                  pw.Text(e.eventType.englishLabel, style: pw.TextStyle(font: boldFont, fontSize: 8.5, color: PdfColors.grey900)),
                  pw.SizedBox(width: 6),
                  pw.Text('•  ${e.purpose}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: badgeBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Text(badgeText, style: pw.TextStyle(font: boldFont, fontSize: 6.5, color: badgeCol)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildPrescriptionCard(HealthEvent rx, pw.Font boldFont) {
    final rxData = rx.prescriptionData;
    final medicines = rxData?.medicines ?? [];

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.purple200),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        color: PdfColors.purple50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('💊 Purpose: ${rx.purpose}', style: pw.TextStyle(font: boldFont, fontSize: 9.5, color: PdfColors.purple900)),
              pw.Text('Date: ${rx.formattedDate} (${rx.eventTime})', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            ],
          ),
          if (rx.notes?.isNotEmpty == true) ...[
            pw.SizedBox(height: 3),
            pw.Text('Notes: ${rx.notes}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
          ],
          if (medicines.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text('Medicines:', style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.purple900)),
            ...medicines.map((m) => pw.Text('• $m', style: const pw.TextStyle(fontSize: 7.5))),
          ],
          if (rx.evidence.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Text('Attached Proof: ', style: pw.TextStyle(font: boldFont, fontSize: 7.5, color: PdfColors.green900)),
                ...rx.evidence.map((ev) => pw.Text('${ev.displayName}  ', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildLabReportCard(HealthEvent lab, pw.Font boldFont) {
    final labData = lab.labReportData;
    final result = labData?.resultSummary ?? 'Document attached for clinical review';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.amber200),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        color: PdfColors.amber50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('📄 Report: ${lab.purpose}', style: pw.TextStyle(font: boldFont, fontSize: 9.5, color: PdfColors.amber900)),
              pw.Text('Date: ${lab.formattedDate}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Row(
            children: [
              pw.Text('Result / Summary: ', style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.grey900)),
              pw.Text(result, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
            ],
          ),
          if (lab.evidence.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Text('Original Document: ', style: pw.TextStyle(font: boldFont, fontSize: 7.5, color: PdfColors.green900)),
                ...lab.evidence.map((ev) => pw.Text('${ev.displayName}  ', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildSugarTable(List<HealthEvent> sugars, pw.Font boldFont) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.teal50),
          children: [
            _buildTableHeaderCell('Date', boldFont),
            _buildTableHeaderCell('Time', boldFont),
            _buildTableHeaderCell('Value (mg/dL)', boldFont),
            _buildTableHeaderCell('Context', boldFont),
            _buildTableHeaderCell('Source & Evidence', boldFont),
          ],
        ),
        ...sugars.map((s) {
          final data = s.sugarData;
          final val = data != null ? '${data.value.toStringAsFixed(0)} mg/dL' : '-';
          final ctx = data?.context.label ?? '-';
          final source = s.hasEvidence ? '🟢 Document Attached' : '🟡 Manual Entry';

          return pw.TableRow(
            children: [
              _buildTableCell(s.formattedDate),
              _buildTableCell(s.eventTime),
              _buildTableCell(val),
              _buildTableCell(ctx),
              _buildTableCell(source),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildBpTable(List<HealthEvent> bps, pw.Font boldFont) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.red50),
          children: [
            _buildTableHeaderCell('Date', boldFont),
            _buildTableHeaderCell('Time', boldFont),
            _buildTableHeaderCell('Systolic / Diastolic', boldFont),
            _buildTableHeaderCell('Pulse', boldFont),
            _buildTableHeaderCell('Source & Evidence', boldFont),
          ],
        ),
        ...bps.map((bp) {
          final data = bp.bpData;
          final reading = data != null ? '${data.systolic} / ${data.diastolic} mmHg' : '-';
          final pulse = data?.pulse != null ? '${data!.pulse} bpm' : '-';
          final source = bp.hasEvidence ? '🟢 Document Attached' : '🟡 Manual Entry';

          return pw.TableRow(
            children: [
              _buildTableCell(bp.formattedDate),
              _buildTableCell(bp.eventTime),
              _buildTableCell(reading),
              _buildTableCell(pulse),
              _buildTableCell(source),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableHeaderCell(String text, pw.Font boldFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: pw.TextStyle(font: boldFont, fontSize: 7.5, color: PdfColors.grey900)),
    );
  }

  static pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
    );
  }

  static pw.Widget _buildGenericEventCard(HealthEvent event, pw.Font boldFont) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('${event.eventType.englishLabel} • ${event.purpose}', style: pw.TextStyle(font: boldFont, fontSize: 8.5)),
              if (event.notes?.isNotEmpty == true)
                pw.Text('Note: ${event.notes}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
            ],
          ),
          pw.Text('${event.formattedDate} (${event.eventTime})', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  static pw.Widget _buildEvidenceAppendix(List<HealthEvidence> evidenceList, pw.Font boldFont) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableHeaderCell('#', boldFont),
            _buildTableHeaderCell('Human-Readable Document Name', boldFont),
            _buildTableHeaderCell('Type', boldFont),
            _buildTableHeaderCell('Attachment Date', boldFont),
          ],
        ),
        ...evidenceList.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final ev = entry.value;
          return pw.TableRow(
            children: [
              _buildTableCell('$idx'),
              _buildTableCell(ev.displayName),
              _buildTableCell(ev.evidenceType),
              _buildTableCell(DateFormat('dd MMM yyyy').format(ev.createdAt)),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildEmptyNotice(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
    );
  }
}
