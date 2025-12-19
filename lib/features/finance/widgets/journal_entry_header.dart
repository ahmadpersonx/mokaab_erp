//journal_entry_header.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_theme.dart';

class JournalEntryHeader extends StatelessWidget {
  final TextEditingController refController;
  final TextEditingController descController;
  final DateTime entryDate;
  final bool canEdit;
  final Function(DateTime) onDateChanged;

  const JournalEntryHeader({
    super.key,
    required this.refController,
    required this.descController,
    required this.entryDate,
    required this.canEdit,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.kDarkBrown, width: 1.5)),
      filled: true,
      fillColor: Colors.white,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: refController,
              readOnly: !canEdit,
              decoration: inputDecoration.copyWith(labelText: 'الرقم المرجعي', prefixIcon: const Icon(LucideIcons.bookmark, size: 18)),
            ),
          ),
          const SizedBox(width: 15),
          InkWell(
            onTap: !canEdit ? null : () async {
              final d = await showDatePicker(
                context: context,
                initialDate: entryDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.kDarkBrown)), child: child!),
              );
              if (d != null) onDateChanged(d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(LucideIcons.calendar, size: 18, color: AppTheme.kDarkBrown),
                const SizedBox(width: 10),
                Text(DateFormat('yyyy-MM-dd').format(entryDate), style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        TextFormField(
          controller: descController,
          readOnly: !canEdit,
          decoration: inputDecoration.copyWith(labelText: 'البيان العام', prefixIcon: const Icon(LucideIcons.fileText, size: 18)),
        ),
      ]),
    );
  }
}
