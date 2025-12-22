// FileName: lib/features/finance/screens/cost_centers_screen.dart
// Revision: 5.0 (Full Fix: Compatible with new Model & Service)
// Date: 2025-12-20

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_theme.dart';
import '../models/cost_center_model.dart';
import '../services/finance_service.dart';

class CostCentersScreen extends StatefulWidget {
  const CostCentersScreen({super.key});

  @override
  State<CostCentersScreen> createState() => _CostCentersScreenState();
}

class _CostCentersScreenState extends State<CostCentersScreen> {
  final FinanceService _service = FinanceService();
  final _formKey = GlobalKey<FormState>();

  List<CostCenterModel> _costCenters = [];
  bool _isLoading = true;

  // Controllers for Dialog
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String _selectedType = 'general'; // general, project, department

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getAllCostCenters();
      if (mounted) {
        setState(() {
          _costCenters = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading cost centers: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddEditDialog({CostCenterModel? center}) {
    final isEditing = center != null;
    
    // تعيين القيم في حال التعديل
    if (isEditing) {
      _codeController.text = center.code;
      _nameController.text = center.name;
      _selectedType = center.type ?? 'general';
    } else {
      _codeController.clear();
      _nameController.clear();
      _selectedType = 'general';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? "تعديل مركز تكلفة" : "إضافة مركز تكلفة"),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: "رمز المركز",
                    prefixIcon: Icon(LucideIcons.hash),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val!.isEmpty ? "مطلوب" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "اسم المركز",
                    prefixIcon: Icon(LucideIcons.type),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val!.isEmpty ? "مطلوب" : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: "نوع المركز",
                    prefixIcon: Icon(LucideIcons.layers),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text("عام")),
                    DropdownMenuItem(value: 'project', child: Text("مشروع")),
                    DropdownMenuItem(value: 'department', child: Text("قسم إداري")),
                  ],
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kDarkBrown, foregroundColor: Colors.white),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                // ✅ إنشاء الموديل بالبيانات الصحيحة والمتوافقة
                final newCenter = CostCenterModel(
                  id: center?.id ?? 0, // 0 للإضافة الجديدة (الباك إند سيولد الرقم)
                  code: _codeController.text,
                  name: _nameController.text,
                  type: _selectedType,
                  balance: center?.balance ?? 0.0,
                );

                try {
                  Navigator.pop(ctx); // إغلاق الديالوج
                  setState(() => _isLoading = true);

                  if (isEditing) {
                    // تحديث مباشر
                    await _service.supabase
                        .from('cost_centers')
                        .update(newCenter.toJson())
                        .eq('id', newCenter.id);
                  } else {
                    // إضافة مباشرة (نحذف الـ id ليتم توليده تلقائياً)
                    final data = newCenter.toJson();
                    data.remove('id'); 
                    await _service.supabase
                        .from('cost_centers')
                        .insert(data);
                  }
                  
                  await _loadData(); // تحديث القائمة
                  
                } catch (e) {
                  debugPrint("Error saving: $e");
                  if (mounted) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e"), backgroundColor: Colors.red));
                  }
                }
              }
            },
            child: Text(isEditing ? "تحديث" : "حفظ"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCenter(int id) async {
    try {
      await _service.supabase.from('cost_centers').delete().eq('id', id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الحذف بنجاح"), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("فشل الحذف، قد يكون المركز مرتبطاً بقيود"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("مراكز التكلفة"),
        backgroundColor: AppTheme.kDarkBrown,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppTheme.kDarkBrown,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _costCenters.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.network, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("لا توجد مراكز تكلفة معرفة", style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _costCenters.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final center = _costCenters[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(LucideIcons.network, color: Colors.orange.shade800),
                        ),
                        title: Text("${center.name} (${center.code})", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("النوع: ${center.type ?? 'عام'} | الرصيد: ${center.balance}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(LucideIcons.edit3, size: 20, color: Colors.blueGrey),
                              onPressed: () => _showAddEditDialog(center: center),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.trash2, size: 20, color: Colors.redAccent),
                              onPressed: () => _deleteCenter(center.id),
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