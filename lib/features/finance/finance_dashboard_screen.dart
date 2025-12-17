// [كود رقم 64] - finance_dashboard_screen.dart (تصميم الأيقونات الصغيرة)
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_theme.dart';
import 'journal_entries_screen.dart';
import 'chart_of_accounts_screen.dart';
import 'cost_centers_screen.dart';
import 'finance_service.dart';

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  final FinanceService _service = FinanceService();
  String rawRole = "viewer";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final profile = await _service.getCurrentUserProfile();
    if (mounted) {
      setState(() {
        rawRole = profile?['role'] ?? 'viewer';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFinanceModules() {
    return [
      {
        'title': 'القيود اليومية',
        'icon': FontAwesomeIcons.fileInvoice,
        'color': Colors.green,
        'route': const JournalEntriesScreen(),
        'visible': true, 
      },
      {
        'title': 'دليل الحسابات',
        'icon': FontAwesomeIcons.bookOpen,
        'color': Colors.purple,
        'route': const ChartOfAccountsScreen(),
        'visible': rawRole == 'admin' || rawRole == 'accountant',
      },
      {
        'title': 'مراكز التكلفة',
        'icon': FontAwesomeIcons.codeBranch,
        'color': Colors.orange,
        'route': const CostCentersScreen(),
        'visible': rawRole == 'admin', // متاحة فقط للمدير
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final activeModules = _getFinanceModules().where((m) => m['visible']).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإدارة المالية'),
        backgroundColor: AppTheme.kDarkBrown,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Text('أقسام المالية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // تطابق تصميم الشاشة الرئيسية
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: activeModules.length,
                  itemBuilder: (context, index) => _buildSmallModuleIcon(context, activeModules[index]),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildSmallModuleIcon(BuildContext context, Map<String, dynamic> module) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => module['route'])),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: module['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(module['icon'], size: 28, color: module['color']),
          ),
          const SizedBox(height: 8),
          Text(module['title'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}