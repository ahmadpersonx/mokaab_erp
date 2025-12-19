// FileName: lib/features/finance/widgets/print_action_menu.dart
// Revision: 1.3 (Integrated Selection Mode Toggle)

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PrintActionMenu extends StatelessWidget {
  final VoidCallback onPrintFull;
  final VoidCallback onPrintSelected;
  final VoidCallback onToggleSelection;
  final bool isSelectionEmpty;
  final bool isSelectionMode;

  const PrintActionMenu({
    super.key,
    required this.onPrintFull,
    required this.onPrintSelected,
    required this.onToggleSelection,
    this.isSelectionEmpty = true,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.printer, color: Colors.white),
      tooltip: 'خيارات الطباعة',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (String value) {
        if (value == 'full') {
          onPrintFull();
        } else if (value == 'toggle') {
          onToggleSelection();
        } else if (value == 'print_now') {
          onPrintSelected();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'full',
          child: ListTile(
            leading: Icon(LucideIcons.fileText, color: Colors.blue),
            title: Text('طباعة الكل'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: isSelectionMode ? 'print_now' : 'toggle',
          enabled: isSelectionMode ? !isSelectionEmpty : true,
          child: ListTile(
            leading: Icon(
              isSelectionMode ? LucideIcons.printer : LucideIcons.checkSquare,
              color: isSelectionMode 
                  ? (isSelectionEmpty ? Colors.grey : Colors.green) 
                  : Colors.orange,
            ),
            title: Text(isSelectionMode ? 'تأكيد طباعة المحدد' : 'تفعيل اختيار للطباعة'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        if (isSelectionMode)
          const PopupMenuItem<String>(
            value: 'toggle',
            child: ListTile(
              leading: Icon(LucideIcons.xCircle, color: Colors.red),
              title: Text('إلغاء وضع التحديد'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
      ],
    );
  }
}