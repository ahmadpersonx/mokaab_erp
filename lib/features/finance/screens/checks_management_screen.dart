import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_theme.dart';
import '../services/finance_service.dart';
import '../widgets/print_action_menu.dart'; // تأكد أن هذا الملف موجود

class ChecksManagementScreen extends StatefulWidget {
  const ChecksManagementScreen({super.key});

  @override
  State<ChecksManagementScreen> createState() => _ChecksManagementScreenState();
}

class _ChecksManagementScreenState extends State<ChecksManagementScreen> with SingleTickerProviderStateMixin {
  final FinanceService _service = FinanceService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _incomingChecks = [];
  List<Map<String, dynamic>> _outgoingChecks = [];
  final Set<int> _selectedIds = {}; 
  
  bool _isLoading = true;
  bool _isSelectionMode = false; // ✅ للتحكم في ظهور الـ Checkbox

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChecks();
  }

  Future<void> _loadChecks() async {
    setState(() => _isLoading = true);
    try {
      final incoming = await _service.getChecks(status: 'pending');
      final outgoing = await _service.getChecks(status: 'collected');
      if (mounted) {
        setState(() {
          _incomingChecks = incoming;
          _outgoingChecks = outgoing;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- دوال الطباعة الوهمية (للتجربة حالياً) ---
  void _handlePrintFull() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري الطباعة الكاملة...')));
  }

  void _handlePrintSelected() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('جاري طباعة ${_selectedIds.length} شيك...')));
    // إغلاق وضع التحديد بعد الأمر
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إدارة الشيكات", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.kDarkBrown,
        foregroundColor: Colors.white,
        actions: [
          // ✅ زر الإلغاء يظهر فقط في وضع التحديد
          if (_isSelectionMode)
            TextButton.icon(
              icon: const Icon(Icons.close, color: Colors.white),
              label: const Text("إلغاء", style: TextStyle(color: Colors.white)),
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedIds.clear();
              }),
            ),
          
          PrintActionMenu(
            onPrintFull: _handlePrintFull,
            onPrintSelected: _handlePrintSelected,
            // زر "تفعيل اختيار للطباعة" في القائمة يفعل الوضع
            onToggleSelection: () => setState(() => _isSelectionMode = true),
            isSelectionEmpty: _selectedIds.isEmpty,
            isSelectionMode: _isSelectionMode,
          ),
        ],
        // ✅ إصلاح مشكلة عرض التبويبات (Tabs)
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.amber, // اللون عند الاختيار
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          isScrollable: false, // ✅ هذا يضمن توزيع المساحة بالتساوي
          tabs: const [
            Tab(text: "شيكات واردة", icon: Icon(LucideIcons.arrowDownCircle)),
            Tab(text: "شيكات صادرة", icon: Icon(LucideIcons.arrowUpCircle)),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildChecksList(_incomingChecks),
              _buildChecksList(_outgoingChecks),
            ],
          ),
    );
  }

  Widget _buildChecksList(List<Map<String, dynamic>> checks) {
    if (checks.isEmpty) return const Center(child: Text("لا توجد شيكات"));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: checks.length,
      itemBuilder: (context, index) {
        final check = checks[index];
        final int id = check['id'];
        final bool isSelected = _selectedIds.contains(id);

        return Card(
          elevation: 2,
          // تغيير اللون عند التحديد
          color: isSelected ? Colors.green.withOpacity(0.1) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: isSelected ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none,
          ),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            // ✅ الـ Checkbox يظهر فقط إذا كان الوضع مفعلاً
            leading: _isSelectionMode 
              ? Checkbox(
                  value: isSelected,
                  activeColor: Colors.green,
                  onChanged: (val) => setState(() => val! ? _selectedIds.add(id) : _selectedIds.remove(id)),
                )
              : CircleAvatar(
                  backgroundColor: AppTheme.kDarkBrown.withOpacity(0.1),
                  child: const Icon(LucideIcons.creditCard, color: AppTheme.kDarkBrown),
                ),
            title: Text(check['banks']?['name'] ?? 'بنك غير محدد', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("رقم الشيك: ${check['check_no']}"),
            trailing: Text("${check['amount']} د.أ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            // عند النقر في وضع التحديد، يتم تحديد العنصر
            onTap: _isSelectionMode 
              ? () => setState(() => isSelected ? _selectedIds.remove(id) : _selectedIds.add(id))
              : null, // يمكن هنا فتح التفاصيل لاحقاً
          ),
        );
      },
    );
  }
}