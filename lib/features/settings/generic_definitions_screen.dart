// FileName: lib/features/settings/generic_definitions_screen.dart
// Revision: 7.0 (Separated Logic from UI - Final Structure)

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_theme.dart';
import '../../core/models/definition_model.dart';
import '../../core/widgets/draggable_popup.dart';
import '../finance/services/finance_service.dart';

// استدعاء ملفات الـ Widgets الجديدة
import 'widgets/page_header.dart';
import 'widgets/definition_item_card.dart';

class GenericDefinitionsScreen extends StatefulWidget {
  final String definitionType;
  final String title;
  final Map<String, dynamic> config; 
  final bool canAdd;

  const GenericDefinitionsScreen({
    super.key,
    required this.definitionType,
    required this.title,
    required this.config,
    this.canAdd = true,
  });

  @override
  State<GenericDefinitionsScreen> createState() => _GenericDefinitionsScreenState();
}

class _GenericDefinitionsScreenState extends State<GenericDefinitionsScreen> {
  final FinanceService _service = FinanceService();
  List<DefinitionModel> _items = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _service.getDefinitions(widget.definitionType);
      if (mounted) {
        setState(() {
          _items = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "حدث خطأ: $e";
          _isLoading = false;
        });
      }
    }
  }

  List<DefinitionModel> get _filteredItems {
    if (_searchQuery.isEmpty) return _items;
    return _items.where((item) {
      final name = item.nameAr.toLowerCase();
      final code = item.code?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || code.contains(query);
    }).toList();
  }

  // --- Dialog Logic Remains Here (It's part of the screen logic) ---
  void _showEditDialog({DefinitionModel? item}) {
    final bool isEditing = item != null;
    final nameController = TextEditingController(text: item?.nameAr);
    final codeController = TextEditingController(text: item?.code);
    
    String phone = item?.extraData['phone'] ?? '';
    String note = item?.extraData['note'] ?? '';
    String colorHex = item?.extraData['color'] ?? '#000000';

    final bool hasCode = widget.config['has_code'] ?? true;
    final bool hasPhone = widget.config['has_phone'] ?? false;
    final bool hasColor = widget.config['has_color'] ?? false;
    final bool hasNote = widget.config['has_note'] ?? false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return DraggablePopup(
            title: isEditing ? "تعديل: ${widget.title}" : "إضافة جديد: ${widget.title}",
            onClose: () => Navigator.pop(context),
            width: 500,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "الاسم (عربي)", prefixIcon: Icon(LucideIcons.type, size: 18), border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 16),

                if (hasCode) ...[
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(labelText: "الكود / الرمز", prefixIcon: Icon(LucideIcons.qrCode, size: 18), border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 16),
                ],

                if (hasPhone) ...[
                  TextFormField(
                    initialValue: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: "رقم الهاتف", prefixIcon: Icon(LucideIcons.phone, size: 18), border: OutlineInputBorder(), isDense: true),
                    onChanged: (v) => phone = v,
                  ),
                  const SizedBox(height: 16),
                ],

                if (hasColor) ...[
                  const Text("لون التمييز", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [Colors.red, Colors.green, Colors.blue, Colors.black, Colors.orange, Colors.purple].map((color) {
                        final colorString = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                        final isSelected = colorHex.toUpperCase().contains(colorString.replaceAll('#', ''));
                        return GestureDetector(
                          onTap: () => setStateDialog(() => colorHex = colorString),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: isSelected ? Border.all(color: AppTheme.kDarkBrown, width: 3) : null),
                            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (hasNote) ...[
                  TextFormField(
                    initialValue: note,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: "ملاحظات", prefixIcon: Icon(LucideIcons.stickyNote, size: 18), border: OutlineInputBorder(), isDense: true),
                    onChanged: (v) => note = v,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء", style: TextStyle(color: Colors.grey))),
              ElevatedButton.icon(
                icon: const Icon(Icons.save, size: 18),
                label: const Text("حفظ"),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kDarkBrown, foregroundColor: Colors.white),
                onPressed: () async {
                  if (nameController.text.isEmpty) return;
                  Map<String, dynamic> extraData = {};
                  if (hasPhone) extraData['phone'] = phone;
                  if (hasNote) extraData['note'] = note;
                  if (hasColor) extraData['color'] = colorHex;

                  final newItem = DefinitionModel(
                    id: item?.id ?? 0,
                    type: widget.definitionType,
                    nameAr: nameController.text,
                    code: (hasCode && codeController.text.isNotEmpty) ? codeController.text : null,
                    extraData: extraData,
                    isActive: true,
                  );

                  try {
                    if (isEditing) await _service.updateDefinition(newItem);
                    else await _service.addDefinition(newItem);
                    
                    if (mounted) {
                      Navigator.pop(context);
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الحفظ"), backgroundColor: Colors.green));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل الحفظ: $e"), backgroundColor: Colors.red));
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteItem(int id) async {
    // Delete Logic...
    try {
      await _service.deleteDefinition(id);
      _loadData();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الحذف"), backgroundColor: Colors.green));
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("فشل الحذف"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Reusable Header
            PageHeader(
              title: widget.title,
              subtitle: "إدارة سجلات ${widget.title}",
              onSearch: (val) => setState(() => _searchQuery = val),
              onBack: () => Navigator.pop(context),
            ),

            // 2. List Body
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                  ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                  : _filteredItems.isEmpty
                    ? Center(child: Text("لا توجد بيانات", style: TextStyle(color: Colors.grey.shade600)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _filteredItems.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return DefinitionItemCard(
                            item: _filteredItems[index],
                            hasColor: widget.config['has_color'] == true,
                            canEdit: true,
                            canDelete: widget.canAdd,
                            onEdit: () => _showEditDialog(item: _filteredItems[index]),
                            onDelete: () => _deleteItem(_filteredItems[index].id),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.canAdd
          ? FloatingActionButton.extended(
              onPressed: () => _showEditDialog(),
              backgroundColor: AppTheme.kDarkBrown,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("إضافة جديد", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}