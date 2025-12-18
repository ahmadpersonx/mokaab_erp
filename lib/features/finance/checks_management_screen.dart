//checks_management_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_theme.dart';
import 'finance_service.dart';

class ChecksManagementScreen extends StatefulWidget {
  const ChecksManagementScreen({super.key});

  @override
  State<ChecksManagementScreen> createState() => _ChecksManagementScreenState();
}

class _ChecksManagementScreenState extends State<ChecksManagementScreen> with SingleTickerProviderStateMixin {
  final FinanceService _service = FinanceService();
  late TabController _tabController;
  List<Map<String, dynamic>> _incomingChecks = []; // شيكات واردة (قبض)
  List<Map<String, dynamic>> _outgoingChecks = []; // شيكات صادرة (صرف)
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChecks();
  }

  Future<void> _loadChecks() async {
    setState(() => _isLoading = true);
    try {
      final incoming = await _service.getChecks(type: 'receipt'); // شيكات العملاء
      final outgoing = await _service.getChecks(type: 'payment'); // شيكاتنا للموردين
      setState(() {
        _incomingChecks = incoming;
        _outgoingChecks = outgoing;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ديالوج لتغيير حالة الشيك
  void _changeStatus(Map<String, dynamic> check) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("تحديث حالة الشيك ${check['check_no']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text("تم التحصيل / الصرف"),
              onTap: () async {
                await _service.updateCheckStatus(check['id'], 'collected');
                if (mounted) {
                  Navigator.pop(context);
                  _loadChecks();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text("شيك راجع / مرتجع"),
              onTap: () async {
                await _service.updateCheckStatus(check['id'], 'bounced');
                if (mounted) {
                  Navigator.pop(context);
                  _loadChecks();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.orange),
              title: const Text("إعادة للانتظار (Pending)"),
              onTap: () async {
                await _service.updateCheckStatus(check['id'], 'pending');
                if (mounted) {
                  Navigator.pop(context);
                  _loadChecks();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إدارة الشيكات"),
        backgroundColor: AppTheme.kDarkBrown,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(text: "شيكات واردة (قبض)", icon: Icon(LucideIcons.arrowDownCircle)),
            Tab(text: "شيكات صادرة (صرف)", icon: Icon(LucideIcons.arrowUpCircle)),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildChecksList(_incomingChecks, isIncoming: true),
              _buildChecksList(_outgoingChecks, isIncoming: false),
            ],
          ),
    );
  }

  Widget _buildChecksList(List<Map<String, dynamic>> checks, {required bool isIncoming}) {
    if (checks.isEmpty) return const Center(child: Text("لا توجد شيكات"));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: checks.length,
      itemBuilder: (context, index) {
        final check = checks[index];
        String status = check['check_status'] ?? 'pending';
        Color statusColor = status == 'collected' ? Colors.green : (status == 'bounced' ? Colors.red : Colors.orange);
        String statusText = status == 'collected' ? 'تم التحصيل' : (status == 'bounced' ? 'مرتجع' : 'في الانتظار');

        // تنسيق التاريخ
        String dueDateStr = "";
        if (check['check_due_date'] != null) {
           dueDateStr = DateFormat('yyyy-MM-dd').format(DateTime.parse(check['check_due_date']));
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(check['banks']?['name'] ?? 'بنك غير محدد', style: const TextStyle(fontWeight: FontWeight.bold)),
                // ✅ تم تعديل العملة هنا إلى الدينار الأردني
                Text("${check['amount']} د.أ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("رقم الشيك: ${check['check_no']}"),
                Text("تاريخ الاستحقاق: $dueDateStr", 
                  style: TextStyle(
                    color: check['check_due_date'] != null && 
                           DateTime.parse(check['check_due_date']).isBefore(DateTime.now()) && 
                           status == 'pending' 
                           ? Colors.red 
                           : Colors.grey
                  )
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.more_vert, size: 16, color: Colors.grey),
              ],
            ),
            onTap: () => _changeStatus(check), // فتح قائمة تغيير الحالة
          ),
        );
      },
    );
  }
}