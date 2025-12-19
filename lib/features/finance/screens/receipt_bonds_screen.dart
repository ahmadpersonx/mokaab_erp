// FileName: lib/features/finance/screens/receipt_bonds_screen.dart
// Revision: 2.0 (Merged Real Logic with UI)
// Date: 2025-12-19

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/services/pdf_service.dart';
import '../../../../core/screens/pdf_preview_screen.dart';
import '../services/finance_service.dart';
import '../models/account_model.dart';
import 'smart_voucher_screen.dart';

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
              const SnackBar(content: Text('يرجى تحديد سندات أولاً للطباعة')),
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
            title: Text('طباعة الكل'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
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

class ReceiptBondsScreen extends StatefulWidget {
  const ReceiptBondsScreen({super.key});

  @override
  State<ReceiptBondsScreen> createState() => _ReceiptBondsScreenState();
}

class _ReceiptBondsScreenState extends State<ReceiptBondsScreen> {
  // Services
  final FinanceService _service = FinanceService();
  final PdfService _pdfService = PdfService();
  
  // Formatters
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  // State
  bool _isLoading = true;
  List<Map<String, dynamic>> _bonds = [];
  List<Map<String, dynamic>> _filteredBonds = [];
  List<AccountModel> _accounts = [];
  
  // Filters
  final Set<String> _selectedIds = {}; // استخدام رقم السند كمعرف
  DateTime? _fromDate;
  DateTime? _toDate;
  AccountModel? _selectedAccount;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // تحميل الحسابات للفلترة
      _accounts = await _service.getAllAccounts();
      
      // تحميل السندات
      await _loadBonds();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  Future<void> _loadBonds() async {
    try {
      final data = await _service.getVouchers(
        type: 'receipt', // تحديد النوع: قبض
        fromDate: _fromDate,
        toDate: _toDate,
      );

      if (mounted) {
        setState(() {
          _bonds = data;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      rethrow;
    }
  }

  void _applyFilters() {
    String query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredBonds = _bonds.where((v) {
        final number = v['voucher_number'].toString().toLowerCase();
        final desc = (v['description'] ?? '').toString().toLowerCase();
        final amount = v['amount'].toString();
        
        bool matchesQuery = number.contains(query) || desc.contains(query) || amount.contains(query);
        
        bool matchesAccount = true;
        if (_selectedAccount != null) {
          final lines = v['voucher_lines'] as List;
          matchesAccount = lines.any((line) => line['account_id'] == _selectedAccount!.id);
        }

        return matchesQuery && matchesAccount;
      }).toList();
    });
  }

  // منطق الطباعة الحقيقي
  void _executePrint({required bool onlySelected}) {
    List<Map<String, dynamic>> toPrint = [];
    String titleSuffix = "";

    if (onlySelected) {
      toPrint = _filteredBonds.where((v) => _selectedIds.contains(v['voucher_number'].toString())).toList();
      titleSuffix = "(محدد)";
    } else {
      toPrint = _filteredBonds;
    }

    if (toPrint.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لا توجد بيانات للطباعة")));
      return;
    }

    List<List<String>> data = toPrint.map((v) => <String>[
      _currencyFormat.format((v['amount'] as num?)?.toDouble() ?? 0.0),
      v['payment_method'] == 'check' ? 'شيك' : 'نقدي',
      v['description'] ?? '',
      v['date'].toString().split(' ')[0],
      v['voucher_number'].toString(),
    ]).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          title: "تقرير سندات القبض $titleSuffix",
          buildPdf: (format) => _pdfService.generateListReport(
            format,
            title: "تقرير سندات القبض $titleSuffix",
            headers: ['المبلغ', 'الدفع', 'البيان', 'التاريخ', 'رقم السند'],
            data: data,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("سندات القبض"),
        centerTitle: true,
        backgroundColor: const Color(0xFF388E3C),
        foregroundColor: Colors.white,
        actions: [
          PrintActionMenu(
            onPrintFull: () => _executePrint(onlySelected: false),
            onPrintSelected: () => _executePrint(onlySelected: true),
            isSelectionEmpty: _selectedIds.isEmpty,
          ),
          IconButton(
            icon: const Icon(LucideIcons.rotateCw),
            onPressed: _loadBonds,
            tooltip: 'تحديث',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          _buildSummarySection(),
          const Divider(height: 1),
          Expanded(child: _buildBondsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SmartVoucherScreen(voucherType: 'receipt'),
            ),
          );
          _loadBonds();
        },
        backgroundColor: const Color(0xFF388E3C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        children: [
          // حقل البحث النصي
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'بحث برقم السند، الوصف...',
              prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              isDense: true,
            ),
            onChanged: (val) => _applyFilters(),
          ),
          const SizedBox(height: 10),
          // قائمة الحسابات
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AccountModel>(
                isExpanded: true,
                hint: const Text("تصفية حسب العميل / الحساب"),
                value: _selectedAccount,
                items: _accounts.map((e) => DropdownMenuItem(
                  value: e, 
                  child: Text("${e.code} - ${e.nameAr}", overflow: TextOverflow.ellipsis)
                )).toList(),
                onChanged: (v) {
                  setState(() => _selectedAccount = v);
                  _applyFilters();
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          // التاريخ
          Row(
            children: [
              Expanded(
                child: _buildDateButton('من تاريخ', _fromDate, (d) {
                   setState(() => _fromDate = d);
                   _loadBonds();
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDateButton('إلى تاريخ', _toDate, (d) {
                   setState(() => _toDate = d);
                   _loadBonds();
                }),
              ),
              if (_fromDate != null || _toDate != null || _selectedAccount != null)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _fromDate = null;
                      _toDate = null;
                      _selectedAccount = null;
                      _searchController.clear();
                    });
                    _loadBonds();
                  },
                )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context, initialDate: DateTime.now(), 
          firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (picked != null) onSelect(picked);
      },
      child: Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date != null ? _dateFormat.format(date) : label,
              style: TextStyle(color: date != null ? Colors.black : Colors.grey.shade600, fontSize: 13),
            ),
            const Icon(LucideIcons.calendar, size: 18, color: Color(0xFF388E3C)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    double total = _filteredBonds.fold(0, (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      color: const Color(0xFFE8F5E9), // خلفية خضراء فاتحة
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("إجمالي المقبوضات:", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            '${_currencyFormat.format(total)} د.أ',
            style: const TextStyle(color: Color(0xFF388E3C), fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildBondsList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF388E3C)));
    if (_filteredBonds.isEmpty) return const Center(child: Text("لا توجد سندات"));

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _filteredBonds.length,
      itemBuilder: (context, index) {
        final bond = _filteredBonds[index];
        final String voucherNo = bond['voucher_number'].toString();
        final bool isSelected = _selectedIds.contains(voucherNo);
        
        // استخراج اسم العميل/الحساب من الأسطر
        final lines = bond['voucher_lines'] as List;
        String accountName = lines.isNotEmpty && lines[0]['accounts'] != null 
            ? lines[0]['accounts']['name_ar'] 
            : 'غير محدد';

        return Card(
          elevation: 2,
          color: isSelected ? Colors.green.withOpacity(0.05) : Colors.white,
          shape: RoundedRectangleBorder(
            side: isSelected ? const BorderSide(color: Colors.green, width: 1.5) : BorderSide.none,
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            leading: Checkbox(
              value: isSelected,
              activeColor: const Color(0xFF388E3C),
              onChanged: (val) {
                setState(() {
                  if (val == true) _selectedIds.add(voucherNo);
                  else _selectedIds.remove(voucherNo);
                });
              },
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('سند #$voucherNo', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${_currencyFormat.format(bond['amount'])} د.أ',
                  style: const TextStyle(color: Color(0xFF388E3C), fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.user, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(accountName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      bond['date'].toString().split(' ')[0],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (bond['payment_method'] == 'check') ...[
                       const SizedBox(width: 10),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                         decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(4)),
                         child: const Text('شيك', style: TextStyle(fontSize: 10, color: Colors.brown)),
                       )
                    ]
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () async {
              // فتح للتعديل في وضع التحديد نلغي التحديد، وإلا نفتح التفاصيل
              if (_selectedIds.isNotEmpty) {
                 setState(() {
                  if (isSelected) _selectedIds.remove(voucherNo);
                  else _selectedIds.add(voucherNo);
                });
              } else {
                 await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SmartVoucherScreen(
                      voucherType: 'receipt',
                      voucherNumber: voucherNo,
                    ),
                  ),
                );
                _loadBonds();
              }
            },
          ),
        );
      },
    );
  }
}