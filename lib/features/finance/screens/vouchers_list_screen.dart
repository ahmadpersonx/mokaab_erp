//vouchers_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../core/constants/app_theme.dart';
import '../models/account_model.dart';
import '../../../core/services/pdf_service.dart';
import '../services/finance_service.dart';
import 'smart_voucher_screen.dart';
import '../../../core/screens/pdf_preview_screen.dart';

class VouchersListScreen extends StatefulWidget {
  final String voucherType; // 'receipt' or 'payment'

  const VouchersListScreen({super.key, required this.voucherType});

  @override
  State<VouchersListScreen> createState() => _VouchersListScreenState();
}

class _VouchersListScreenState extends State<VouchersListScreen> {
  final FinanceService _service = FinanceService();
  final PdfService _pdfService = PdfService();
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  List<Map<String, dynamic>> _vouchers = [];
  List<Map<String, dynamic>> _filteredVouchers = [];
  
  List<AccountModel> _accounts = [];
  AccountModel? _selectedAccountFilter;

  // متغيرات وضع التحديد والطباعة
  bool _isSelectionMode = false;
  List<String> _selectedVoucherNumbers = [];

  bool _isLoading = true;

  // فلاتر البحث
  DateTime? _fromDate;
  DateTime? _toDate;
  final TextEditingController _searchController = TextEditingController();

  String get _title => widget.voucherType == 'receipt' ? 'سندات القبض' : 'سندات الصرف';
  Color get _themeColor => widget.voucherType == 'receipt' ? Colors.green.shade700 : Colors.red.shade700;
  IconData get _icon => widget.voucherType == 'receipt' ? LucideIcons.arrowDownCircle : LucideIcons.arrowUpCircle;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      _accounts = await _service.getAllAccounts();
      await _loadVouchers();
    } catch (e) {
      debugPrint("Error loading data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadVouchers() async {
    try {
      final data = await _service.getVouchers(
        type: widget.voucherType,
        fromDate: _fromDate,
        toDate: _toDate,
      );

      if (mounted) {
        setState(() {
          _vouchers = data;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  void _applyFilters() {
    String query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredVouchers = _vouchers.where((v) {
        final number = v['voucher_number'].toString().toLowerCase();
        final desc = (v['description'] ?? '').toString().toLowerCase();
        final amount = v['amount'].toString();
        bool matchesQuery = number.contains(query) || desc.contains(query) || amount.contains(query);

        bool matchesAccount = true;
        if (_selectedAccountFilter != null) {
          final lines = v['voucher_lines'] as List;
          matchesAccount = lines.any((line) => line['account_id'] == _selectedAccountFilter!.id);
        }

        return matchesQuery && matchesAccount;
      }).toList();
    });
  }

  Future<void> _selectDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: _themeColor)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _fromDate = picked; else _toDate = picked;
      });
      _loadVouchers();
    }
  }

  void _printSelectedOrAll() { // أزل async لأننا سننتقل لشاشة أخرى
    List<Map<String, dynamic>> toPrint = [];
    String titleSuffix = "";

    if (_isSelectionMode && _selectedVoucherNumbers.isNotEmpty) {
      toPrint = _filteredVouchers.where((v) => _selectedVoucherNumbers.contains(v['voucher_number'])).toList();
      titleSuffix = "(محدد)";
    } else {
      toPrint = _filteredVouchers;
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

    // ✅ التوجيه لشاشة المعاينة
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          title: "تقرير $_title $titleSuffix",
          buildPdf: (format) => _pdfService.generateListReport(
            format,
            title: "تقرير $_title $titleSuffix",
            headers: ['المبلغ', 'الدفع', 'البيان', 'التاريخ', 'رقم السند'],
            data: data,
          ),
        ),
      ),
    );
  }

  void _openVoucherScreen({String? voucherNumber}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SmartVoucherScreen(
          voucherType: widget.voucherType,
          voucherNumber: voucherNumber,
        ),
      ),
    );
    _loadVouchers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _themeColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.printer),
            onPressed: _printSelectedOrAll,
            tooltip: "طباعة القائمة",
          ),
          IconButton(
            icon: Icon(_isSelectionMode ? LucideIcons.checkSquare : LucideIcons.square),
            onPressed: () {
              setState(() {
                _isSelectionMode = !_isSelectionMode;
                _selectedVoucherNumbers.clear();
              });
            },
            tooltip: "تحديد للطباعة",
          ),
          IconButton(icon: const Icon(LucideIcons.rotateCw), onPressed: _loadVouchers),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _themeColor,
        child: const Icon(LucideIcons.plus, color: Colors.white),
        onPressed: () => _openVoucherScreen(),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث برقم السند، الوصف، أو المبلغ...',
                    prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    isDense: true,
                  ),
                  onChanged: (val) => _applyFilters(),
                ),
                const SizedBox(height: 10),
                
                DropdownSearch<AccountModel>(
                  items: (f, l) => _accounts,
                  itemAsString: (a) => "${a.code} - ${a.nameAr}",
                  compareFn: (item, selectedItem) => item.id == selectedItem.id,
                  selectedItem: _selectedAccountFilter,
                  onChanged: (val) {
                    setState(() => _selectedAccountFilter = val);
                    _applyFilters();
                  },
                  decoratorProps: const DropDownDecoratorProps(
                    decoration: InputDecoration(
                      labelText: "تصفية حسب الحساب المقابل",
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(decoration: InputDecoration(hintText: "بحث عن حساب...", isDense: true)),
                  ),
                  suffixProps: const DropdownSuffixProps(
                    clearButtonProps: ClearButtonProps(isVisible: true),
                  ),
                ),

                const SizedBox(height: 10),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(LucideIcons.calendar),
                        label: Text(_fromDate == null ? "من تاريخ" : _dateFormat.format(_fromDate!)),
                        onPressed: () => _selectDate(true),
                        style: OutlinedButton.styleFrom(foregroundColor: _themeColor),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(LucideIcons.calendar),
                        label: Text(_toDate == null ? "إلى تاريخ" : _dateFormat.format(_toDate!)),
                        onPressed: () => _selectDate(false),
                        style: OutlinedButton.styleFrom(foregroundColor: _themeColor),
                      ),
                    ),
                    if (_fromDate != null || _toDate != null || _selectedAccountFilter != null)
                      IconButton(
                        icon: const Icon(LucideIcons.filterX, color: Colors.red),
                        tooltip: "إلغاء الفلاتر",
                        onPressed: () {
                          setState(() { 
                            _fromDate = null; 
                            _toDate = null;
                            _selectedAccountFilter = null;
                            _searchController.clear();
                          });
                          _loadVouchers();
                        },
                      )
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: _themeColor))
                : _filteredVouchers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_icon, size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            Text("لا توجد $_title مطابقة", style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredVouchers.length,
                        itemBuilder: (context, index) {
                          final item = _filteredVouchers[index];
                          final double amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
                          final String paymentMethod = item['payment_method'] == 'check' ? 'شيك' : (item['payment_method'] == 'transfer' ? 'حوالة' : 'نقدي');
                          final String voucherNumber = item['voucher_number'].toString();
                          
                          final lines = item['voucher_lines'] as List;
                          String accountNames = lines.map((l) {
                            if (l['accounts'] != null) {
                              return "${l['accounts']['name_ar']}";
                            }
                            return '';
                          }).where((name) => name.isNotEmpty).join('، ');

                          return Row(
                            children: [
                              if (_isSelectionMode)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Checkbox(
                                    value: _selectedVoucherNumbers.contains(voucherNumber),
                                    activeColor: _themeColor,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedVoucherNumbers.add(voucherNumber);
                                        } else {
                                          _selectedVoucherNumbers.remove(voucherNumber);
                                        }
                                      });
                                    },
                                  ),
                                ),

                              Expanded(
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: InkWell(
                                    onTap: () {
                                      if (_isSelectionMode) {
                                        setState(() {
                                          if (_selectedVoucherNumbers.contains(voucherNumber)) {
                                            _selectedVoucherNumbers.remove(voucherNumber);
                                          } else {
                                            _selectedVoucherNumbers.add(voucherNumber);
                                          }
                                        });
                                        return;
                                      }
                                      _openVoucherScreen(voucherNumber: voucherNumber);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                voucherNumber,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                              Text(
                                                _currencyFormat.format(amount),
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _themeColor),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(LucideIcons.calendar, size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                _dateFormat.format(DateTime.parse(item['date'])),
                                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                                              ),
                                              const SizedBox(width: 15),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(color: _themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                                child: Text(paymentMethod, style: TextStyle(fontSize: 11, color: _themeColor, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 20),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(LucideIcons.user, size: 14, color: Colors.grey),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  accountNames.isNotEmpty ? accountNames : (item['description'] ?? 'بدون بيان'),
                                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}