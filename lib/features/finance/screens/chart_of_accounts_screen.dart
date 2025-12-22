// FileName: lib/features/finance/screens/chart_of_accounts_screen.dart
// Revision: 5.0 (Professional Tree View, Cost Centers, Print/Export)

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/services/finance_formatter.dart';
import '../../../../core/services/pdf_service.dart';
import '../../../../core/services/excel_service.dart';
import '../../../../core/screens/pdf_preview_screen.dart';
import '../../../../core/widgets/finance/index.dart';
import '../../../core/models/account.dart';
import '../services/finance_service.dart';

class ChartOfAccountsScreen extends StatefulWidget {
  const ChartOfAccountsScreen({super.key});

  @override
  State<ChartOfAccountsScreen> createState() => _ChartOfAccountsScreenState();
}

class _ChartOfAccountsScreenState extends State<ChartOfAccountsScreen> {
  final FinanceService _service = FinanceService();
  final ExcelService _excelService = ExcelService();
  final PdfService _pdfService = PdfService();
  final FinanceFormatter _formatter = FinanceFormatter();

  List<Account> _accounts = [];
  List<Account> _filteredAccounts = [];
  bool _isLoading = true;
  String _searchQuery = "";

  // لإدارة حالة الطي والتوسيع
  final Map<String, bool> _expandedNodes = {};

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getAllAccounts();
      if (mounted) {
        setState(() {
          _accounts = data;
          _filterAccounts(_searchQuery);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterAccounts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredAccounts = List.from(_accounts);
      } else {
        _filteredAccounts = _accounts.where((acc) {
          return acc.code.contains(query) || 
                 acc.nameAr.toLowerCase().contains(query.toLowerCase()) ||
                 (acc.nameEn?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  // دالة جديدة لترتيب وعرض الحسابات بشكل شجري
  List<Account> _getVisibleAccounts() {
    final visibleAccounts = <Account>[];
    // عرض الحسابات الرئيسية (المستوى 1) دائماً
    final rootAccounts = _filteredAccounts.where((acc) => acc.level == 1).toList();

    void addChildren(Account parent) {
      visibleAccounts.add(parent);
      if (_expandedNodes[parent.code] == true) {
        final children = _filteredAccounts.where((acc) => acc.parentCode == parent.code).toList();
        for (var child in children) {
          addChildren(child); // استدعاء متكرر لإضافة الأحفاد
        }
      }
    }
    for (var root in rootAccounts) { addChildren(root); }
    return visibleAccounts;
  }

  String _generateNextCode(Account parent) {
    final siblings = _accounts.where((a) => a.parentCode == parent.code).toList();
    if (siblings.isEmpty) {
      return "${parent.code}01";
    }
    
    // Sort by code to find last
    siblings.sort((a, b) => a.code.compareTo(b.code));
    final lastCode = siblings.last.code;
    
    if (RegExp(r'^\d+$').hasMatch(lastCode)) {
       final val = int.tryParse(lastCode);
       if (val != null) return (val + 1).toString();
    }
    return "${parent.code}${siblings.length + 1}";
  }

  // --- Actions ---
  Future<void> _handlePrint() async {
    List<List<String>> data = _filteredAccounts.map((a) => [
      _formatter.formatCurrency(a.balance),
      a.requireCostCenter ? 'نعم' : 'لا',
      a.type,
      a.nameAr,
      a.code,
    ]).toList();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => PdfPreviewScreen(
          title: "دليل الحسابات",
          buildPdf: (f) => _pdfService.generateListReport(
            f,
            title: "شركة مكعب - دليل الحسابات",
            headers: ['الرصيد', 'مركز تكلفة', 'النوع', 'اسم الحساب', 'الرمز'],
            data: data,
          ),
        ),
      ),
    );
  }

  Future<void> _handleExport() async {
    await _excelService.exportAccounts(_filteredAccounts);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تصدير ملف Excel بنجاح")));
    }
  }

  Future<void> _handleImport() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        await _excelService.importAccounts(result.files.single.path!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم استيراد الحسابات بنجاح")));
          _loadAccounts();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ في الاستيراد: $e")));
      }
    }
  }

  // --- Dialog Logic ---
  void _showAccountDialog({Account? parent, Account? accountToEdit}) {
    final bool isEditing = accountToEdit != null;

    // محاولة العثور على الأب عند التعديل لضمان ظهور خيارات الوراثة والحساب العكسي
    if (isEditing && parent == null && accountToEdit!.parentCode != null) {
      try {
        parent = _accounts.firstWhere((a) => a.code == accountToEdit.parentCode);
      } catch (_) {}
    }

    final formKey = GlobalKey<FormState>();
    
    final codeController = TextEditingController(text: accountToEdit?.code);
    final nameArController = TextEditingController(text: accountToEdit?.nameAr);
    final nameEnController = TextEditingController(text: accountToEdit?.nameEn);
    
    String type = accountToEdit?.type ?? (parent?.type ?? 'asset');
    String nature = accountToEdit?.nature ?? (parent?.nature ?? 'debit');
    bool isParent = accountToEdit?.isParent ?? (parent != null ? false : true);
    bool requireCostCenter = accountToEdit?.requireCostCenter ?? false;
    bool isContra = accountToEdit?.isContra ?? false;

    if (!isEditing && parent != null) {
      codeController.text = _generateNextCode(parent);
    }
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? "تعديل حساب" : "إضافة حساب جديد"),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (parent != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                    child: Text("تابع للحساب: ${parent.nameAr} (${parent.code})", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: codeController,
                        decoration: const InputDecoration(labelText: "رقم الحساب", border: OutlineInputBorder(), isDense: true),
                        validator: (v) => v!.isEmpty ? "مطلوب" : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: type,
                        decoration: const InputDecoration(labelText: "نوع الحساب", border: OutlineInputBorder(), isDense: true),
                        items: const [
                          DropdownMenuItem(value: 'asset', child: Text('أصول')),
                          DropdownMenuItem(value: 'liability', child: Text('خصوم')),
                          DropdownMenuItem(value: 'equity', child: Text('حقوق ملكية')),
                          DropdownMenuItem(value: 'revenue', child: Text('إيرادات')),
                          DropdownMenuItem(value: 'expense', child: Text('مصروفات')),
                        ],
                        onChanged: (v) => type = v!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: nameArController,
                  decoration: const InputDecoration(labelText: "الاسم (عربي)", border: OutlineInputBorder(), isDense: true),
                  validator: (v) => v!.isEmpty ? "مطلوب" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: nameEnController,
                  decoration: const InputDecoration(labelText: "الاسم (إنجليزي)", border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      children: [
                        if (parent == null)
                        DropdownButtonFormField<String>(
                          value: nature,
                          decoration: const InputDecoration(labelText: "طبيعة الحساب", border: OutlineInputBorder(), isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'debit', child: Text('مدين')),
                            DropdownMenuItem(value: 'credit', child: Text('دائن')),
                          ],
                          onChanged: (v) => nature = v!,
                        ),
                        const SizedBox(height: 10),
                        if (parent != null)
                        CheckboxListTile(
                          title: const Text("حساب عكسي (Contra Account)"),
                          subtitle: const Text("عكس طبيعة الحساب الأب"),
                          value: isContra,
                          onChanged: (v) => setState(() => isContra = v!),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          title: const Text("حساب رئيسي (تجميعي)"),
                          value: isParent,
                          onChanged: (v) => setState(() => isParent = v!),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          title: const Text("يتطلب مركز تكلفة"),
                          subtitle: const Text("مفيد لحسابات الإنتاج والمصاريف"),
                          value: requireCostCenter,
                          onChanged: (v) => setState(() => requireCostCenter = v!),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    );
                  }
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                String finalNature = nature;
                if (parent != null) {
                   finalNature = isContra 
                      ? (parent.nature == 'debit' ? 'credit' : 'debit')
                      : (parent.nature ?? 'debit');
                }

                final newAccount = Account(
                  id: accountToEdit?.id ?? 0,
                  code: codeController.text,
                  nameAr: nameArController.text,
                  nameEn: nameEnController.text,
                  type: type,
                  isTransaction: !isParent,
                  // ✅ تصحيح: الحفاظ على المستوى ورمز الأب عند التعديل
                  level: isEditing ? accountToEdit.level : (parent != null ? parent.level + 1 : 1),
                  parentCode: isEditing ? accountToEdit.parentCode : parent?.code,
                  nature: finalNature,
                  isParent: isParent,
                  requireCostCenter: requireCostCenter,
                  isContra: isContra,
                );

                try {
                  if (isEditing) {
                    await _service.updateAccount(newAccount.id, newAccount);
                  } else {
                    await _service.addAccount(newAccount);
                  }
                  if (mounted) {
                    Navigator.pop(ctx);
                    _loadAccounts();
                  }
                } catch (e) {
                  print(e);
                }
              }
            },
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  // --- UI Building ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppTheme.kDarkBrown,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.kDarkBrown.withOpacity(0.9), AppTheme.kDarkBrown],
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
                        Icon(LucideIcons.book, color: Colors.white, size: 32),
                        SizedBox(width: 10),
                        Text(
                          "دليل الحسابات",
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              FinancePrintMenu(
                onPrint: (isSelected) async => _handlePrint(),
                enablePrintSelected: false,
              ),
              FinanceExportImportMenu(
                onExport: (isSelected) async => _handleExport(),
                onImport: _handleImport,
                enableExportSelected: false,
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                FinanceSearchBar(
                  onSearchChanged: _filterAccounts,
                  onAdvancedFiltersTap: () {}, // يمكن إضافة فلاتر متقدمة لاحقاً
                  showAdvancedFiltersButton: false,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: FinanceSummaryCard(
                    label: "عدد الحسابات",
                    amount: _filteredAccounts.length.toDouble(),
                    currency: 'حساب',
                    showIcon: false,
                  ),
                ),
              ],
            ),
          ),

          _isLoading
              ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // ✅ تصحيح: استخدام الدالة التي تعرض الحسابات المرئية فقط
                      final visibleAccounts = _getVisibleAccounts();
                      final account = visibleAccounts[index];
                      return _buildAccountRow(account);
                    },
                    childCount: _getVisibleAccounts().length,
                  ),
                ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAccountDialog(),
        backgroundColor: AppTheme.kDarkBrown,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAccountRow(Account account) {
    // حساب المسافة البادئة بناءً على المستوى
    final double indent = (account.level - 1) * 20.0;
    final bool isParent = account.isParent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: InkWell(
        onTap: () {
          if (isParent) {
            setState(() {
              _expandedNodes[account.code] = !(_expandedNodes[account.code] ?? false);
            });
          } else {
            _showAccountDialog(accountToEdit: account); // تعديل الحساب الفرعي بالضغط العادي
          }
        },
        onLongPress: () {
          if (account.isParent) {
            _showAccountDialog(accountToEdit: account); // تعديل الحساب الرئيسي بالضغط المطول
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("لا يمكن إضافة حساب فرعي لحساب غير تجميعي")),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              SizedBox(width: indent),
              Icon(
                isParent 
                  ? (_expandedNodes[account.code] == true ? LucideIcons.folderOpen : LucideIcons.folder) 
                  : LucideIcons.fileText,
                size: 20,
                color: isParent 
                  ? (_expandedNodes[account.code] == true ? AppTheme.kDarkBrown : Colors.amber.shade700)
                  : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          account.code,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (account.requireCostCenter)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.purple.shade200),
                            ),
                            child: const Text("م.تكلفة", style: TextStyle(fontSize: 9, color: Colors.purple)),
                          ),
                      ],
                    ),
                    Text(
                      account.nameAr,
                      style: TextStyle(
                        fontWeight: isParent ? FontWeight.bold : FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatter.formatCurrency(account.balance),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: account.balance >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  Text(
                    account.type,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              if (isParent)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20, color: AppTheme.kDarkBrown),
                  onPressed: () => _showAccountDialog(parent: account),
                  tooltip: "إضافة حساب فرعي",
                ),
            ],
          ),
        ),
      ),
    );
  }
}