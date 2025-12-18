// [كود رقم 64] - finance_dashboard_screen.dart (تصميم الأيقونات الصغيرة)
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/permissions.dart';
import 'journal_entries_screen.dart';
import 'chart_of_accounts_screen.dart';
import 'cost_centers_screen.dart';
import 'smart_voucher_screen.dart';
import 'vouchers_history_screen.dart'; // ✅ تمت الإضافة
import 'checks_management_screen.dart'; // ✅ تمت الإضافة
import 'finance_service.dart';

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  final FinanceService _service = FinanceService();

  @override
  void initState() {
    super.initState();
    _service.loadUserPermissions().then((_) {
      if (mounted) setState(() {});
    });
  }

  List<Map<String, dynamic>> _getFinanceModules() {
    return [
      // 1. سند قبض
      {
        'title': 'سند قبض',
        'icon': LucideIcons.arrowDownCircle,
        'color': Colors.green.shade700,
        'route': const SmartVoucherScreen(voucherType: 'receipt'),
        'visible': _service.hasPermission(AppPermissions.entriesCreate) || true,
      },
      
      // 2. سند صرف
      {
        'title': 'سند صرف',
        'icon': LucideIcons.arrowUpCircle,
        'color': Colors.red.shade700,
        'route': const SmartVoucherScreen(voucherType: 'payment'),
        'visible': _service.hasPermission(AppPermissions.entriesCreate) || true,
      },

      // ✅ 3. إدارة الشيكات (جديد)
      {
        'title': 'إدارة الشيكات',
        'icon': LucideIcons.banknote, // أو ticket
        'color': Colors.indigo,
        'route': const ChecksManagementScreen(),
        'visible': _service.hasPermission(AppPermissions.entriesView) || true,
      },

      // 4. القيود اليومية
      {
        'title': 'القيود اليومية',
        'icon': LucideIcons.fileText,
        'color': Colors.blueGrey,
        'route': const JournalEntriesScreen(),
        'visible': _service.hasPermission(AppPermissions.entriesView) || true,
      },

      // ✅ 5. أرشيف المقبوضات (جديد)
      {
        'title': 'أرشيف المقبوضات',
        'icon': LucideIcons.history,
        'color': Colors.teal,
        'route': const VouchersHistoryScreen(voucherType: 'receipt'),
        'visible': _service.hasPermission(AppPermissions.entriesView) || true,
      },

      // ✅ 6. أرشيف المدفوعات (جديد)
      {
        'title': 'أرشيف المدفوعات',
        'icon': LucideIcons.history, // نفس الأيقونة بلون مختلف
        'color': Colors.orangeAccent.shade700,
        'route': const VouchersHistoryScreen(voucherType: 'payment'),
        'visible': _service.hasPermission(AppPermissions.entriesView) || true,
      },

      // 7. دليل الحسابات
      {
        'title': 'دليل الحسابات',
        'icon': LucideIcons.bookOpen,
        'color': Colors.purple,
        'route': const ChartOfAccountsScreen(),
        'visible': _service.hasPermission(AppPermissions.accountsView) || true,
      },

      // 8. مراكز التكلفة
      {
        'title': 'مراكز التكلفة',
        'icon': LucideIcons.network,
        'color': Colors.orange,
        'route': const CostCentersScreen(),
        'visible': _service.hasPermission(AppPermissions.costCentersView) || true,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final activeModules = _getFinanceModules().where((m) => m['visible']).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('الإدارة المالية', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.kDarkBrown,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "العمليات المالية",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.kDarkBrown),
                ),
                const SizedBox(height: 5),
                Text(
                  "إدارة السندات، الشيكات، القيود والحسابات",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: activeModules.isEmpty 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.lock, size: 60, color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    const Text("لا توجد صلاحيات لعرض الأقسام المالية", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, 
                  childAspectRatio: 0.9, 
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: activeModules.length,
                itemBuilder: (context, index) {
                  return _buildSmallModuleIcon(context, activeModules[index]);
                },
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallModuleIcon(BuildContext context, Map<String, dynamic> module) {
    return InkWell(
      onTap: () {
        if (module['route'] != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => module['route']));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${module['title']} قيد التطوير...'))
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (module['color'] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(module['icon'], size: 28, color: module['color']),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                module['title'],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}