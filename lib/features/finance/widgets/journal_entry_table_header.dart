//lib\features\finance\widgets\journal_entry_table_header.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';

class JournalEntryTableHeader extends StatelessWidget {
  const JournalEntryTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.kDarkBrown.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(children: const [
        Expanded(flex: 3, child: Text("الحساب", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        SizedBox(width: 8),
        Expanded(flex: 3, child: Text("البيان / م.تكلفة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        SizedBox(width: 8),
        Expanded(flex: 1, child: Text("مدين", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        SizedBox(width: 8),
        Expanded(flex: 1, child: Text("دائن", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        SizedBox(width: 32),
      ]),
    );
  }
}