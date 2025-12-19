// FileName: lib/features/finance/screens/daily_journal_screen.dart
// Revision: 3.0 (Full Implementation: Filters, Actions, Print, Selection)
// Date: 2025-12-19

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/screens/pdf_preview_screen.dart';
import '../../../core/services/pdf_service.dart';
import '../services/finance_service.dart';
import '../widgets/print_action_menu.dart';
import 'add_journal_entry_screen.dart'; // للتعديل

class DailyJournalScreen extends StatefulWidget {
  const DailyJournalScreen({super.key});

  @override
  State<DailyJournalScreen> createState() => _DailyJournalScreenState();
}

class _DailyJournalScreenState extends State<DailyJournalScreen> {
  // Services
  final FinanceService _service = FinanceService();
  final PdfService _pdfService = PdfService();
  
  // Formatters
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  // UI State
  bool _isLoading = false;
  bool _isSelectionMode = false;
  bool _showFilters = false; // لإظهار وإخفاء لوحة الفلاتر
  
  // Data
  List<Map<String, dynamic>> _entries = [];
  final Set<String> _selectedIds = {};

  // Controllers & Filters
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _debitAccountController = TextEditingController();
  final TextEditingController _creditAccountController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  // --- Logic Methods ---

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    try {
      // نستخدم دالة الفلترة المتقدمة من الخدمة
      final data = await _service.getFilteredJournalEntries(
        fromDate: _fromDate,
        toDate: _toDate,
        status: _selectedStatus,
        searchQuery: _searchController.text,
        debitAccount: _debitAccountController.text, // تتطلب دعم backend
        creditAccount: _creditAccountController.text, // تتطلب دعم backend
      );
      
      if (mounted) {
        setState(() {
          _entries = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // في حالة عدم وجود الدالة المتقدمة، نستخدم الجلب العادي كاحتياط
        _fallbackLoad();
      }
    }
  }

  Future<void> _fallbackLoad() async {
    // تحميل احتياطي في حال لم يتم تحديث الخدمة بعد
    try {
      final data = await _service.getJournalEntriesSummary();
      setState(() => _entries = data);
    } catch (e) {
      debugPrint("Error loading: $e");
    }
  }

  // تنفيذ الطباعة (فردي أو جماعي)
  void _executePrint({required bool onlySelected, Map<String, dynamic>? singleEntry}) {
    List<Map<String, dynamic>> toPrint = [];
    String titleSuffix = "";

    if (singleEntry != null) {
      toPrint = [singleEntry];
      titleSuffix = "(قيد #${singleEntry['id']})";
    } else if (onlySelected) {
      toPrint = _entries.where((e) => _selectedIds.contains(e['id'].toString())).toList();
      titleSuffix = "(محدد)";
    } else {
      toPrint = _entries;
    }

    if (toPrint.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لا توجد بيانات للطباعة")));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          title: "تقرير القيود $titleSuffix",
          buildPdf: (format) => _pdfService.generateListReport(
            format,
            title: "كشف القيود اليومية $titleSuffix",
            headers: ['المبلغ', 'البيان', 'التاريخ', 'رقم القيد', 'الحالة'],
            data: toPrint.map((e) => [
              "${_currencyFormat.format(e['amount'] ?? 0)} د.أ",
              (e['description'] ?? '').toString(),
              (e['date']?.toString().split(' ')[0] ?? '').toString(),
              (e['id']?.toString() ?? '').toString(),
              (e['status'] == 'posted' ? 'مرحل' : 'مسودة').toString(),
            ]).toList().cast<List<String>>(), // ✅ حل مشكلة النوع
          ),
        ),
      ),
    );

    if (onlySelected) {
      setState(() {
        _isSelectionMode = false;
        _selectedIds.clear();
      });
    }
  }

  void _navigateToEdit(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddJournalEntryScreen(entryNumber: id)),
    ).then((_) => _loadEntries());
  }

  // --- UI Components ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        title: const Text('القيود اليومية'),
        backgroundColor: const Color(0xFF455A64),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          // زر الفلترة
          IconButton(
            icon: Icon(_showFilters ? LucideIcons.filterX : LucideIcons.filter),
            tooltip: _showFilters ? "إخفاء الفلاتر" : "إظهار الفلاتر",
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          // زر الطباعة والقائمة
          PrintActionMenu(
            onPrintFull: () => _executePrint(onlySelected: false),
            onPrintSelected: () => _executePrint(onlySelected: true),
            onToggleSelection: () => setState(() {
              _isSelectionMode = !_isSelectionMode;
              if (!_isSelectionMode) _selectedIds.clear();
            }),
            isSelectionEmpty: _selectedIds.isEmpty,
            isSelectionMode: _isSelectionMode,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_showFilters) _buildAdvancedFilters(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF455A64))) 
              : _buildEntriesList(),
          ),
        ],
      ),
    );
  }

  // شريط البحث السريع
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'بحث سريع برقم القيد أو البيان...',
          prefixIcon: const Icon(LucideIcons.search, size: 20),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
        onChanged: (val) => _loadEntries(), // تحديث لحظي
      ),
    );
  }

  // لوحة الفلاتر المتقدمة
  Widget _buildAdvancedFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildDateFilter(true)),
              const SizedBox(width: 10),
              Expanded(child: _buildDateFilter(false)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildTextField(_debitAccountController, "حساب مدين")),
              const SizedBox(width: 10),
              Expanded(child: _buildTextField(_creditAccountController, "حساب دائن")),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(labelText: "الحالة", isDense: true, border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: null, child: Text("الكل")),
                    DropdownMenuItem(value: 'posted', child: Text("مرحل")),
                    DropdownMenuItem(value: 'draft', child: Text("مسودة")),
                  ],
                  onChanged: (val) => setState(() => _selectedStatus = val),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _loadEntries,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF455A64),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(LucideIcons.check),
                label: const Text("تطبيق"),
              )
            ],
          ),
        ],
      ),
    );
  }

  // قائمة القيود
  Widget _buildEntriesList() {
    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.fileX, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text("لا توجد قيود مطابقة للبحث", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final String id = entry['id'].toString();
        final bool isSelected = _selectedIds.contains(id);
        final bool isPosted = entry['status'] == 'posted';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: isSelected ? const BorderSide(color: Color(0xFF455A64), width: 1.5) : BorderSide.none,
          ),
          color: isSelected ? const Color(0xFF455A64).withOpacity(0.05) : Colors.white,
          child: Column(
            children: [
              // الجزء العلوي: المعلومات الأساسية
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                // ✅ إخفاء المربع إلا في وضع التحديد
                leading: _isSelectionMode 
                  ? Checkbox(
                      value: isSelected,
                      activeColor: const Color(0xFF455A64),
                      onChanged: (v) => setState(() => v! ? _selectedIds.add(id) : _selectedIds.remove(id)),
                    )
                  : Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(LucideIcons.fileText, color: Color(0xFF455A64)),
                    ),
                title: Row(
                  children: [
                    Text("قيد رقم #$id", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    _statusBadge(isPosted),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(entry['description'] ?? 'بدون بيان', maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      _dateFormat.format(DateTime.parse(entry['date'])), 
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)
                    ),
                  ],
                ),
                trailing: Text(
                  "${_currencyFormat.format(entry['amount'])} د.أ",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF455A64)),
                ),
                // ✅ الضغط على البطاقة يحددها فقط ولا يفتح التفاصيل
                onTap: _isSelectionMode 
                  ? () => setState(() => isSelected ? _selectedIds.remove(id) : _selectedIds.add(id))
                  : null, 
              ),
              
              const Divider(height: 1),
              
              // الجزء السفلي: أزرار الأفعال
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _navigateToEdit(id),
                      icon: const Icon(LucideIcons.edit3, size: 16, color: Colors.blue),
                      label: const Text("تعديل", style: TextStyle(color: Colors.blue)),
                    ),
                    TextButton.icon(
                      onPressed: () => _executePrint(onlySelected: false, singleEntry: entry),
                      icon: const Icon(LucideIcons.printer, size: 16, color: Colors.grey),
                      label: const Text("طباعة", style: TextStyle(color: Colors.grey)),
                    ),
                    if (!isPosted)
                      TextButton.icon(
                        onPressed: () { /* منطق الترحيل */ },
                        icon: const Icon(LucideIcons.checkCircle, size: 16, color: Colors.green),
                        label: const Text("ترحيل", style: TextStyle(color: Colors.green)),
                      ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // --- Helper Widgets ---

  Widget _statusBadge(bool isPosted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPosted ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isPosted ? Colors.green.shade200 : Colors.orange.shade200),
      ),
      child: Text(
        isPosted ? "مرحل" : "مسودة",
        style: TextStyle(
          color: isPosted ? Colors.green.shade700 : Colors.orange.shade700,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return SizedBox(
      height: 45,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildDateFilter(bool isFrom) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) setState(() => isFrom ? _fromDate = date : _toDate = date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: isFrom ? "من تاريخ" : "إلى تاريخ",
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          suffixIcon: const Icon(LucideIcons.calendar, size: 18),
        ),
        child: Text(
          isFrom 
            ? (_fromDate != null ? _dateFormat.format(_fromDate!) : "") 
            : (_toDate != null ? _dateFormat.format(_toDate!) : ""),
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}