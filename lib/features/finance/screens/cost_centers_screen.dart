//cost_centers_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/cost_center_model.dart';
import '../../../core/constants/app_theme.dart';
import '../services/cost_center_service.dart'; // <--- هذا هو السطر المهم

class CostCentersScreen extends StatefulWidget {
  final CostCenterModel? parentCenter;
  const CostCentersScreen({super.key, this.parentCenter});

  @override
  State<CostCentersScreen> createState() => _CostCentersScreenState();
}

class _CostCentersScreenState extends State<CostCentersScreen> {
  // هنا كان الخطأ، النظام لم يكن يعرف ما هو CostCenterService
  final CostCenterService _service = CostCenterService(); 

  // ... (باقي الكود كما هو) ...
  // لتوفير المساحة، تأكد أن باقي الكود موجود
  // (دوال _generateAutoCode, _showCenterDialog, build...)
  
  // إذا كنت قد فقدت الكود، أخبرني لأرسله لك كاملاً مرة أخرى.
  
  String _generateAutoCode() {
    String number = Random().nextInt(9999).toString().padLeft(4, '0');
    if (widget.parentCenter != null) {
      return '${widget.parentCenter!.code}-$number'; 
    }
    return 'C-$number';
  }

  void _refresh() => setState(() {});

  void _showCenterDialog({CostCenterModel? centerToEdit}) {
    final codeController = TextEditingController(text: centerToEdit?.code ?? _generateAutoCode());
    final nameController = TextEditingController(text: centerToEdit?.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(centerToEdit == null 
              ? (widget.parentCenter == null ? 'إضافة مركز رئيسي' : 'إضافة فرع لـ ${widget.parentCenter!.name}')
              : 'تعديل المركز'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController, 
                decoration: const InputDecoration(labelText: 'اسم المركز', border: OutlineInputBorder())
              ),
              const SizedBox(height: 15),
              TextField(
                controller: codeController,
                readOnly: true, 
                decoration: InputDecoration(
                  labelText: 'الكود', 
                  filled: true, 
                  fillColor: Colors.grey.shade200, 
                  border: const OutlineInputBorder()
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (codeController.text.isNotEmpty && nameController.text.isNotEmpty) {
                  if (centerToEdit == null) {
                    await _service.addCostCenter(CostCenterModel(
                      code: codeController.text,
                      name: nameController.text,
                      parentCode: widget.parentCenter?.code, 
                    ));
                  } else {
                    await _service.updateCostCenter(centerToEdit.id!, nameController.text, codeController.text);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    _refresh();
                  }
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.parentCenter == null ? 'مراكز التكلفة الرئيسية' : widget.parentCenter!.name;

    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCenterDialog(), 
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (widget.parentCenter != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppTheme.kLightBeige.withOpacity(0.2),
              child: Row(
                children: [
                  const Icon(Icons.folder_open, color: AppTheme.kDarkBrown),
                  const SizedBox(width: 8),
                  Text('أنت داخل: ${widget.parentCenter!.name}', 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.kDarkBrown)),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<CostCenterModel>>(
              future: _service.getCostCentersByParent(widget.parentCenter?.code),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.parentCenter == null ? Icons.domain : Icons.folder_off, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        const Text('لا توجد مراكز هنا', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: snapshot.data!.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _buildCenterCard(snapshot.data![i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterCard(CostCenterModel item) {
    return FutureBuilder<bool>(
      future: _service.hasChildren(item.code),
      builder: (context, snapshot) {
        bool hasChildren = snapshot.data ?? false;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: hasChildren ? AppTheme.kDarkBrown : Colors.grey.shade200,
              child: Icon(
                hasChildren ? Icons.folder : Icons.description, 
                color: hasChildren ? AppTheme.kLightBeige : Colors.grey.shade600
              ),
            ),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item.code, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    '${item.balance.toStringAsFixed(2)} د.أ', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CostCentersScreen(parentCenter: item)),
              ).then((_) => _refresh());
            },
            onLongPress: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit, color: Colors.blue),
                      title: const Text('تعديل الاسم'),
                      onTap: () { Navigator.pop(context); _showCenterDialog(centerToEdit: item); },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text('حذف المركز'),
                      onTap: () async {
                         Navigator.pop(context);
                         if (hasChildren) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن حذف مركز يحتوي على فروع')));
                         } else {
                            await _service.deleteCostCenter(item.id!);
                            _refresh();
                         }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }
    );
  }
}