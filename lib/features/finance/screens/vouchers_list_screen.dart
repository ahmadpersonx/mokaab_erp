// FileName: lib/features/finance/screens/vouchers_list_screen.dart
// Revision: 4.0 (Unified Voucher List with Advanced Filters & Actions)
// Date: 2025-12-19

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_theme.dart';
import '../services/finance_service.dart';
import '../../../core/models/account.dart';

// استدعاء المكونات الجديدة
import '../widgets/finance_action_bar.dart';
import '../widgets/voucher_list_card.dart'; // البطاقة الجديدة
import 'smart_voucher_screen.dart';

class VouchersListScreen extends StatefulWidget {
  final String voucherType; // 'receipt' or 'payment'

  const VouchersListScreen({super.key, required this.voucherType});

  @override
  State<VouchersListScreen> createState() => _VouchersListScreenState();
}

class _VouchersListScreenState extends State<VouchersListScreen> {
  final FinanceService _service = FinanceService();
  
  // Data State
  List<Map<String, dynamic>> _vouchers = [];
  List<Account> _accounts = [];
  bool _isLoading = true;

  // Filter State
  String _searchQuery = "";
  DateTime? _fromDate;
  DateTime? _toDate;
  Account? _selectedAccountFilter;

  // Selection State
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  // Properties based on type
  String get _title => widget.voucherType == 'receipt' ? 'سندات القبض' : 'سندات الصرف';
  Color get _themeColor => widget.voucherType == 'receipt' ? AppTheme.kSuccess : AppTheme.kError;
  IconData get _icon => widget.voucherType == 'receipt' ? LucideIcons.arrowDownCircle : LucideIcons.arrowUpCircle;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _accounts = await _service.getAllAccounts();
      await _refreshVouchers();
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshVouchers() async {
    final data = await _service.getVouchers(
      type: widget.voucherType,
      fromDate: _fromDate,
      toDate: _toDate,
    );
    if (mounted) setState(() => _vouchers = data);
  }

  List<Map<String, dynamic>> get _filteredVouchers {
    return _vouchers.where((v) {
      final searchContent = "${v['voucher_number']} ${v['amount']} ${v['description'] ?? ''}".toLowerCase();
      
      // 1. Text Search
      if (_searchQuery.isNotEmpty && !searchContent.contains(_searchQuery.toLowerCase())) {
        return false;
      }
      
      // 2. Account Filter
      if (_selectedAccountFilter != null) {
        final lines = v['voucher_lines'] as List;
        bool hasAccount = lines.any((l) => l['account_id'] == _selectedAccountFilter!.id);
        if (!hasAccount) return false;
      }
      
      return true;
    }).toList();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredVouchers;
    final totalAmount = filteredList.fold(0.0, (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: CustomScrollView(
        slivers: [
          // 1. Sliver Header (Unified Style)
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: _themeColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _themeColor.withOpacity(0.9), 
                      _themeColor
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/pattern.jpg'),
                    fit: BoxFit.cover,
                    opacity: 0.1,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_icon, color: Colors.white, size: 32),
                        const SizedBox(width: 10),
                        Text(
                          _title,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              FinanceActionBar(
                hasSelection: _selectedIds.isNotEmpty,
                onPrintAll: () { /* Print All Logic */ },
                onPrintSelected: () { /* Print Selected Logic */ },
                onExportExcelAll: () { /* Export All */ },
                onExportExcelSelected: () { /* Export Selected */ },
                onImportExcel: () { /* Import */ },
              ),
              if (_isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _exitSelectionMode,
                )
            ],
          ),

          // 2. Filters & Search Area
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: "بحث برقم السند، المبلغ، أو البيان...",
                      prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                          child: DropdownButtonHideUnderline(child: DropdownButton<Account>(
                              isExpanded: true,
                              hint: const Text("كل الحسابات"),
                              value: _selectedAccountFilter,
                              items: [
                                const DropdownMenuItem(value: null, child: Text("الكل")),
                                ..._accounts.map((e) => DropdownMenuItem(value: e, child: Text(e.nameAr, overflow: TextOverflow.ellipsis))),
                              ],
                              onChanged: (val) => setState(() => _selectedAccountFilter = val),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Date Filter Button (Simplified for brevity)
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (d != null) setState(() { _fromDate = d; _refreshVouchers(); });
                          },
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                            child: Text(_fromDate == null ? "من تاريخ" : DateFormat('yyyy-MM-dd').format(_fromDate!), style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. Sticky Total Header
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTotalDelegate(total: totalAmount, count: filteredList.length, color: _themeColor),
          ),

          // 4. Vouchers List
          _isLoading 
            ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            : filteredList.isEmpty
                ? SliverFillRemaining(child: Center(child: Text("لا توجد بيانات", style: TextStyle(color: Colors.grey.shade500))))
                : SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final voucher = filteredList[index];
                          final id = voucher['voucher_number'].toString();
                          final isSelected = _selectedIds.contains(id);

                          return VoucherListCard(
                            voucher: voucher,
                            isSelected: isSelected,
                            selectionMode: _isSelectionMode,
                            voucherType: widget.voucherType,
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleSelection(id);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SmartVoucherScreen(
                                      voucherType: widget.voucherType,
                                      voucherNumber: id,
                                    ),
                                  ),
                                );
                              }
                            },
                            onLongPress: () => _toggleSelection(id),
                          );
                        },
                        childCount: filteredList.length,
                      ),
                    ),
                  ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SmartVoucherScreen(voucherType: widget.voucherType)),
          ).then((_) => _refreshVouchers());
        },
        backgroundColor: _themeColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("سند جديد", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}

class _StickyTotalDelegate extends SliverPersistentHeaderDelegate {
  final double total;
  final int count;
  final Color color;

  _StickyTotalDelegate({required this.total, required this.count, required this.color});

  @override
  double get minExtent => 50;
  @override
  double get maxExtent => 50;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: color.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("العدد: $count", style: TextStyle(color: color)),
          Text(
            "الإجمالي: ${NumberFormat.currency(symbol: '', decimalDigits: 2).format(total)} د.أ",
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyTotalDelegate oldDelegate) {
    return oldDelegate.total != total || oldDelegate.count != count;
  }
}
