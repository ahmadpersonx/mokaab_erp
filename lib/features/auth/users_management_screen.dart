// FileName: lib/features/auth/users_management_screen.dart
// Revision: 3.0 (Unified Header Style)
// Date: 2025-12-19

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_theme.dart';
import '../finance/services/finance_service.dart';

// استدعاء المكونات
import 'widgets/user_list_tile.dart';
import 'widgets/users_management_header.dart'; // الهيدر الجديد
import 'user_details_screen.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final FinanceService _service = FinanceService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      _users = await _service.getAllUsers();
    } catch (e) {
      debugPrint("Error loading users: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((u) {
      return u['full_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (u['email'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
            slivers: [
              // 1. الهيدر الموحد الجديد
              UsersManagementHeader(
                onBack: () => Navigator.pop(context),
              ),

              // 2. شريط البحث (مفصول أسفل الهيدر)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: "ابحث بالاسم أو البريد...",
                        prefixIcon: const Icon(LucideIcons.search, size: 20, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. قائمة المستخدمين
              _filteredUsers.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.userX, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text("لا يوجد مستخدمين بهذا الاسم", style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final user = _filteredUsers[index];
                            return UserListTile(
                              name: user['full_name'],
                              email: user['email'] ?? '',
                              phone: user['phone'],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserDetailsScreen(user: user),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: _filteredUsers.length,
                        ),
                      ),
                    ),
              
              // مساحة سفلية
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("قيد التطوير: إضافة مستخدم")));
        },
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.person_add_alt_1),
      ),
    );
  }
}