// FileName: lib/features/finance/screens/smart_voucher_screen.dart
// Revision: 2.1 (Fixed Syntax Errors & Linked with System Definitions)
// Date: 2025-12-19

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/permissions.dart';
import '../models/account_model.dart'; // ✅ المسار الصحيح
import '../services/finance_service.dart'; // ✅ المسار الصحيح

class SmartVoucherScreen extends StatefulWidget {
  final String voucherType; // 'receipt' or 'payment'
  final String? voucherNumber;

  const SmartVoucherScreen({
    super.key,
    required this.voucherType,
    this.voucherNumber,
  });

  @override
  State<SmartVoucherScreen> createState() => _SmartVoucherScreenState();
}

class _SmartVoucherScreenState extends State<SmartVoucherScreen> {
  final FinanceService _service = FinanceService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _refController = TextEditingController();
  final TextEditingController _checkNumController = TextEditingController();

  // State Data
  DateTime _selectedDate = DateTime.now();
  String _paymentMethod = 'cash'; // cash, check, transfer
  AccountModel? _selectedAccount;
  Map<String, dynamic>? _selectedBank;
  
  List<AccountModel> _accounts = [];
  List<Map<String, dynamic>> _banks = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // جلب الحسابات الفرعية فقط
      final accountsData = await _service.getAllAccounts();
      _accounts = accountsData.where((a) => !a.isParent).toList();

      // جلب البنوك من نظام التعريفات الموحد (النوع banks)
      _banks = await _service.getBanks();

      if (widget.voucherNumber != null) {
        // منطق تحميل بيانات السند للتعديل يوضع هنا
      }
    } catch (e) {
      _showSnack("خطأ في تحميل البيانات: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveVoucher() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccount == null) {
      _showSnack("يرجى اختيار الحساب", isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      // تنفيذ عملية الحفظ عبر FinanceService
      await Future.delayed(const Duration(seconds: 1)); // محاكاة عملية الحفظ
      
      if (mounted) {
        _showSnack("تم حفظ السند بنجاح");
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnack("فشل الحفظ: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.voucherType == 'receipt' ? "سند قبض" : "سند صرف";
    Color themeColor = widget.voucherType == 'receipt' ? Colors.green.shade700 : Colors.red.shade700;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(themeColor),
                    const SizedBox(height: 20),
                    _buildMainFields(),
                    const SizedBox(height: 20),
                    _buildPaymentMethodSection(themeColor),
                    if (_paymentMethod != 'cash') _buildBankSection(),
                    const SizedBox(height: 30),
                    _buildSaveButton(themeColor),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(Color color) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: color.withOpacity(0.2))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("تاريخ السند", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2026),
                      );
                      if (date != null) setState(() => _selectedDate = date);
                    },
                    icon: const Icon(LucideIcons.calendar, size: 18),
                    label: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: _refController,
                decoration: const InputDecoration(labelText: "رقم المرجع (إن وجد)", isDense: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainFields() {
    return Column(
      children: [
        DropdownButtonFormField<AccountModel>(
          value: _selectedAccount,
          decoration: const InputDecoration(labelText: "الحساب المالي", border: OutlineInputBorder(), prefixIcon: Icon(LucideIcons.user)),
          items: _accounts.map((acc) => DropdownMenuItem(value: acc, child: Text("${acc.code} - ${acc.nameAr}"))).toList(),
          onChanged: (val) => setState(() => _selectedAccount = val),
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(labelText: "المبلغ الإجمالي", border: OutlineInputBorder(), prefixIcon: Icon(LucideIcons.coins), suffixText: "د.أ"),
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _noteController,
          maxLines: 2,
          decoration: const InputDecoration(labelText: "البيان / ملاحظات", border: OutlineInputBorder(), prefixIcon: Icon(LucideIcons.fileText)),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("وسيلة الدفع", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            _methodChip("نقد", 'cash', color),
            const SizedBox(width: 10),
            _methodChip("شيك", 'check', color),
            const SizedBox(width: 10),
            _methodChip("تحويل", 'transfer', color),
          ],
        ),
      ],
    );
  }

  Widget _methodChip(String label, String value, Color color) {
    bool isSelected = _paymentMethod == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentMethod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? color : Colors.grey.shade300),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildBankSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedBank,
            decoration: const InputDecoration(labelText: "اختر البنك", border: OutlineInputBorder(), prefixIcon: Icon(LucideIcons.building)),
            items: _banks.map((bank) => DropdownMenuItem(value: bank, child: Text(bank['name']))).toList(),
            onChanged: (val) => setState(() => _selectedBank = val),
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _checkNumController,
            decoration: InputDecoration(labelText: _paymentMethod == 'check' ? "رقم الشيك" : "رقم الحوالة", border: const OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(Color color) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: _isSaving ? null : _saveVoucher,
        icon: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Icon(LucideIcons.save),
        label: Text(_isSaving ? "جاري الحفظ..." : "حفظ السند", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}