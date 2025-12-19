//check_details_section.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CheckDetailsSection extends StatelessWidget {
  final TextEditingController checkNoController;
  final DateTime checkDueDate;
  final int? selectedBankId;
  final List<Map<String, dynamic>> banksList;
  
  // ✅ 1. المتغير الجديد
  final bool isReadOnly; 
  
  final Function(DateTime) onDueDateChanged;
  final Function(int?) onBankChanged;
  final VoidCallback onManageBanks;

  const CheckDetailsSection({
    super.key,
    required this.checkNoController,
    required this.checkDueDate,
    required this.selectedBankId,
    required this.banksList,
    
    // ✅ 2. إضافته للمنشئ
    this.isReadOnly = false,
    
    required this.onDueDateChanged,
    required this.onBankChanged,
    required this.onManageBanks,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade200)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("بيانات الشيك", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.brown)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: checkNoController,
                readOnly: isReadOnly, // ✅ جعل الحقل للقراءة فقط
                decoration: const InputDecoration(labelText: 'رقم الشيك', isDense: true, border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: isReadOnly ? null : () async { // ✅ تعطيل النقر
                  final d = await showDatePicker(context: context, initialDate: checkDueDate, firstDate: DateTime.now(), lastDate: DateTime(2100));
                  if (d != null) onDueDateChanged(d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'تاريخ الاستحقاق', isDense: true, border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                  child: Text(DateFormat('yyyy-MM-dd').format(checkDueDate)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: selectedBankId,
                decoration: const InputDecoration(labelText: 'اسم البنك', isDense: true, border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                items: banksList.map((bank) => DropdownMenuItem(value: bank['id'] as int, child: Text(bank['name']))).toList(),
                onChanged: isReadOnly ? null : onBankChanged, // ✅ تعطيل التغيير
              ),
            ),
            if (!isReadOnly) ...[ // ✅ إخفاء زر الإعدادات
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                child: IconButton(icon: const Icon(LucideIcons.settings, color: Colors.grey), tooltip: "إدارة قائمة البنوك", onPressed: onManageBanks),
              ),
            ]
          ]),
        ]),
      ),
    ]);
  }
}
