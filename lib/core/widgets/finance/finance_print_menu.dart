// FileName: lib/core/widgets/finance/finance_print_menu.dart
// Purpose: Unified print menu for all finance screens
// Features: Print all, Print selected, Print preview
// Used in: Vouchers, Invoices, Reports

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/app_theme.dart';

typedef PrintCallback = Future<void> Function(bool isSelected);

class FinancePrintMenu extends StatelessWidget {
  final PrintCallback onPrint;
  final bool enablePrintSelected;
  final int selectedItemsCount;
  final String tooltipText;

  const FinancePrintMenu({
    super.key,
    required this.onPrint,
    this.enablePrintSelected = true,
    this.selectedItemsCount = 0,
    this.tooltipText = 'طباعة',
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: tooltipText,
      onSelected: (value) async {
        if (value == 'print_all') {
          await onPrint(false);
        } else if (value == 'print_selected') {
          await onPrint(true);
        }
      },
      itemBuilder: (BuildContext context) => [
        // Print All
        PopupMenuItem<String>(
          value: 'print_all',
          child: Row(
            spacing: 8,
            children: [
              const Icon(LucideIcons.printer, size: 16, color: AppTheme.kDarkBrown),
              const Text('طباعة الكل'),
            ],
          ),
        ),

        // Print Selected
        if (enablePrintSelected)
          PopupMenuItem<String>(
            enabled: selectedItemsCount > 0,
            value: 'print_selected',
            child: Row(
              spacing: 8,
              children: [
                Icon(
                  LucideIcons.printer,
                  size: 16,
                  color: selectedItemsCount > 0 ? Colors.orange : Colors.grey,
                ),
                Text(
                  'طباعة المحدد (${selectedItemsCount > 0 ? selectedItemsCount : 0})',
                  style: TextStyle(
                    color: selectedItemsCount > 0 ? Colors.orange : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
