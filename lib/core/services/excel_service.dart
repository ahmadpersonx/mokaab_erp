// FileName: lib/core/services/excel_service.dart
// Revision: 3.0 (Final Fix: Compatible with new AccountModel)

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// الاستيراد الصحيح للموديل
import '../models/account.dart';
import '../../features/finance/services/finance_service.dart';

class ExcelService {
  final FinanceService _financeService = FinanceService();

  Future<void> exportAccounts(List<Account> accounts) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Accounts'];
    
    // تحديث العناوين لتشمل جميع الحقول
    List<String> headers = [
      'الرمز', 'الاسم (عربي)', 'الاسم (انجليزي)', 'النوع', 'المستوى', 'الرصيد',
      'رمز الأب', 'الطبيعة', 'حساب أب', 'يتطلب مركز تكلفة', 'حساب عكسي'
    ];
    sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

    for (var account in accounts) {
      sheetObject.appendRow([
        TextCellValue(account.code),
        TextCellValue(account.nameAr),
        TextCellValue(account.nameEn ?? ''),
        TextCellValue(account.type),
        IntCellValue(account.level),
        DoubleCellValue(account.balance),
        TextCellValue(account.parentCode ?? ''),
        TextCellValue(account.nature ?? ''),
        TextCellValue(account.isParent ? 'نعم' : 'لا'),
        TextCellValue(account.requireCostCenter ? 'نعم' : 'لا'),
        TextCellValue(account.isContra ? 'نعم' : 'لا'),
      ]);
    }

    var fileBytes = excel.save();
    var directory = await getApplicationDocumentsDirectory();
    
    File file = File('${directory.path}/accounts_export_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    await file.writeAsBytes(fileBytes!);
    
    await Share.shareXFiles([XFile(file.path)], text: 'تصدير الحسابات');
  }

  Future<void> importAccounts(String filePath) async {
    var bytes = File(filePath).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    List<Account> accountsToImport = [];

    for (var table in excel.tables.keys) {
      // .skip(1) to ignore header row
      for (var row in excel.tables[table]!.rows.skip(1)) {
        final firstCell = row[0]?.value.toString();
        if (firstCell == null || firstCell.isEmpty) continue;

        try {
          bool parseBool(dynamic val) {
             final v = val?.toString().trim().toLowerCase();
             return v == 'yes' || v == 'true' || v == '1' || v == 'نعم';
          }

          final account = Account(
            id: 0, // ID will be ignored by DB on insert
            code: row[0]?.value.toString().trim() ?? '',
            nameAr: row[1]?.value.toString().trim() ?? '',
            nameEn: row[2]?.value.toString().trim() ?? '',
            type: row[3]?.value.toString().trim().toLowerCase() ?? 'asset',
            level: int.tryParse(row[4]?.value.toString() ?? '1') ?? 1,
            balance: double.tryParse(row[5]?.value.toString() ?? '0.0') ?? 0.0,
            parentCode: (row[6]?.value?.toString().trim().isEmpty ?? true) ? null : row[6]?.value.toString().trim(),
            nature: (row[7]?.value?.toString().trim().isEmpty ?? true) ? 'debit' : row[7]!.value.toString().trim(),
            isParent: parseBool(row[8]?.value),
            requireCostCenter: parseBool(row[9]?.value),
            isContra: parseBool(row[10]?.value),
            isTransaction: !parseBool(row[8]?.value.toString()),
          );
          accountsToImport.add(account);
        } catch (e) {
          print("خطأ في تحليل السطر: $e");
        }
      }
    }

    // الخطوة الأهم: ترتيب القائمة حسب المستوى (تصاعدياً)
    accountsToImport.sort((a, b) => a.level.compareTo(b.level));

    // ✅ الحل النهائي: الإدخال المتتالي بعد الترتيب
    // هذا يضمن أن كل أب يتم إدخاله قبل ابنه، مما يحل مشكلة المفتاح الأجنبي
    for (var account in accountsToImport) {
      try {
        // استخدام addAccount بدلاً من upsert لضمان الترتيب
        // يمكن تعديل addAccount لاحقاً ليقوم بـ upsert لصف واحد إذا أردنا تحديث البيانات
        await _financeService.addAccount(account);
        print("تم إدخال: ${account.code}");
      } catch (e) {
        print("خطأ في إدخال الحساب ${account.code}: $e");
        // يمكن إيقاف العملية أو الاستمرار حسب الحاجة
        // rethrow; // لإيقاف العملية
      }
    }
  }
}