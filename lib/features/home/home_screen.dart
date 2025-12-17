// [كود رقم 32] - home_screen.dart (مع أيقونات Font Awesome)
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_theme.dart';
import '../finance/finance_dashboard_screen.dart';
import '../finance/finance_service.dart';
// ✅ تم تعديل المسار هنا ليتطابق مع ما حددته
import '../auth/users_management_screen.dart'; 

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
        'icon': FontAwesomeIcons.moneyBillTrendUp,
        'color': Colors.blue,
        'route': const FinanceDashboardScreen(),
        'visible': true, 
      },
      {
        'title': 'المستودع',
        'icon': FontAwesomeIcons.warehouse,
        'color': Colors.grey,
        'route': null,
        'visible': rawRole == 'admin' || rawRole == 'accountant',
      },
      {
        'title': 'الإنتاج',
        'icon': FontAwesomeIcons.industry,
        'color': Colors.red,
        'route': null,
        'visible': rawRole == 'admin',
      },
      {
        'title': 'العملاء',
        'icon': FontAwesomeIcons.userGroup,
        'color': Colors.orange,
        'route': null,
        'visible': true,
      },
      {
        'title': 'الإعدادات',
        'icon': FontAwesomeIcons.gears,
        'color': Colors.black54,
        'route': const UsersManagementScreen(), // استخدام الشاشة من المسار الجديد
        'visible': rawRole == 'admin', 
      },
      {
        'title': 'التقارير',
        'icon': FontAwesomeIcons.chartSimple,
        'color': Colors.teal,
        'route': null,
        'visible': rawRole == 'admin' || rawRole == 'accountant',
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
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _service.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfoHeader(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
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
            SnackBar(content: Text('${module['title']} قيد الإنشاء...'))
          );
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (module['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(module['icon'], size: 28, color: module['color']),
          ),
          const SizedBox(height: 6),
          Text(
            module['title'],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          FaIcon(FontAwesomeIcons.circleUser, color: Colors.blue.shade700, size: 40),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(userRoleDisplay, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      selectedItemColor: AppTheme.kDarkBrown,
      unselectedItemColor: Colors.grey,
      currentIndex: 2,
      items: const [
        BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.calendarDay), label: 'النشاطات'),
        BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.peopleGroup), label: 'العملاء'),
        BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.house), label: 'الرئيسية'),
      ],
    );
  }
}