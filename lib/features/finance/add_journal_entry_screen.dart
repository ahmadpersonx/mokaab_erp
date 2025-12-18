// شاشة القيود الذكية: lib/features/finance/add_journal_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../core/models/account_model.dart';
import '../../core/models/journal_entry_model.dart';
import '../../core/models/cost_center_model.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/permissions.dart';
import 'finance_service.dart';

class AddJournalEntryScreen extends StatefulWidget {
  final String? entryNumber;
  const AddJournalEntryScreen({super.key, this.entryNumber});

  @override
  State<AddJournalEntryScreen> createState() => _AddJournalEntryScreenState();
}

class _AddJournalEntryScreenState extends State<AddJournalEntryScreen> {
  final FinanceService _service = FinanceService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _refController, _descController;
  DateTime _entryDate = DateTime.now();
  List<JournalEntryLine> _lines = [];
  List<AccountModel> _allAccounts = [];
  List<CostCenterModel> _costCenters = [];
  
  bool _isLoading = true;
  bool _canEdit = false;
  bool _canPost = false; // صلاحية الترحيل

  bool get isEditing => widget.entryNumber != null;

  // ستايل الحقول (Modern Style)
  final InputDecoration _inputDecoration = InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.kDarkBrown, width: 1.5)),
    filled: true,
    fillColor: Colors.white,
  );

  @override
  void initState() {
    super.initState();
    _refController = TextEditingController();
    _descController = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _service.loadUserPermissions();
      _allAccounts = (await _service.getAllAccounts()).where((a) => a.isTransaction).toList();
      _costCenters = await _service.getAllCostCenters();

      // التحقق من الصلاحيات
      bool hasCreatePerm = _service.hasPermission(AppPermissions.entriesCreate);
      bool hasEditPerm = _service.hasPermission(AppPermissions.entriesEdit);
      _canPost = _service.hasPermission(AppPermissions.entriesPost); // فحص صلاحية الترحيل

      // منطق التعديل
      if (!isEditing && hasCreatePerm) {
        _canEdit = true;
      } else if (isEditing && hasEditPerm) {
         // إذا كان القيد مرحلاً، نمنع التعديل إلا إذا كان هناك منطق خاص
        _canEdit = true; 
      }

      if (isEditing) {
        final entry = await _service.getJournalEntryByNumber(widget.entryNumber!);
        if (entry != null) {
          _entryDate = entry.entryDate;
          _refController.text = entry.reference ?? '';
          _descController.text = entry.description ?? '';
          _lines = List.from(entry.lines);
          
          // إذا كان القيد مرحلاً بالفعل (posted)، نمنع التعديل تماماً للحفاظ على البيانات
          if (entry.status == 'posted') {
            _canEdit = false;
          }
        }
      }
      if (_lines.isEmpty) { _addLine(); _addLine(); }

    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addLine() => setState(() => _lines.add(JournalEntryLine(accountId: '', description: _descController.text)));

  // دالة الحفظ المعدلة لتقبل الحالة (Draft / Posted)
  Future<void> _save(String targetStatus) async {
    if (!_canEdit || !_formKey.currentState!.validate()) return;

    double totalDebit = _lines.fold(0.0, (s, l) => s + l.debit);
    double totalCredit = _lines.fold(0.0, (s, l) => s + l.credit);
    
    // التحقق من التوازن (مطلوب في الحالتين لضمان نظافة البيانات)
    if ((totalDebit - totalCredit).abs() > 0.01) {
      _showSnack("القيد غير متوازن! الفرق: ${(totalDebit - totalCredit).toStringAsFixed(2)}", isError: true);
      return;
    }

    try {
      final entry = JournalEntryModel(
        id: isEditing ? (await _service.getJournalEntryByNumber(widget.entryNumber!))?.id : null,
        entryNumber: isEditing ? widget.entryNumber! : '',
        entryDate: _entryDate,
        reference: _refController.text,
        description: _descController.text,
        status: targetStatus, // ✅ هنا نرسل الحالة المختارة (draft أو posted)
        lines: _lines,
      );
      
      await (isEditing ? _service.updateJournalEntry(entry) : _service.saveJournalEntry(entry));
      
      if (mounted) {
        Navigator.pop(context);
        String msg = targetStatus == 'posted' ? "تم ترحيل القيد بنجاح" : "تم حفظ المسودة";
        _showSnack(msg, isError: false);
      }
    } catch (e) {
      _showSnack("خطأ في العملية: $e", isError: true);
    }
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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(isEditing ? "قيد رقم: ${widget.entryNumber}" : "إنشاء قيد جديد", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.kDarkBrown,
        foregroundColor: Colors.white,
        actions: [
          if (!_canEdit) 
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.amber.shade200, borderRadius: BorderRadius.circular(20)),
              child: const Center(child: Text("مرحل / للعرض", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12))),
            )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.kDarkBrown)) 
        : Form(
            key: _formKey,
            child: Column(children: [
              _buildTopSection(),
              const SizedBox(height: 8),
              _buildTableHeader(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: _lines.length,
                  itemBuilder: (c, i) => _buildRow(i),
                ),
              ),
              _buildFooter(),
            ]),
          ),
    );
  }

  // ... (نفس دوال _buildTopSection, _buildTableHeader, _buildRow السابقة تماماً بدون تغيير) ...
  // سأضع هنا دوال الواجهة نفسها لضمان النسخ الكامل الصحيح
  
  Widget _buildTopSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: Column(children: [
        Row(children: [
          Expanded(child: TextFormField(controller: _refController, readOnly: !_canEdit, decoration: _inputDecoration.copyWith(labelText: 'الرقم المرجعي', prefixIcon: const Icon(Icons.bookmark_border, size: 18)))),
          const SizedBox(width: 15),
          InkWell(
            onTap: !_canEdit ? null : () async {
              final d = await showDatePicker(context: context, initialDate: _entryDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (d != null) setState(() => _entryDate = d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.calendar_today, size: 18, color: AppTheme.kDarkBrown),
                const SizedBox(width: 10),
                Text(DateFormat('yyyy-MM-dd').format(_entryDate), style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        TextFormField(controller: _descController, readOnly: !_canEdit, decoration: _inputDecoration.copyWith(labelText: 'البيان العام', prefixIcon: const Icon(Icons.description_outlined, size: 18))),
      ]),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppTheme.kDarkBrown.withOpacity(0.9), borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
      child: Row(children: const [
        Expanded(flex: 3, child: Text("الحساب", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        SizedBox(width: 8),
        Expanded(flex: 3, child: Text("البيان / م.تكلفة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        SizedBox(width: 8),
        Expanded(flex: 1, child: Text("مدين", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        SizedBox(width: 8),
        Expanded(flex: 1, child: Text("دائن", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        SizedBox(width: 32),
      ]),
    );
  }

  Widget _buildRow(int i) {
    final selectedAcc = _lines[i].accountId.isNotEmpty ? _allAccounts.firstWhere((a) => a.code == _lines[i].accountId, orElse: () => _allAccounts.first) : null;
    bool needsCostCenter = selectedAcc?.requireCostCenter ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: i % 2 == 0 ? Colors.white : Colors.grey.shade50, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 3, child: DropdownSearch<AccountModel>(
            enabled: _canEdit,
            items: (f, l) => _allAccounts,
            itemAsString: (a) => "${a.code} - ${a.nameAr}",
            compareFn: (a, b) => a.code == b.code,
            selectedItem: selectedAcc,
            onChanged: (a) => setState(() => _lines[i].accountId = a?.code ?? ''),
            popupProps: const PopupProps.menu(showSearchBox: true, searchFieldProps: TextFieldProps(decoration: InputDecoration(hintText: "بحث...", isDense: true))),
            decoratorProps: DropDownDecoratorProps(decoration: _inputDecoration.copyWith(hintText: "اختر الحساب", contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12))),
        )),
        const SizedBox(width: 8),
        Expanded(flex: 3, child: Row(children: [
            Expanded(flex: needsCostCenter ? 3 : 5, child: TextFormField(initialValue: _lines[i].description, readOnly: !_canEdit, decoration: _inputDecoration.copyWith(hintText: "البيان"), onChanged: (v) => _lines[i].description = v)),
            if (needsCostCenter) ...[
              const SizedBox(width: 5),
              Expanded(flex: 2, child: Container(
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                child: DropdownButtonFormField<int>(isExpanded: true, initialValue: _lines[i].costCenterId, decoration: const InputDecoration(hintText: 'م.تكلفة', isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), prefixIcon: Icon(Icons.api, color: Colors.orange, size: 16)), items: _costCenters.map((cc) => DropdownMenuItem(value: cc.id, child: Text(cc.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))).toList(), onChanged: !_canEdit ? null : (v) => setState(() => _lines[i].costCenterId = v)),
              )),
            ]
        ])),
        const SizedBox(width: 8),
        Expanded(flex: 1, child: TextFormField(initialValue: _lines[i].debit == 0 ? '' : _lines[i].debit.toString(), readOnly: !_canEdit, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: _inputDecoration.copyWith(hintText: "0.0"), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green), onChanged: (v) => setState(() { _lines[i].debit = double.tryParse(v) ?? 0; if (_lines[i].debit > 0) _lines[i].credit = 0; }))),
        const SizedBox(width: 8),
        Expanded(flex: 1, child: TextFormField(initialValue: _lines[i].credit == 0 ? '' : _lines[i].credit.toString(), readOnly: !_canEdit, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: _inputDecoration.copyWith(hintText: "0.0"), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red), onChanged: (v) => setState(() { _lines[i].credit = double.tryParse(v) ?? 0; if (_lines[i].credit > 0) _lines[i].debit = 0; }))),
        if (_canEdit) Padding(padding: const EdgeInsets.only(right: 4), child: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 22), onPressed: () => setState(() => _lines.removeAt(i)))),
      ]),
    );
  }

  // ✅ الفوتر الجديد: يحتوي على زرين منفصلين (مسودة وترحيل)
  Widget _buildFooter() {
    double totalDebit = _lines.fold(0.0, (s, l) => s + l.debit);
    double totalCredit = _lines.fold(0.0, (s, l) => s + l.credit);
    double diff = totalDebit - totalCredit;
    bool isBalanced = diff.abs() < 0.01;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -3))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
             // مربعات الإجمالي (كما هي)
             Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("الإجمالي", style: TextStyle(color: Colors.grey, fontSize: 12)), Text(totalDebit.toStringAsFixed(2), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16))]),
             if (!isBalanced) 
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.red)), child: Text("غير متوازن: ${diff.toStringAsFixed(2)}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)))
             else const Chip(label: Text("متوازن ✅"), backgroundColor: Colors.greenAccent, visualDensity: VisualDensity.compact),
             Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("الإجمالي", style: TextStyle(color: Colors.grey, fontSize: 12)), Text(totalCredit.toStringAsFixed(2), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16))]),
          ]),
          const SizedBox(height: 16),
          
          Row(children: [
            if (_canEdit) 
              Expanded(child: OutlinedButton.icon(onPressed: _addLine, icon: const Icon(Icons.add), label: const Text("سطر جديد"), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)))),
            const SizedBox(width: 10),
            
            // ✅ زر حفظ مسودة (Draft)
            if (_canEdit) 
              Expanded(
                child: ElevatedButton(
                  onPressed: isBalanced ? () => _save('draft') : null, // نحفظ كـ مسودة
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 1,
                  ),
                  child: const Text("حفظ مسودة"),
                ),
              ),
            
            const SizedBox(width: 10),
            
            // ✅ زر الترحيل (Post) - يظهر فقط لمن يملك الصلاحية
            if (_canEdit && _canPost) 
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isBalanced ? () => _save('posted') : null, // نحفظ كـ مرحل
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.kDarkBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text("ترحيل"),
                ),
              ),
          ]),
        ]),
      ),
    );
  }
}