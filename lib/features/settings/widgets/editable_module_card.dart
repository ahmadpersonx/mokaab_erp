//lib\features\settings\widgets\editable_module_card.dart
import 'package:flutter/material.dart';
import '../../home/widgets/module_card.dart'; // ✅ نعيد استخدام البطاقة الأصلية

class EditableModuleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool canManage;

  const EditableModuleCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.canManage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ✅ البطاقة الأساسية (تصميم موحد)
        ModuleCard(
          title: title,
          icon: icon,
          color: color,
          onTap: onTap,
        ),

        // ✅ زر الخيارات (فقط للمدير)
        if (canManage)
          Positioned(
            top: 4,
            left: 4, // أو right حسب اللغة
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
              onSelected: (value) {
                if (value == 'edit' && onEdit != null) onEdit!();
                if (value == 'delete' && onDelete != null) onDelete!();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [Icon(Icons.edit, size: 16, color: Colors.blue), SizedBox(width: 8), Text("تعديل")]),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 8), Text("حذف")]),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
