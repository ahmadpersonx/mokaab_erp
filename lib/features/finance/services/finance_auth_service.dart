//finance_auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'finance_base.dart';
import 'finance_service.dart';

mixin FinanceAuthService on FinanceBase {
  // قائمة لتخزين صلاحيات المستخدم المسجل حالياً
  static List<String> _currentUserPermissions = [];

  // 1. المصادقة (Auth) وإدارة الجلسة
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      return await supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      debugPrint("Sign-in error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      _currentUserPermissions = [];
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint("Sign-out error: $e");
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    try {
      return await supabase.from('profiles').select().eq('id', user.id).single();
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      return null;
    }
  }

  // 2. نظام الصلاحيات التفصيلي (Permissions)
  Future<void> loadUserPermissions() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _currentUserPermissions = [];
      return;
    }
    try {
      final response = await supabase
          .from('user_permissions')
          .select('permission_code')
          .eq('user_id', user.id);
      
      _currentUserPermissions = (response as List)
          .map((e) => e['permission_code'] as String)
          .toList();
    } catch (e) {
      debugPrint("Error loading permissions: $e");
      _currentUserPermissions = [];
    }
  }

  bool hasPermission(String permissionCode) {
    return _currentUserPermissions.contains(permissionCode);
  }

  Future<List<Map<String, dynamic>>> getAllPermissionDefinitions() async {
    final response = await supabase.from('permissions_def').select().order('module');
    return List<Map<String, dynamic>>.from(response);
  }

  // 3. إدارة المستخدمين
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await supabase.from('profiles').select().order('full_name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetching users: $e");
      rethrow;
    }
  }

  Future<void> updateUserPermissions(String userId, List<String> newPermissions) async {
    await supabase.from('user_permissions').delete().eq('user_id', userId);
    if (newPermissions.isNotEmpty) {
      final data = newPermissions.map((code) => {
        'user_id': userId,
        'permission_code': code
      }).toList();
      await supabase.from('user_permissions').insert(data);
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await supabase.from('profiles').update({'role': newRole}).eq('id', userId);
    } catch (e) {
      debugPrint("Error updating role: $e");
      rethrow;
    }
  }
}