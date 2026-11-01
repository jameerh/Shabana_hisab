import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/gadi_models.dart';

class GadiPdfService {
  /// 1. Vehicle Service & Maintenance Ledger Booklet
  static Future<File> generateServiceLedgerPdf({
    required GadiVehicle vehicle,
    required List<GadiEvent> serviceEvents,
    DateTime? startDate,
    DateTime? endDate,
    Directory? outputDir,
    pw.Font? regularFontOverride,
    pw.Font? boldFontOverride,
  }) async {
    final pdf = pw.Document();

    final regularFont = regularFontOverride ?? await PdfGoogleFonts.notoSansDevanagariRegular();
    final boldFont = boldFontOverride ?? await PdfGoogleFonts.notoSansDevanagariBold();

    final dateRangeStr = startDate != null && endDate != null
        ? '${DateFormat('dd MMM yyyy').format(startDate)} to ${DateFormat('dd MMM yyyy').format(endDate)}'
        : 'All-Time Complete Vehicle History';
    final generatedAtStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    double totalServiceCost = 0.0;
    int oilChangeCount = 0;
    final allReplacedParts = <String>[];

    for (final e in serviceEvents) {
      totalServiceCost += e.amount;
      final payload = e.servicePayload ?? e.repairPayload;
      if (payload is ServicePayload) {
        if (payload.engineOilReplaced) oilChangeCount++;
        allReplacedParts.addAll(payload.replacedPartsList);
      } else if (payload is RepairPayload) {
        allReplacedParts.addAll(payload.replacedParts);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        header: (context) => _buildReportHeader(
          title: 'VEHICLE SERVICE & MAINTENANCE LEDGER',
          subTitle: 'गाडी सर्व्हिसिंग आणि देखभाल नोंदवही',
          vehicle: vehicle,
          boldFont: boldFont,
          generatedAtStr: generatedAtStr,
        ),
        footer: (context) => _buildReportFooter(context),
        build: (context) => [
          pw.SizedBox(height: 10),
          _buildVehicleProfileCard(vehicle, boldFont),
          pw.SizedBox(height: 14),

          // SUMMARY GRID
          _buildSectionTitle('01 MAINTENANCE & REPAIR OVERVIEW', boldFont),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.blue200),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat('Total Maintenance', '₹${totalServiceCost.toStringAsFixed(0)}', boldFont),
                _buildSummaryStat('Total Garage Visits', '${serviceEvents.length}', boldFont),
                _buildSummaryStat('Oil Changes', '$oilChangeCount', boldFont),
                _buildSummaryStat('Current Odometer', '${vehicle.currentOdometer.toStringAsFixed(0)} KM', boldFont),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // CHRONOLOGICAL LOGS
          _buildSectionTitle('02 CHRONOLOGICAL SERVICE & REPAIR LOGS', boldFont),
          if (serviceEvents.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              alignment: pw.Alignment.center,
              child: pw.Text('No maintenance or garage records found for this vehicle.', style: const pw.TextStyle(color: PdfColors.grey700)),
            )
          else
            ...serviceEvents.map((ev) => _buildServiceEntryCard(ev, boldFont)),

          pw.SizedBox(height: 16),

          // REPLACED PARTS SUMMARY
          if (allReplacedParts.isNotEmpty) ...[
            _buildSectionTitle('03 REPLACED SPARE PARTS INVENTORY', boldFont),
            pw.Wrap(
              spacing: 6,
              runSpacing: 6,
              children: allReplacedParts.map((p) => pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(p, style: pw.TextStyle(font: boldFont, fontSize: 9)),
              )).toList(),
            ),
          ],
        ],
      ),
    );

    return _saveAndReturnPdf(pdf, 'Service_Ledger_${vehicle.registrationNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf', outputDir: outputDir);
  }

  /// 2. Tax & Business Reimbursement Claim Report
  static Future<File> generateReimbursementPdf({
    required GadiVehicle vehicle,
    required List<GadiTrip> trips,
    required List<GadiEvent> expenses,
    required DateTime startDate,
    required DateTime endDate,
    String? employeeOrBusinessName,
    Directory? outputDir,
    pw.Font? regularFontOverride,
    pw.Font? boldFontOverride,
  }) async {
    final pdf = pw.Document();

    final regularFont = regularFontOverride ?? await PdfGoogleFonts.notoSansDevanagariRegular();
    final boldFont = boldFontOverride ?? await PdfGoogleFonts.notoSansDevanagariBold();

    final startStr = DateFormat('dd MMM yyyy').format(startDate);
    final endStr = DateFormat('dd MMM yyyy').format(endDate);
    final generatedAtStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    double businessKm = 0.0;
    double personalKm = 0.0;
    double totalReimbursement = 0.0;

    for (final t in trips) {
      if (t.isBusiness) {
        businessKm += t.distanceKm;
        totalReimbursement += t.computedReimbursement;
      } else {
        personalKm += t.distanceKm;
      }
    }

    double fuelSpend = 0.0;
    double tollAndParking = 0.0;
    for (final e in expenses) {
      if (e.eventType == GadiEventType.fuel) {
        fuelSpend += e.amount;
      } else if (e.eventType == GadiEventType.toll || e.eventType == GadiEventType.parking) {
        tollAndParking += e.amount;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        header: (context) => _buildReportHeader(
          title: 'VEHICLE TRAVEL & BUSINESS REIMBURSEMENT REPORT',
          subTitle: 'प्रवास आणि व्यवसाय खर्च प्रतिपूर्ती अहवाल',
          vehicle: vehicle,
          boldFont: boldFont,
          generatedAtStr: generatedAtStr,
        ),
        footer: (context) => _buildReportFooter(context),
        build: (context) => [
          pw.SizedBox(height: 10),
          _buildVehicleProfileCard(vehicle, boldFont, customLabel: employeeOrBusinessName != null ? 'Claimant: $employeeOrBusinessName' : null),
          pw.SizedBox(height: 14),

          // CLAIM SUMMARY
          _buildSectionTitle('01 CLAIM & DISTANCE SUMMARY ($startStr to $endStr)', boldFont),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.green200),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat('Total Claim Due', '₹${totalReimbursement.toStringAsFixed(0)}', boldFont, color: PdfColors.green800),
                _buildSummaryStat('Business Travel', '${businessKm.toStringAsFixed(1)} KM', boldFont),
                _buildSummaryStat('Fuel Paid', '₹${fuelSpend.toStringAsFixed(0)}', boldFont),
                _buildSummaryStat('Tolls / Parking', '₹${tollAndParking.toStringAsFixed(0)}', boldFont),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // ITEMIZED BUSINESS TRIPS TABLE
          _buildSectionTitle('02 ITEMIZED BUSINESS & WORK JOURNEYS', boldFont),
          if (trips.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              alignment: pw.Alignment.center,
              child: pw.Text('No journey records logged for this period.', style: const pw.TextStyle(color: PdfColors.grey700)),
            )
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              headers: ['Date & Time', 'Trip Type', 'Route (From - To)', 'Purpose', 'KM', 'Rate', 'Claim (₹)'],
              data: trips.map((t) => [
                DateFormat('dd-MMM HH:mm').format(t.startDateTime),
                t.tripType.englishLabel,
                '${t.startLocation ?? '-'} -> ${t.endLocation ?? '-'}',
                t.purpose ?? '-',
                t.distanceKm.toStringAsFixed(1),
                '₹${t.reimbursementRatePerKm?.toStringAsFixed(2) ?? '-'}',
                '₹${t.computedReimbursement.toStringAsFixed(0)}',
              ]).toList(),
            ),

          pw.SizedBox(height: 16),

          // ITEMIZED FUEL & TOLL RECEIPTS
          if (expenses.isNotEmpty) ...[
            _buildSectionTitle('03 FUEL, TOLL & PARKING EXPENSES', boldFont),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey700),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              headers: ['Date', 'Category', 'Description / Station', 'Odo (KM)', 'Amount (₹)'],
              data: expenses.map((e) => [
                formatDateOnly(e.eventDate),
                e.eventType.englishLabel,
                e.title,
                e.odometerKm != null ? '${e.odometerKm!.toStringAsFixed(0)} KM' : '-',
                '₹${e.amount.toStringAsFixed(0)}',
              ]).toList(),
            ),
          ],

          pw.SizedBox(height: 24),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Claimant Signature: _______________________', style: const pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 4),
                  pw.Text('Date: $startStr', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Authorized Approver: ____________________', style: const pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 4),
                  pw.Text('Verified & Approved for Payment', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return _saveAndReturnPdf(pdf, 'Reimbursement_${vehicle.registrationNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf', outputDir: outputDir);
  }

  /// 3. Accident & Insurance Claim Dossier
  static Future<File> generateInsuranceClaimPdf({
    required GadiVehicle vehicle,
    required GadiEvent claimEvent,
    Directory? outputDir,
    pw.Font? regularFontOverride,
    pw.Font? boldFontOverride,
  }) async {
    final pdf = pw.Document();

    final regularFont = regularFontOverride ?? await PdfGoogleFonts.notoSansDevanagariRegular();
    final boldFont = boldFontOverride ?? await PdfGoogleFonts.notoSansDevanagariBold();

    final payload = claimEvent.claimPayload ?? AccidentClaimPayload();
    final generatedAtStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        header: (context) => _buildReportHeader(
          title: 'VEHICLE ACCIDENT & INSURANCE CLAIM DOSSIER',
          subTitle: 'अपघात आणि विमा क्लेम अहवाल',
          vehicle: vehicle,
          boldFont: boldFont,
          generatedAtStr: generatedAtStr,
        ),
        footer: (context) => _buildReportFooter(context),
        build: (context) => [
          pw.SizedBox(height: 10),
          _buildVehicleProfileCard(vehicle, boldFont),
          pw.SizedBox(height: 14),

          // CLAIM STATUS BANNER
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.amber300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Claim Status: ${payload.claimStatus}', style: pw.TextStyle(font: boldFont, fontSize: 11, color: PdfColors.amber900)),
                pw.Text('Claim #: ${payload.claimNumber ?? 'Pending'}', style: pw.TextStyle(font: boldFont, fontSize: 11)),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // INCIDENT DETAILS
          _buildSectionTitle('01 INCIDENT & ACCIDENT DETAILS', boldFont),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Accident Date:', payload.accidentDate ?? formatDateOnly(claimEvent.eventDate), boldFont),
                _buildInfoRow('Accident Location:', payload.accidentLocation ?? 'Not specified', boldFont),
                _buildInfoRow('Third Party Involved:', payload.thirdPartyInvolved ? 'Yes' : 'No', boldFont),
                _buildInfoRow('Police Station:', payload.policeStation ?? '-', boldFont),
                _buildInfoRow('FIR / Diary Number:', payload.firNumber ?? '-', boldFont),
                _buildInfoRow('Remarks / Narrative:', claimEvent.notes ?? 'No additional remarks', boldFont),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // SURVEYOR & INSURANCE
          _buildSectionTitle('02 INSURANCE COMPANY & SURVEYOR DETAILS', boldFont),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Insurance Company:', payload.insuranceCompany ?? vehicle.insurancePolicyNumber ?? 'Not specified', boldFont),
                _buildInfoRow('Policy Number:', vehicle.insurancePolicyNumber ?? '-', boldFont),
                _buildInfoRow('Assigned Surveyor:', payload.surveyorName ?? '-', boldFont),
                _buildInfoRow('Surveyor Phone:', payload.surveyorPhone ?? '-', boldFont),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // FINANCIAL BREAKDOWN
          _buildSectionTitle('03 FINANCIAL LOSS & SETTLEMENT SUMMARY', boldFont),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat('Estimated Loss', '₹${payload.estimatedLossAmount.toStringAsFixed(0)}', boldFont),
                _buildSummaryStat('Claim Approved', '₹${payload.approvedAmount.toStringAsFixed(0)}', boldFont, color: PdfColors.green800),
                _buildSummaryStat('Owner Out-of-Pocket', '₹${payload.outOfPocketAmount.toStringAsFixed(0)}', boldFont, color: PdfColors.red800),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // ATTACHED EVIDENCE LIST
          _buildSectionTitle('04 ATTACHED EVIDENCE & DOCUMENTS (${claimEvent.evidence.length})', boldFont),
          if (claimEvent.evidence.isEmpty)
            pw.Text('No physical photographs or FIR/Bills attached to this dossier.', style: const pw.TextStyle(color: PdfColors.grey700))
          else
            pw.Column(
              children: claimEvent.evidence.map((ev) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey200),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(ev.displayName, style: pw.TextStyle(font: boldFont, fontSize: 9)),
                    pw.Text(ev.evidenceType, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              )).toList(),
            ),
        ],
      ),
    );

    return _saveAndReturnPdf(pdf, 'Claim_Dossier_${vehicle.registrationNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf', outputDir: outputDir);
  }

  // ==========================================
  // SHARED PDF WIDGETS
  // ==========================================

  static pw.Widget _buildReportHeader({
    required String title,
    required String subTitle,
    required GadiVehicle vehicle,
    required pw.Font boldFont,
    required String generatedAtStr,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('SHABANA GADI HISAAB', style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.blue800)),
                pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 11)),
                pw.Text(subTitle, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Reg: ${vehicle.registrationNumber}', style: pw.TextStyle(font: boldFont, fontSize: 11)),
                pw.Text('Generated: $generatedAtStr', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 1, color: PdfColors.blueGrey800),
      ],
    );
  }

  static pw.Widget _buildReportFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount} • Shabana Digital Vehicle File',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }

  static pw.Widget _buildVehicleProfileCard(GadiVehicle vehicle, pw.Font boldFont, {String? customLabel}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('${vehicle.name} (${vehicle.vehicleType.englishLabel})', style: pw.TextStyle(font: boldFont, fontSize: 11)),
              pw.Text('Fuel: ${vehicle.fuelType.englishLabel} | Current ODO: ${vehicle.currentOdometer.toStringAsFixed(0)} KM', style: const pw.TextStyle(fontSize: 9)),
              if (customLabel != null)
                pw.Text(customLabel, style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.blue800)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('PUC Expiry: ${vehicle.pucExpiryDate != null ? formatDateOnly(vehicle.pucExpiryDate!) : 'N/A'}', style: const pw.TextStyle(fontSize: 8.5)),
              pw.Text('Insurance: ${vehicle.insuranceExpiryDate != null ? formatDateOnly(vehicle.insuranceExpiryDate!) : 'N/A'}', style: const pw.TextStyle(fontSize: 8.5)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title, pw.Font boldFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.blueGrey800)),
    );
  }

  static pw.Widget _buildSummaryStat(String label, String value, pw.Font boldFont, {PdfColor? color}) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(font: boldFont, fontSize: 13, color: color ?? PdfColors.blueGrey900)),
        pw.SizedBox(height: 2),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value, pw.Font boldFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 140, child: pw.Text(label, style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.grey800))),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 9))),
        ],
      ),
    );
  }

  static pw.Widget _buildServiceEntryCard(GadiEvent ev, pw.Font boldFont) {
    final service = ev.servicePayload;
    final repair = ev.repairPayload;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${ev.title} (${formatDateOnly(ev.eventDate)})', style: pw.TextStyle(font: boldFont, fontSize: 10)),
              pw.Text('₹${ev.amount.toStringAsFixed(0)}', style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.blue800)),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Odometer: ${ev.odometerKm != null ? '${ev.odometerKm!.toStringAsFixed(0)} KM' : 'Not recorded'}', style: const pw.TextStyle(fontSize: 8.5)),
              if (service?.serviceCenterName != null || repair?.garageName != null)
                pw.Text('Center: ${service?.serviceCenterName ?? repair?.garageName}', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
            ],
          ),
          if (service?.engineOilReplaced == true) ...[
            pw.SizedBox(height: 2),
            pw.Text('Engine Oil Replaced: Yes (${service?.oilGrade ?? 'Standard Grade'})', style: pw.TextStyle(font: boldFont, fontSize: 8.5, color: PdfColors.teal800)),
          ],
          if (ev.notes != null && ev.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text('Notes: ${ev.notes}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ],
        ],
      ),
    );
  }

  static Future<File> _saveAndReturnPdf(pw.Document pdf, String filename, {Directory? outputDir}) async {
    final tempDir = outputDir ?? await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Helper to share generated PDF via system share sheet
  static Future<void> sharePdf(File file, String subject) async {
    await Share.shareXFiles([XFile(file.path)], subject: subject);
  }
}
