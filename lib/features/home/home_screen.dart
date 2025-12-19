// FileName: lib/features/home/home_screen.dart
// Revision: 2.0 (Refactored: Clean Material UI with Custom Logo Header)
// Date: 2025-12-19

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_theme.dart';
import '../finance/screens/finance_dashboard_screen.dart';
import '../finance/services/finance_service.dart';
import '../auth/users_management_screen.dart'; 
import '../settings/system_dashboard_screen.dart'; 

// استيراد المكونات (Components)
import 'widgets/module_card.dart';
import 'widgets/home_header.dart'; // ✅ استدعاء الهيدر الجديد

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FinanceService _service = FinanceService();
  String userName = "جاري التحميل...";
  String userRoleDisplay = "...";
  String rawRole = "viewer";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _service.getCurrentUserProfile();
      if (profile != null && mounted) {
        setState(() {
          userName = profile['full_name'] ?? 'مستخدم ERP';
          rawRole = profile['role'] ?? 'viewer';

          if (rawRole == 'admin') {
            userRoleDisplay = 'مدير نظام';
          } else if (rawRole == 'accountant') {
            userRoleDisplay = 'محاسب';
          } else {
            userRoleDisplay = 'مشاهد';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // مصفوفة الوحدات (المنطق)
  List<Map<String, dynamic>> _getModules() {
    return [
      {
        'title': 'الإدارة المالية',
        'icon': LucideIcons.banknote,
        'color': Colors.blue.shade700,
        'route': const FinanceDashboardScreen(),
        'visible': true, 
      },
      {
        'title': 'المستودع',
        'icon': LucideIcons.warehouse,
        'color': Colors.blueGrey.shade600,
        'route': null,
        'visible': rawRole == 'admin' || rawRole == 'accountant',
      },
      {
        'title': 'الإنتاج',
        'icon': LucideIcons.factory,
        'color': Colors.red.shade400,
        'route': null,
        'visible': rawRole == 'admin',
      },
      {
        'title': 'العملاء',
        'icon': LucideIcons.users,
        'color': Colors.orange.shade400,
        'route': null,
        'visible': true,
      },
      {
        'title': 'الطلبات',
        'icon': LucideIcons.shoppingCart,
        'color': Colors.green.shade600,
        'route': null,
        'visible': true,
      },
      {
        'title': 'التقارير',
        'icon': LucideIcons.barChart3,
        'color': Colors.teal.shade600,
        'route': null,
        'visible': rawRole == 'admin' || rawRole == 'accountant',
      },
      {
        'title': 'المستخدمين',
        'icon': LucideIcons.userCog, 
        'color': Colors.indigo.shade400,
        'route': const UsersManagementScreen(),
        'visible': rawRole == 'admin', 
      },
      {
        'title': 'تعريفات النظام',
        'icon': LucideIcons.settings2,
        'color': const Color(0xFF5D4037), // لون مطابق للثيم
        'route': const SystemDashboardScreen(),
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
          content: Text('${module['title']} قيد التطوير...'),
          backgroundColor: AppTheme.kDarkBrown,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeModules = _getModules().where((m) => m['visible']).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      // لا نحتاج AppBar هنا لأننا صممنا Header خاص
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.kDarkBrown))
          : CustomScrollView(
              slivers: [
                // 1. الهيدر الجديد (يحتوي الشعار ومعلومات المستخدم)
                HomeHeader(
                  userName: userName,
                  userRole: userRoleDisplay,
                  onLogout: () async {
                     await _service.signOut();
                     if (mounted) Navigator.pushReplacementNamed(context, '/login');
                  },
                ),

                // 2. عنوان القسم (اختياري لجمالية أكثر)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Text(
                      "الوحدات الرئيسية",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ),

                // 3. شبكة العناصر (Responsive Grid)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200, // حجم مناسب للبطاقات
                      childAspectRatio: 1.1,
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

                // مساحة فارغة في الأسفل
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: BottomNavigationBar(
        selectedItemColor: AppTheme.kDarkBrown,
        unselectedItemColor: Colors.grey.shade400,
        showUnselectedLabels: true,
        currentIndex: 2, // الصفحة الرئيسية
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.history), label: 'النشاطات'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.users), label: 'العملاء'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'الرئيسية'),
        ],
      ),
    );
  }
}