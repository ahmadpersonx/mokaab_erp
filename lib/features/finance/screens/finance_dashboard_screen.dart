// FileName: lib/features/finance/screens/finance_dashboard_screen.dart
// Revision: 4.0 (Final: Unified Header Style & Clean Grid Layout)
// Date: 2025-12-19

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/permissions.dart';
import '../services/finance_service.dart';
import '../../home/widgets/module_card.dart';

// ✅ استدعاء الهيدر الموحد الجديد
import '../widgets/finance_dashboard_header.dart';

// ✅ استيراد الشاشات الفرعية
import 'daily_journal_screen.dart';
import 'chart_of_accounts_screen.dart';
import 'cost_centers_screen.dart';
import 'checks_management_screen.dart';
import 'vouchers_list_screen.dart';
import 'financial_reports_dashboard.dart';

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
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

  // تعريف قائمة الخدمات المالية (المنطق)
  List<Map<String, dynamic>> _getFinanceModules() {
    return [
      {
        'title': 'سندات القبض',
        'icon': LucideIcons.arrowDownCircle,
        'color': AppTheme.kSuccess, 
        'route': const VouchersListScreen(voucherType: 'receipt'),
        'visible': _service.hasPermission(AppPermissions.entriesView) || true,
      },
      {
        'title': 'سندات الصرف',
        'icon': LucideIcons.arrowUpCircle,
        'color': AppTheme.kError,
        'route': const VouchersListScreen(voucherType: 'payment'),
        'visible': _service.hasPermission(AppPermissions.entriesView) || true,
      },
      {
        'title': 'إدارة الشيكات',
        'icon': LucideIcons.banknote,
        'color': AppTheme.kInfo,
        'route': const ChecksManagementScreen(),
        'visible': _service.hasPermission(AppPermissions.entriesView) || true,
      },
      {
        'title': 'اليومية العامة',
        'icon': LucideIcons.fileText,
        'color': const Color(0xFF5D4037), // بني غامق (لون رسمي)
        'route': const DailyJournalScreen(),
        'visible': _service.hasPermission(AppPermissions.entriesView) || true,
      },
      {
        'title': 'التقارير المالية',
        'icon': LucideIcons.pieChart,
        'color': Colors.indigo.shade700,
        'route': FinancialReportsDashboard(),
        'visible': _service.hasPermission(AppPermissions.entriesView) || true,
      },
      {
        'title': 'دليل الحسابات',
        'icon': LucideIcons.bookOpen,
        'color': Colors.purple.shade700,
        'route': const ChartOfAccountsScreen(),
        'visible': _service.hasPermission(AppPermissions.accountsView) || true,
      },
      {
        'title': 'مراكز التكلفة',
        'icon': LucideIcons.network,
        'color': Colors.orange.shade800,
        'route': const CostCentersScreen(),
        'visible': _service.hasPermission(AppPermissions.costCentersView) || true,
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
        const SnackBar(
          content: Text('هذه الميزة قيد التطوير حالياً'),
          backgroundColor: AppTheme.kDarkBrown,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // تصفية العناصر بناءً على الصلاحيات
    final activeModules = _getFinanceModules().where((m) => m['visible']).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      // استخدام CustomScrollView لدمج الهيدر والقائمة بشكل سلس
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
            slivers: [
              // 1. الهيدر الموحد الجديد (بنفس ستايل الشاشة الرئيسية)
              FinanceDashboardHeader(
                onBack: () => Navigator.pop(context),
              ),

              // 2. شبكة الخدمات مباشرة
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                sliver: activeModules.isEmpty
                    ? SliverFillRemaining(child: _buildNoPermissionView())
                    : SliverGrid(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 280, // عرض مثالي للبطاقات
                          childAspectRatio: 1.2,   // نسبة العرض للارتفاع
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final module = activeModules[index];
                            return ModuleCard(
                              title: module['title'],
                              icon: module['icon'],
                              color: module['color'],
                              onTap: () => _handleModuleTap(module),
                            );
                          },
                          childCount: activeModules.length,
                        ),
                      ),
              ),
              
              // مساحة فارغة في الأسفل لضمان سهولة التمرير
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
    );
  }

  Widget _buildNoPermissionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.lock, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "عذراً، لا تملك صلاحيات للوصول إلى النظام المالي",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}