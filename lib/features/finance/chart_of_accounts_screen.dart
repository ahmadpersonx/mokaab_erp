// [كود رقم 18] - chart_of_accounts_screen.dartimport 'dart:math';import 'dart:math';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/account_model.dart';
import '../../core/constants/app_theme.dart';
import '../../core/services/excel_service.dart';
import 'finance_service.dart';

class ChartOfAccountsScreen extends StatefulWidget {
  const ChartOfAccountsScreen({super.key});

  @override
  State<ChartOfAccountsScreen> createState() => _ChartOfAccountsScreenState();
}

class _ChartOfAccountsScreenState extends State<ChartOfAccountsScreen> {
  final FinanceService _service = FinanceService();
  final ExcelService _excelService = ExcelService(); // خدمة الإكسل
  
  List<AccountModel> _accounts = [];
  bool _isLoading = true;

  // تعريف فئات الحسابات الرئيسية (لضمان التكويد المحاسبي الصحيح)
  final Map<String, Map<String, dynamic>> _rootCategories = {
    '1': {'name': '1- الأصول (Assets)', 'nature': 'debit'},
    '2': {'name': '2- الخصوم (Liabilities)', 'nature': 'credit'},
    '3': {'name': '3- حقوق الملكية (Equity)', 'nature': 'credit'},
    '4': {'name': '4- الإيرادات (Revenue)', 'nature': 'credit'},
    '5': {'name': '5- المصروفات (Expenses)', 'nature': 'debit'},
  };

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    // جلب الشجرة كاملة
    try {
      final data = await _service.getAllAccounts();
      setState(() {
        _accounts = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // التعامل مع الخطأ بصمت أو إظهار سناك بار
    }
  }

  // دالة توليد الكود "الخبير"
  String _generateAutoCode({AccountModel? parent, String? rootCategoryPrefix}) {
    if (parent != null) {
      // حالة حساب فرعي: كود الأب + رقمين عشوائيين
      String randomSuffix = Random().nextInt(99).toString().padLeft(2, '0');
      return '${parent.code}$randomSuffix'; 
    } else {
      // حالة حساب رئيسي: يبدأ بـ 1، 2، 3... بناءً على الفئة المختارة
      String prefix = rootCategoryPrefix ?? '1';
      String suffix = Random().nextInt(9).toString(); 
      return '$prefix$suffix'; 
    }
  }

  // ديالوج الإضافة/التعديل "الخبير"
  void _showAccountDialog({AccountModel? accountToEdit, AccountModel? parentAccount}) {
    
    // تحديد القيم الأولية
    String selectedRootCategory = accountToEdit != null 
        ? accountToEdit.code[0] 
        : (parentAccount != null ? parentAccount.code[0] : '1');

    // تحديد الطبيعة "الأصلية" (بدون عكس)
    String baseNature = parentAccount?.nature ?? _rootCategories[selectedRootCategory]!['nature'];
    
    // هل الحساب حالياً معكوس؟
    bool isContra = accountToEdit?.isContra ?? false;
    
    // الطبيعة النهائية المحسوبة
    String currentNature = accountToEdit?.nature ?? (isContra ? (baseNature == 'debit' ? 'credit' : 'debit') : baseNature);

    final codeController = TextEditingController(
      text: accountToEdit?.code ?? _generateAutoCode(parent: parentAccount, rootCategoryPrefix: selectedRootCategory)
    );
    final nameController = TextEditingController(text: accountToEdit?.nameAr);
    bool requireCostCenter = accountToEdit?.requireCostCenter ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            
            // دالة لحساب الطبيعة
            void recalculateNature() {
              if (isContra) {
                currentNature = baseNature == 'debit' ? 'credit' : 'debit';
              } else {
                currentNature = baseNature;
              }
            }

            void updateRootCategory(String? newCategory) {
              if (newCategory != null && accountToEdit == null && parentAccount == null) {
                setStateDialog(() {
                  selectedRootCategory = newCategory;
                  baseNature = _rootCategories[newCategory]!['nature'];
                  recalculateNature(); 
                  codeController.text = _generateAutoCode(rootCategoryPrefix: newCategory); 
                });
              }
            }

            return AlertDialog(
              title: Row(
                children: [
                  Icon(parentAccount != null ? Icons.subdirectory_arrow_right : Icons.account_balance, color: AppTheme.kDarkBrown),
                  const SizedBox(width: 8),
                  Text(accountToEdit == null ? 'إضافة حساب' : 'تعديل حساب'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // اختيار الفئة الرئيسية (فقط للجديد الرئيسي)
                    if (parentAccount == null && accountToEdit == null) ...[
                      const Text('نوع الحساب الرئيسي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: selectedRootCategory,
                        items: _rootCategories.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value['name']))).toList(),
                        onChanged: updateRootCategory,
                      ),
                      const SizedBox(height: 15),
                    ],

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'اسم الحساب', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 15),

                    // --- منطقة الطبيعة والحساب العكسي ---
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isContra ? Colors.red.withOpacity(0.05) : Colors.grey.shade50,
                        border: Border.all(color: isContra ? Colors.red.shade200 : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(currentNature == 'debit' ? Icons.add_circle : Icons.remove_circle, 
                                   color: currentNature == 'debit' ? Colors.green : Colors.red),
                              const SizedBox(width: 10),
                              Text(
                                currentNature == 'debit' ? 'مدين (Debit)' : 'دائن (Credit)',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(),
                          
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('حساب عكسي (Contra Account)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: const Text('مثل مجمع الإهلاك (دائن) تحت الأصول', style: TextStyle(fontSize: 11)),
                            value: isContra,
                            activeColor: Colors.red,
                            onChanged: (val) {
                              if (val == true) {
                                // تحذير الأمان
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Row(children: [Icon(Icons.warning, color: Colors.orange), SizedBox(width: 8), Text("تنبيه محاسبي")]),
                                    content: const Text("تفعيل هذا الخيار سيجعل طبيعة الحساب عكس طبيعة الحساب الرئيسي.\nيستخدم فقط لحالات خاصة (مجمع إهلاك، مردودات).\n\nهل أنت متأكد؟"),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          setStateDialog(() {
                                            isContra = true;
                                            recalculateNature();
                                          });
                                        },
                                        child: const Text("تفعيل"),
                                      )
                                    ],
                                  ),
                                );
                              } else {
                                setStateDialog(() {
                                  isContra = false;
                                  recalculateNature();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    // ------------------------------------

                    const SizedBox(height: 15),
                    SwitchListTile(
                      title: const Text('إلزامية مركز التكلفة؟', style: TextStyle(fontSize: 14)),
                      value: requireCostCenter,
                      activeThumbColor: AppTheme.kDarkBrown,
                      onChanged: (val) => setStateDialog(() => requireCostCenter = val),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: codeController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'كود الحساب (تلقائي)',
                        filled: true, fillColor: Colors.grey.shade200, border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.qr_code),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kDarkBrown, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      int newLevel = accountToEdit?.level ?? (parentAccount != null ? parentAccount.level + 1 : 1);

                      final newAccount = AccountModel(
                        id: accountToEdit?.id,
                        code: codeController.text,
                        nameAr: nameController.text,
                        parentCode: parentAccount?.code ?? accountToEdit?.parentCode,
                        nature: currentNature,
                        isTransaction: true,
                        level: newLevel,
                        requireCostCenter: requireCostCenter,
                        isContra: isContra,
                      );

                      try {
                        if (accountToEdit == null) {
                          await _service.addAccount(newAccount);
                        } else {
                          await _service.updateAccount(
                            newAccount.id!, 
                            newAccount.nameAr, 
                            newAccount.nature, 
                            newAccount.requireCostCenter,
                            newAccount.isContra
                          );
                        }
                        if (mounted) {
                          Navigator.pop(context);
                          _loadAccounts();
                        }
                      } catch (e) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                      }
                    }
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل الحسابات'),
        centerTitle: true,
        actions: [
          // زر القائمة للاستيراد والتصدير
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'export') {
                if (_accounts.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد بيانات للتصدير')));
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري إنشاء ملف Excel...')));
                
                // استقبال الرسالة لعرضها للمستخدم (مثلاً: مكان الحفظ)
                String message = await _excelService.exportAccountsToExcel(_accounts);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                }

              } else if (value == 'import') {
                bool confirm = await showDialog(
                  context: context, 
                  builder: (ctx) => AlertDialog(
                    title: const Text("استيراد من Excel"),
                    content: const Text("سيتم إضافة الحسابات من ملف الإكسل.\nيفضل عمل تصدير أولاً لفهم القالب.\n\nهل تريد المتابعة؟"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("إلغاء")),
                      ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("اختيار ملف")),
                    ],
                  )) ?? false;

                if (confirm) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري الاستيراد...')));
                  String result = await _excelService.importAccountsFromExcel();
                  if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
                     _loadAccounts(); // تحديث القائمة بعد الاستيراد
                  }
                }
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download, color: Colors.green),
                      SizedBox(width: 8),
                      Text('تصدير (Backup)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [
                      Icon(Icons.upload, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('استيراد من Excel'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAccountDialog(parentAccount: null),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
              ? const Center(child: Text('لا توجد حسابات، ابدأ بإضافة حساب رئيسي أو استورد من Excel'))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: _accounts.length,
                  itemBuilder: (context, index) {
                    return _buildAccountRow(_accounts[index]);
                  },
                ),
    );
  }

  Widget _buildAccountRow(AccountModel account) {
    double indent = (account.level - 1) * 24.0;
    bool isRoot = account.level == 1;

    return Padding(
      padding: EdgeInsets.only(right: indent, left: 8, top: 4, bottom: 4),
      child: Card(
        elevation: isRoot ? 4 : 1,
        color: isRoot ? Colors.blue.shade50 : (account.isContra ? Colors.red.shade50 : Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onTap: () => _showAccountDialog(accountToEdit: account),
          onLongPress: () => _showOptionsBottomSheet(account),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(
                  isRoot ? Icons.folder : Icons.subdirectory_arrow_right,
                  color: isRoot ? AppTheme.kDarkBrown : Colors.grey,
                  size: isRoot ? 24 : 20,
                ),
                const SizedBox(width: 10),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.nameAr,
                        style: TextStyle(
                          fontWeight: isRoot ? FontWeight.bold : FontWeight.normal,
                          fontSize: isRoot ? 16 : 14,
                        ),
                      ),
                      Text(
                        account.code,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                if (account.requireCostCenter)
                  Tooltip(
                    message: 'يتطلب مركز تكلفة',
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Icon(Icons.factory, color: Colors.orange, size: 18),
                    ),
                  ),
                
                if (account.isContra)
                   Tooltip(
                    message: 'حساب عكسي',
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Icon(Icons.swap_horiz, color: Colors.red, size: 18),
                    ),
                  ),
                
                const SizedBox(width: 8),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: account.nature == 'debit' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: account.nature == 'debit' ? Colors.green : Colors.red, width: 0.5),
                  ),
                  child: Text(
                    account.nature == 'debit' ? 'مدين' : 'دائن',
                    style: TextStyle(fontSize: 10, color: account.nature == 'debit' ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptionsBottomSheet(AccountModel account) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add_box, color: Colors.green),
            title: Text('إضافة فرع تحت "${account.nameAr}"'),
            onTap: () {
              Navigator.pop(context);
              _showAccountDialog(parentAccount: account);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('تعديل الحساب'),
            onTap: () {
              Navigator.pop(context);
              _showAccountDialog(accountToEdit: account);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('حذف الحساب'),
            onTap: () async {
               Navigator.pop(context);
               try {
                 await _service.deleteAccount(account.id!);
                 _loadAccounts();
               } catch (e) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
               }
            },
          ),
        ],
      ),
    );
  }
}