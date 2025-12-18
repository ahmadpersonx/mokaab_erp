//banks_management_popup.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_theme.dart';
import '../../core/widgets/draggable_popup.dart';
import 'finance_service.dart';

class BanksManagementPopup extends StatefulWidget {
  final VoidCallback onUpdate; // لتحديث القائمة في الشاشة الرئيسية عند الإغلاق
  const BanksManagementPopup({super.key, required this.onUpdate});

  @override
  State<BanksManagementPopup> createState() => _BanksManagementPopupState();
}

class _BanksManagementPopupState extends State<BanksManagementPopup> {
  final FinanceService _service = FinanceService();
  final TextEditingController _nameController = TextEditingController();
  List<Map<String, dynamic>> _banks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    setState(() => _isLoading = true);
    final data = await _service.getBanks();
    if (mounted) setState(() { _banks = data; _isLoading = false; });
  }

  Future<void> _addBank() async {
    if (_nameController.text.isEmpty) return;
    try {
      await _service.addBank(_nameController.text.trim());
      _nameController.clear();
      _loadBanks();
      widget.onUpdate(); // تحديث الشاشة الخلفية
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("فشل الحفظ (قد يكون الاسم مكرراً)"), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteBank(int id) async {
    await _service.deleteBank(id);
    _loadBanks();
    widget.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return DraggablePopup(
      title: "إدارة قائمة البنوك",
      width: 400,
      onClose: () => Navigator.pop(context),
      child: SizedBox(
        height: 400, // ارتفاع ثابت للنافذة
        child: Column(
          children: [
            // حقل الإضافة
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "اسم البنك الجديد",
                      prefixIcon: Icon(LucideIcons.landmark),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addBank,
                  style: IconButton.styleFrom(backgroundColor: AppTheme.kDarkBrown, foregroundColor: Colors.white),
                  icon: const Icon(Icons.add),
                  tooltip: "إضافة",
                ),
              ],
            ),
            const Divider(height: 30),
            
            // القائمة
            Expanded(
              child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  itemCount: _banks.length,
                  separatorBuilder: (c, i) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final bank = _banks[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(bank['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 18),
                        onPressed: () => _deleteBank(bank['id']),
                      ),
                    );
                  },
                ),
            ),
          ],
        ),
      ),
    );
  }
}