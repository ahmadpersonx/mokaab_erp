import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_theme.dart';
import '../services/finance_service.dart';
import '../../../core/models/account.dart';
import '../models/cost_center_model.dart';
import '../models/journal_entry_model.dart'; // استيراد الموديل الصحيح
import '../widgets/journal_entry_row.dart';

class AddJournalEntryScreen extends StatefulWidget {
  final String? entryNumber;

  const AddJournalEntryScreen({super.key, this.entryNumber});

  @override
  State<AddJournalEntryScreen> createState() => _AddJournalEntryScreenState();
}

class _AddJournalEntryScreenState extends State<AddJournalEntryScreen> {
  final FinanceService _service = FinanceService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _descController = TextEditingController();
  final TextEditingController _refController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  List<Account> _accounts = [];
  List<CostCenterModel> _costCenters = [];
  List<JournalLineModel> _lines = []; // استخدام JournalLineModel من ملف الموديل

  bool _isLoading = true;
  bool _isSaving = false;
  int _entryId = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final accounts = await _service.getAllAccounts();
      final costCenters = await _service.getAllCostCenters();

      setState(() {
        _accounts = accounts;
        _costCenters = costCenters;
      });

      if (widget.entryNumber != null) {
        await _loadEntryDetails(widget.entryNumber!);
      } else {
        _addLine();
        _addLine();
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEntryDetails(String number) async {
    final entry = await _service.getJournalEntryByNumber(number);
    if (entry != null && mounted) {
      setState(() {
        _entryId = entry.id;
        _selectedDate = entry.entryDate;
        _descController.text = entry.description ?? '';
        _refController.text = entry.reference ?? '';
        _lines = entry.lines;
        _isLoading = false;
      });
    }
  }

  void _addLine() {
    setState(() {
      _lines.add(JournalLineModel(id: 0, accountId: 0));
    });
  }

  void _removeLine(int index) {
    if (_lines.length > 2) {
      setState(() => _lines.removeAt(index));
    }
  }

  void _updateLine(int index, JournalLineModel newLine) {
    setState(() {
      _lines[index] = newLine;
    });
  }

  double get _totalDebit => _lines.fold(0.0, (sum, item) => sum + (item.debit ?? 0.0));
  double get _totalCredit => _lines.fold(0.0, (sum, item) => sum + (item.credit ?? 0.0));
  bool get _isBalanced => (_totalDebit - _totalCredit).abs() < 0.01 && _totalDebit > 0;

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);

    try {
      final entry = JournalEntryModel(
        id: _entryId,
        entryNumber: widget.entryNumber ?? "JE-${DateTime.now().millisecondsSinceEpoch}",
        entryDate: _selectedDate,
        description: _descController.text,
        reference: _refController.text,
        totalDebit: _totalDebit,
        totalCredit: _totalCredit,
        lines: _lines,
      );

      if (widget.entryNumber != null) {
        await _service.updateJournalEntry(_entryId, entry);
      } else {
        await _service.saveJournalEntry(entry);
      }
      
      if (mounted) Navigator.pop(context);

    } catch (e) {
      // Error handling
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("قيد يومية")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              children: [
                // ... Header Inputs ...
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _lines.length,
                  itemBuilder: (context, index) => JournalEntryRow(
                    line: _lines[index],
                    accounts: _accounts,
                    costCenters: _costCenters,
                    onChanged: (l) => _updateLine(index, l),
                    onDelete: () => _removeLine(index),
                  ),
                ),
                // ... Footer ...
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveEntry,
                  child: Text(_isSaving ? "جاري الحفظ..." : "حفظ"),
                )
              ],
            ),
          ),
    );
  }
}