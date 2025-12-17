//شاشة إدارة المستخدمين lib/features/auth/users_management_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_theme.dart';
import '../finance/finance_service.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final FinanceService _service = FinanceService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getAllUsers();
      setState(() {
        _users = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("فشل جلب المستخدمين", isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  // نافذة تغيير الصلاحية
  void _editUserRole(Map<String, dynamic> user) {
    String currentRole = user['role'] ?? 'viewer';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("تعديل صلاحية ${user['full_name']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _roleOption("مدير نظام", "admin", currentRole, (val) => _updateRole(user['id'], val)),
            _roleOption("محاسب", "accountant", currentRole, (val) => _updateRole(user['id'], val)),
            _roleOption("مشاهد فقط", "viewer", currentRole, (val) => _updateRole(user['id'], val)),
          ],
        ),
      ),
    );
  }

  Widget _roleOption(String label, String value, String current, Function(String) onSelect) {
    return ListTile(
      title: Text(label),
      leading: Radio<String>(
        value: value,
        groupValue: current,
        onChanged: (val) {
          Navigator.pop(context);
          onSelect(val!);
        },
      ),
      onTap: () {
        Navigator.pop(context);
        onSelect(value);
      },
    );
  }

  Future<void> _updateRole(String userId, String newRole) async {
    try {
      await _service.updateUserRole(userId, newRole);
      _showSnackBar("تم تحديث الصلاحية بنجاح");
      _fetchUsers(); // تحديث القائمة
    } catch (e) {
      _showSnackBar("فشل التحديث", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إدارة المستخدمين والصلاحيات"),
        backgroundColor: AppTheme.kDarkBrown,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              separatorBuilder: (c, i) => const Divider(),
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  leading: const FaIcon(FontAwesomeIcons.userShield, color: AppTheme.kDarkBrown),
                  title: Text(user['full_name'] ?? "بدون اسم", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("الصلاحية الحالية: ${_translateRole(user['role'])}"),
                  trailing: const Icon(Icons.edit, size: 20),
                  onTap: () => _editUserRole(user),
                );
              },
            ),
    );
  }

  String _translateRole(String? role) {
    switch (role) {
      case 'admin': return 'مدير نظام';
      case 'accountant': return 'محاسب';
      default: return 'مشاهد فقط';
    }
  }
}