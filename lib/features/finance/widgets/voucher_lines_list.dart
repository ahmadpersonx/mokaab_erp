//voucher_lines_list.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dropdown_search/dropdown_search.dart';

// ✅✅✅ تصحيح المسارات (3 خطوات للخلف بدلاً من 2)
import '../../../core/models/account.dart';
import '../models/cost_center_model.dart';

class VoucherLinesList extends StatelessWidget {
  final List<Map<String, dynamic>> lines;
  final List<Account> accountsList;
  final List<CostCenterModel> costCentersList;
  final bool isReadOnly; 
  final Function(int, Account?) onAccountChanged;
  final Function(int, String) onAmountChanged;
  final Function(int, CostCenterModel?) onCostCenterChanged;
  final Function(int) onDeleteLine;
  final VoidCallback onAddLine;
  final Color themeColor;

  const VoucherLinesList({
    super.key,
    required this.lines,
    required this.accountsList,
    required this.costCentersList,
    this.isReadOnly = false, 
    required this.onAccountChanged,
    required this.onAmountChanged,
    required this.onCostCenterChanged,
    required this.onDeleteLine,
    required this.onAddLine,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(children: [
        _buildHeader(),
        Expanded(
          child: ListView.separated(
            itemCount: lines.length,
            separatorBuilder: (c, i) => const Divider(height: 1),
            itemBuilder: (c, i) => _buildRow(i),
          ),
        ),
        if (!isReadOnly) 
          TextButton.icon(onPressed: onAddLine, icon: const Icon(LucideIcons.plusCircle), label: const Text("إضافة حساب آخر"), style: TextButton.styleFrom(foregroundColor: themeColor)),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(padding: const EdgeInsets.all(10), color: Colors.grey.shade100, child: Row(children: const [Expanded(flex: 3, child: Text("الحساب المقابل (عميل/مورد/إيراد)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))), SizedBox(width: 5), Expanded(flex: 2, child: Text("المبلغ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))), SizedBox(width: 5), Expanded(flex: 2, child: Text("مركز التكلفة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))), SizedBox(width: 30)]));
  }

  Widget _buildRow(int i) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 3,
          child: DropdownSearch<Account>(
            enabled: !isReadOnly, 
            items: (f, l) => accountsList,
            itemAsString: (a) => a.nameAr ?? '',
            compareFn: (item, selectedItem) => item.code == selectedItem?.code,
            selectedItem: lines[i]['account'],
            onChanged: (val) => onAccountChanged(i, val),
            popupProps: const PopupProps.menu(showSearchBox: true),
            decoratorProps: const DropDownDecoratorProps(decoration: InputDecoration(hintText: "اختر الحساب", isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12))),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          flex: 2,
          child: TextFormField(
            initialValue: lines[i]['amount'].toString(),
            readOnly: isReadOnly, 
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "0.00", isDense: true, border: OutlineInputBorder()),
            onChanged: (v) => onAmountChanged(i, v),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<CostCenterModel>(
            initialValue: lines[i]['cost_center'],
            items: costCentersList.map((c) => DropdownMenuItem(value: c, child: Text(c.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
            onChanged: isReadOnly ? null : (v) => onCostCenterChanged(i, v), 
            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), hintText: "بلا", contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
          ),
        ),
        if (!isReadOnly) 
          IconButton(icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 20), onPressed: () => onDeleteLine(i)),
      ]),
    );
  }
}