//financial_reports_dashboard.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_theme.dart';
import '../../home/widgets/module_card.dart'; // ✅ الاستخدام الموحد
import 'account_statement_screen.dart';

// سنقوم بإنشاء هذه الشاشة في الخطوة القادمة
// import 'reports/account_statement_screen.dart'; 

class FinancialReportsDashboard extends StatelessWidget {
  const FinancialReportsDashboard({super.key});

  List<Map<String, dynamic>> _getReportModules(BuildContext context) {
    return [
      // 1. كشف الحساب (الأكثر استخداماً)
      {
    'title': 'كشف حساب',
    'icon': LucideIcons.fileSearch, 
    'color': Colors.blue,
    'route': const AccountStatementScreen(), // ✅ الربط هنا
    'visible': true,
  },
      // 2. ميزان المراجعة
      {
        'title': 'ميزان المراجعة',
        'icon': LucideIcons.scale,
        'color': Colors.teal,
        'route': null,
        'visible': true,
      },
      // 3. قائمة الدخل
      {
        'title': 'قائمة الدخل',
        'icon': LucideIcons.trendingUp,
        'color': Colors.green,
        'route': null,
        'visible': true,
      },
      // 4. الميزانية العمومية
      {
        'title': 'الميزانية العمومية',
        'icon': LucideIcons.landmark,
        'color': Colors.brown,
        'route': null,
        'visible': true,
      },
    ];
  }

  void _handleModuleTap(BuildContext context, Map<String, dynamic> module) {
    if (module['route'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => module['route']),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${module['title']} قيد التطوير...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final modules = _getReportModules(context).where((m) => m['visible']).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        title: const Text('التقارير المالية', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.kDarkBrown,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "مركز التقارير",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.kDarkBrown),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "تحليل الأداء المالي، كشوفات الحسابات، والقوائم الختامية",
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = 2;
                    if (constraints.maxWidth > 900) crossAxisCount = 4;
                    else if (constraints.maxWidth > 600) crossAxisCount = 3;

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1.1,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                      ),
                      itemCount: modules.length,
                      itemBuilder: (context, index) {
                        final module = modules[index];
                        return ModuleCard(
                          title: module['title'],
                          icon: module['icon'],
                          color: module['color'],
                          onTap: () => _handleModuleTap(context, module),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}