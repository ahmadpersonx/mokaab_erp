//الكود الكامل والنهائي لملف lib/features/finance/journal_entries_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../core/constants/app_theme.dart';
import '../../core/models/account_model.dart';
import '../../core/widgets/draggable_popup.dart'; // ✅ تأكد من وجود هذا الملف
import 'add_journal_entry_screen.dart';
import 'finance_service.dart';

class JournalEntriesScreen extends StatefulWidget {
  const JournalEntriesScreen({super.key});

  @override
  State<JournalEntriesScreen> createState() => _JournalEntriesScreenState();
}

class _JournalEntriesScreenState extends State<JournalEntriesScreen> {
  final FinanceService _service = FinanceService();
  
  List<Map<String, dynamic>> _allEntries = [];
  List<Map<String, dynamic>> _filteredEntries = [];
  List<AccountModel> _accounts = []; // قائمة الحسابات للفلتر

  bool _isLoading = true;

  // فلاتر البحث المحلي
  final TextEditingController _searchController = TextEditingController();
  
  // فلاتر التصفية (للسيرفر)
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // تحميل الحسابات لاستخدامها في الفلتر
      _accounts = await _service.getAllAccounts();
      // تحميل القيود
      await _loadEntries();
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getJournalEntriesSummary(
        fromDate: _fromDate,
        toDate: _toDate,
        accountId: _selectedAccountId,
      );
      setState(() {
        _allEntries = data;
        _applyLocalSearch(); // تطبيق البحث النصي
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e")));
      }
    }
  }

  // البحث المحلي السريع داخل القائمة المحملة
  void _applyLocalSearch() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredEntries = _allEntries.where((entry) {
        final entryNo = entry['id'].toString().toLowerCase();
        final refNo = (entry['ref_number'] ?? '').toString().toLowerCase();
        final desc = (entry['description'] ?? '').toString().toLowerCase();
        final accounts = (entry['search_text'] ?? '').toString().toLowerCase(); // البحث في أسماء الحسابات
        
        return entryNo.contains(query) || 
               refNo.contains(query) || 
               desc.contains(query) ||
               accounts.contains(query);
      }).toList();
    });
  }

  // ✅ النافذة المنبثقة القابلة للتحريك (Draggable Popup)
  void _showFilterSheet() {
    showDialog(
      context: context,
      barrierDismissible: false, // نجعلها تبدو ثابتة
      builder: (context) => DraggablePopup(
        title: "تصفية القيود",
        width: 500, // عرض مناسب
        onClose: () => Navigator.pop(context),
        child: StatefulBuilder(
          builder: (context, setStatePopup) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. التاريخ
                const Text("نطاق التاريخ", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.kDarkBrown)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_fromDate == null ? "من تاريخ" : DateFormat('yyyy-MM-dd').format(_fromDate!)),
                        onPressed: () async {
                          final d = await showDatePicker(context: context, initialDate: _fromDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (d != null) setStatePopup(() => _fromDate = d);
                        },
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_toDate == null ? "إلى تاريخ" : DateFormat('yyyy-MM-dd').format(_toDate!)),
                        onPressed: () async {
                          final d = await showDatePicker(context: context, initialDate: _toDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (d != null) setStatePopup(() => _toDate = d);
                        },
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),

                // 2. فلتر الحساب
                const Text("يحتوي على الحساب", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.kDarkBrown)),
                const SizedBox(height: 10),
                DropdownSearch<AccountModel>(
                  items: (f, l) => _accounts,
                  itemAsString: (a) => "${a.code} - ${a.nameAr}",
                  compareFn: (a, b) => a.code == b.code,
                  selectedItem: _selectedAccountId == null 
                      ? null 
                      : _accounts.firstWhere((a) => a.code == _selectedAccountId, orElse: () => _accounts.first),
                  onChanged: (val) => setStatePopup(() => _selectedAccountId = val?.code),
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(decoration: InputDecoration(hintText: "بحث عن حساب...", isDense: true, border: OutlineInputBorder())),
                    menuProps: MenuProps(borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                  decoratorProps: const DropDownDecoratorProps(
                    decoration: InputDecoration(
                      labelText: "اختر حساباً",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // أزرار التحكم
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // تصفير القيم في الحالة العامة
                          setState(() {
                            _fromDate = null;
                            _toDate = null;
                            _selectedAccountId = null;
                          });
                          Navigator.pop(context);
                          _loadEntries();
                        },
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: const Text("مسح الكل"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.kDarkBrown, 
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14)
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _loadEntries(); // تطبيق الفلتر وإعادة التحميل
                        },
                        child: const Text("تطبيق"),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('القيود اليومية', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppTheme.kDarkBrown,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.kDarkBrown,
        tooltip: 'إضافة قيد جديد',
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddJournalEntryScreen()));
          _loadEntries();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // شريط البحث العلوي
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "بحث برقم القيد، البيان، أو اسم الحساب...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) => _applyLocalSearch(),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _showFilterSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (_fromDate != null || _selectedAccountId != null) ? AppTheme.kDarkBrown.withOpacity(0.1) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: (_fromDate != null || _selectedAccountId != null) ? AppTheme.kDarkBrown : Colors.transparent),
                    ),
                    child: Icon(Icons.filter_list, color: (_fromDate != null || _selectedAccountId != null) ? AppTheme.kDarkBrown : Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
          
          // قائمة القيود
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.kDarkBrown))
                : _filteredEntries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text("لا توجد قيود مطابقة", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: _filteredEntries.length,
                        itemBuilder: (context, index) {
                          final entry = _filteredEntries[index];
                          final bool isPosted = entry['status'] == 'posted';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (context) => AddJournalEntryScreen(entryNumber: entry['id'])));
                                _loadEntries();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(entry['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isPosted ? Colors.green.shade50 : Colors.amber.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: isPosted ? Colors.green.shade200 : Colors.amber.shade200),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(isPosted ? Icons.check_circle : Icons.edit_note, size: 14, color: isPosted ? Colors.green.shade700 : Colors.amber.shade800),
                                              const SizedBox(width: 4),
                                              Text(isPosted ? "مرحل" : "مسودة", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isPosted ? Colors.green.shade700 : Colors.amber.shade800)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (entry['description'] != null)
                                      Text(entry['description'], style: const TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    
                                    // عرض أطراف القيد (للتأكد من نتيجة البحث)
                                    if (entry['search_text'] != null) 
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          "أطراف: ${(entry['search_text'] as String).split(' ').take(4).join(' - ')}...", 
                                          style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade400),
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(entry['date'])), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                          ],
                                        ),
                                        Text(
                                          (entry['debit'] as double).toStringAsFixed(2), 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.kDarkBrown, fontFamily: 'Courier'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
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