//smart_voucher_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../core/models/account_model.dart';
import '../../core/models/cost_center_model.dart';
import 'finance_service.dart';
import 'banks_management_popup.dart'; // ✅ تأكد من وجود نافذة إدارة البنوك

class SmartVoucherScreen extends StatefulWidget {
  final String voucherType; // 'receipt' (قبض) or 'payment' (صرف)

  const SmartVoucherScreen({super.key, required this.voucherType});

  @override
  State<SmartVoucherScreen> createState() => _SmartVoucherScreenState();
}

class _SmartVoucherScreenState extends State<SmartVoucherScreen> {
  final FinanceService _service = FinanceService();
  final _formKey = GlobalKey<FormState>();

  // بيانات أساسية
  DateTime _date = DateTime.now();
  String _paymentMethod = 'cash'; 
  AccountModel? _treasuryAccount; // حساب الخزينة (الصندوق/البنك)
  
  // بيانات الشيك
  final TextEditingController _checkNoController = TextEditingController();
  DateTime _checkDueDate = DateTime.now();
  int? _selectedBankId; // رقم البنك المختار
  final TextEditingController _descController = TextEditingController();

  // القوائم المساعدة
  List<AccountModel> _allAccounts = [];
  List<AccountModel> _treasuryAccountsList = []; // الطرف الأول (صناديق وبنوك)
  List<AccountModel> _otherAccountsList = [];    // الطرف الثاني (عملاء/موردين/إيرادات/مصروفات)
  List<CostCenterModel> _costCenters = [];
  List<Map<String, dynamic>> _banksFromDb = []; 
  bool _isLoading = true;

  final List<Map<String, dynamic>> _lines = [];
  late Color _themeColor;
  late String _title;

  @override
  void initState() {
    super.initState();
    // تحديد لون وعنوان الشاشة حسب النوع
    _themeColor = widget.voucherType == 'receipt' ? Colors.green.shade700 : Colors.red.shade700;
    _title = widget.voucherType == 'receipt' ? 'سند قبض' : 'سند صرف';
    _loadData();
    _addLine();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _allAccounts = await _service.getAllAccounts();
      _costCenters = await _service.getAllCostCenters();
      _banksFromDb = await _service.getBanks(); 

      // ✅ 1. فلترة حسابات الخزينة (الطرف الأول - المدين في القبض / الدائن في الصرف)
      // الشرط: حساب حركة + (يبدأ بـ 11 أو اسمه يحتوي نقدية/صندوق/بنك) + (ليس عميل)
      _treasuryAccountsList = _allAccounts.where((a) {
        return a.isTransaction && 
               (a.code.startsWith('11') || a.nameAr.contains('صندوق') || a.nameAr.contains('بنك') || a.nameAr.contains('نقدية')) &&
               !a.nameAr.contains('عملاء'); // استثناء العملاء
      }).toList();

      // ✅ 2. فلترة الحسابات المقابلة (الطرف الثاني) بدقة محاسبية
      _otherAccountsList = _allAccounts.where((a) {
        // أولاً: يجب ألا يكون من حسابات الخزينة (لا نقبض من صندوق لصندوق في السند العادي)
        if (_treasuryAccountsList.contains(a)) return false;
        
        // ثانياً: الفلترة حسب نوع السند
        if (widget.voucherType == 'receipt') {
          // 📥 سند قبض: الطرف الدائن
          // المسموح: العملاء (أصول)، الإيرادات (4)، الخصوم (2)، حقوق الملكية (3)
          // الممنوع: المصروفات (5) - إلا في حالات نادرة جداً كاسترداد مصروف
          return !a.code.startsWith('5'); 
        } else {
          // 📤 سند صرف: الطرف المدين
          // المسموح: الموردين (خصوم)، المصروفات (5)، الأصول (1)، حقوق الملكية (3 - مسحوبات)
          // الممنوع: الإيرادات (4) - إلا في حالات نادرة جداً كإرجاع إيراد
          return !a.code.startsWith('4');
        }
      }).toList();

    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addLine() {
    setState(() {
      _lines.add({
        'account': null,
        'amount': 0.0,
        'cost_center': null,
        'description': '',
      });
    });
  }

  double get _totalAmount => _lines.fold(0.0, (sum, line) => sum + (line['amount'] as double));

  Future<void> _saveVoucher() async {
    if (!_formKey.currentState!.validate()) return;
    if (_treasuryAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يجب اختيار حساب الصندوق/البنك")));
      return;
    }
    if (_totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("قيمة السند يجب أن تكون أكبر من صفر")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> formattedLines = _lines.map((l) => {
        'account_id': (l['account'] as AccountModel).code,
        'amount': l['amount'],
        'cost_center_id': (l['cost_center'] as CostCenterModel?)?.id,
        'description': l['description'],
      }).toList();

      await _service.createVoucher(
        type: widget.voucherType,
        paymentMethod: _paymentMethod,
        date: _date,
        treasuryAccountId: _treasuryAccount!.code,
        totalAmount: _totalAmount,
        description: _descController.text,
        lines: formattedLines,
        checkNo: _paymentMethod == 'check' ? _checkNoController.text : null,
        bankId: _paymentMethod == 'check' ? _selectedBankId : null,
        checkDueDate: _paymentMethod == 'check' ? _checkDueDate : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم حفظ $_title وترحيل القيد بنجاح ✅"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e"), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _themeColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Form(
            key: _formKey,
            child: Column(
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      children: [
                        _buildLinesHeader(),
                        Expanded(
                          child: ListView.separated(
                            itemCount: _lines.length,
                            separatorBuilder: (c, i) => const Divider(height: 1),
                            itemBuilder: (c, i) => _buildLineRow(i),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addLine,
                          icon: const Icon(LucideIcons.plusCircle),
                          label: const Text("إضافة حساب آخر"),
                          style: TextButton.styleFrom(foregroundColor: _themeColor),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (d != null) setState(() => _date = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'تاريخ السند', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(10)),
                    child: Row(children: [const Icon(LucideIcons.calendar, size: 16), const SizedBox(width: 8), Text(DateFormat('yyyy-MM-dd').format(_date))]),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(labelText: 'طريقة الدفع', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(10)),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('نقدي')),
                    DropdownMenuItem(value: 'check', child: Text('شيك')),
                    DropdownMenuItem(value: 'transfer', child: Text('حوالة بنكية')),
                  ],
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          DropdownSearch<AccountModel>(
            items: (f, l) => _treasuryAccountsList,
            itemAsString: (a) => "${a.code} - ${a.nameAr}",
            compareFn: (item, selectedItem) => item.code == selectedItem.code,
            selectedItem: _treasuryAccount,
            onChanged: (val) => setState(() => _treasuryAccount = val),
            decoratorProps: DropDownDecoratorProps(
              decoration: InputDecoration(
                labelText: widget.voucherType == 'receipt' ? 'إيداع في (الصندوق/البنك)' : 'صرف من (الصندوق/البنك)',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(widget.voucherType == 'receipt' ? LucideIcons.arrowDownCircle : LucideIcons.arrowUpCircle, color: _themeColor),
                filled: true,
                fillColor: _themeColor.withOpacity(0.05),
                isDense: true,
              ),
            ),
            popupProps: const PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(decoration: InputDecoration(hintText: "بحث في الصناديق والبنوك...", isDense: true)),
            ),
          ),
          
          if (_paymentMethod == 'check') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("بيانات الشيك", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.brown)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextFormField(controller: _checkNoController, decoration: const InputDecoration(labelText: 'رقم الشيك', isDense: true, border: OutlineInputBorder(), filled: true, fillColor: Colors.white))),
                    const SizedBox(width: 10),
                    Expanded(child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(context: context, initialDate: _checkDueDate, firstDate: DateTime.now(), lastDate: DateTime(2100));
                        if (d != null) setState(() => _checkDueDate = d);
                      },
                      child: InputDecorator(decoration: const InputDecoration(labelText: 'تاريخ الاستحقاق', isDense: true, border: OutlineInputBorder(), filled: true, fillColor: Colors.white), child: Text(DateFormat('yyyy-MM-dd').format(_checkDueDate))),
                    )),
                  ]),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedBankId,
                          decoration: const InputDecoration(labelText: 'اسم البنك', isDense: true, border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                          items: _banksFromDb.map((bank) => DropdownMenuItem(
                            value: bank['id'] as int, 
                            child: Text(bank['name'])
                          )).toList(),
                          onChanged: (val) => setState(() => _selectedBankId = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                        child: IconButton(
                          icon: const Icon(LucideIcons.settings, color: Colors.grey),
                          tooltip: "إدارة قائمة البنوك",
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => BanksManagementPopup(
                                onUpdate: () async {
                                  final updatedBanks = await _service.getBanks();
                                  setState(() => _banksFromDb = updatedBanks);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          TextFormField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'البيان العام للسند', border: OutlineInputBorder(), prefixIcon: Icon(LucideIcons.fileText)),
          ),
        ],
      ),
    );
  }

  Widget _buildLinesHeader() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.grey.shade100,
      child: Row(children: const [
        Expanded(flex: 3, child: Text("الحساب المقابل (عميل/مورد/إيراد)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        SizedBox(width: 5),
        Expanded(flex: 2, child: Text("المبلغ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        SizedBox(width: 5),
        Expanded(flex: 2, child: Text("مركز التكلفة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        SizedBox(width: 30),
      ]),
    );
  }

  Widget _buildLineRow(int i) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3, 
            child: DropdownSearch<AccountModel>(
              items: (f, l) => _otherAccountsList, // ✅ القائمة المفلترة بعناية
              itemAsString: (a) => a.nameAr,
              compareFn: (item, selectedItem) => item.code == selectedItem.code,
              selectedItem: _lines[i]['account'],
              onChanged: (val) => setState(() => _lines[i]['account'] = val),
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(decoration: InputDecoration(hintText: "بحث...", isDense: true))
              ),
              decoratorProps: const DropDownDecoratorProps(decoration: InputDecoration(hintText: "اختر الحساب", isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12))),
            )
          ),
          const SizedBox(width: 5),
          Expanded(flex: 2, child: TextFormField(
            initialValue: _lines[i]['amount'].toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "0.00", isDense: true, border: OutlineInputBorder()),
            onChanged: (v) => setState(() => _lines[i]['amount'] = double.tryParse(v) ?? 0.0),
          )),
          const SizedBox(width: 5),
          Expanded(flex: 2, child: DropdownButtonFormField<CostCenterModel>(
            initialValue: _lines[i]['cost_center'],
            items: _costCenters.map((c) => DropdownMenuItem(value: c, child: Text(c.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => setState(() => _lines[i]['cost_center'] = v),
            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), hintText: "بلا", contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
          )),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 20),
            onPressed: () => setState(() => _lines.removeAt(i)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))]),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("إجمالي السند", style: TextStyle(color: Colors.grey)),
                Text(_totalAmount.toStringAsFixed(2), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _themeColor)),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _saveVoucher,
              style: ElevatedButton.styleFrom(
                backgroundColor: _themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(LucideIcons.save),
              label: const Text("حفظ وترحيل", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}