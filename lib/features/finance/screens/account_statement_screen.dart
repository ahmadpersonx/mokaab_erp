// FileName: lib/features/finance/screens/account_statement_screen.dart
// Revision: 2.3 (Fixed PopupMenuDivider & Excel Service Call)
// Date: 2025-12-19

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/services/excel_service.dart'; // ✅ استيراد خدمة الإكسل
import '../models/account_model.dart';
import '../services/finance_service.dart';
import 'smart_voucher_screen.dart'; 
import 'add_journal_entry_screen.dart';

// --- Shared Component: Print Action Menu ---
class PrintActionMenu extends StatelessWidget {
  final VoidCallback onPrintFull;
  final VoidCallback onPrintSelected;
  final bool isSelectionEmpty;
  final Color iconColor;

  const PrintActionMenu({
    super.key,
    required this.onPrintFull,
    required this.onPrintSelected,
    this.isSelectionEmpty = true,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(LucideIcons.printer, color: iconColor),
      tooltip: 'خيارات الطباعة',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (String value) {
        if (value == 'full') {
          onPrintFull();
        } else if (value == 'selected') {
          if (isSelectionEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('يرجى تحديد عناصر أولاً للطباعة')),
            );
          } else {
            onPrintSelected();
          }
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'full',
          child: ListTile(
            leading: Icon(LucideIcons.fileText, color: Colors.blue),
            title: Text('طباعة الكشف كامل'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        // ✅ تصحيح الخطأ: تغيير PopupDivider إلى PopupMenuDivider
        const PopupMenuDivider(), 
        PopupMenuItem<String>(
          value: 'selected',
          enabled: !isSelectionEmpty,
          child: ListTile(
            leading: Icon(LucideIcons.checkSquare, 
              color: isSelectionEmpty ? Colors.grey : Colors.green),
            title: Text(
              'طباعة المحدد',
              style: TextStyle(color: isSelectionEmpty ? Colors.grey : null),
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
    );
  }
}

class AccountStatementScreen extends StatefulWidget {
  const AccountStatementScreen({super.key});

  @override
  State<AccountStatementScreen> createState() => _AccountStatementScreenState();
}

class _AccountStatementScreenState extends State<AccountStatementScreen> {
  final FinanceService _service = FinanceService();
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  bool _isLoading = false;
  bool _isSearching = false;
  
  List<AccountModel> _accounts = [];
  AccountModel? _selectedAccount;
  List<Map<String, dynamic>> _transactions = [];
  final Set<String> _selectedIds = {}; 

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  
  double _totalDebit = 0;
  double _totalCredit = 0;
  double _balance = 0;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    try {
      final accounts = await _service.getAllAccounts();
      final subAccounts = accounts.where((a) => !a.isParent).toList();
      
      if (mounted) {
        setState(() {
          _accounts = subAccounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showMsg('خطأ في تحميل الحسابات: $e');
    }
  }

  // دالة تصدير البيانات إلى ملف Excel
  Future<void> _exportToExcel() async {
    if (_transactions.isEmpty) {
      _showMsg("لا توجد بيانات لتصديرها");
      return;
    }

    setState(() => _isLoading = true);
    try {
      // ✅ ملاحظة: تأكد أن ExcelService يحتوي على ميثود static أو قم بإنشاء instance صحيح
      final excel = ExcelService();
      
      await excel.exportAccountStatement(
        accountName: _selectedAccount?.nameAr ?? '',
        accountCode: _selectedAccount?.code ?? '',
        fromDate: _fromDate,
        toDate: _toDate,
        transactions: _transactions,
        totalDebit: _totalDebit,
        totalCredit: _totalCredit,
        finalBalance: _balance,
      );

      _showMsg("تم تصدير الملف بنجاح");
    } catch (e) {
      _showMsg("خطأ أثناء التصدير: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _search() async {
    if (_selectedAccount == null) {
      _showMsg('الرجاء اختيار حساب أولاً');
      return;
    }

    setState(() {
      _isSearching = true;
      _selectedIds.clear();
    });

    try {
      final data = await _service.getJournalEntriesSummary(
        accountId: _selectedAccount!.id.toString(),
        fromDate: _fromDate,
        toDate: _toDate,
      );

      double tDebit = 0;
      double tCredit = 0;
      double runningBalance = 0;
      List<Map<String, dynamic>> processedData = [];
      
      final sortedData = List<Map<String, dynamic>>.from(data);
      sortedData.sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

      for (var item in sortedData) {
        double debit = (item['debit'] as num).toDouble();
        double credit = (item['credit'] as num).toDouble();
        
        tDebit += debit;
        tCredit += credit;
        runningBalance += (debit - credit);

        processedData.add({
          ...item,
          'running_balance': runningBalance,
        });
      }

      processedData = processedData.reversed.toList();

      if (mounted) {
        setState(() {
          _transactions = processedData;
          _totalDebit = tDebit;
          _totalCredit = tCredit;
          _balance = runningBalance;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        _showMsg('خطأ في جلب البيانات: $e');
      }
    }
  }

  void _openTransactionDetails(Map<String, dynamic> transaction) {
    String systemNumber = transaction['id'].toString(); 

    if (systemNumber.startsWith('RV')) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => SmartVoucherScreen(voucherType: 'receipt', voucherNumber: systemNumber)));
    } else if (systemNumber.startsWith('PV')) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => SmartVoucherScreen(voucherType: 'payment', voucherNumber: systemNumber)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => AddJournalEntryScreen(entryNumber: systemNumber)));
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.kDarkBrown),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _fromDate = picked; else _toDate = picked;
      });
    }
  }

  void _showMsg(String txt) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(txt)));

  void _handlePrint(bool onlySelected) {
    int count = onlySelected ? _selectedIds.length : _transactions.length;
    String accountName = _selectedAccount?.nameAr ?? "غير محدد";
    _showMsg("جاري تجهيز طباعة $count حركة للحساب: $accountName");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        title: const Text('كشف حساب', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00695C), 
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.fileOutput, color: Colors.white),
            tooltip: 'تصدير إكسل',
            onPressed: _transactions.isEmpty ? null : _exportToExcel,
          ),
          PrintActionMenu(
            onPrintFull: () => _handlePrint(false),
            onPrintSelected: () => _handlePrint(true),
            isSelectionEmpty: _selectedIds.isEmpty,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                DropdownButtonFormField<AccountModel>(
                  value: _selectedAccount,
                  decoration: const InputDecoration(
                    labelText: 'اختر الحساب',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(LucideIcons.user),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  items: _accounts.map((acc) {
                    return DropdownMenuItem(
                      value: acc,
                      child: Text("${acc.code} - ${acc.nameAr}", overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedAccount = val),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'من تاريخ',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(LucideIcons.calendar),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          child: Text(_dateFormat.format(_fromDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'إلى تاريخ',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(LucideIcons.calendar),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          child: Text(_dateFormat.format(_toDate)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00695C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _isSearching ? null : _search,
                    icon: _isSearching 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : const Icon(LucideIcons.search),
                    label: Text(_isSearching ? "جاري البحث..." : "عرض التقرير"),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty && !_isSearching
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.fileSearch, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text(
                          _selectedAccount == null ? "اختر حساباً لعرض الكشف" : "لا توجد حركات في هذه الفترة",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1), 
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryItem("مجموع مدين", _totalDebit, Colors.green),
                            Container(width: 1, height: 30, color: Colors.teal.shade200),
                            _buildSummaryItem("مجموع دائن", _totalCredit, Colors.red),
                            Container(width: 1, height: 30, color: Colors.teal.shade200),
                            _buildSummaryItem("الرصيد", _balance, Colors.blue),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: Colors.grey[200],
                        child: const Row(
                          children: [
                            SizedBox(width: 40), 
                            Expanded(flex: 2, child: Text("التاريخ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(flex: 3, child: Text("رقم القيد/البيان", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(child: Text("مدين", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(child: Text("دائن", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(child: Text("رصيد", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: _transactions.length,
                          separatorBuilder: (c, i) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _transactions[index];
                            final String transId = item['id'].toString();
                            final isSelected = _selectedIds.contains(transId);
                            
                            final debit = (item['debit'] as num).toDouble();
                            final credit = (item['credit'] as num).toDouble();
                            final balance = (item['running_balance'] as num).toDouble();

                            return InkWell(
                              onTap: () => _openTransactionDetails(item),
                              child: Container(
                                color: isSelected ? Colors.teal.withOpacity(0.1) : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      activeColor: Colors.teal,
                                      visualDensity: VisualDensity.compact,
                                      onChanged: (v) {
                                        setState(() {
                                          if (v == true) _selectedIds.add(transId);
                                          else _selectedIds.remove(transId);
                                        });
                                      },
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        _dateFormat.format(DateTime.parse(item['date'])),
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(transId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          Text(
                                            item['description'] ?? '', 
                                            maxLines: 1, 
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(child: Text(debit > 0 ? _currencyFormat.format(debit) : '-', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                    Expanded(child: Text(credit > 0 ? _currencyFormat.format(credit) : '-', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                    Expanded(child: Text(_currencyFormat.format(balance), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(
          _currencyFormat.format(value),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}