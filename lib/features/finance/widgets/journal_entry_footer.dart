//journal_entry_footer.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_theme.dart';

class JournalEntryFooter extends StatelessWidget {
  final double totalDebit;
  final double totalCredit;
  final bool isBalanced;
  final bool canEdit;
  final bool canPost;
  final VoidCallback onAddLine;
  final VoidCallback onSaveDraft;
  final VoidCallback onPost;

  const JournalEntryFooter({
    super.key,
    required this.totalDebit,
    required this.totalCredit,
    required this.isBalanced,
    required this.canEdit,
    required this.canPost,
    required this.onAddLine,
    required this.onSaveDraft,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    double diff = totalDebit - totalCredit;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -3))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            // المجاميع
            _buildTotalBox("الإجمالي", totalDebit, Colors.green),
            
            if (!isBalanced)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.red)),
                child: Text("فرق: ${diff.toStringAsFixed(2)}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
              )
            else
              const Chip(label: Text("متوازن ✅"), backgroundColor: Colors.greenAccent, visualDensity: VisualDensity.compact),
            
            _buildTotalBox("الإجمالي", totalCredit, Colors.red),
          ]),
          const SizedBox(height: 16),
          
          Row(children: [
            if (canEdit)
              Expanded(child: OutlinedButton.icon(onPressed: onAddLine, icon: const Icon(LucideIcons.plus), label: const Text("سطر جديد"), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)))),
            const SizedBox(width: 10),
            
            // زر حفظ المسودة
            if (canEdit)
              Expanded(
                child: ElevatedButton(
                  onPressed: isBalanced ? onSaveDraft : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 1),
                  child: const Text("حفظ مسودة"),
                ),
              ),
            
            const SizedBox(width: 10),
            
            // زر الترحيل
            if (canEdit && canPost)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isBalanced ? onPost : null,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kDarkBrown, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 3),
                  icon: const Icon(LucideIcons.checkCircle, size: 18),
                  label: const Text("ترحيل"),
                ),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildTotalBox(String label, double value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      Text(value.toStringAsFixed(2), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
    ]);
  }
}
