//excel_service.dart
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/account_model.dart';
import '../../features/finance/finance_service.dart';

class ExcelService {
  final FinanceService _financeService = FinanceService();

  // ==============================
  // 1. تصدير الحسابات (Export)
  // ==============================
  Future<String> exportAccountsToExcel(List<AccountModel> accounts) async {
    var excel = Excel.createExcel();
    
    // إعادة تسمية الورقة الأساسية
    String sheetName = 'ChartOfAccounts';
    Sheet sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);

    // 1. إضافة ترويسة الأعمدة (Headers)
    List<String> headers = [
      'Code', 'Name (AR)', 'Parent Code', 'Nature', 
      'Is Transaction', 'Level', 'Require Cost Center', 'Is Contra', 'Current Balance'
    ];
    
    // تنسيق الترويسة
    CellStyle headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      // تصحيح خطأ الألوان للإصدارات الحديثة
      backgroundColorHex: ExcelColor.fromHexString('#CCCCCC'), 
    );

    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // 2. إضافة البيانات
    for (int i = 0; i < accounts.length; i++) {
      var account = accounts[i];
      List<CellValue> row = [
        TextCellValue(account.code),
        TextCellValue(account.nameAr),
        account.parentCode != null ? TextCellValue(account.parentCode!) : TextCellValue(""),
        TextCellValue(account.nature),
        BoolCellValue(account.isTransaction),
        IntCellValue(account.level),
        BoolCellValue(account.requireCostCenter),
        BoolCellValue(account.isContra),
        DoubleCellValue(account.currentBalance),
      ];
      
      sheet.appendRow(row);
    }

    // 3. حفظ الملف (منطق منفصل لكل نظام)
    var fileBytes = excel.save();
    
    if (fileBytes != null) {
      String fileName = 'Accounts_Backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';

      // فحص النظام: هل هو ديسكتوب (Windows/Linux/Mac)؟
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // --- للمحاكي والديسكتوب: فتح نافذة حفظ باسم ---
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'حفظ ملف الإكسل',
          fileName: fileName,
          allowedExtensions: ['xlsx'],
          type: FileType.custom,
        );

        if (outputFile != null) {
          // التأكد من الامتداد
          if (!outputFile.endsWith('.xlsx')) {
             outputFile = '$outputFile.xlsx';
          }
          
          File(outputFile)
            ..createSync(recursive: true)
            ..writeAsBytesSync(fileBytes);
            
          return "تم حفظ الملف بنجاح في: $outputFile";
        } else {
          return "تم إلغاء الحفظ";
        }
      } else {
        // --- للموبايل (Android/iOS): استخدام المشاركة ---
        final directory = await getTemporaryDirectory();
        final path = "${directory.path}/$fileName";
        
        File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);

        await Share.shareXFiles([XFile(path)], text: 'نسخة احتياطية من شجرة الحسابات');
        return "تمت مشاركة الملف";
      }
    }
    return "فشل إنشاء الملف";
  }

  // ==============================
  // 2. استيراد الحسابات (Import)
  // ==============================
  Future<String> importAccountsFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        var file = File(result.files.single.path!);
        var bytes = file.readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);

        var table = excel.tables[excel.tables.keys.first];
        
        if (table == null || table.maxRows <= 1) {
          return "الملف فارغ أو لا يحتوي على بيانات";
        }

        int successCount = 0;
        int errorCount = 0;

        List<List<Data?>> rows = table.rows.skip(1).toList();
        
        // ترتيب لضمان الأب قبل الابن
        rows.sort((a, b) {
           String codeA = a[0]?.value.toString() ?? "";
           String codeB = b[0]?.value.toString() ?? "";
           return codeA.length.compareTo(codeB.length);
        });

        for (var row in rows) {
          try {
            String code = row[0]?.value.toString() ?? "";
            String name = row[1]?.value.toString() ?? "";
            
            if (code.isEmpty || name.isEmpty) continue;

            String? parentCode = row[2]?.value?.toString();
            if (parentCode == "null" || parentCode == "") parentCode = null;

            String nature = row[3]?.value.toString() ?? "debit";
            bool isTransaction = _parseBool(row[4]?.value);
            int level = int.tryParse(row[5]?.value.toString() ?? "1") ?? 1;
            bool requireCostCenter = _parseBool(row[6]?.value);
            bool isContra = _parseBool(row[7]?.value);

            AccountModel account = AccountModel(
              code: code,
              nameAr: name,
              parentCode: parentCode,
              nature: nature,
              isTransaction: isTransaction,
              level: level,
              requireCostCenter: requireCostCenter,
              isContra: isContra,
            );

            await _financeService.addAccount(account);
            successCount++;

          } catch (e) {
            print("Error importing row: $e");
            errorCount++;
          }
        }

        return "تم الاستيراد بنجاح: $successCount حساب. (فشل: $errorCount)";
      } else {
        return "تم إلغاء اختيار الملف";
      }
    } catch (e) {
      return "حدث خطأ أثناء الاستيراد: $e";
    }
  }

  bool _parseBool(dynamic value) {
    if (value == null) return false;
    String str = value.toString().toLowerCase();
    return str == 'true' || str == '1' || str == 'yes';
  }
}