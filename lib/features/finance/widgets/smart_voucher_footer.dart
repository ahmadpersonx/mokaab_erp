//smart_voucher_footer.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SmartVoucherFooter extends StatelessWidget {
  final double totalAmount;
  final Color themeColor;
  final bool isReadOnly; // ✅ متغير جديد
  final VoidCallback onSave;

  const SmartVoucherFooter({
    super.key,
    required this.totalAmount,
    required this.themeColor,
    this.isReadOnly = false, // ✅ قيمة افتراضية
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("إجمالي السند", style: TextStyle(color: Colors.grey)),
                Text(
                  totalAmount.toStringAsFixed(2), 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: themeColor)
                ),
              ],
            ),
            const Spacer(),
            
            // ✅ إظهار الزر فقط إذا لم يكن للقراءة
            if (!isReadOnly)
              ElevatedButton.icon(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(LucideIcons.save),
                label: const Text("حفظ وترحيل", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}