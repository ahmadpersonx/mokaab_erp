//journal_entry_row.dart
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/account_model.dart';
import '../models/journal_entry_model.dart';
import '../models/cost_center_model.dart';
import '../../../core/constants/app_theme.dart';

class JournalEntryRow extends StatelessWidget {
  final int index;
  final JournalEntryLine line;
  final List<AccountModel> allAccounts;
  final List<CostCenterModel> costCenters;
  final bool canEdit;
  final VoidCallback onRemove;
  final VoidCallback onChanged; // لإعلام الأب بتحديث المجاميع

  const JournalEntryRow({
    super.key,
    required this.index,
    required this.line,
    required this.allAccounts,
    required this.costCenters,
    required this.canEdit,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedAcc = line.accountId.isNotEmpty
        ? allAccounts.firstWhere((a) => a.code == line.accountId, orElse: () => allAccounts.first)
        : null;
    bool needsCostCenter = selectedAcc?.requireCostCenter ?? false;

    final inputDecoration = InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      filled: true,
      fillColor: Colors.white,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 1. الحساب
        Expanded(
          flex: 3,
          child: DropdownSearch<AccountModel>(
            enabled: canEdit,
            items: (f, l) => allAccounts,
            itemAsString: (a) => "${a.code} - ${a.nameAr}",
            compareFn: (a, b) => a.code == b.code,
            selectedItem: selectedAcc,
           onChanged: (a) {
  // هنا نحن نخزن الكود "1101" في الموديل المؤقت للواجهة
  // هذا صحيح للعرض، وسنقوم بتحويله لـ ID عند الحفظ
  line.accountId = a?.code ?? ''; 
  onChanged();
},
            popupProps: const PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(decoration: InputDecoration(hintText: "بحث...", isDense: true)),
            ),
            decoratorProps: DropDownDecoratorProps(
              decoration: inputDecoration.copyWith(hintText: "اختر الحساب"),
            ),
          ),
        ),
        const SizedBox(width: 8),
        
        // 2. البيان ومركز التكلفة
        Expanded(
          flex: 3,
          child: Row(children: [
            Expanded(
              flex: needsCostCenter ? 3 : 5,
              child: TextFormField(
                initialValue: line.description,
                readOnly: !canEdit,
                decoration: inputDecoration.copyWith(hintText: "البيان"),
                onChanged: (v) {
                  line.description = v;
                  // لا نحتاج onChanged هنا لأن البيان لا يؤثر على الحسابات
                },
              ),
            ),
            if (needsCostCenter) ...[
              const SizedBox(width: 5),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: line.costCenterId,
                    decoration: const InputDecoration(hintText: 'م.تكلفة', isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), prefixIcon: Icon(LucideIcons.network, color: Colors.orange, size: 16)),
                    items: costCenters.map((cc) => DropdownMenuItem(value: cc.id, child: Text(cc.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: !canEdit ? null : (v) => line.costCenterId = v,
                  ),
                ),
              ),
            ]
          ]),
        ),
        const SizedBox(width: 8),
        
        // 3. المدين
        Expanded(
          flex: 1,
          child: TextFormField(
            initialValue: line.debit == 0 ? '' : line.debit.toString(),
            readOnly: !canEdit,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: inputDecoration.copyWith(hintText: "0.0"),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            onChanged: (v) {
              line.debit = double.tryParse(v) ?? 0;
              if (line.debit > 0) line.credit = 0; // تصفير الجانب الآخر
              onChanged();
            },
          ),
        ),
        const SizedBox(width: 8),
        
        // 4. الدائن
        Expanded(
          flex: 1,
          child: TextFormField(
            initialValue: line.credit == 0 ? '' : line.credit.toString(),
            readOnly: !canEdit,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: inputDecoration.copyWith(hintText: "0.0"),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            onChanged: (v) {
              line.credit = double.tryParse(v) ?? 0;
              if (line.credit > 0) line.debit = 0; // تصفير الجانب الآخر
              onChanged();
            },
          ),
        ),
        
        // 5. زر الحذف
        if (canEdit)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(LucideIcons.minusCircle, color: Colors.red, size: 22),
              onPressed: onRemove,
            ),
          ),
      ]),
    );
  }
}