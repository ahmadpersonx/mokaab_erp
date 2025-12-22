// File: lib/features/finance/widgets/voucher_list_card.dart
// Description: A generic card for displaying any voucher (Receipt/Payment).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class VoucherListCard extends StatelessWidget {
  final Map<String, dynamic> voucher;
  final bool isSelected;
  final bool selectionMode;
  final String voucherType; // 'receipt' or 'payment'
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const VoucherListCard({
    super.key,
    required this.voucher,
    required this.isSelected,
    required this.selectionMode,
    required this.voucherType,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'د.أ ', decimalDigits: 2);
    final amount = (voucher['amount'] as num?)?.toDouble() ?? 0.0;
    
    // تحديد اللون بناءً على النوع
    final Color typeColor = voucherType == 'receipt' ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final Color bgColor = voucherType == 'receipt' ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);

    final lines = voucher['voucher_lines'] as List? ?? [];
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
          color: isSelected ? bgColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? typeColor : Colors.grey.shade200,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (selectionMode)
                        Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isSelected ? typeColor : Colors.grey,
                          size: 20,
                        ),
                      if (selectionMode) const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "#${voucher['voucher_number']}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    currencyFormat.format(amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: typeColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(LucideIcons.user, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(accountName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(LucideIcons.calendar, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    voucher['date'].toString().split(' ')[0],
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const Spacer(),
                  if (voucher['description'] != null)
                    Expanded(
                      child: Text(
                        voucher['description'],
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}