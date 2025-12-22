// FileName: lib/core/widgets/finance/finance_export_import_menu.dart
// Purpose: Unified export/import menu for Excel operations
// Features: Export all, Export selected, Import from Excel
// Used in: Vouchers, Invoices, Reports

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/app_theme.dart';

typedef ExportCallback = Future<void> Function(bool isSelected);
typedef ImportCallback = Future<void> Function();

class FinanceExportImportMenu extends StatelessWidget {
  final ExportCallback onExport;
  final ImportCallback onImport;
  final bool enableExportSelected;
  final int selectedItemsCount;

  const FinanceExportImportMenu({
    super.key,
    required this.onExport,
    required this.onImport,
    this.enableExportSelected = true,
    this.selectedItemsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'تصدير / استيراد',
      onSelected: (value) async {
        if (value == 'export_all') {
          await onExport(false);
        } else if (value == 'export_selected') {
          await onExport(true);
        } else if (value == 'import') {
          await onImport();
        }
      },
      itemBuilder: (BuildContext context) => [
        // Export All
        PopupMenuItem<String>(
          value: 'export_all',
          child: Row(
            spacing: 8,
            children: [
              const Icon(LucideIcons.download, size: 16, color: AppTheme.kDarkBrown),
              const Text('تصدير الكل'),
            ],
          ),
        ),

        // Export Selected
        if (enableExportSelected)
          PopupMenuItem<String>(
            enabled: selectedItemsCount > 0,
            value: 'export_selected',
            child: Row(
              spacing: 8,
              children: [
                const Icon(LucideIcons.downloadCloud, size: 16, color: Colors.orange),
                Text(
                  'تصدير المحدد (${selectedItemsCount > 0 ? selectedItemsCount : 0})',
                  style: TextStyle(
                    color: selectedItemsCount > 0 ? Colors.orange : Colors.grey,
                  ),
                ),
              ],
            ),
          ),

        const PopupMenuDivider(),

        // Import
        PopupMenuItem<String>(
          value: 'import',
          child: Row(
            spacing: 8,
            children: [
              const Icon(LucideIcons.upload, size: 16, color: AppTheme.kSuccess),
              const Text('استيراد من Excel'),
            ],
          ),
        ),
      ],
    );
  }
}
