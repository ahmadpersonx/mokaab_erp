//settings_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/permissions.dart';
import '../finance/finance_service.dart';
import 'system_definitions_screen.dart'; // الشاشة التي تدمج العرض والإدارة

class SettingsDashboardScreen extends StatelessWidget {
  const SettingsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FinanceService service = FinanceService();

    // القائمة
    final List<Map<String, dynamic>> settingsModules = [
      {
        'title': 'تعريفات النظام',
        'icon': LucideIcons.library,
        'color': Colors.brown,
        'route': const SystemDefinitionsScreen(),
        // هل يملك صلاحية إدارة الهيكل؟ أو على الأقل رؤية إحدى القوائم؟
        // للتبسيط: نجعلها متاحة لمن لديه صلاحية دخول الإعدادات
        'visible': service.hasPermission(AppPermissions.settingsView) || 
                   service.hasPermission(AppPermissions.definitionsManage), 
      },
      // يمكن إضافة أيقونات أخرى مستقبلاً: "إعدادات عامة"، "النسخ الاحتياطي"...
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("إعدادات النظام"),
        backgroundColor: AppTheme.kDarkBrown,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 في الصف
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: settingsModules.length,
        itemBuilder: (context, index) {
          final module = settingsModules[index];
          if (!module['visible']) return const SizedBox.shrink();

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => module['route']));
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (module['color'] as Color).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(module['icon'], size: 30, color: module['color']),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    module['title'], 
                    textAlign: TextAlign.center, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
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