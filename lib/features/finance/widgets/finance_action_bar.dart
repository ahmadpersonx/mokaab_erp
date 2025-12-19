// File: lib/features/finance/widgets/finance_action_bar.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FinanceActionBar extends StatelessWidget {
  final VoidCallback onPrintAll;
  final VoidCallback onPrintSelected;
  final VoidCallback onExportExcelAll;
  final VoidCallback onExportExcelSelected;
  final VoidCallback onImportExcel;
  final bool hasSelection;

  const FinanceActionBar({
    super.key,
    required this.onPrintAll,
    required this.onPrintSelected,
    required this.onExportExcelAll,
    required this.onExportExcelSelected,
    required this.onImportExcel,
    required this.hasSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- قائمة الطباعة ---
        PopupMenuButton<String>(
          icon: const Icon(LucideIcons.printer, color: Colors.white),
          tooltip: 'خيارات الطباعة',
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (val) {
            if (val == 'all') onPrintAll();
            if (val == 'selected') onPrintSelected();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'all',
              child: ListTile(
                leading: Icon(LucideIcons.files, color: Colors.blue),
                title: Text('طباعة الكل'),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'selected',
              enabled: hasSelection,
              child: ListTile(
                leading: Icon(LucideIcons.checkSquare, color: hasSelection ? Colors.green : Colors.grey),
                title: Text('طباعة المحدد (${hasSelection ? "مفعل" : "معطل"})'),
                dense: true,
              ),
            ),
          ],
        ),

        // --- قائمة التصدير والاستيراد ---
        PopupMenuButton<String>(
          icon: const Icon(LucideIcons.downloadCloud, color: Colors.white),
          tooltip: 'تصدير / استيراد',
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (val) {
            if (val == 'export_all') onExportExcelAll();
            if (val == 'export_selected') onExportExcelSelected();
            if (val == 'import') onImportExcel();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export_all',
              child: ListTile(
                leading: Icon(LucideIcons.sheet, color: Colors.green),
                title: Text('تصدير الكل (Excel)'),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'export_selected',
              enabled: hasSelection,
              child: ListTile(
                leading: Icon(LucideIcons.checkSquare, color: hasSelection ? Colors.green : Colors.grey),
                title: Text('تصدير المحدد'),
                dense: true,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'import',
              child: ListTile(
                leading: Icon(LucideIcons.uploadCloud, color: Colors.orange),
                title: Text('استيراد من Excel'),
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}