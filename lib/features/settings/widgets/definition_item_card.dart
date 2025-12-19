// File: lib/features/settings/widgets/definition_item_card.dart
// Description: A clean material card to display a single definition item.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/models/definition_model.dart';

class DefinitionItemCard extends StatelessWidget {
  final DefinitionModel item;
  final bool hasColor;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DefinitionItemCard({
    super.key,
    required this.item,
    this.hasColor = false,
    this.canEdit = true,
    this.canDelete = true,
    required this.onEdit,
    required this.onDelete,
  });

  Color _hexToColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return const Color(0xFF5D4037); // Fallback color
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemColor = hasColor 
        ? _hexToColor(item.extraData['color'] ?? '#000000') 
        : const Color(0xFF5D4037);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        
        // الأيقونة
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: itemColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            hasColor ? LucideIcons.palette : LucideIcons.checkCircle,
            color: itemColor,
            size: 20,
          ),
        ),

        // العنوان والكود
        title: Row(
          children: [
            Text(
              item.nameAr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (item.code != null && item.code!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300)
                ),
                child: Text(
                  item.code!,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ),
            ]
          ],
        ),

        // المعلومات الإضافية
        subtitle: Text(
          [
            if (item.extraData['phone'] != null) "📞 ${item.extraData['phone']}",
            if (item.extraData['note'] != null) "📝 ${item.extraData['note']}",
          ].join('  |  '),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // الأزرار
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canEdit)
              IconButton(
                icon: const Icon(LucideIcons.edit3, size: 18, color: Colors.blueGrey),
                onPressed: onEdit,
              ),
            if (canDelete)
              IconButton(
                icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.redAccent),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}