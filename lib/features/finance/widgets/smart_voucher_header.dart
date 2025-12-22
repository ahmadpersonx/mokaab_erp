//smart_voucher_header.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../core/models/account.dart';

class SmartVoucherHeader extends StatelessWidget {
  final DateTime date;
  final String paymentMethod;
  final Account? treasuryAccount;
  final List<Account> treasuryAccountsList;
  final String voucherType;
  final Color themeColor;
  
  // ✅ 1. تعريف المتغير الجديد
  final bool isReadOnly; 

  final Function(DateTime) onDateChanged;
  final Function(String?) onPaymentMethodChanged;
  final Function(Account?) onTreasuryAccountChanged;

  const SmartVoucherHeader({
    super.key,
    required this.date,
    required this.paymentMethod,
    required this.treasuryAccount,
    required this.treasuryAccountsList,
    required this.voucherType,
    required this.themeColor,
    
    // ✅ 2. إضافته للمنشئ (Constructor) مع قيمة افتراضية
    this.isReadOnly = false, 
    
    required this.onDateChanged,
    required this.onPaymentMethodChanged,
    required this.onTreasuryAccountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: InkWell(
                // ✅ 3. تعطيل النقر إذا كان للعرض فقط
                onTap: isReadOnly ? null : () async { 
                  final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (d != null) onDateChanged(d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'تاريخ السند', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(10)),
                  child: Row(children: [const Icon(LucideIcons.calendar, size: 16), const SizedBox(width: 8), Text(DateFormat('yyyy-MM-dd').format(date))]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: paymentMethod,
                decoration: const InputDecoration(labelText: 'طريقة الدفع', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(10)),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('نقدي')),
                  DropdownMenuItem(value: 'check', child: Text('شيك')),
                  DropdownMenuItem(value: 'transfer', child: Text('حوالة بنكية')),
                ],
                // ✅ 4. تعطيل التغيير
                onChanged: isReadOnly ? null : onPaymentMethodChanged, 
              ),
            ),
          ]),
          const SizedBox(height: 12),
          DropdownSearch<Account>(
            // ✅ 5. تعطيل البحث والاختيار
            enabled: !isReadOnly, 
            items: (f, l) => treasuryAccountsList,
            itemAsString: (a) => "${a.code} - ${a.nameAr ?? ''}",
            compareFn: (item, selectedItem) => item.code == selectedItem?.code,
            selectedItem: treasuryAccount,
            onChanged: onTreasuryAccountChanged,
            decoratorProps: DropDownDecoratorProps(
              decoration: InputDecoration(
                labelText: voucherType == 'receipt' ? 'إيداع في (الصندوق/البنك)' : 'صرف من (الصندوق/البنك)',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(voucherType == 'receipt' ? LucideIcons.arrowDownCircle : LucideIcons.arrowUpCircle, color: themeColor),
                filled: true,
                fillColor: themeColor.withOpacity(0.05),
                isDense: true,
              ),
            ),
            popupProps: const PopupProps.menu(showSearchBox: true),
          ),
        ],
      ),
    );
  }
}