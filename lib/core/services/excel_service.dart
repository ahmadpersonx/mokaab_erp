// FileName: lib/core/services/excel_service.dart
// Revision: 4.0 (Merged All Excel Functions)

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; 
import '../../features/finance/models/account_model.dart';
import '../../features/finance/services/finance_service.dart';

class ExcelService {
  final FinanceService _financeService = FinanceService();

  // ============================================================
  // 1. الوظيفة الجديدة: تصدير كشف الحساب (لحل مشكلة الشاشة)
  // ============================================================
  Future<void> exportAccountStatement({
    required String accountName,
    required String accountCode,
    required DateTime fromDate,
    required DateTime toDate,
    required List<Map<String, dynamic>> transactions,
    required double totalDebit,
    required double totalCredit,
    required double finalBalance,
  }) async {
    try {
      var excel = Excel.createExcel();
      // استخدام الورقة الافتراضية بدلاً من البحث بالاسم لتجنب الأخطاء
      Sheet sheetObject = excel[excel.getDefaultSheet()!];

      final DateFormat df = DateFormat('yyyy-MM-dd');

      // إضافة الترويسة
      sheetObject.appendRow([TextCellValue("كشف حساب: $accountName ($accountCode)")]);
      sheetObject.appendRow([TextCellValue("من: ${df.format(fromDate)} إلى: ${df.format(toDate)}")]);
      sheetObject.appendRow([]); // سطر فارغ

      // عناوين الجدول
      List<String> headers = ["التاريخ", "رقم القيد", "البيان", "مدين", "دائن", "الرصيد"];
      sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

      // إضافة البيانات
      for (var trans in transactions) {
        sheetObject.appendRow([
          TextCellValue(df.format(DateTime.parse(trans['date']))),
          TextCellValue(trans['id'].toString()),
          TextCellValue(trans['description'] ?? ''),
          DoubleCellValue((trans['debit'] as num).toDouble()),
          DoubleCellValue((trans['credit'] as num).toDouble()),
          DoubleCellValue((trans['running_balance'] as num).toDouble()),
        ]);
      }

      // إضافة المجموع
      sheetObject.appendRow([]);
      sheetObject.appendRow([
        TextCellValue("الإجماليات"),
        TextCellValue(""),
        TextCellValue(""),
        DoubleCellValue(totalDebit),
        DoubleCellValue(totalCredit),
        DoubleCellValue(finalBalance),
      ]);

      await _saveExcelFile(excel, "Statement_$accountCode");
    } catch (e) {
      debugPrint("Export Error: $e");
      rethrow; 
    }
  }

  // ============================================================
  // 2. الوظيفة القديمة: تصدير شجرة الحسابات (مع تحسينات)
  // ============================================================
  Future<String> exportAccountsToExcel(List<AccountModel> accounts) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['ChartOfAccounts'];
    
    // عناوين الأعمدة
    List<String> headers = [
      'Code', 'Name (AR)', 'Parent Code', 'Nature', 
      'Is Parent', 'Level', 'Require Cost Center', 'Is Contra', 'Current Balance'
    ];
    
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = TextCellValue(headers[i]);
    }

    for (var account in accounts) {
      sheet.appendRow([
        TextCellValue(account.code),
        TextCellValue(account.nameAr),
        TextCellValue(account.parentCode ?? ""),
        TextCellValue(account.nature),
        BoolCellValue(account.isParent),
        IntCellValue(account.level),
        BoolCellValue(account.requireCostCenter),
        BoolCellValue(account.isContra),
        DoubleCellValue(account.currentBalance),
      ]);
    }

    return await _saveExcelFile(excel, "ChartOfAccounts");
  }

  // ============================================================
  // 3. الوظيفة القديمة: استيراد الحسابات
  // ============================================================
  Future<String> importAccountsFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null) return "تم إلغاء العملية";

      var bytes = File(result.files.single.path!).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      var table = excel.tables[excel.tables.keys.first];

      if (table == null || table.maxRows <= 1) return "الملف فارغ";

      int successCount = 0;
      List<List<Data?>> rows = table.rows.skip(1).toList();
      
      // ترتيب الادخال (الأب أولاً)
      rows.sort((a, b) => (a[0]?.value.toString().length ?? 0).compareTo(b[0]?.value.toString().length ?? 0));

      for (var row in rows) {
        try {
          String code = row[0]?.value.toString() ?? "";
          String name = row[1]?.value.toString() ?? "";
          if (code.isEmpty) continue;

          await _financeService.addAccount(AccountModel(
            id: 0,
            code: code,
            nameAr: name,
            parentCode: row[2]?.value?.toString() == "" ? null : row[2]?.value?.toString(),
            nature: row[3]?.value.toString() ?? "debit",
            isParent: _parseBool(row[4]?.value), // العمود الرابع
            level: int.tryParse(row[5]?.value.toString() ?? "1") ?? 1,
            requireCostCenter: _parseBool(row[6]?.value),
            isContra: _parseBool(row[7]?.value),
          ));
          successCount++;
        } catch (e) {
          debugPrint("Row Import Error: $e");
        }
      }
      return "تم استيراد $successCount حساب بنجاح";
    } catch (e) {
      return "خطأ: $e";
    }
  }

  // --- دوال مساعدة (Helper Methods) ---
  Future<String> _saveExcelFile(Excel excel, String prefix) async {
    var fileBytes = excel.save();
    if (fileBytes == null) return "فشل الحفظ";

    String fileName = "${prefix}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx";

    if (Platform.isWindows || Platform.isMacOS) {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ ملف الإكسل',
        fileName: fileName,
        allowedExtensions: ['xlsx'],
      );
      if (outputFile != null) {
        if (!outputFile.endsWith('.xlsx')) outputFile += '.xlsx';
        File(outputFile)..createSync(recursive: true)..writeAsBytesSync(fileBytes);
        return "تم الحفظ: $outputFile";
      }
      return "تم الإلغاء";
    } else {
      final dir = await getTemporaryDirectory();
      final path = "${dir.path}/$fileName";
      File(path)..createSync(recursive: true)..writeAsBytesSync(fileBytes);
      await Share.shareXFiles([XFile(path)]);
      return "تمت المشاركة";
    }
  }

  bool _parseBool(dynamic value) {
    if (value == null) return false;
    String str = value.toString().toLowerCase();
    return str == 'true' || str == '1' || str == 'yes';
  }
}