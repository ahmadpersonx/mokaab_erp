// lib/features/finance/chart_of_accounts_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/permissions.dart';
import '../../../core/services/excel_service.dart';
import '../services/finance_service.dart';

class ChartOfAccountsScreen extends StatefulWidget {
  const ChartOfAccountsScreen({super.key});

  @override
  State<ChartOfAccountsScreen> createState() => _ChartOfAccountsScreenState();
}

class _ChartOfAccountsScreenState extends State<ChartOfAccountsScreen> {
  final FinanceService _service = FinanceService();
  final ExcelService _excelService = ExcelService();
  List<AccountModel> _accounts = [];
  bool _isLoading = true;

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
    await _service.loadUserPermissions();
    try {
      final data = await _service.getAllAccounts();
      setState(() {
        _accounts = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _generateAutoCode({AccountModel? parent, String? rootCategoryPrefix}) {
    if (parent != null) {
      String randomSuffix = Random().nextInt(99).toString().padLeft(2, '0');
      return '${parent.code}$randomSuffix'; 
    } else {
      String prefix = rootCategoryPrefix ?? '1';
      String suffix = Random().nextInt(9).toString(); 
      return '$prefix$suffix'; 
    }
  }

  void _showAccountDialog({AccountModel? accountToEdit, AccountModel? parentAccount}) {
    if (accountToEdit == null && !_service.hasPermission(AppPermissions.accountsCreate)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ليس لديك صلاحية إضافة حساب")));
      return;
    }
    if (accountToEdit != null && !_service.hasPermission(AppPermissions.accountsEdit)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ليس لديك صلاحية تعديل الحساب")));
      return;
    }

    String selectedRootCategory = accountToEdit != null ? accountToEdit.code[0] : (parentAccount != null ? parentAccount.code[0] : '1');
    String baseNature = parentAccount?.nature ?? _rootCategories[selectedRootCategory]!['nature'];
    bool isContra = accountToEdit?.isContra ?? false;
    String currentNature = accountToEdit?.nature ?? (isContra ? (baseNature == 'debit' ? 'credit' : 'debit') : baseNature);

    final codeController = TextEditingController(text: accountToEdit?.code ?? _generateAutoCode(parent: parentAccount, rootCategoryPrefix: selectedRootCategory));
    final nameController = TextEditingController(text: accountToEdit?.nameAr);
    bool requireCostCenter = accountToEdit?.requireCostCenter ?? false;
    
    // متغير لتحديد هل الحساب رئيسي أم فرعي (افتراضياً: فرعي إذا لم نحدد)
    bool isParentAccount = accountToEdit?.isParent ?? false; 

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void recalculateNature() {
              currentNature = isContra ? (baseNature == 'debit' ? 'credit' : 'debit') : baseNature;
            }

            return AlertDialog(
              title: Text(accountToEdit == null ? 'إضافة حساب' : 'تعديل حساب'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الحساب', border: OutlineInputBorder())),
                    const SizedBox(height: 15),
                    
                    CheckboxListTile(
                      title: const Text('حساب رئيسي (يحتوي فروعاً)'),
                      subtitle: const Text('لن يتمكن من تسجيل قيود مباشرة'),
                      value: isParentAccount,
                      onChanged: (val) => setStateDialog(() => isParentAccount = val ?? false),
                    ),

                    CheckboxListTile(
                      title: const Text('حساب عكسي (Contra)', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('مثل مجمع الإهلاك (دائن) تحت الأصول'),
                      value: isContra,
                      activeColor: Colors.red,
                      onChanged: (val) {
                        setStateDialog(() {
                          isContra = val ?? false;
                          recalculateNature();
                        });
                      },
                    ),
                    
                    Text("الطبيعة الحالية: ${currentNature == 'debit' ? 'مدين' : 'دائن'}", style: TextStyle(color: currentNature == 'debit' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                    
                    SwitchListTile(
                      title: const Text('يتطلب مركز تكلفة'),
                      value: requireCostCenter,
                      onChanged: (val) => setStateDialog(() => requireCostCenter = val),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: codeController, readOnly: true, decoration: InputDecoration(labelText: 'الكود', filled: true, fillColor: Colors.grey.shade200)),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kDarkBrown, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      final newAccount = AccountModel(
                        id: accountToEdit?.id ?? 0, // 0 عند الإضافة
                        code: codeController.text,
                        nameAr: nameController.text,
                        parentCode: parentAccount?.code ?? accountToEdit?.parentCode, // ✅ استخدام parentCode
                        nature: currentNature,
                        
                        // ✅ الحل هنا: استخدام القيمة من الـ Checkbox
                        isParent: isParentAccount, 
                        
                        level: accountToEdit?.level ?? (parentAccount != null ? parentAccount.level + 1 : 1),
                        requireCostCenter: requireCostCenter,
                        isContra: isContra,
                      );

                      try {
                        if (accountToEdit == null) {
                          await _service.addAccount(newAccount);
                        } else {
                          await _service.updateAccount(newAccount.id, newAccount.nameAr, newAccount.nature, newAccount.requireCostCenter, newAccount.isContra);
                        }
                        if (mounted) { Navigator.pop(context); _loadAccounts(); }
                      } catch (e) {
                        // Error handling
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
      appBar: AppBar(title: const Text('دليل الحسابات'), backgroundColor: AppTheme.kDarkBrown, foregroundColor: Colors.white),
      floatingActionButton: _service.hasPermission(AppPermissions.accountsCreate)
          ? FloatingActionButton(onPressed: () => _showAccountDialog(parentAccount: null), child: const Icon(Icons.add))
          : null,
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _accounts.length,
              itemBuilder: (context, index) => _buildAccountRow(_accounts[index]),
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
        child: InkWell(
          onTap: () => _showAccountDialog(accountToEdit: account),
          onLongPress: () => _showOptionsBottomSheet(account),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(isRoot ? Icons.folder : Icons.subdirectory_arrow_right, color: isRoot ? AppTheme.kDarkBrown : Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(account.nameAr, style: TextStyle(fontWeight: isRoot ? FontWeight.bold : FontWeight.normal, fontSize: 16)),
                    Text(account.code, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                ),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (account.requireCostCenter) const Icon(Icons.api, size: 16, color: Colors.orange),
                    const SizedBox(height: 4),
                    Text(
                      "${account.currentBalance.toStringAsFixed(2)} \$",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: account.nature == 'debit' ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
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
          if (_service.hasPermission(AppPermissions.accountsCreate))
            ListTile(leading: const Icon(Icons.add_box, color: Colors.green), title: Text('إضافة فرع تحت "${account.nameAr}"'), onTap: () { Navigator.pop(context); _showAccountDialog(parentAccount: account); }),
          
          if (_service.hasPermission(AppPermissions.accountsEdit))
            ListTile(leading: const Icon(Icons.edit, color: Colors.blue), title: const Text('تعديل الحساب'), onTap: () { Navigator.pop(context); _showAccountDialog(accountToEdit: account); }),
          
          if (_service.hasPermission(AppPermissions.accountsDelete))
            ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('حذف الحساب'), onTap: () async {
               Navigator.pop(context);
               await _service.deleteAccount(account.id);
               _loadAccounts();
            }),
        ],
      ),
    );
  }
}