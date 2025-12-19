// FileName: lib/features/settings/system_dashboard_screen.dart
// Revision: 4.0 (Refactored: Separated UI Header from Logic)
// Date: 2025-12-19

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/permissions.dart';
import '../finance/services/finance_service.dart';
import '../home/widgets/module_card.dart'; 
import 'system_definitions_screen.dart';

// استدعاء ملف الهيدر الجديد
import 'widgets/system_dashboard_header.dart'; 

class SystemDashboardScreen extends StatefulWidget {
  const SystemDashboardScreen({super.key});

  @override
  State<SystemDashboardScreen> createState() => _SystemDashboardScreenState();
}

class _SystemDashboardScreenState extends State<SystemDashboardScreen> {
  final FinanceService _service = FinanceService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    await _service.loadUserPermissions();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // تعريف قائمة الموديولات (المنطق)
  List<Map<String, dynamic>> _getSystemModules() {
    return [
      {
        'title': 'إدارة القوائم',
        'subtitle': 'تعريف الثوابت، الوحدات، والقوائم المنسدلة',
        'icon': LucideIcons.listTree,
        'color': Colors.purple.shade700,
        'route': const SystemDefinitionsScreen(),
        'visible': _service.hasPermission(AppPermissions.definitionsManage),
      },
      {
        'title': 'إعدادات الشركة',
        'subtitle': 'بيانات المؤسسة والشعار والضريبة',
        'icon': LucideIcons.building2,
        'color': Colors.blueGrey.shade700,
        'route': null, 
        'visible': true, 
      },
      {
        'title': 'المستخدمين',
        'subtitle': 'إدارة الموظفين والصلاحيات',
        'icon': LucideIcons.users,
        'color': Colors.orange.shade800,
        'route': null,
        'visible': _service.hasPermission(AppPermissions.usersManage),
      },
      {
        'title': 'النسخ الاحتياطي',
        'subtitle': 'حفظ واسترجاع قاعدة البيانات',
        'icon': LucideIcons.databaseBackup,
        'color': Colors.teal.shade700,
        'route': null,
        'visible': true,
      },
    ];
  }

  void _handleModuleTap(Map<String, dynamic> module) {
    if (module['route'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => module['route']),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${module['title']} قيد التطوير حالياً...'),
          backgroundColor: AppTheme.kDarkBrown,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // تصفية العناصر بناءً على الصلاحيات
    final modules = _getSystemModules().where((m) => m['visible']).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
            slivers: [
              // 1. استدعاء الهيدر المفصول
              const SystemDashboardHeader(),

              // 2. شبكة العناصر
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: modules.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Text(
                            "لا توجد صلاحيات لعرض الإعدادات",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          childAspectRatio: 1.3,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final module = modules[index];
                            return ModuleCard(
                              title: module['title'],
                              icon: module['icon'],
                              color: module['color'],
                              // subtitle: module['subtitle'], // تأكد أن ModuleCard يدعم هذا الحقل
                              onTap: () => _handleModuleTap(module),
                            );
                          },
                          childCount: modules.length,
                        ),
                      ),
              ),
            ],
          ),
    );
  }
}