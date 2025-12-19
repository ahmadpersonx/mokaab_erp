// FileName: lib/features/finance/screens/payment_bonds_screen.dart
// Revision: 2.0 (Merged Real Logic with UI)
// Date: 2025-12-19

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/services/pdf_service.dart';
import '../../../../core/screens/pdf_preview_screen.dart';
import '../services/finance_service.dart';
import '../models/account_model.dart';
import 'smart_voucher_screen.dart';

// --- Shared Print Component (Reusable) ---
class PrintActionMenu extends StatelessWidget {
  final VoidCallback onPrintFull;
  final VoidCallback onPrintSelected;
  final bool isSelectionEmpty;
  final Color iconColor;
  const PrintActionMenu({super.key, required this.onPrintFull, required this.onPrintSelected, this.isSelectionEmpty = true, this.iconColor = Colors.white});
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(LucideIcons.printer, color: iconColor),
      onSelected: (v) => v == 'full' ? onPrintFull() : (isSelectionEmpty ? null : onPrintSelected()),
      itemBuilder: (c) => [
        const PopupMenuItem(value: 'full', child: Text('طباعة الكل')),
        PopupMenuItem(value: 'selected', enabled: !isSelectionEmpty, child: Text('طباعة المحدد')),
      ],
    );
  }
}

class PaymentBondsScreen extends StatefulWidget {
  const PaymentBondsScreen({super.key});

  @override
  State<PaymentBondsScreen> createState() => _PaymentBondsScreenState();
}

class _PaymentBondsScreenState extends State<PaymentBondsScreen> {
  final FinanceService _service = FinanceService();
  final PdfService _pdfService = PdfService();
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  bool _isLoading = true;
  List<Map<String, dynamic>> _bonds = [];
  List<Map<String, dynamic>> _filteredBonds = [];
  List<AccountModel> _accounts = [];
  
  final Set<String> _selectedIds = {};
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
      _accounts = await _service.getAllAccounts();
      await _loadBonds();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBonds() async {
    try {
      final data = await _service.getVouchers(
        type: 'payment', // تحديد النوع: صرف
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

  void _executePrint({required bool onlySelected}) {
    List<Map<String, dynamic>> toPrint = onlySelected 
        ? _filteredBonds.where((v) => _selectedIds.contains(v['voucher_number'].toString())).toList()
        : _filteredBonds;

    if (toPrint.isEmpty) return;

    List<List<String>> data = toPrint.map((v) => <String>[
      _currencyFormat.format((v['amount'] as num?)?.toDouble() ?? 0.0),
      v['payment_method'] == 'check' ? 'شيك' : 'نقدي',
      v['description'] ?? '',
      v['date'].toString().split(' ')[0],
      v['voucher_number'].toString(),
    ]).toList();

    Navigator.push(context, MaterialPageRoute(builder: (c) => PdfPreviewScreen(
      title: "تقرير سندات الصرف",
      buildPdf: (f) => _pdfService.generateListReport(f, title: "تقرير سندات الصرف", headers: ['المبلغ', 'الدفع', 'البيان', 'التاريخ', 'رقم السند'], data: data),
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("سندات الصرف"),
        centerTitle: true,
        backgroundColor: const Color(0xFFD32F2F), // لون أحمر
        foregroundColor: Colors.white,
        actions: [
          PrintActionMenu(
            onPrintFull: () => _executePrint(onlySelected: false),
            onPrintSelected: () => _executePrint(onlySelected: true),
            isSelectionEmpty: _selectedIds.isEmpty,
          ),
          IconButton(icon: const Icon(LucideIcons.rotateCw), onPressed: _loadBonds),
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
          await Navigator.push(context, MaterialPageRoute(builder: (c) => const SmartVoucherScreen(voucherType: 'payment')));
          _loadBonds();
        },
        backgroundColor: const Color(0xFFD32F2F),
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
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'بحث...',
              prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
              filled: true, fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0), isDense: true,
            ),
            onChanged: (val) => _applyFilters(),
          ),
          const SizedBox(height: 10),
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AccountModel>(
                isExpanded: true,
                hint: const Text("تصفية حسب المورد / المستفيد"),
                value: _selectedAccount,
                items: _accounts.map((e) => DropdownMenuItem(value: e, child: Text("${e.code} - ${e.nameAr}", overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) { setState(() => _selectedAccount = v); _applyFilters(); },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildDateButton('من تاريخ', _fromDate, (d) { setState(() => _fromDate = d); _loadBonds(); })),
              const SizedBox(width: 10),
              Expanded(child: _buildDateButton('إلى تاريخ', _toDate, (d) { setState(() => _toDate = d); _loadBonds(); })),
              if (_fromDate != null || _toDate != null || _selectedAccount != null)
                 IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () { setState(() { _fromDate = null; _toDate = null; _selectedAccount = null; _searchController.clear(); }); _loadBonds(); })
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (picked != null) onSelect(picked);
      },
      child: Container(
        height: 45, padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(25)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(date != null ? _dateFormat.format(date) : label, style: TextStyle(color: date != null ? Colors.black : Colors.grey.shade600, fontSize: 13)),
            const Icon(LucideIcons.calendar, size: 18, color: Color(0xFFD32F2F)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    double total = _filteredBonds.fold(0, (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0));
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      color: const Color(0xFFFFEBEE),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("إجمالي المدفوعات:", style: TextStyle(fontWeight: FontWeight.bold)),
          Text('${_currencyFormat.format(total)} د.أ', style: const TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildBondsList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)));
    if (_filteredBonds.isEmpty) return const Center(child: Text("لا توجد سندات"));

    return ListView.builder(
      padding: const EdgeInsets.all(10), itemCount: _filteredBonds.length,
      itemBuilder: (context, index) {
        final bond = _filteredBonds[index];
        final String voucherNo = bond['voucher_number'].toString();
        final bool isSelected = _selectedIds.contains(voucherNo);
        final lines = bond['voucher_lines'] as List;
        String beneficiary = lines.isNotEmpty && lines[0]['accounts'] != null ? lines[0]['accounts']['name_ar'] : 'غير محدد';

        return Card(
          elevation: 2, color: isSelected ? Colors.red.withOpacity(0.05) : Colors.white,
          shape: RoundedRectangleBorder(side: isSelected ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none, borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Checkbox(value: isSelected, activeColor: const Color(0xFFD32F2F), onChanged: (v) => setState(() => v == true ? _selectedIds.add(voucherNo) : _selectedIds.remove(voucherNo))),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('سند #$voucherNo', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${_currencyFormat.format(bond['amount'])} د.أ', style: const TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
              ],
            ),
            subtitle: Text("المستفيد: $beneficiary\nالتاريخ: ${bond['date'].toString().split(' ')[0]}"),
            onTap: () async {
              if (_selectedIds.isNotEmpty) {
                 setState(() => isSelected ? _selectedIds.remove(voucherNo) : _selectedIds.add(voucherNo));
              } else {
                 await Navigator.push(context, MaterialPageRoute(builder: (c) => SmartVoucherScreen(voucherType: 'payment', voucherNumber: voucherNo)));
                 _loadBonds();
              }
            },
          ),
        );
      },
    );
  }
}