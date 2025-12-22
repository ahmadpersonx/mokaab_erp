//pdf_service.dart
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../features/finance/models/journal_entry_model.dart';

class PdfService {
  Future<pw.Font> _getFont() async {
    try {
      final fontData = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
      return pw.Font.ttf(fontData);
    } catch (e) {
      return pw.Font.courier(); 
    }
  }

  // ... (دوال generateJournalEntryPdf و generateListReport السابقة كما هي) ...

  // ✅✅✅ أضف هذه الدالة الجديدة لطباعة سند القبض/الصرف الفردي
  Future<Uint8List> generateVoucherPdf(Map<String, dynamic> voucher, String title, PdfPageFormat format) async {
    final font = await _getFont();
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: format,
        theme: pw.ThemeData.withFont(base: font),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0, 
                child: pw.Center(
                  child: pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, font: font))
                )
              ),
              pw.SizedBox(height: 20),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("رقم السند: ${voucher['voucher_number'] ?? 'جديد'}", style: pw.TextStyle(font: font)),
                pw.Text("التاريخ: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(voucher['date']))}", style: pw.TextStyle(font: font)),
              ]),
              pw.SizedBox(height: 10),
              pw.Text("المبلغ: ${(voucher['amount'] as num).toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: font)),
              pw.Text("طريقة الدفع: ${voucher['payment_method'] == 'check' ? 'شيك' : 'نقدي'}", style: pw.TextStyle(font: font)),
              if (voucher['check_no'] != null) pw.Text("رقم الشيك: ${voucher['check_no']}", style: pw.TextStyle(font: font)),
              pw.SizedBox(height: 20),
              pw.Text("البيان العام: ${voucher['description'] ?? ''}", style: pw.TextStyle(font: font)),
              pw.SizedBox(height: 20),
              
              pw.Table.fromTextArray(
                headers: ['المبلغ', 'الحساب', 'البيان', 'م.تكلفة'],
                data: (voucher['voucher_lines'] as List).map((l) => [
                  (l['amount'] as num).toStringAsFixed(2),
                  l['account_name'] ?? '', // تأكد من تمرير الاسم هنا
                  l['description'] ?? '',
                  l['cost_center_name'] ?? '',
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, font: font),
                cellStyle: pw.TextStyle(font: font, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
                cellAlignment: pw.Alignment.center,
              ),
              pw.SizedBox(height: 40),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("التوقيع: ....................", style: pw.TextStyle(font: font)),
                  pw.Text("المستلم: ....................", style: pw.TextStyle(font: font)),
                ]
              )
            ],
          );
        },
      ),
    );

    return doc.save();
  }
  
  // (تأكد أن generateJournalEntryPdf و generateListReport موجودة أيضاً في الملف)
  Future<Uint8List> generateJournalEntryPdf(JournalEntryModel entry, PdfPageFormat format) async {
    final font = await _getFont();
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: format, 
        theme: pw.ThemeData.withFont(base: font),
        textDirection: pw.TextDirection.rtl, 
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0, 
                child: pw.Center(
                  child: pw.Text("سند قيد يومي", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, font: font))
                )
              ),
              pw.SizedBox(height: 20),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("رقم القيد: ${entry.entryNumber}", style: pw.TextStyle(font: font)),
                pw.Text("التاريخ: ${DateFormat('yyyy-MM-dd').format(entry.entryDate)}", style: pw.TextStyle(font: font)),
              ]),
              pw.SizedBox(height: 10),
              pw.Text("البيان: ${entry.description}", style: pw.TextStyle(font: font)),
              pw.SizedBox(height: 20),
              
              pw.Table.fromTextArray(
                headers: ['مدين', 'دائن', 'الحساب', 'البيان', 'م.تكلفة'],
                data: entry.lines.map((l) => [
                  (l.debit ?? 0.0).toStringAsFixed(2),
                  (l.credit ?? 0.0).toStringAsFixed(2),
                  l.accountId,
                  l.description,
                  l.costCenterId?.toString() ?? '',
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, font: font),
                cellStyle: pw.TextStyle(font: font, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
                cellAlignment: pw.Alignment.center,
              ),
            ],
          );
        },
      ),
    );

    return doc.save(); 
  }
  
  Future<Uint8List> generateListReport(
    PdfPageFormat format, {
    required String title,
    required List<String> headers,
    required List<List<String>> data,
  }) async {
    final font = await _getFont();
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        theme: pw.ThemeData.withFont(base: font),
        textDirection: pw.TextDirection.rtl,
        header: (context) => pw.Center(
          child: pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, font: font))
        ),
        build: (context) => [
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, font: font),
            cellStyle: pw.TextStyle(font: font, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey700),
            cellAlignment: pw.Alignment.center,
            tableWidth: pw.TableWidth.max,
          ),
        ],
      ),
    );

    return doc.save();
  }
}