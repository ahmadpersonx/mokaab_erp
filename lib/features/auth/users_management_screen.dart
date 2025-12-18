//شاشة إدارة المستخدمين lib/features/auth/users_management_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';
// import '../../core/constants/permissions.dart'; // يمكن استخدامه مستقبلاً
import '../finance/finance_service.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final FinanceService _service = FinanceService();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _allPermissions = [];
  bool _isLoading = true;

  // لون رئيسي خاص بهذه الشاشة (بنفسجي فاتح كما في التصميم)
  final Color _primaryColor = const Color(0xFF6C63FF); 

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      _users = await _service.getAllUsers();
      _allPermissions = await _service.getAllPermissionDefinitions();
    } catch (e) {
      debugPrint("Error loading users data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // استبدلنا الديالوج بـ Bottom Sheet لتصميم احترافي
  void _openPermissionsSheet(Map<String, dynamic> user) async {
    // 1. جلب صلاحيات المستخدم الحالية
    final currentPermsResponse = await _service.supabase
        .from('user_permissions')
        .select('permission_code')
        .eq('user_id', user['id']);
    
    List<String> selectedPermissions = (currentPermsResponse as List)
        .map((e) => e['permission_code'] as String)
        .toList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // للسماح بارتفاع اكبر للشاشة
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSheet) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85, // 85% من ارتفاع الشاشة
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              children: [
                // 1. رأس القائمة (الهيدر)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("صلاحيات: ${user['full_name']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                
                // 2. قائمة الصلاحيات (مجمعة حسب القسم)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: _groupPermissionsByModule().entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 20, 8, 8),
                            child: Text(
                              entry.key.toUpperCase(), // اسم القسم (مثل FINANCE)
                              style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor, letterSpacing: 1.2),
                            ),
                          ),
                          ...entry.value.map((perm) {
                            final code = perm['code'];
                            final isSelected = selectedPermissions.contains(code);
                            return Card(
                              elevation: 0,
                              color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.grey.shade50,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: isSelected ? _primaryColor : Colors.transparent)
                              ),
                              child: CheckboxListTile(
                                activeColor: _primaryColor,
                                title: Text(perm['description'], style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                subtitle: Text(code, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                value: isSelected,
                                onChanged: (val) {
                                  setStateSheet(() {
                                    if (val == true) {
                                      selectedPermissions.add(code);
                                    } else {
                                      selectedPermissions.remove(code);
                                    }
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                
                // 3. زر الحفظ في الأسفل
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: () async {
                        // إظهار مؤشر تحميل سريع
                        showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
                        
                        await _service.updateUserPermissions(user['id'], selectedPermissions);
                        
                        if (mounted) {
                          Navigator.pop(ctx); // إغلاق مؤشر التحميل
                          Navigator.pop(ctx); // إغلاق الـ Bottom Sheet
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("تم تحديث صلاحيات ${user['full_name']} بنجاح"),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      },
                      child: const Text("حفظ التغييرات", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // دالة مساعدة لتجميع الصلاحيات
  Map<String, List<Map<String, dynamic>>> _groupPermissionsByModule() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var perm in _allPermissions) {
      String module = perm['module'] ?? 'other';
      if (!grouped.containsKey(module)) grouped[module] = [];
      grouped[module]!.add(perm);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("إدارة المستخدمين", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppTheme.kDarkBrown,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                // تصميم البطاقة حسب الصورة المطلوبة
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // أيقونة المستخدم
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(Icons.person, color: _primaryColor, size: 30),
                            ),
                            const SizedBox(width: 16),
                            // اسم وبريد المستخدم
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['full_name'] ?? "مستخدم نظام",
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user['email'] ?? "", // تأكد أن الإيميل يتم جلبه إذا كان متاحاً في جدول البروفايل
                                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // زر تعديل الصلاحيات
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () => _openPermissionsSheet(user),
                            icon: const Icon(Icons.vpn_key_outlined, size: 18),
                            label: const Text("تعديل الصلاحيات"),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}