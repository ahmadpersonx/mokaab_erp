//الكود المحدث لملف add_journal_entry_screen.dart (مع نظام الصلاحيات)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/models/account_model.dart';
import '../../core/models/journal_entry_model.dart';
import '../../core/constants/app_theme.dart';
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
  String userRole = "viewer";
  bool _isLoading = true;

  bool get isEditing => widget.entryNumber != null;

  bool get canEdit {
    if (userRole == 'admin') return true;
    if (userRole == 'accountant') return true; // مسموح للمحاسب الإضافة والتعديل في هذا النموذج
    return false;
  }

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
      final profile = await _service.getCurrentUserProfile();
      userRole = profile?['role'] ?? 'viewer';
      _allAccounts = (await _service.getAllAccounts()).where((a) => a.isTransaction).toList();

      if (isEditing) {
        final entry = await _service.getJournalEntryByNumber(widget.entryNumber!);
        if (entry != null) {
          setState(() {
            _entryDate = entry.entryDate;
            _refController.text = entry.reference ?? '';
            _descController.text = entry.description ?? '';
            _lines = List.from(entry.lines);
          });
        }
      }
      if (_lines.isEmpty) { _addLine(); _addLine(); }
    } catch (e) {
      debugPrint("Error loading: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addLine() => setState(() => _lines.add(JournalEntryLine(accountId: '', description: _descController.text)));

  Future<void> _save() async {
    if (!canEdit || !_formKey.currentState!.validate()) return;
    
    double totalDebit = _lines.fold(0.0, (s, l) => s + l.debit);
    double totalCredit = _lines.fold(0.0, (s, l) => s + l.credit);
    
    if ((totalDebit - totalCredit).abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("القيد غير متوازن!"), backgroundColor: Colors.red));
      return;
    }

    try {
      final entry = JournalEntryModel(
        id: isEditing ? (await _service.getJournalEntryByNumber(widget.entryNumber!))?.id : null,
        entryNumber: isEditing ? widget.entryNumber! : '',
        entryDate: _entryDate, reference: _refController.text, description: _descController.text, lines: _lines,
      );
      await (isEditing ? _service.updateJournalEntry(entry) : _service.saveJournalEntry(entry));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Save error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? "قيد: ${widget.entryNumber}" : "إضافة قيد"), backgroundColor: AppTheme.kDarkBrown, foregroundColor: Colors.white),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Form(
        key: _formKey,
        child: Column(children: [
          if (!canEdit) Container(width: double.infinity, color: Colors.amber.shade100, padding: const EdgeInsets.all(8), child: const Text("وضع العرض فقط", textAlign: TextAlign.center)),
          _buildHeader(),
          const Divider(height: 1),
          Expanded(child: ListView.builder(itemCount: _lines.length, itemBuilder: (c, i) => _buildRow(i))),
          _buildFooter(),
        ]),
      ),
    );
  }

  Widget _buildHeader() => Padding(padding: const EdgeInsets.all(12), child: Column(children: [
    Row(children: [
      Expanded(child: TextFormField(controller: _refController, readOnly: !canEdit, decoration: const InputDecoration(labelText: 'المرجع', border: OutlineInputBorder()))),
      const SizedBox(width: 10),
      InkWell(
        onTap: !canEdit ? null : () async {
          final d = await showDatePicker(context: context, initialDate: _entryDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
          if (d != null) setState(() => _entryDate = d);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
          child: Row(children: [const Icon(Icons.calendar_today, size: 16), const SizedBox(width: 8), Text(DateFormat('yyyy-MM-dd').format(_entryDate))]),
        ),
      ),
    ]),
    const SizedBox(height: 10),
    TextFormField(controller: _descController, readOnly: !canEdit, decoration: const InputDecoration(labelText: 'البيان العام للقيد', border: OutlineInputBorder())),
  ]));

  Widget _buildRow(int i) => Card(margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [
    Row(children: [
      Expanded(flex: 3, child: DropdownSearch<AccountModel>(
        enabled: canEdit,
        items: (f, l) => _allAccounts,
        itemAsString: (a) => "${a.code} - ${a.nameAr}",
        compareFn: (a, b) => a.code == b.code,
        selectedItem: _lines[i].accountId.isEmpty ? null : _allAccounts.firstWhere((a) => a.code == _lines[i].accountId, orElse: () => _allAccounts.first),
        onChanged: (a) => setState(() => _lines[i].accountId = a?.code ?? ''),
        decoratorProps: const DropDownDecoratorProps(decoration: InputDecoration(labelText: "الحساب", border: OutlineInputBorder(), isDense: true)),
      )),
      const SizedBox(width: 10),
      Expanded(child: TextFormField(
        initialValue: _lines[i].debit == 0 ? '' : _lines[i].debit.toString(), 
        readOnly: !canEdit, 
        decoration: const InputDecoration(labelText: 'مدين', border: OutlineInputBorder(), isDense: true), 
        keyboardType: TextInputType.number, 
        onChanged: (v) => setState(() {
          _lines[i].debit = double.tryParse(v) ?? 0;
          if (_lines[i].debit > 0) _lines[i].credit = 0;
        })
      )),
      const SizedBox(width: 5),
      Expanded(child: TextFormField(
        initialValue: _lines[i].credit == 0 ? '' : _lines[i].credit.toString(), 
        readOnly: !canEdit, 
        decoration: const InputDecoration(labelText: 'دائن', border: OutlineInputBorder(), isDense: true), 
        keyboardType: TextInputType.number, 
        onChanged: (v) => setState(() {
          _lines[i].credit = double.tryParse(v) ?? 0;
          if (_lines[i].credit > 0) _lines[i].debit = 0;
        })
      )),
      if (canEdit) IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _lines.removeAt(i))),
    ]),
    const SizedBox(height: 5),
    TextFormField(
      initialValue: _lines[i].description,
      readOnly: !canEdit,
      decoration: const InputDecoration(hintText: "بيان السطر (ملاحظات)", border: UnderlineInputBorder(), isDense: true),
      onChanged: (v) => _lines[i].description = v,
    )
  ])));

  Widget _buildFooter() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text("إجمالي مدين: ${_lines.fold(0.0, (s, l) => s + l.debit).toStringAsFixed(2)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        Text("إجمالي دائن: ${_lines.fold(0.0, (s, l) => s + l.credit).toStringAsFixed(2)}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        if (canEdit) Expanded(child: OutlinedButton.icon(onPressed: _addLine, icon: const Icon(Icons.add), label: const Text("إضافة سطر"))),
        const SizedBox(width: 10),
        if (canEdit) Expanded(child: ElevatedButton.icon(
          onPressed: _save, 
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kDarkBrown, foregroundColor: Colors.white), 
          icon: const Icon(Icons.save), label: const Text("حفظ القيد")
        )),
      ]),
    ]),
  );
}