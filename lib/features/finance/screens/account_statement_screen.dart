// FileName: lib/features/finance/screens/account_statement_screen.dart
// Revision: 2.0 (Updated to use JournalEntryModel)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_theme.dart';
import '../services/finance_service.dart';
import '../../../core/models/account.dart';
import '../models/journal_entry_model.dart'; // استيراد الموديل

class AccountStatementScreen extends StatefulWidget {
  final Account? initialAccount;

  const AccountStatementScreen({super.key, this.initialAccount});

  @override
  State<AccountStatementScreen> createState() => _AccountStatementScreenState();
}

class _AccountStatementScreenState extends State<AccountStatementScreen> {
  final FinanceService _service = FinanceService();
  final NumberFormat _currency = NumberFormat.currency(symbol: '', decimalDigits: 2);
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  List<JournalEntryModel> _entries = []; // استخدام الموديل
  bool _isLoading = false;
  
  Account? _selectedAccount;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _selectedAccount = widget.initialAccount;
    if (_selectedAccount != null) {
      _loadStatement();
    }
  }

  Future<void> _loadStatement() async {
    if (_selectedAccount == null) return;
    
    setState(() => _isLoading = true);
    try {
      // هنا نفترض أن السيرفس لديها دالة لجلب حركات حساب معين، أو نستخدم الفلترة
      // للتبسيط سنستخدم getFilteredJournalEntries ونقوم بالفلترة محلياً (أو نعدل السيرفس)
      // الأفضل إضافة دالة getAccountStatement في السيرفس، لكن سنستخدم المتاح حالياً
      
      final allEntries = await _service.getFilteredJournalEntries(
        from: _fromDate,
        to: _toDate,
      );

      // تصفية القيود التي تحتوي على الحساب المحدد
      final accountEntries = allEntries.where((entry) {
        return entry.lines.any((line) => line.accountId == _selectedAccount!.id);
      }).toList();

      setState(() {
        _entries = accountEntries;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("كشف حساب"),
        backgroundColor: AppTheme.kDarkBrown,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Section (Simplified)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      // Account Picker logic here
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300)),
                      child: Text(
                        _selectedAccount?.nameAr ?? "اختر حساب...",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(LucideIcons.search),
                  onPressed: _loadStatement,
                  style: IconButton.styleFrom(backgroundColor: AppTheme.kDarkBrown, foregroundColor: Colors.white),
                )
              ],
            ),
          ),

          // Statement List
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _entries.length,
                    separatorBuilder: (c, i) => const Divider(),
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      // العثور على السطر الخاص بهذا الحساب
                      final line = entry.lines.firstWhere((l) => l.accountId == _selectedAccount?.id, orElse: () => entry.lines.first);
                      
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Text(_dateFormat.format(entry.entryDate), style: const TextStyle(fontSize: 12)),
                        title: Text(line.description ?? entry.description ?? '-'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if ((line.debit ?? 0) > 0)
                              Text("مدين: ${_currency.format(line.debit)}", style: const TextStyle(color: Colors.green, fontSize: 12)),
                            if ((line.credit ?? 0) > 0)
                              Text("دائن: ${_currency.format(line.credit)}", style: const TextStyle(color: Colors.red, fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}