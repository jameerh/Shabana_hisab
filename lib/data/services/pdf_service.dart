import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart' as material;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database.dart';
import '../../main.dart';
import '../core/config/app_config.dart';

import 'dart:ui' as ui;

class PdfService {
  static Future<pw.Widget> _buildNativeText(
    String text, {
    double fontSize = 12,
    material.Color color = material.Colors.black,
    material.FontWeight fontWeight = material.FontWeight.normal,
  }) async {
    if (text.trim().isEmpty) return pw.SizedBox();
    
    // Use a scale factor for HD text without excessive file size
    const double scale = 3.0;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final material.Canvas canvas = material.Canvas(recorder);
    canvas.scale(scale, scale);

    final material.TextPainter tp = material.TextPainter(
      text: material.TextSpan(
        text: text,
        style: material.TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: 'NotoSansDevanagari',
        ),
      ),
      textDirection: material.TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, material.Offset.zero);
    
    final picture = recorder.endRecording();
    final img = await picture.toImage((tp.width * scale).ceil(), (tp.height * scale).ceil());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png); // PNG compression helps keep text file size low
    final buffer = byteData!.buffer.asUint8List();
    
    return pw.Image(
      pw.MemoryImage(buffer), 
      width: tp.width.toDouble(), 
      height: tp.height.toDouble(),
      fit: pw.BoxFit.contain,
    );
  }

  static Future<File> generateReceiptFile(Transaction tx) async {
    final pdf = pw.Document();
    
    final boldFont = await PdfGoogleFonts.notoSansDevanagariBold();
    
    final now = DateTime.now();
    final generatedStr = "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";
    
    final settings = await database.getShopSettings();
    final shopNameText = settings?.shopName ?? AppConfig.shopName;
    final shopAddressText = settings?.address ?? "Jath, Sangli";
    final shopContactText = settings?.mobileNumber ?? "+91 9876543210";

    final shopNameImg = await _buildNativeText(shopNameText, fontSize: 18, fontWeight: material.FontWeight.bold, color: material.Colors.blue.shade900);
    final shopAddrImg = await _buildNativeText(shopAddressText, fontSize: 10, color: material.Colors.grey.shade700);
    final shopContImg = await _buildNativeText('Contact: $shopContactText', fontSize: 10, color: material.Colors.grey.shade700);
    
    final receiptTitleImg = await _buildNativeText('व्यवहार पावती (Transaction Receipt)', fontSize: 14, fontWeight: material.FontWeight.bold, color: material.Colors.blueGrey);
    
    final dateLblImg = await _buildNativeText('तारीख (Date):', fontSize: 10, fontWeight: material.FontWeight.bold);
    final dateValImg = await _buildNativeText("${tx.timestamp.day}/${tx.timestamp.month}/${tx.timestamp.year} ${tx.timestamp.hour}:${tx.timestamp.minute.toString().padLeft(2, '0')}", fontSize: 10);
    
    final typeLblImg = await _buildNativeText('प्रकार (Type):', fontSize: 10, fontWeight: material.FontWeight.bold);
    final nameLblImg = await _buildNativeText('नाव / तपशील (Name):', fontSize: 10, fontWeight: material.FontWeight.bold);
    final catLblImg = await _buildNativeText('कॅटेगरी (Category):', fontSize: 10, fontWeight: material.FontWeight.bold);
    final totalLblImg = await _buildNativeText('एकूण रक्कम (Total):', fontSize: 12, fontWeight: material.FontWeight.bold, color: material.Colors.white);
    
    final partyNameImg = await _buildNativeText(tx.partyName, fontSize: 12, fontWeight: material.FontWeight.bold);
    final catNameImg = await _buildNativeText(tx.categoryName ?? 'General', fontSize: 10);
    
    final authSignImg = await _buildNativeText('Authorized Signatory', fontSize: 8, color: material.Colors.grey);
    final signLineImg = await _buildNativeText('____________________', fontSize: 8, color: material.Colors.grey);

    final typeColorPdf = tx.type == 'Income' ? PdfColors.green800 : (tx.type == 'Expense' ? PdfColors.red800 : PdfColors.orange800);
    final typeBg = tx.type == 'Income' ? PdfColors.green50 : (tx.type == 'Expense' ? PdfColors.red50 : PdfColors.orange50);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: shopNameImg),
              pw.Center(child: shopAddrImg),
              pw.Center(child: shopContImg),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),
              pw.Center(child: receiptTitleImg),
              pw.SizedBox(height: 10),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  dateLblImg,
                  dateValImg,
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  typeLblImg,
                  pw.Text(
                    tx.type,
                    style: pw.TextStyle(font: boldFont, fontSize: 12, color: typeColorPdf),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  nameLblImg,
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: partyNameImg,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  catLblImg,
                  catNameImg,
                ],
              ),

              pw.SizedBox(height: 14),
              
              // Total Box
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: typeBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: typeColorPdf, width: 1),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    totalLblImg,
                    pw.Text('Rs. ${tx.amount.toStringAsFixed(0)}', style: pw.TextStyle(font: boldFont, fontSize: 16, color: typeColorPdf, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),
              pw.SizedBox(
                width: double.infinity,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    signLineImg,
                    pw.SizedBox(height: 4),
                    authSignImg,
                  ]
                )
              ),
              
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              
              // Proof Images Section
              if (tx.images != null) () {
                try {
                  final List<String> paths = List<String>.from(jsonDecode(tx.images!));
                  if (paths.isNotEmpty) {
                    return pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(height: 8),
                        pw.Text('Attached Photos:', style: pw.TextStyle(font: boldFont, fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: paths.map((p) {
                            final file = File(p);
                            if (file.existsSync()) {
                              return pw.Image(
                                pw.MemoryImage(file.readAsBytesSync()),
                                width: 70,
                                height: 70,
                                fit: pw.BoxFit.cover,
                              );
                            }
                            return pw.SizedBox();
                          }).toList().cast<pw.Widget>(),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
                      ],
                    );
                  }
                } catch(_) {}
                return pw.SizedBox();
              }(),

              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text('Thank you for your business!', style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.grey700)),
              ),
              pw.Center(
                child: pw.Text('Report Generated on: $generatedStr', style: pw.TextStyle(fontSize: 6, color: PdfColors.grey500)),
              ),
            ]
          );
        }
      )
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/receipt_${tx.id}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<void> generateCalculatorReceiptPdf(CalculatorEntry entry, String profileName) async {
    final pdf = pw.Document();
    final boldFont = await PdfGoogleFonts.notoSansDevanagariBold();
    
    final now = DateTime.now();
    final generatedStr = "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";
    
    final settings = await database.getShopSettings();
    final shopNameText = settings?.shopName ?? AppConfig.shopName;

    final shopNameImg = await _buildNativeText(shopNameText, fontSize: 18, fontWeight: material.FontWeight.bold, color: material.Colors.indigo);
    final titleImg = await _buildNativeText('कॅल्क्युलेटर पावती (Calculator Receipt)', fontSize: 12, fontWeight: material.FontWeight.bold);
    final profileImg = await _buildNativeText('प्रोफाईल: $profileName', fontSize: 10);
    final dateImg = await _buildNativeText('तारीख: ${entry.createdAt.day}/${entry.createdAt.month}/${entry.createdAt.year}', fontSize: 10);
    final totalImg = await _buildNativeText('एकूण: ${entry.isCurrency ? "₹" : ""}${entry.parsedValue.toStringAsFixed(2)}', fontSize: 16, fontWeight: material.FontWeight.bold, color: material.Colors.indigo);

    final expressionImg = await _buildNativeText(entry.expression, fontSize: 12);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(child: shopNameImg),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1),
            pw.Center(child: titleImg),
            pw.SizedBox(height: 10),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [profileImg, dateImg]),
            pw.SizedBox(height: 16),
            pw.Text('Details:', style: pw.TextStyle(font: boldFont, fontSize: 10)),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              child: expressionImg,
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(color: PdfColors.indigo50, border: pw.Border.all(color: PdfColors.indigo)),
              child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Total', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                totalImg,
              ]),
            ),
            pw.SizedBox(height: 20),
            pw.Center(child: pw.Text('Generated by Shabana Hisaab on $generatedStr', style: pw.TextStyle(fontSize: 6, color: PdfColors.grey500))),
          ],
        ),
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/calc_receipt_${entry.id}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'Calculator Receipt shared');
  }

  static Future<void> generateGroceryItemReceiptPdf(GroceryList list, GroceryItem item) async {
    final pdf = pw.Document();
    final boldFont = await PdfGoogleFonts.notoSansDevanagariBold();
    
    final settings = await database.getShopSettings();
    final shopNameText = settings?.shopName ?? AppConfig.shopName;

    final shopNameImg = await _buildNativeText(shopNameText, fontSize: 18, fontWeight: material.FontWeight.bold, color: material.Colors.teal);
    final titleImg = await _buildNativeText('किराणा आयटम पावती (Grocery Item)', fontSize: 12, fontWeight: material.FontWeight.bold);
    final itemNameImg = await _buildNativeText(item.itemName, fontSize: 14, fontWeight: material.FontWeight.bold);
    final qtyImg = await _buildNativeText('नंग/प्रमाण: ${item.quantity} ${item.unit}', fontSize: 12);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(child: shopNameImg),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1),
            pw.Center(child: titleImg),
            pw.SizedBox(height: 10),
            pw.Text('List: ${list.name}', style: const pw.TextStyle(fontSize: 8)),
            pw.SizedBox(height: 16),
            pw.Center(child: itemNameImg),
            pw.SizedBox(height: 8),
            pw.Center(child: qtyImg),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
            pw.SizedBox(height: 10),
            pw.Center(child: pw.Text('Shabana Multiservices, Jath', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700))),
          ],
        ),
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/grocery_item_${item.id}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'Grocery Item shared: ${item.itemName}');
  }

  static Future<void> generateDashboardReport({
    required String profileName,
    required double totalIncome,
    required double totalExpense,
    required String startStr,
    required String endStr,
    Uint8List? chartsImg,
  }) async {
    final pdf = pw.Document();
    
    final settings = await database.getShopSettings();
    final shopNameText = settings?.shopName ?? AppConfig.shopName;

    final titleImg = await _buildNativeText('$shopNameText - सारांश अहवाल ($profileName)', fontSize: 20, fontWeight: material.FontWeight.bold, color: material.Colors.blue.shade900);
    final dateRangeImg = await _buildNativeText('कालावधी: $startStr ते $endStr', fontSize: 12, color: material.Colors.grey.shade800);
    final genDateImg = await _buildNativeText('Report Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', fontSize: 10, color: material.Colors.grey.shade600);
    
    final incImg = await _buildNativeText('एकूण जमा: ₹${totalIncome.toStringAsFixed(0)}', fontSize: 18, color: material.Colors.green.shade800, fontWeight: material.FontWeight.bold);
    final expImg = await _buildNativeText('एकूण खर्च: ₹${totalExpense.toStringAsFixed(0)}', fontSize: 18, color: material.Colors.red.shade800, fontWeight: material.FontWeight.bold);
    
    final balance = totalIncome - totalExpense;
    final balColor = balance >= 0 ? material.Colors.green.shade900 : material.Colors.red.shade900;
    final balImg = await _buildNativeText('शिल्लक (Balance): ₹${balance.toStringAsFixed(0)}', fontSize: 20, color: balColor, fontWeight: material.FontWeight.bold);
    
    final profImg = await _buildNativeText('प्रोफाईल: $profileName', fontSize: 14, color: material.Colors.blueGrey);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              titleImg,
              pw.SizedBox(height: 4),
              dateRangeImg,
              pw.SizedBox(height: 4),
              genDateImg,
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 16),
              
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  color: PdfColors.grey50,
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        incImg,
                        expImg,
                      ]
                    ),
                    pw.SizedBox(height: 12),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 8),
                    balImg,
                  ]
                )
              ),
              pw.SizedBox(height: 16),
              profImg,
              pw.SizedBox(height: 24),
              
              if (chartsImg != null)
                pw.Center(
                  child: pw.Image(pw.MemoryImage(chartsImg), fit: pw.BoxFit.contain, height: 350)
                ),
              pw.Spacer(),
              pw.Text('All rights reserved © Shabana Multiservices, Jath', style: pw.TextStyle(color: PdfColors.grey500, fontSize: 10)),
            ]
          );
        }
      )
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/dashboard_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: 'माझा डॅशबोर्ड रिपोर्ट ($startStr ते $endStr)');
  }

  static Future<void> generateListPdf({
    required List<Transaction> transactions,
    required String profileName,
    required String filterDesc,
    bool includeChart = false,
  }) async {
    final pdf = pw.Document();
    
    final font = await PdfGoogleFonts.notoSansDevanagariRegular();
    final boldFont = await PdfGoogleFonts.notoSansDevanagariBold();
    
    final now = DateTime.now();
    final generatedStr = "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    final settings = await database.getShopSettings();
    final shopNameText = settings?.shopName ?? AppConfig.shopName;

    final titleImg = await _buildNativeText('$shopNameText - व्यवहार रिपोर्ट ($profileName)', fontSize: 16, fontWeight: material.FontWeight.bold);
    final filterImg = await _buildNativeText('फिल्टर: $filterDesc', fontSize: 12);
    final genDateImg = await _buildNativeText('अहवाल तयार केला: $generatedStr', fontSize: 10, color: material.Colors.grey.shade700);
    
    double totalInc = 0, totalExp = 0, totalUdh = 0;
    for(var tx in transactions) {
      if(tx.type == 'Income') totalInc += tx.amount;
      else if(tx.type == 'Expense') totalExp += tx.amount;
      else if(tx.type == 'Udhaari') totalUdh += tx.amount;
    }
    
    final incImg = await _buildNativeText('एकूण जमा: ₹${totalInc.toStringAsFixed(0)}', fontSize: 14, color: material.Colors.green.shade800, fontWeight: material.FontWeight.bold);
    final expImg = await _buildNativeText('एकूण खर्च: ₹${totalExp.toStringAsFixed(0)}', fontSize: 14, color: material.Colors.red.shade800, fontWeight: material.FontWeight.bold);
    
    final totalBal = totalInc - totalExp;
    final balColor = totalBal >= 0 ? material.Colors.green.shade900 : material.Colors.red.shade900;
    final balImg = await _buildNativeText('शिल्लक (Balance): ₹${totalBal.toStringAsFixed(0)}', fontSize: 14, color: balColor, fontWeight: material.FontWeight.bold);

    final projBal = totalBal + totalUdh;
    final projImg = await _buildNativeText('उधारी वसुली नंतर एकूण (Potential): ₹${projBal.toStringAsFixed(0)}', fontSize: 14, color: material.Colors.blue.shade900, fontWeight: material.FontWeight.bold);
    final udhImg = await _buildNativeText('उधारी (Pending Udhaari): ₹${totalUdh.toStringAsFixed(0)}', fontSize: 11, color: material.Colors.orange.shade900);

    final toShow = transactions.take(150).toList(); 

    // Pre-render table rows to handle Marathi correctly
    final List<List<pw.Widget>> tableRows = [];
    for (var tx in toShow) {
      final isInc = tx.type == 'Income';
      final date = "${tx.timestamp.day}/${tx.timestamp.month} ${tx.timestamp.hour}:${tx.timestamp.minute.toString().padLeft(2, '0')}";
      
      tableRows.add([
        pw.Text(date, style: const pw.TextStyle(fontSize: 10)),
        await _buildNativeText(tx.partyName, fontSize: 10),
        pw.Text('Rs. ${tx.amount}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: isInc ? PdfColors.green800 : PdfColors.red800)),
        pw.Text(tx.type, style: const pw.TextStyle(fontSize: 10)),
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Center(child: titleImg),
            pw.SizedBox(height: 4),
            pw.Center(child: filterImg),
            pw.Center(child: genDateImg),
            pw.SizedBox(height: 16),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                color: PdfColors.grey50,
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      incImg,
                      expImg,
                    ]
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(color: PdfColors.grey300),
                  pw.SizedBox(height: 6),
                  balImg,
                  if (totalUdh > 0) ...[
                    pw.SizedBox(height: 8),
                    pw.Divider(color: PdfColors.blue100, thickness: 0.5),
                    pw.SizedBox(height: 4),
                    udhImg,
                    pw.SizedBox(height: 4),
                    projImg,
                  ],
                ]
              )
            ),
            pw.SizedBox(height: 16),

            if (includeChart && (totalInc > 0 || totalExp > 0)) ...[
              pw.Center(
                child: pw.SizedBox(
                  width: 150,
                  height: 150,
                  child: pw.Chart(
                    grid: pw.PieGrid(),
                    datasets: [
                      if (totalInc > 0)
                        pw.PieDataSet(
                          legend: 'Income',
                          value: totalInc,
                          color: PdfColors.green,
                        ),
                      if (totalExp > 0)
                        pw.PieDataSet(
                          legend: 'Expense',
                          value: totalExp,
                          color: PdfColors.red,
                        ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
            ],
            
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Party', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                  ]
                ),
                ...tableRows.map((row) => pw.TableRow(
                  children: row.map((cell) => pw.Padding(padding: const pw.EdgeInsets.all(6), child: cell)).toList(),
                )),
              ]
            ),
            
            // Proofs Appendix
            if (transactions.any((tx) => tx.images != null)) ...[
              pw.SizedBox(height: 32),
              pw.Divider(thickness: 2, color: PdfColors.blue800),
              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text('Attachments & Proofs (पुराव्यांचे फोटो)', style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.blue800))),
              pw.SizedBox(height: 20),
              ...transactions.where((tx) => tx.images != null).expand((tx) {
                List<String> paths = [];
                try { paths = List<String>.from(jsonDecode(tx.images!)); } catch(_) {}
                if (paths.isEmpty) return [];

                return [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('${tx.partyName} - ₹${tx.amount}', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                        pw.Text('${tx.timestamp.day}/${tx.timestamp.month}/${tx.timestamp.year}', style: pw.TextStyle(font: font, fontSize: 10)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: paths.map((p) {
                      final file = File(p);
                      if (file.existsSync()) {
                        return pw.Container(
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                          ),
                          child: pw.Image(
                            pw.MemoryImage(file.readAsBytesSync()),
                            width: 150,
                            height: 150,
                            fit: pw.BoxFit.contain,
                          ),
                        );
                      }
                      return pw.SizedBox();
                    }).toList().cast<pw.Widget>(),
                  ),
                  pw.SizedBox(height: 24),
                ];
              }),
            ],

            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text('All rights reserved © ${AppConfig.appName}', style: pw.TextStyle(color: PdfColors.grey500, fontSize: 10)),
            ),
          ];

        }
      )
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/transactions_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: 'व्यवहार रिपोर्ट शेअर केला');
  }

  static Future<void> generateGroceryPdf({
    required GroceryList list,
    required List<GroceryItem> items,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansDevanagariRegular();
    final boldFont = await PdfGoogleFonts.notoSansDevanagariBold();
    
    final settings = await database.getShopSettings();
    final shopNameText = settings?.shopName ?? AppConfig.shopName;

    final titleImg = await _buildNativeText('$shopNameText - किराणा लिस्ट', fontSize: 16, fontWeight: material.FontWeight.bold);
    final listNameImg = await _buildNativeText(list.name, fontSize: 14, fontWeight: material.FontWeight.bold, color: material.Colors.teal);
    final dateImg = await _buildNativeText('तारीख: ${list.createdAt.day}/${list.createdAt.month}/${list.createdAt.year}', fontSize: 10);

    // Pre-render table rows to handle Marathi correctly
    final List<List<pw.Widget>> tableRows = [];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final checkTimeStr = item.checkedAt != null 
          ? "${item.checkedAt!.day}/${item.checkedAt!.month} ${item.checkedAt!.hour}:${item.checkedAt!.minute.toString().padLeft(2, '0')}"
          : "-";
          
      tableRows.add([
        pw.Text('${i + 1}', style: const pw.TextStyle(fontSize: 10)),
        await _buildNativeText(item.itemName, fontSize: 10),
        await _buildNativeText('${item.quantity} ${item.unit}', fontSize: 10, fontWeight: material.FontWeight.bold),
        pw.Text(item.isChecked ? 'COMPLETE' : 'PENDING', 
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: item.isChecked ? PdfColors.green : PdfColors.red)),
        pw.Text(checkTimeStr, style: const pw.TextStyle(fontSize: 8)),
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          pw.Center(child: titleImg),
          pw.SizedBox(height: 8),
          pw.Center(child: listNameImg),
          pw.Center(child: dateImg),
          pw.SizedBox(height: 16),
          pw.Divider(thickness: 1, color: PdfColors.teal),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(30),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('No.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Item Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Date/Time', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                ]
              ),
              ...tableRows.map((row) => pw.TableRow(
                children: row.map((cell) => pw.Padding(padding: const pw.EdgeInsets.all(6), child: cell)).toList(),
              )),
            ]
          ),
          pw.SizedBox(height: 30),
          pw.Center(child: pw.Text('Generated by Shabana Hisaab', style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 8))),
        ],
      )
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/grocery_${list.id}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'माझी किराणा लिस्ट: ${list.name}');
  }

  static Future<void> generateCalculatorPdf({
    required List<CalculatorEntry> entries,
    required String profileName,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansDevanagariRegular();
    final boldFont = await PdfGoogleFonts.notoSansDevanagariBold();
    
    final settings = await database.getShopSettings();
    final shopNameText = settings?.shopName ?? AppConfig.shopName;

    final titleImg = await _buildNativeText('$shopNameText - कॅल्क्युलेटर रिपोर्ट', fontSize: 16, fontWeight: material.FontWeight.bold);
    final profileImg = await _buildNativeText('प्रोफाईल: $profileName', fontSize: 12);
    
    double total = entries.fold(0, (sum, e) => sum + e.parsedValue);
    final totalImg = await _buildNativeText('एकूण: ₹${total.toStringAsFixed(2)}', fontSize: 16, fontWeight: material.FontWeight.bold, color: material.Colors.indigo);

    // Pre-render table rows to handle Marathi correctly
    final List<List<pw.Widget>> tableRows = [];
    for (var e in entries) {
      final date = "${e.createdAt.day}/${e.createdAt.month} ${e.createdAt.hour}:${e.createdAt.minute}";
      tableRows.add([
        pw.Text(date, style: const pw.TextStyle(fontSize: 10)),
        await _buildNativeText(e.expression, fontSize: 10),
        pw.Text('₹${e.parsedValue.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          pw.Center(child: titleImg),
          pw.SizedBox(height: 4),
          pw.Center(child: profileImg),
          pw.SizedBox(height: 16),
          pw.Divider(thickness: 1, color: PdfColors.indigo),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Calculation Details', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                ]
              ),
              ...tableRows.map((row) => pw.TableRow(
                children: row.map((cell) => pw.Padding(padding: const pw.EdgeInsets.all(6), child: cell)).toList(),
              )),
            ]
          ),
          pw.SizedBox(height: 20),
          pw.Align(alignment: pw.Alignment.centerRight, child: totalImg),
          pw.Spacer(),
          pw.Center(child: pw.Text('Generated by Shabana Hisaab', style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 8))),
        ],
      )
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/calc_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'कॅल्क्युलेटर रिपोर्ट शेअर केला');
  }
}