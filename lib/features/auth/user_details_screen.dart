// File: lib/features/auth/user_details_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_theme.dart';
import '../finance/services/finance_service.dart';

class UserDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserDetailsScreen({super.key, required this.user});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> with SingleTickerProviderStateMixin {
  final FinanceService _service = FinanceService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _allPermissions = [];
  List<String> _selectedPermissions = []; // الأكواد المختارة
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    setState(() => _isLoading = true);
    try {
      // 1. جلب كل تعريفات الصلاحيات
      _allPermissions = await _service.getAllPermissionDefinitions();
      
      // 2. جلب صلاحيات المستخدم الحالية
      final currentPermsResponse = await _service.supabase
          .from('user_permissions')
          .select('permission_code')
          .eq('user_id', widget.user['id']);
      
      _selectedPermissions = (currentPermsResponse as List)
          .map((e) => e['permission_code'] as String)
          .toList();

    } catch (e) {
      debugPrint("Error loading permissions: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePermissions() async {
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
    
    await _service.updateUserPermissions(widget.user['id'], _selectedPermissions);
    
    if (mounted) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم حفظ الصلاحيات بنجاح"), backgroundColor: Colors.green),
      );
    }
  }

  // تجميع الصلاحيات حسب الموديول
  Map<String, List<Map<String, dynamic>>> _groupPermissions() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var perm in _allPermissions) {
      String module = perm['module'] ?? 'عام';
      if (!grouped.containsKey(module)) grouped[module] = [];
      grouped[module]!.add(perm);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // خلفية فاتحة جداً
      appBar: AppBar(
        title: Text("تفاصيل المستخدم: ${widget.user['full_name']}"),
        backgroundColor: AppTheme.kDarkBrown,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // زر حفظ يظهر فقط في تبويب الصلاحيات
          IconButton(
            onPressed: _savePermissions,
            icon: const Icon(Icons.save),
            tooltip: "حفظ التغييرات",
          )
        ],
      ),
      body: Column(
        children: [
          // --- Header Card ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.shade50,
                  child: Text(
                    widget.user['full_name'][0].toUpperCase(),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user['full_name'],
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.user['email'] ?? '',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // --- Tabs ---
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.kDarkBrown,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.kDarkBrown,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: "التفاصيل", icon: Icon(LucideIcons.info)),
                Tab(text: "الصلاحيات", icon: Icon(LucideIcons.shieldCheck)),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // --- Tab Content ---
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Details (Read Only)
                    _buildDetailsTab(),
                    
                    // Tab 2: Permissions (Toggle Switches)
                    _buildPermissionsTab(),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoTile("الاسم الكامل", widget.user['full_name'], LucideIcons.user),
        _buildInfoTile("اسم المستخدم", widget.user['username'] ?? '-', LucideIcons.atSign),
        _buildInfoTile("البريد الإلكتروني", widget.user['email'] ?? '-', LucideIcons.mail),
        _buildInfoTile("رقم الهاتف", widget.user['phone'] ?? '-', LucideIcons.phone),
        _buildInfoTile("تاريخ التسجيل", widget.user['created_at']?.toString().split(' ')[0] ?? '-', LucideIcons.calendar),
      ],
    );
  }

  Widget _buildPermissionsTab() {
    final groupedPerms = _groupPermissions();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedPerms.keys.length,
      itemBuilder: (context, index) {
        String module = groupedPerms.keys.elementAt(index);
        List<Map<String, dynamic>> perms = groupedPerms[module]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Module Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(top: 16, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.folder, size: 16, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Text(
                    module.toUpperCase(), 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),

            // Permissions List (Switches)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
              ),
              child: Column(
                children: perms.map((perm) {
                  final code = perm['code'];
                  final isSelected = _selectedPermissions.contains(code);
                  
                  return Column(
                    children: [
                      SwitchListTile(
                        value: isSelected,
                        activeColor: Colors.blue, // لون السويتش الأزرق كما في الصورة
                        onChanged: (val) {
                          setState(() {
                            if (val) {
                              _selectedPermissions.add(code);
                            } else {
                              _selectedPermissions.remove(code);
                            }
                          });
                        },
                        title: Text(perm['description'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        subtitle: Text(code, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      if (perm != perms.last)
                         Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}