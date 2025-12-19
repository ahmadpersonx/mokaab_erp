// FileName: lib/features/finance/screens/add_journal_entry_screen.dart
// Revision: 2.1 (Restructured Imports & Standardized UI)
// Date: 2025-12-19

import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../models/journal_entry_model.dart';
import '../models/cost_center_model.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/permissions.dart';
import '../../../../core/services/pdf_service.dart'; 
import '../../../../core/screens/pdf_preview_screen.dart'; 
import '../services/finance_service.dart';

// المكونات الفرعية (Widgets)
import '../widgets/journal_entry_header.dart';
import '../widgets/journal_entry_table_header.dart';
import '../widgets/journal_entry_row.dart';
import '../widgets/journal_entry_footer.dart';

class AddJournalEntryScreen extends StatefulWidget {
  final String? entryNumber;
  const AddJournalEntryScreen({super.key, this.entryNumber});

  @override
  State<AddJournalEntryScreen> createState() => _AddJournalEntryScreenState();
}

class _AddJournalEntryScreenState extends State<AddJournalEntryScreen> {
  final FinanceService _service = FinanceService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _refController;
  late TextEditingController _descController;
  
  DateTime _entryDate = DateTime.now();
  List<JournalEntryLine> _lines = [];
  List<AccountModel> _allAccounts = [];
  List<CostCenterModel> _costCenters = [];
  
  bool _isLoading = true;
  bool _canEdit = false;
  bool _canPost = false;

  bool get isEditing => widget.entryNumber != null;

  @override
  void initState() {
    super.initState();
    _refController = TextEditingController();
    _descController = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // 1. تحميل الصلاحيات
      await _service.loadUserPermissions();
      
      // 2. تحميل الحسابات (الفرعية فقط) ومراكز التكلفة
      final accountsData = await _service.getAllAccounts();
      _allAccounts = accountsData.where((a) => !a.isParent).toList(); 
      _costCenters = await _service.getAllCostCenters();

      // 3. التحقق من صلاحيات التعديل والترحيل
      bool hasCreatePerm = _service.hasPermission(AppPermissions.entriesCreate);
      bool hasEditPerm = _service.hasPermission(AppPermissions.entriesEdit);
      _canPost = _service.hasPermission(AppPermissions.entriesPost);

      if (!isEditing && hasCreatePerm) {
        _canEdit = true;
      } else if (isEditing && hasEditPerm) {
        _canEdit = true; 
      }

      // 4. تحميل بيانات القيد إذا كانت حالة "تعديل"
      if (isEditing) {
        final entry = await _service.getJournalEntryByNumber(widget.entryNumber!);
        if (entry != null) {
          _entryDate = entry.entryDate;
          _refController.text = entry.reference ?? '';
          _descController.text = entry.description ?? '';
          _lines = List.from(entry.lines);
          
          if (entry.status == 'posted') {
            _canEdit = false; // القيد المرحل لا يمكن تعديله
          }
        }
      }

      // إيقاف القيد بسطرين فارغين على الأقل للبداية
      if (_lines.isEmpty) { _addLine(); _addLine(); }

    } catch (e) {
      debugPrint("Error loading Journal Entry data: $e");
      _showSnack("حدث خطأ أثناء تحميل البيانات", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addLine() => setState(() => _lines.add(JournalEntryLine(accountId: '', description: _descController.text)));

  Future<void> _save(String targetStatus) async {
    if (!_canEdit || !_formKey.currentState!.validate()) return;

    double totalDebit = _lines.fold(0.0, (s, l) => s + l.debit);
    double totalCredit = _lines.fold(0.0, (s, l) => s + l.credit);
    
    // التحقق من توازن القيد (مدين = دائن)
    if ((totalDebit - totalCredit).abs() > 0.01) {
      _showSnack("القيد غير متوازن! الفرق: ${(totalDebit - totalCredit).toStringAsFixed(2)}", isError: true);
      return;
    }

    try {
      List<JournalEntryLine> linesToSend = [];
      List<JournalEntryLine> linesForPrint = [];
      
      for (var line in _lines) {
        if (line.accountId.isEmpty) continue;

        final accountObj = _allAccounts.firstWhere(
          (a) => a.code == line.accountId,
          orElse: () => throw Exception("الحساب ${line.accountId} غير موجود"),
        );

        linesToSend.add(JournalEntryLine(
          accountId: accountObj.id.toString(), 
          description: line.description,
          debit: line.debit,
          credit: line.credit,
          costCenterId: line.costCenterId,
        ));

        // نسخة الطباعة تحتوي على مسميات واضحة
        linesForPrint.add(JournalEntryLine(
          accountId: "${accountObj.code} - ${accountObj.nameAr}", 
          description: line.description,
          debit: line.debit,
          credit: line.credit,
          costCenterId: line.costCenterId,
        ));
      }

      final entry = JournalEntryModel(
        id: isEditing ? (await _service.getJournalEntryByNumber(widget.entryNumber!))?.id : null,
        entryNumber: isEditing ? widget.entryNumber! : '',
        entryDate: _entryDate,
        reference: _refController.text,
        description: _descController.text,
        status: targetStatus,
        lines: linesToSend,
      );
      
      String savedEntryNumber = "";
      if (isEditing) {
        savedEntryNumber = await _service.updateJournalEntry(entry);
      } else {
        savedEntryNumber = await _service.saveJournalEntry(entry);
      }
      
      if (mounted) {
        Navigator.pop(context);
        _showSnack(targetStatus == 'posted' ? "تم ترحيل القيد بنجاح" : "تم حفظ المسودة");

        // استدعاء حوار الطباعة بعد الحفظ الناجح
        _showPrintDialog(savedEntryNumber, linesForPrint);
      }
    } catch (e) {
      _showSnack("خطأ في العملية: $e", isError: true);
    }
  }

  void _showPrintDialog(String entryNum, List<JournalEntryLine> printLines) {
    final entryForPrint = JournalEntryModel(
      entryNumber: isEditing ? widget.entryNumber! : entryNum,
      entryDate: _entryDate,
      reference: _refController.text,
      description: _descController.text,
      lines: printLines,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("نجاح العملية"),
        content: const Text("تم الحفظ بنجاح. هل ترغب بطباعة سند القيد الآن؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("لا لاحقاً")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kDarkBrown),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfPreviewScreen(
                    title: "سند قيد ${entryForPrint.entryNumber}",
                    buildPdf: (format) => PdfService().generateJournalEntryPdf(entryForPrint, format),
                  ),
                ),
              );
            },
            child: const Text("طباعة الآن", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    double totalDebit = _lines.fold(0.0, (s, l) => s + l.debit);
    double totalCredit = _lines.fold(0.0, (s, l) => s + l.credit);
    bool isBalanced = (totalDebit - totalCredit).abs() < 0.01;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(isEditing ? "قيد رقم: ${widget.entryNumber}" : "إنشاء قيد جديد", 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppTheme.kDarkBrown,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          if (!_canEdit) 
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.amber.shade200, borderRadius: BorderRadius.circular(20)),
              child: const Center(child: Text("عرض فقط", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 11))),
            )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.kDarkBrown)) 
        : Form(
            key: _formKey,
            child: Column(children: [
              JournalEntryHeader(
                refController: _refController,
                descController: _descController,
                entryDate: _entryDate,
                canEdit: _canEdit,
                onDateChanged: (d) => setState(() => _entryDate = d),
              ),
              const SizedBox(height: 8),
              const JournalEntryTableHeader(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: _lines.length,
                  itemBuilder: (c, i) => JournalEntryRow(
                    key: ValueKey(_lines[i]), 
                    index: i,
                    line: _lines[i],
                    allAccounts: _allAccounts,
                    costCenters: _costCenters,
                    canEdit: _canEdit,
                    onRemove: () => setState(() => _lines.removeAt(i)),
                    onChanged: () => setState(() {}),
                  ),
                ),
              ),
              JournalEntryFooter(
                totalDebit: totalDebit,
                totalCredit: totalCredit,
                isBalanced: isBalanced,
                canEdit: _canEdit,
                canPost: _canPost,
                onAddLine: _addLine,
                onSaveDraft: () => _save('draft'),
                onPost: () => _save('posted'),
              ),
            ]),
          ),
    );
  }
}