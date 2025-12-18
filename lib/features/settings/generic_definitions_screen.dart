//generic_definitions_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_theme.dart';
import '../../core/models/definition_model.dart';
import '../../core/widgets/draggable_popup.dart';
import '../finance/finance_service.dart';

class GenericDefinitionsScreen extends StatefulWidget {
  final String definitionType;
  final String title;
  final Map<String, bool> config; // الإعدادات الديناميكية
  final bool canAdd; // صلاحية الإضافة

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
  String? _errorMessage; // متغير لحفظ رسالة الخطأ إن وجدت

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
      // محاولة جلب البيانات
      final data = await _service.getDefinitions(widget.definitionType);
      
      if (mounted) {
        setState(() {
          _items = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      // في حال حدوث خطأ
      debugPrint("Error loading definitions: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "حدث خطأ أثناء تحميل البيانات: $e";
          _isLoading = false;
        });
      }
    }
  }

  void _showEditDialog({DefinitionModel? item}) {
    final bool isEditing = item != null;
    final nameController = TextEditingController(text: item?.nameAr);
    final codeController = TextEditingController(text: item?.code);
    
    // استخراج القيم الحالية أو القيم الافتراضية
    String phone = item?.extraData['phone'] ?? '';
    String note = item?.extraData['note'] ?? '';
    String colorHex = item?.extraData['color'] ?? '#000000';

    showDialog(
      context: context,
      builder: (context) => DraggablePopup(
        title: isEditing ? "تعديل ${widget.title}" : "إضافة ${widget.title}",
        onClose: () => Navigator.pop(context),
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              children: [
                // 1. الاسم (دائماً موجود)
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "الاسم", border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),

                // 2. الكود (حسب الإعدادات)
                if (widget.config['has_code'] == true) ...[
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(labelText: "الكود / الرمز", border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 10),
                ],

                // 3. الهاتف (حسب الإعدادات)
                if (widget.config['has_phone'] == true) ...[
                  TextFormField(
                    initialValue: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: "رقم الهاتف", border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.phone, size: 18)),
                    onChanged: (v) => phone = v,
                  ),
                  const SizedBox(height: 10),
                ],

                // 4. اللون (حسب الإعدادات)
                if (widget.config['has_color'] == true) ...[
                  Row(
                    children: [
                      const Text("لون التمييز: ", style: TextStyle(fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () {
                          _showSimpleColorPicker(context, (color) {
                            String hex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                            setStateDialog(() => colorHex = hex);
                          });
                        },
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: _hexToColor(colorHex),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey)
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                // 5. الملاحظات (حسب الإعدادات)
                if (widget.config['has_note'] == true) ...[
                  TextFormField(
                    initialValue: note,
                    decoration: const InputDecoration(labelText: "ملاحظات / وصف", border: OutlineInputBorder(), isDense: true),
                    onChanged: (v) => note = v,
                  ),
                  const SizedBox(height: 10),
                ],

                const SizedBox(height: 20),
                
                // زر الحفظ
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kDarkBrown, foregroundColor: Colors.white),
                    onPressed: () async {
                      if (nameController.text.isEmpty) return;
                      
                      // تجميع البيانات الإضافية
                      Map<String, dynamic> extraData = {};
                      if (widget.config['has_phone'] == true) extraData['phone'] = phone;
                      if (widget.config['has_note'] == true) extraData['note'] = note;
                      if (widget.config['has_color'] == true) extraData['color'] = colorHex;

                      final newItem = DefinitionModel(
                        id: item?.id ?? 0,
                        type: widget.definitionType,
                        nameAr: nameController.text,
                        code: (widget.config['has_code'] == true && codeController.text.isNotEmpty) ? codeController.text : null,
                        extraData: extraData,
                        isActive: true, // ✅✅✅ تصحيح هام: ضمان أن العنصر فعال
                      );

                      try {
                        if (isEditing) {
                          // ✅ تحديث
                          await _service.updateDefinition(newItem);
                        } else {
                          // ✅ إضافة جديد
                          await _service.addDefinition(newItem);
                        }

                        if (mounted) {
                          Navigator.pop(context);
                          _loadData(); // إعادة التحميل
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الحفظ بنجاح"), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل الحفظ: $e"), backgroundColor: Colors.red));
                      }
                    },
                    child: const Text("حفظ"),
                  ),
                )
              ],
            );
          }
        ),
      ),
    );
  }

  Future<void> _deleteItem(int id) async {
    try {
       await _service.deleteDefinition(id);
       _loadData();
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الحذف بنجاح"), backgroundColor: Colors.green));
       }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("فشل الحذف"), backgroundColor: Colors.red));
       }
    }
  }

  void _showSimpleColorPicker(BuildContext context, Function(Color) onSelect) {
    final List<Color> colors = [Colors.red, Colors.green, Colors.blue, Colors.black, Colors.grey, Colors.orange, Colors.purple, Colors.yellow, Colors.teal, Colors.brown];
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("اختر لوناً"),
      content: Wrap(spacing: 10, runSpacing: 10, children: colors.map((color) => GestureDetector(onTap: () { onSelect(color); Navigator.pop(c); }, child: Container(width: 40, height: 40, decoration: BoxDecoration(color: color, shape: BoxShape.circle)))).toList()),
    ));
  }

  Color _hexToColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (e) { return Colors.black; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), backgroundColor: AppTheme.kDarkBrown, foregroundColor: Colors.white),
      
      floatingActionButton: widget.canAdd
          ? FloatingActionButton(
              backgroundColor: AppTheme.kDarkBrown,
              onPressed: () => _showEditDialog(),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      
      body: Builder(
        builder: (context) {
          // 1. حالة التحميل
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. حالة الخطأ
          if (_errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 10),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _loadData, child: const Text("إعادة المحاولة"))
                ],
              ),
            );
          }

          // 3. حالة القائمة فارغة
          if (_items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(LucideIcons.folderOpen, size: 60, color: Colors.grey.withOpacity(0.5)),
                   const SizedBox(height: 15),
                   Text("لا توجد ${widget.title} حالياً", style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                   if (widget.canAdd)
                     TextButton.icon(
                       onPressed: () => _showEditDialog(),
                       icon: const Icon(Icons.add),
                       label: const Text("أضف جديد")
                     )
                ],
              ),
            );
          }

          // 4. عرض البيانات
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _items.length,
            separatorBuilder: (c, i) => const Divider(),
            itemBuilder: (context, index) {
              final item = _items[index];
              return ListTile(
                leading: widget.config['has_color'] == true 
                    ? CircleAvatar(backgroundColor: _hexToColor(item.extraData['color'] ?? '#000000'), radius: 15)
                    : Icon(LucideIcons.circle, size: 12, color: AppTheme.kDarkBrown),
                
                title: Text(item.nameAr, style: const TextStyle(fontWeight: FontWeight.bold)),
                
                subtitle: Text(
                  [
                    if (item.code != null && item.code!.isNotEmpty) "كود: ${item.code}",
                    if (item.extraData['phone'] != null) "هاتف: ${item.extraData['phone']}",
                    if (item.extraData['note'] != null) "${item.extraData['note']}",
                  ].join(' | '),
                  style: const TextStyle(fontSize: 11, color: Colors.grey)
                ),
                
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.edit3, color: Colors.blue, size: 18),
                      onPressed: () => _showEditDialog(item: item),
                    ),
                    if (widget.canAdd)
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 18), 
                        onPressed: () => _deleteItem(item.id)
                      ),
                  ],
                ),
              );
            },
          );
        }
      ),
    );
  }
}