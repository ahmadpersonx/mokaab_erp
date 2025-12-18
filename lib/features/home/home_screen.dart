// [كود رقم 32] - home_screen.dart 
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_theme.dart';
import '../finance/finance_dashboard_screen.dart';
import '../finance/finance_service.dart';
import '../auth/users_management_screen.dart'; 
import '../settings/system_definitions_screen.dart'; // ✅ الشاشة الموحدة الجديدة

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FinanceService _service = FinanceService();
  String userName = "جاري التحميل...";
  String userRoleDisplay = "جاري التحميل...";
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

  List<Map<String, dynamic>> _getModules() {
    return [
      {
        'title': 'الإدارة المالية',
        'icon': LucideIcons.banknote,
        'color': Colors.blue,
        'route': const FinanceDashboardScreen(),
        'visible': true, 
      },
      {
        'title': 'المستودع',
        'icon': LucideIcons.warehouse,
        'color': Colors.grey,
        'route': null,
        'visible': rawRole == 'admin' || rawRole == 'accountant',
      },
      {
        'title': 'الإنتاج',
        'icon': LucideIcons.factory,
        'color': Colors.red,
        'route': null,
        'visible': rawRole == 'admin',
      },
      {
        'title': 'العملاء',
        'icon': LucideIcons.users,
        'color': Colors.orange,
        'route': null,
        'visible': true,
      },
      {
        'title': 'الطلبات',
        'icon': LucideIcons.shoppingCart,
        'color': Colors.green,
        'route': null,
        'visible': true,
      },
      {
        'title': 'التقارير',
        'icon': LucideIcons.barChart3,
        'color': Colors.teal,
        'route': null,
        'visible': rawRole == 'admin' || rawRole == 'accountant',
      },
      
      // ✅ أيقونة المستخدمين
      {
        'title': 'المستخدمين',
        'icon': LucideIcons.userCog, 
        'color': Colors.indigo,
        'route': const UsersManagementScreen(),
        'visible': rawRole == 'admin', 
      },

      // ✅ أيقونة تعريفات النظام (التوجيه الصحيح)
      {
        'title': 'تعريفات النظام',
        'icon': LucideIcons.settings2,
        'color': Colors.blueGrey,
        'route': const SystemDefinitionsScreen(), // ✅ التوجيه للشاشة الموحدة
        'visible': true, // الشاشة ستتحقق من الصلاحيات داخلياً
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final activeModules = _getModules().where((m) => m['visible']).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('مكعب ERP'),
        centerTitle: true,
        backgroundColor: AppTheme.kDarkBrown,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(LucideIcons.logOut),
            onPressed: () async {
              await _service.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.kDarkBrown))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfoHeader(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Text(
                  'الوحدات الرئيسية',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.kDarkBrown),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.85,
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
      bottomNavigationBar: _buildBottomNavBar(),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (module['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(module['icon'], size: 28, color: module['color']), 
          ),
          const SizedBox(height: 8),
          Text(
            module['title'],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade50
            ),
            child: Icon(LucideIcons.user, color: Colors.blue.shade700, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4)
                ),
                child: Text(userRoleDisplay, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      selectedItemColor: AppTheme.kDarkBrown,
      unselectedItemColor: Colors.grey.shade400,
      showUnselectedLabels: true,
      currentIndex: 2,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(LucideIcons.history), label: 'النشاطات'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.users), label: 'العملاء'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'الرئيسية'),
      ],
    );
  }
}