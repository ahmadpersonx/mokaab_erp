// File: lib/features/finance/widgets/receipt_bond_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ReceiptBondCard extends StatelessWidget {
  final Map<String, dynamic> bond;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onPrint;

  const ReceiptBondCard({
    super.key,
    required this.bond,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'د.أ ', decimalDigits: 2);
    final amount = (bond['amount'] as num?)?.toDouble() ?? 0.0;
    
    // استخراج اسم الحساب من السطور (عادة السطر الأول هو المدين/العميل في سند القبض)
    // ملاحظة: قد يختلف الهيكل حسب الـ JSON القادم من الباك اند
    final lines = bond['voucher_lines'] as List? ?? [];
    final accountName = lines.isNotEmpty && lines[0]['accounts'] != null
        ? lines[0]['accounts']['name_ar']
        : 'حساب غير محدد';

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- السطر الأول: الرقم والتاريخ والمبلغ ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // أيقونة التحديد (تظهر فقط عند التحديد)
                      if (selectionMode)
                        Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isSelected ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                      if (selectionMode) const SizedBox(width: 8),
                      
                      // رقم السند
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "#${bond['voucher_number']}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),

                  // المبلغ (باللون الأخضر لأنه قبض)
                  Text(
                    currencyFormat.format(amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2E7D32), // Green 800
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),

              // --- السطر الثاني: اسم الحساب ---
              Row(
                children: [
                  const Icon(LucideIcons.user, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    accountName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // --- السطر الثالث: البيان + التاريخ ---
              Row(
                children: [
                  const Icon(LucideIcons.fileText, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bond['description'] ?? 'لا يوجد بيان',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    bond['date'].toString().split(' ')[0],
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),

              // --- أزرار الإجراءات السريعة (تظهر عند فتح البطاقة فقط، سننفذها لاحقاً في Details) ---
              // هنا سنكتفي بالعرض، والتفاعل عند الضغط يفتح التفاصيل
            ],
          ),
        ),
      ),
    );
  }
}