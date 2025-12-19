//pdf_preview_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../constants/app_theme.dart'; // تأكد من المسار

class PdfPreviewScreen extends StatelessWidget {
  final String title;
  // دالة تطلب التنسيق وترجع ملف الـ PDF كبيانات
  final Future<Uint8List> Function(PdfPageFormat format) buildPdf;

  const PdfPreviewScreen({
    super.key,
    required this.title,
    required this.buildPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.kDarkBrown, // أو أي لون
        foregroundColor: Colors.white,
      ),
      body: PdfPreview(
        build: buildPdf,
        // تفعيل الخيارات
        canChangeOrientation: false, // منع تدوير الورقة لتبسيط العرض
        canChangePageFormat: false, // تثبيت التنسيق على A4
        canDebug: false,
        
        // تخصيص اسم الملف عند الحفظ
        pdfFileName: "$title.pdf",
        
        // الأزرار ستظهر تلقائياً في الشريط العلوي للمعينة (حفظ، طباعة، مشاركة)
      ),
    );
  }
}
