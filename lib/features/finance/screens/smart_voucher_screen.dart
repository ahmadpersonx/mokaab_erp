import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_theme.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../core/models/account.dart';
import '../../../core/models/bank.dart';
import '../../../core/models/voucher.dart';
import '../../../../core/services/finance_formatter.dart';
import '../services/finance_service.dart';
import '../../../core/services/settings_service.dart'; // ✅ استيراد خدمة الإعدادات
import '../../../../core/services/pdf_service.dart';
import '../../../../core/screens/pdf_preview_screen.dart';

class SmartVoucherScreen extends StatefulWidget {
  final String voucherType; // 'receipt' (قبض) or 'payment' (صرف)
  final String? voucherNumber; // في حالة التعديل

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
  final PdfService _pdfService = PdfService();
  final SettingsService _settingsService = SettingsService(); // ✅ إنشاء نسخة من الخدمة
  final FinanceFormatter _formatter = FinanceFormatter();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // State Variables
  bool _isLoading = true;
  bool _isEditMode = false;
  String? _generatedVoucherNumber;
  DateTime _date = DateTime.now();
  
  // Accounts Lists
  List<Account> _creditAccounts = []; // الحساب المقابل (الدائن في القبض)
  List<Account> _debitAccounts = []; // حساب التوجيه (المدين في القبض)
  List<Bank> _banks = []; // قائمة البنوك للشيكات

  // Form Fields
  Account? _selectedCreditAccount; // العميل
  Account? _selectedDebitAccount; // الصندوق/البنك
  String _paymentMethod = 'cash'; // cash, check, transfer
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Check Fields
  final TextEditingController _checkNoController = TextEditingController();
  Bank? _selectedCheckBank;
  DateTime? _checkDueDate;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.voucherNumber != null;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // 1. جلب القوائم الأساسية
      if (widget.voucherType == 'receipt') {
        // في سند القبض: الطرف الدائن هو العملاء حصراً
        _creditAccounts = await _service.getCustomerAccounts();
      } else {
        // في سند الصرف: الطرف الدائن هو الصندوق/البنك (سيتم التعامل معه لاحقاً)
        // هنا سنفترض أننا نركز على سند القبض كما في الطلب
        _creditAccounts = await _service.getAllAccounts(); 
      }

      // جلب قائمة البنوك من التعريفات (لتعريف الشيكات)
      _banks = await _service.getBanks();

      // ✅ التحقق من صحة البنك المختار بعد تحديث القائمة
      if (_selectedCheckBank != null && !_banks.any((b) => b.id == _selectedCheckBank!.id)) {
        _selectedCheckBank = null;
      }

      // 2. إعداد الحسابات المدينة (الصناديق/البنوك) بناءً على طريقة الدفع الافتراضية
      await _updateDebitAccountsList();

      // 3. توليد الرقم أو جلب البيانات
      if (_isEditMode) {
        await _loadVoucherData();
      } else {
        _generatedVoucherNumber = await _service.generateVoucherNumber(widget.voucherType);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("خطأ في تحميل البيانات: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadVoucherData() async {
    // منطق تحميل السند للتعديل (يمكن إضافته لاحقاً)
    // حالياً نركز على الإنشاء الجديد كما في الطلب
  }

  /// تحديث قائمة الحسابات المدينة (أين تذهب الأموال؟) بناءً على طريقة الدفع
  Future<void> _updateDebitAccountsList() async {
    List<Account> accounts = [];
    if (_paymentMethod == 'cash' || _paymentMethod == 'check') {
      // نقدي أو شيك -> حسابات الصناديق (حسب طلب المستخدم للشيكات أيضاً)
      accounts = await _service.getCashBoxAccounts();
    } else if (_paymentMethod == 'transfer') {
      // حوالة -> حسابات البنوك (GL Accounts)
      accounts = await _service.getBankAccounts();
    }
    
    setState(() {
      _debitAccounts = accounts;
      // إعادة تعيين الاختيار إذا لم يعد موجوداً في القائمة الجديدة
      if (_selectedDebitAccount != null && !accounts.contains(_selectedDebitAccount)) {
        _selectedDebitAccount = null;
      }
    });
  }

  // --- Logic: Payment Sequence Calculation ---
  Future<Map<String, dynamic>> _calculatePaymentStats(int customerId) async {
    // جلب كل سندات هذا العميل
    final allVouchersData = await _service.getVouchers(type: 'receipt'); // يمكن تحسينه بفلتر في السيرفس
    final allVouchers = allVouchersData.map((v) => Voucher.fromJson(v)).toList();
    
    final customerVouchers = allVouchers.where((v) {
      // التحقق من أن السند يخص العميل (من خلال البنود)
      return v.lines.any((l) => l.account.id == customerId);
    }).toList();

    // ترتيب حسب التاريخ
    customerVouchers.sort((a, b) => a.date.compareTo(b.date));

    // السند الحالي هو الجديد، لذا ترتيبه هو العدد الحالي + 1
    final sequence = customerVouchers.length + 1;
    
    // إجمالي المدفوعات السابقة
    final totalPaid = customerVouchers.fold(0.0, (sum, v) => sum + v.amount);
    final currentAmount = double.tryParse(_amountController.text) ?? 0.0;

    return {
      'sequence': sequence,
      'total_paid': totalPaid + currentAmount,
      'count': sequence,
    };
  }

  Future<void> _saveVoucher() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCreditAccount == null || _selectedDebitAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء اختيار الحسابات")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      
      // 1. إنشاء السند
      final voucher = await _service.createVoucher(
        voucherNumber: _generatedVoucherNumber!,
        type: widget.voucherType,
        date: _date,
        paymentMethod: _paymentMethod,
        treasuryAccountCode: _selectedDebitAccount!.code, // تخزين كود الحساب المدين (حسب السكيما)
        description: _descriptionController.text,
        amount: amount,
        checkNo: _paymentMethod == 'check' ? _checkNoController.text : null,
        checkDueDate: _paymentMethod == 'check' ? _checkDueDate : null,
        bankName: _paymentMethod == 'check' ? _selectedCheckBank?.nameAr : null,
        bankId: _paymentMethod == 'check' ? _selectedCheckBank?.id : null,
        lines: [
          {
            'account_id': _selectedCreditAccount!.id, // العميل
            'amount': amount,
            'description': _descriptionController.text,
            'cost_center_id': null, // يمكن إضافته لاحقاً
          }
        ],
      );

      if (voucher != null) {
        if (mounted) {
          // 2. رسالة التأكيد والطباعة
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text("تم الحفظ بنجاح"),
              content: const Text("هل تريد طباعة السند؟"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx); // إغلاق الحوار
                    Navigator.pop(context); // الخروج من الشاشة
                  },
                  child: const Text("لا"),
                ),
                ElevatedButton.icon(
                  icon: const Icon(LucideIcons.printer),
                  label: const Text("نعم، طباعة"),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kSuccess, foregroundColor: Colors.white),
                  onPressed: () async {
                    Navigator.pop(ctx); // إغلاق الحوار
                    await _printVoucher(voucher);
                    if (mounted) Navigator.pop(context); // الخروج
                  },
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ في الحفظ: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _printVoucher(Voucher voucher) async {
    // حساب التسلسل للطباعة الاحترافية
    final stats = await _calculatePaymentStats(_selectedCreditAccount!.id);
    
    // تجهيز البيانات للطباعة
    final enrichedData = voucher.toJson();
    
    // إضافة بيانات العميل والحسابات للعرض
    enrichedData['voucher_lines'] = [
      {
        'accounts': {'name_ar': _selectedCreditAccount!.nameAr},
        'amount': voucher.amount,
      }
    ];

    // إضافة النص الاحترافي للوصف
    enrichedData['description'] = "${voucher.description ?? ''}\n\n"
        "----------------------------------------\n"
        "تسلسل الدفعة: ${stats['sequence']}\n"
        "إجمالي المدفوعات حتى الآن: ${_formatter.formatCurrency(stats['total_paid'])}";

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => PdfPreviewScreen(
            title: "طباعة سند قبض",
            buildPdf: (f) => _pdfService.generateVoucherPdf(enrichedData, "سند قبض", f),
          ),
        ),
      );
    }
  }

  // دالة مساعدة لفتح نافذة اختيار الحسابات المتعددة
  Future<String?> _selectAccounts(BuildContext context, String currentSelection) async {
    final allAccounts = await _service.getAllAccounts();
    // تصفية الحسابات الرئيسية فقط (isParent = true) لتسهيل الاختيار
    final parentAccounts = allAccounts.where((a) => a.isParent).toList();
    
    final selectedCodes = currentSelection.split(',').map((e) => e.trim()).toSet();

    if (!context.mounted) return null;

    return await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("اختر الحسابات الرئيسية المصدر"),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView.builder(
                  itemCount: parentAccounts.length,
                  itemBuilder: (context, index) {
                    final account = parentAccounts[index];
                    final isSelected = selectedCodes.contains(account.code);
                    return CheckboxListTile(
                      title: Text("${account.code} - ${account.nameAr}"),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selectedCodes.add(account.code);
                          } else {
                            selectedCodes.remove(account.code);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("إلغاء"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, selectedCodes.join(','));
                  },
                  child: const Text("تأكيد"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ✅ دالة جديدة لفتح نافذة الإعدادات
  void _showSettingsDialog() {
    final customerController = TextEditingController();
    final cashController = TextEditingController();
    final bankController = TextEditingController();
    String? selectedBankList;

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<dynamic>>(
          // جلب الإعدادات الحالية لعرضها في الحقول
          future: Future.wait([
            _settingsService.get('vouchers_customer_account_source', defaultValue: '1231'),
            _settingsService.get('vouchers_cash_account_source', defaultValue: '1211'),
            _settingsService.get('vouchers_bank_account_source', defaultValue: '1212'),
            _settingsService.get('vouchers_check_banks_source', defaultValue: 'banks'), // القيمة الافتراضية الصحيحة
            _service.getDefinitionTypes(), // جلب كل أنواع القوائم المتاحة
          ]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasData) {
              customerController.text = snapshot.data![0];
              cashController.text = snapshot.data![1];
              bankController.text = snapshot.data![2];
              
              // القيمة المخزنة حالياً
              String storedBankList = snapshot.data![3];
              
              // استخراج قائمة أنواع التعريفات
              final definitionTypes = (snapshot.data?.length ?? 0) > 4 ? List<Map<String, dynamic>>.from(snapshot.data![4]) : <Map<String, dynamic>>[];

              // التحقق من أن القيمة المخزنة موجودة في القوائم المتاحة
              if (storedBankList.isNotEmpty && definitionTypes.any((t) => t['code'] == storedBankList)) {
                selectedBankList = storedBankList;
              } else {
                // محاولة ذكية: البحث عن قائمة تحتوي على كلمة "bank" أو "بنوك"
                final defaultBank = definitionTypes.firstWhere(
                  (t) => t['code'].toString().toLowerCase().contains('bank') || t['name_ar'].toString().contains('بنوك'),
                  orElse: () => {},
                );
                if (defaultBank.isNotEmpty) selectedBankList = defaultBank['code'];
              }
              
              // تمرير القائمة للواجهة
              return _buildSettingsDialogContent(
                context, 
                customerController, 
                cashController, 
                bankController, 
                selectedBankList, 
                definitionTypes
              );
            }

            return const SizedBox(); // حالة غير متوقعة
          },
        );
      },
    );
  }

  Widget _buildSettingsDialogContent(
    BuildContext context,
    TextEditingController customerController,
    TextEditingController cashController,
    TextEditingController bankController,
    String? initialSelectedBankList,
    List<Map<String, dynamic>> definitionTypes,
  ) {
    // نستخدم StatefulBuilder داخل الديالوج لتحديث القيمة المختارة محلياً
    String? currentSelectedBankList = initialSelectedBankList;

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
              title: const Text('إعدادات مصادر البيانات'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Customer Accounts Source
                    TextFormField(
                      controller: customerController,
                      readOnly: true, // القراءة فقط، الاختيار عبر النقر
                      decoration: const InputDecoration(
                        labelText: 'مصادر حسابات العملاء',
                        hintText: 'اضغط للاختيار...',
                        suffixIcon: Icon(LucideIcons.list),
                      ),
                      onTap: () async {
                        final result = await _selectAccounts(context, customerController.text);
                        if (result != null) customerController.text = result;
                      },
                    ),
                    const SizedBox(height: 16),
                    // 2. Cash Accounts Source
                    TextFormField(
                      controller: cashController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'مصادر حسابات الخزينة',
                        hintText: 'اضغط للاختيار...',
                        suffixIcon: Icon(LucideIcons.list),
                      ),
                      onTap: () async {
                        final result = await _selectAccounts(context, cashController.text);
                        if (result != null) cashController.text = result;
                      },
                    ),
                    const SizedBox(height: 16),
                    // 3. Bank Accounts Source
                    TextFormField(
                      controller: bankController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'مصادر حسابات البنوك',
                        hintText: 'اضغط للاختيار...',
                        suffixIcon: Icon(LucideIcons.list),
                      ),
                      onTap: () async {
                        final result = await _selectAccounts(context, bankController.text);
                        if (result != null) bankController.text = result;
                      },
                    ),
                    const SizedBox(height: 16),
                    // ✅ إضافة قائمة منسدلة لاختيار مصدر قائمة البنوك
                    DropdownButtonFormField<String>(
                      value: currentSelectedBankList,
                      decoration: const InputDecoration(
                        labelText: 'مصدر قائمة البنوك (للشيكات)',
                      ),
                      items: definitionTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type['code'],
                          child: Text(type['name_ar']),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => currentSelectedBankList = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      // حفظ الإعدادات الجديدة
                      await _settingsService.set('vouchers_customer_account_source', customerController.text);
                      await _settingsService.set('vouchers_cash_account_source', cashController.text);
                      await _settingsService.set('vouchers_bank_account_source', bankController.text);
                      if (currentSelectedBankList != null) {
                        await _settingsService.set('vouchers_check_banks_source', currentSelectedBankList!);
                      }
                      
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الإعدادات بنجاح')));
                        _loadInitialData(); // إعادة تحميل البيانات بناءً على الإعدادات الجديدة
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في حفظ الإعدادات: $e'), backgroundColor: Colors.red));
                      }
                    }
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isReceipt = widget.voucherType == 'receipt';
    final primaryColor = isReceipt ? AppTheme.kSuccess : AppTheme.kError;

    return Scaffold(
      appBar: AppBar(
        title: Text(isReceipt ? "سند قبض جديد" : "سند صرف جديد"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // ✅ إضافة زر الإعدادات
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: _showSettingsDialog,
            tooltip: 'إعدادات مصادر البيانات',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Info
                    Row(
                      children: [
                        Expanded(
                          child: _buildReadOnlyField("رقم السند", _generatedVoucherNumber ?? '...'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2030));
                              if (d != null) setState(() => _date = d);
                            },
                            child: _buildReadOnlyField("التاريخ", DateFormat('yyyy-MM-dd').format(_date), icon: LucideIcons.calendar),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 2. Credit Account (Customer)
                    Text(isReceipt ? "بيانات العميل (الدافع)" : "الحساب المستفيد", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    DropdownSearch<Account>(
                      items: (f, l) => _creditAccounts,
                      itemAsString: (a) => "${a.code} - ${a.nameAr}",
                      compareFn: (item, selectedItem) => item.code == selectedItem?.code,
                      selectedItem: _selectedCreditAccount,
                      onChanged: (v) => setState(() => _selectedCreditAccount = v),
                      validator: (v) => v == null ? "حقل مطلوب" : null,
                      popupProps: const PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(hintText: "بحث باسم العميل أو الرمز...", isDense: true),
                        ),
                        constraints: BoxConstraints(maxHeight: 300), // ارتفاع مناسب لـ 4-5 عناصر
                      ),
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: isReceipt ? "اختر اسم العميل" : "اختر الحساب",
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(LucideIcons.user),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. Payment Method & Debit Account
                    Text("تفاصيل الدفع (المستلم)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: "طريقة الدفع", border: OutlineInputBorder()),
                            value: _paymentMethod,
                            items: const [
                              DropdownMenuItem(value: 'cash', child: Text("نقدي")),
                              DropdownMenuItem(value: 'check', child: Text("شيك")),
                              DropdownMenuItem(value: 'transfer', child: Text("حوالة بنكية")),
                            ],
                            onChanged: (v) {
                              setState(() {
                                _paymentMethod = v!;
                                _updateDebitAccountsList();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<Account>(
                            decoration: InputDecoration(
                              labelText: _paymentMethod == 'transfer' ? "حساب البنك (المستلم)" : "حساب الصندوق (المستلم)",
                              border: const OutlineInputBorder(),
                              prefixIcon: Icon(_paymentMethod == 'transfer' ? LucideIcons.landmark : LucideIcons.box),
                            ),
                            value: _selectedDebitAccount,
                            items: _debitAccounts.map((e) => DropdownMenuItem(value: e, child: Text(e.nameAr))).toList(),
                            onChanged: (v) => setState(() => _selectedDebitAccount = v),
                            validator: (v) => v == null ? "حقل مطلوب" : null,
                          ),
                        ),
                      ],
                    ),

                    // 4. Check Details (Conditional)
                    if (_paymentMethod == 'check') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("بيانات الشيك", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _checkNoController,
                                    decoration: const InputDecoration(labelText: "رقم الشيك", border: OutlineInputBorder(), isDense: true),
                                    validator: (v) => v!.isEmpty ? "مطلوب" : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                                      if (d != null) setState(() => _checkDueDate = d);
                                    },
                                    child: InputDecorator(
                                      decoration: const InputDecoration(labelText: "تاريخ الاستحقاق", border: OutlineInputBorder(), isDense: true),
                                      child: Text(_checkDueDate != null ? DateFormat('yyyy-MM-dd').format(_checkDueDate!) : "اختر التاريخ"),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<Bank>(
                              decoration: const InputDecoration(labelText: "البنك المسحوب عليه", border: OutlineInputBorder(), isDense: true),
                              value: _selectedCheckBank,
                              items: _banks.map((e) => DropdownMenuItem(value: e, child: Text(e.nameAr, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) => setState(() => _selectedCheckBank = v),
                              validator: (v) => v == null ? "مطلوب" : null,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // 5. Amount & Description
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "المبلغ",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(LucideIcons.dollarSign),
                        suffixText: "د.أ",
                      ),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "مطلوب";
                        if (double.tryParse(v) == null) return "رقم غير صحيح";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "البيان / الملاحظات",
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => v!.isEmpty ? "مطلوب" : null,
                    ),

                    const SizedBox(height: 30),

                    // 6. Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(LucideIcons.save),
                        label: const Text("حفظ السند", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _saveVoucher,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, {IconData? icon}) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade100,
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
      ),
      child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}