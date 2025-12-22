// FileName: lib/features/finance/widgets/journal_entry_row.dart
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/models/account.dart';
import '../models/cost_center_model.dart';
import '../models/journal_entry_model.dart'; // لاستيراد JournalLineModel

class JournalEntryRow extends StatelessWidget {
  final JournalLineModel line;
  final List<Account> accounts;
  final List<CostCenterModel> costCenters;
  final Function(JournalLineModel) onChanged;
  final VoidCallback onDelete;

  const JournalEntryRow({
    super.key,
    required this.line,
    required this.accounts,
    required this.costCenters,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Helper to find selected account safely
    Account? selectedAccount = accounts.any((a) => a.id == line.accountId) 
        ? accounts.firstWhere((a) => a.id == line.accountId) 
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Account Dropdown
              Expanded(
                flex: 3,
                child: DropdownSearch<Account>(
                  items: (f, ls) => accounts, // Simple list return for DropdownSearch v9+
                  itemAsString: (a) => "${a.code} - ${a.nameAr}",
                  compareFn: (i, s) => i.id == s?.id,
                  selectedItem: selectedAccount,
                  onChanged: (val) {
                    if (val != null) {
                      onChanged(JournalLineModel(
                        id: line.id,
                        accountId: val.id,
                        accountName: val.nameAr,
                        debit: line.debit,
                        credit: line.credit,
                        description: line.description,
                        costCenterId: line.costCenterId,
                      ));
                    }
                  },
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(decoration: InputDecoration(hintText: "بحث...", isDense: true)),
                  ),
                  decoratorProps: const DropDownDecoratorProps(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. Debit
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: line.debit?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, hintText: '0.0'),
                  onChanged: (val) {
                    onChanged(JournalLineModel(
                      id: line.id,
                      accountId: line.accountId,
                      debit: double.tryParse(val) ?? 0.0,
                      credit: 0.0, // تصفير الطرف الآخر
                      description: line.description,
                      costCenterId: line.costCenterId,
                    ));
                  },
                ),
              ),
              const SizedBox(width: 8),

              // 3. Credit
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: line.credit?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, hintText: '0.0'),
                  onChanged: (val) {
                    onChanged(JournalLineModel(
                      id: line.id,
                      accountId: line.accountId,
                      debit: 0.0, // تصفير الطرف الآخر
                      credit: double.tryParse(val) ?? 0.0,
                      description: line.description,
                      costCenterId: line.costCenterId,
                    ));
                  },
                ),
              ),
              
              // 4. Delete Button
              IconButton(
                icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
          
          // Row 2: Description & Cost Center (Optional)
          if (selectedAccount != null && selectedAccount.requireCostCenter)
             Padding(
               padding: const EdgeInsets.only(top: 8.0),
               child: Row(
                 children: [
                   Expanded(
                     child: TextFormField(
                       initialValue: line.description,
                       decoration: const InputDecoration(labelText: "بيان السطر", isDense: true, border: OutlineInputBorder()),
                       onChanged: (val) {
                          onChanged(JournalLineModel(
                            id: line.id, accountId: line.accountId, debit: line.debit, credit: line.credit,
                            description: val, costCenterId: line.costCenterId
                          ));
                       },
                     ),
                   ),
                   const SizedBox(width: 10),
                   Expanded(
                     child: DropdownButtonFormField<int>(
                       value: line.costCenterId,
                       decoration: const InputDecoration(labelText: "مركز التكلفة", isDense: true, border: OutlineInputBorder()),
                       items: costCenters.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                       onChanged: (val) {
                          onChanged(JournalLineModel(
                            id: line.id, accountId: line.accountId, debit: line.debit, credit: line.credit,
                            description: line.description, costCenterId: val
                          ));
                       },
                     ),
                   ),
                 ],
               ),
             )
        ],
      ),
    );
  }
}