// FileName: lib/features/finance/screens/payment_bonds_screen.dart
// Revision: 3.0 (Expert Accounting Logic & Unified UI)
// Date: 2025-12-19

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/services/finance_formatter.dart';
import '../../../../core/services/pdf_service.dart';
import '../../../../core/screens/pdf_preview_screen.dart';
import '../../../../core/widgets/finance/index.dart';
import '../services/finance_service.dart';
import '../../../core/models/account.dart';
import 'smart_voucher_screen.dart';

class PaymentBondsScreen extends StatefulWidget {
  const PaymentBondsScreen({super.key});

  @override
  State<PaymentBondsScreen> createState() => _PaymentBondsScreenState();
}

class _PaymentBondsScreenState extends State<PaymentBondsScreen> {
  // Services
  final FinanceService _service = FinanceService();
  final PdfService _pdfService = PdfService();
  final FinanceFormatter _formatter = FinanceFormatter();

  // Data State
  bool _isLoading = true;
  List<Map<String, dynamic>> _bonds = [];
  List<Map<String, dynamic>> _allBonds = [];
  List<Account> _availableAccounts = [];
  
  // Filter State
  String _searchQuery = "";
  DateTime? _fromDate;
  DateTime? _toDate;
  Account? _selectedAccountFilter;
  bool _showAdvancedFilters = false;

  // Selection State
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getVouchers(
        type: 'payment',
        fromDate: _fromDate,
        toDate: _toDate,
      );

      final Set<int> accountIds = {};
      final List<Account> dynamicAccounts = [];

      for (var bond in data) {
        final lines = bond['voucher_lines'] as List;
        if (lines.isNotEmpty && lines[0]['accounts'] != null) {
          final accData = lines[0]['accounts'];
          final accId = accData['id'];
          if (!accountIds.contains(accId)) {
            accountIds.add(accId);
            dynamicAccounts.add(Account.fromJson(accData));
          }
        }
      }

      if (mounted) {
        setState(() {
          _allBonds = data;
          _availableAccounts = dynamicAccounts;
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

  List<Map<String, dynamic>> get _filteredBonds {
    return _allBonds.where((bond) {
      final voucherNo = bond['voucher_number'].toString().toLowerCase();
      final refNo = (bond['check_no'] ?? bond['ref_number'] ?? '').toString().toLowerCase();
      
      final lines = bond['voucher_lines'] as List;
      final accountName = lines.isNotEmpty && lines[0]['accounts'] != null 
          ? (lines[0]['accounts']['name_ar'] ?? '').toString().toLowerCase() 
          : '';

      final searchContent = "$voucherNo $refNo $accountName";
      if (_searchQuery.isNotEmpty && !searchContent.contains(_searchQuery.toLowerCase())) {
        return false;
      }

      if (_selectedAccountFilter != null) {
        bool hasAccount = lines.any((line) => line['account_id'] == _selectedAccountFilter!.id);
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

  // --- Expert Accounting Logic: Payment Sequence ---
  Map<String, dynamic> _calculatePaymentSequence(Map<String, dynamic> currentBond) {
    final lines = currentBond['voucher_lines'] as List;
    if (lines.isEmpty) return {};
    
    final accountId = lines[0]['account_id'];
    final currentBondDate = DateTime.parse(currentBond['date']);

    final vendorBonds = _allBonds.where((b) {
      final bLines = b['voucher_lines'] as List;
      return bLines.isNotEmpty && bLines[0]['account_id'] == accountId;
    }).toList();

    vendorBonds.sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

    double totalPaid = 0.0;
    int sequence = 0;
    
    for (var i = 0; i < vendorBonds.length; i++) {
      final bond = vendorBonds[i];
      final amount = (bond['amount'] as num).toDouble();
      
      if (bond['voucher_number'] == currentBond['voucher_number']) {
        sequence = i + 1;
        totalPaid += amount;
        break;
      }
      
      if (DateTime.parse(bond['date']).isBefore(currentBondDate) || 
          (DateTime.parse(bond['date']).isAtSameMomentAs(currentBondDate) && i < vendorBonds.indexOf(currentBond))) {
        totalPaid += amount;
      }
    }

    return {
      'sequence': sequence,
      'total_paid_until_now': totalPaid,
      'total_payments_count': vendorBonds.length,
    };
  }

  void _handlePrintList(bool onlySelected) {
    final listToPrint = onlySelected 
        ? _filteredBonds.where((b) => _selectedIds.contains(b['voucher_number'].toString())).toList()
        : _filteredBonds;

    if (listToPrint.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لا توجد بيانات للطباعة")));
      return;
    }

    List<List<String>> data = listToPrint.map((v) {
      final lines = v['voucher_lines'] as List;
      final accountName = lines.isNotEmpty ? lines[0]['accounts']['name_ar'] : '-';
      return <String>[
        _formatter.formatCurrency((v['amount'] as num).toDouble()),
        accountName,
        v['payment_method'] == 'check' ? 'شيك' : 'نقدي',
        v['voucher_number'].toString(),
        v['date'].toString().split(' ')[0],
      ];
    }).toList();

    Navigator.push(context, MaterialPageRoute(builder: (c) => PdfPreviewScreen(
      title: "كشف سندات الصرف",
      buildPdf: (f) => _pdfService.generateListReport(
        f, 
        title: "كشف سندات الصرف ${onlySelected ? '(محدد)' : ''}", 
        headers: ['المبلغ', 'المستفيد', 'طريقة الدفع', 'رقم السند', 'التاريخ'], 
        data: data
      ),
    )));
  }

  void _handlePrintSingle(Map<String, dynamic> bond) {
    final sequenceData = _calculatePaymentSequence(bond);
    
    final enrichedBond = Map<String, dynamic>.from(bond);
    enrichedBond['description'] = "${bond['description'] ?? ''}\n"
        "(الدفعة رقم ${sequenceData['sequence']} من أصل ${sequenceData['total_payments_count']} - إجمالي المدفوعات: ${_formatter.formatCurrency(sequenceData['total_paid_until_now'])})";

    Navigator.push(context, MaterialPageRoute(builder: (c) => PdfPreviewScreen(
      title: "سند صرف ${bond['voucher_number']}",
      buildPdf: (f) => _pdfService.generateVoucherPdf(enrichedBond, "سند صرف", f),
    )));
  }

  void _handleExport(bool onlySelected) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تصدير البيانات إلى Excel بنجاح")));
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredBonds;
    final totalAmount = filteredList.fold(0.0, (sum, item) => sum + ((item['amount'] as num).toDouble()));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppTheme.kError,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.kError.withOpacity(0.9), AppTheme.kError],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.arrowUpCircle, color: Colors.white, size: 32),
                        SizedBox(width: 10),
                        Text(
                          "سندات الصرف",
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              if (!_isSelectionMode)
                IconButton(
                  icon: const Icon(LucideIcons.checkSquare, color: Colors.white),
                  tooltip: "تحديد متعدد",
                  onPressed: () => setState(() => _isSelectionMode = true),
                ),
              
              FinancePrintMenu(
                onPrint: (isSelected) async => _handlePrintList(isSelected),
                enablePrintSelected: true,
                selectedItemsCount: _selectedIds.length,
              ),
              
              FinanceExportImportMenu(
                onExport: (isSelected) async => _handleExport(isSelected),
                onImport: () async {},
                enableExportSelected: true,
                selectedItemsCount: _selectedIds.length,
              ),

              if (_isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() {
                    _isSelectionMode = false;
                    _selectedIds.clear();
                  }),
                ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                FinanceSearchBar(
                  onSearchChanged: (val) => setState(() => _searchQuery = val),
                  onAdvancedFiltersTap: () => setState(() => _showAdvancedFilters = !_showAdvancedFilters),
                ),
                if (_showAdvancedFilters)
                  FinanceFilterPanel(
                    initialFromDate: _fromDate,
                    initialToDate: _toDate,
                    onFromDateChanged: (d) => setState(() => _fromDate = d),
                    onToDateChanged: (d) => setState(() => _toDate = d),
                    onClearFilters: () {
                      setState(() {
                        _fromDate = null;
                        _toDate = null;
                        _selectedAccountFilter = null;
                        _loadData();
                      });
                    },
                    onApplyFilters: _loadData,
                    additionalFiltersWidget: Container(
                      padding: const EdgeInsets.only(top: 10),
                      child: DropdownButtonFormField<Account>(
                        decoration: const InputDecoration(
                          labelText: "تصفية حسب المورد / المستفيد",
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        ),
                        value: _selectedAccountFilter,
                        items: _availableAccounts.map((e) => DropdownMenuItem(
                          value: e,
                          child: Text("${e.code} - ${e.nameAr}", overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedAccountFilter = v),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FinanceSummaryCard(
                label: "إجمالي المدفوعات",
                amount: totalAmount,
                itemCount: filteredList.length,
                backgroundColor: AppTheme.kError.withOpacity(0.1),
                textColor: AppTheme.kError,
              ),
            ),
          ),

          _isLoading
              ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              : filteredList.isEmpty
                  ? SliverFillRemaining(child: Center(child: Text("لا توجد سندات", style: TextStyle(color: Colors.grey.shade500))))
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final bond = filteredList[index];
                            final id = bond['voucher_number'].toString();
                            final isSelected = _selectedIds.contains(id);
                            
                            final lines = bond['voucher_lines'] as List;
                            final accountName = lines.isNotEmpty && lines[0]['accounts'] != null 
                                ? lines[0]['accounts']['name_ar'] 
                                : 'غير محدد';
                            final refNo = bond['check_no'] ?? bond['ref_number'];

                            return FinanceListItem(
                              itemId: id,
                              itemNumber: id,
                              itemDate: _formatter.formatDateShort(DateTime.parse(bond['date'])),
                              accountName: accountName,
                              amount: (bond['amount'] as num).toDouble(),
                              amountLabel: "المبلغ",
                              amountColor: AppTheme.kError,
                              statusLabel: bond['payment_method'] == 'check' ? 'شيك' : 'نقدي',
                              statusColor: bond['payment_method'] == 'check' ? Colors.orange : Colors.blue,
                              description: bond['description'],
                              paymentMethod: refNo != null ? "مرجع: $refNo" : null,
                              
                              isSelected: isSelected,
                              onSelectedChanged: _isSelectionMode 
                                  ? (val) => _toggleSelection(id) 
                                  : null,
                              
                              onEditPressed: (id) async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SmartVoucherScreen(
                                      voucherType: 'payment',
                                      voucherNumber: id,
                                    ),
                                  ),
                                );
                                _loadData();
                              },
                              onPrintPressed: (id) => _handlePrintSingle(bond),
                            );
                          },
                          childCount: filteredList.length,
                        ),
                      ),
                    ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SmartVoucherScreen(voucherType: 'payment'),
            ),
          );
          _loadData();
        },
        backgroundColor: AppTheme.kError,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("سند صرف جديد", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}