//system_definitions_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/permissions.dart'; // تأكد من استيراد ملف الصلاحيات
import '../../core/widgets/draggable_popup.dart';
import '../finance/finance_service.dart';
import 'generic_definitions_screen.dart'; // ✅ تمت الإضافة (ضروري)

class SystemDefinitionsScreen extends StatefulWidget {
  const SystemDefinitionsScreen({super.key});

  @override
  State<SystemDefinitionsScreen> createState() => _SystemDefinitionsScreenState();
}

class _SystemDefinitionsScreenState extends State<SystemDefinitionsScreen> {
  final FinanceService _service = FinanceService();
  List<Map<String, dynamic>> _types = [];
  bool _isLoading = true;
  
  // ✅ متغيرات الصلاحيات
  bool _canManageStructure = false; // هل يستطيع إضافة/حذف قوائم؟

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLoad();
  }

  Future<void> _checkPermissionsAndLoad() async {
    // تحميل الصلاحيات للتأكد
    await _service.loadUserPermissions();
    if (mounted) {
      setState(() {
        // فحص صلاحية إدارة الهيكل
        _canManageStructure = _service.hasPermission(AppPermissions.definitionsManage);
      });
      _loadTypes();
    }
  }

  Future<void> _loadTypes() async {
    setState(() => _isLoading = true);
    final data = await _service.getDefinitionTypes();
    if (mounted) {
      setState(() {
        _types = data;
        _isLoading = false;
      });
    }
  }

  // ==========================================
  // منطق المدير (إضافة وتعديل هيكل القوائم)
  // ==========================================
  void _showStructureDialog({Map<String, dynamic>? itemToEdit}) {
    final bool isEditing = itemToEdit != null;
    final nameController = TextEditingController(text: itemToEdit?['name_ar']);
    final codeController = TextEditingController(text: itemToEdit?['code']);
    
    // استخراج الإعدادات الحالية أو استخدام الافتراضي
    Map<String, dynamic> config = itemToEdit?['field_config'] ?? {};
    
    bool hasCode = config['has_code'] ?? true;
    bool hasColor = config['has_color'] ?? false;
    bool hasPhone = config['has_phone'] ?? false;
    bool hasNote = config['has_note'] ?? false;

    showDialog(
      context: context,
      builder: (context) => DraggablePopup(
        title: isEditing ? "تعديل خصائص القائمة" : "تعريف قائمة جديدة",
        onClose: () => Navigator.pop(context),
        width: 450,
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("إعدادات القائمة", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.kDarkBrown)),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "اسم القائمة (مثال: السائقين)", border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: codeController,
                  // 🔒 الكود لا يمكن تعديله لأنه مفتاح أساسي
                  enabled: !isEditing, 
                  decoration: InputDecoration(
                    labelText: "الرمز البرمجي (Code)", 
                    hintText: "drivers, colors...",
                    border: const OutlineInputBorder(), 
                    isDense: true,
                    filled: isEditing,
                    fillColor: Colors.grey.shade200
                  ),
                ),
                
                const Divider(height: 30),
                const Text("ما هي الحقول المطلوبة للعنصر؟", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.kDarkBrown)),
                
                CheckboxListTile(title: const Text("رمز / كود"), value: hasCode, onChanged: (v) => setStateDialog(() => hasCode = v!), activeColor: AppTheme.kDarkBrown),
                CheckboxListTile(title: const Text("لون تمييز"), value: hasColor, onChanged: (v) => setStateDialog(() => hasColor = v!), activeColor: AppTheme.kDarkBrown),
                CheckboxListTile(title: const Text("رقم هاتف"), value: hasPhone, onChanged: (v) => setStateDialog(() => hasPhone = v!), activeColor: AppTheme.kDarkBrown),
                CheckboxListTile(title: const Text("ملاحظات / وصف"), value: hasNote, onChanged: (v) => setStateDialog(() => hasNote = v!), activeColor: AppTheme.kDarkBrown),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kDarkBrown, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
                    onPressed: () async {
                      if (nameController.text.isEmpty || codeController.text.isEmpty) return;
                      try {
                        final newConfig = {
                          'has_code': hasCode,
                          'has_color': hasColor,
                          'has_phone': hasPhone,
                          'has_note': hasNote,
                        };
                        
                        if (isEditing) {
                          // تحديث
                          await _service.updateDefinitionType(code: itemToEdit['code'], nameAr: nameController.text, config: newConfig);
                        } else {
                          // إنشاء جديد
                          await _service.createDefinitionType(code: codeController.text.toLowerCase().trim(), nameAr: nameController.text, config: newConfig);
                        }

                        if (mounted) {
                          Navigator.pop(context);
                          _loadTypes();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الحفظ بنجاح"), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("خطأ: تأكد أن الرمز غير مكرر"), backgroundColor: Colors.red));
                      }
                    },
                    child: Text(isEditing ? "حفظ التعديلات" : "إنشاء القائمة"),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  // ✅ دالة الحذف مع التأكيد
  Future<void> _confirmDelete(String code, String name) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تحذير هام"),
        content: Text("سيتم حذف قائمة ($name) وجميع البيانات والتعريفات المسجلة بداخلها!\nهل أنت متأكد تماماً؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.deleteDefinitionType(code);
              _loadTypes();
            },
            child: const Text("حذف نهائي", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // الواجهة الرئيسية
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تعريفات النظام"), 
        backgroundColor: AppTheme.kDarkBrown, 
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      // ✅ الزر يظهر فقط لمن يملك صلاحية إدارة الهيكل
      floatingActionButton: _canManageStructure ? FloatingActionButton.extended(
        backgroundColor: AppTheme.kDarkBrown,
        onPressed: () => _showStructureDialog(), // وضع الإضافة
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("تعريف قائمة"),
      ) : null,
      
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _types.isEmpty 
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(LucideIcons.listX, size: 60, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              const Text("لا توجد قوائم معرفة", style: TextStyle(color: Colors.grey))
            ]))
          : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, 
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: _types.length,
            itemBuilder: (context, index) {
              final type = _types[index];
              final config = type['field_config'] ?? {};
              final String code = type['code'];

              // ✅ التحقق من صلاحية رؤية هذه القائمة تحديداً
              // نقوم بتركيب نص الصلاحية: def.view.drivers
              final bool canViewThisList = _service.hasPermission('def.view.$code') || _canManageStructure;

              if (!canViewThisList) return const SizedBox.shrink(); // إخفاء القائمة

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    // ✅ عند الضغط: الذهاب لإدخال البيانات (Generic Screen)
                    // نمرر صلاحية الإضافة للشاشة التالية
                    final bool canAddItems = _service.hasPermission('def.create.$code') || _canManageStructure;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GenericDefinitionsScreen(
                          definitionType: code,
                          title: type['name_ar'],
                          config: Map<String, bool>.from(config),
                          canAdd: canAddItems, // نمرر الصلاحية
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // أيقونة تتغير حسب نوع الحقول
                            Icon(
                              config['has_color'] == true ? LucideIcons.palette 
                              : config['has_phone'] == true ? LucideIcons.truck
                              : config['has_code'] == true ? LucideIcons.qrCode
                              : LucideIcons.list, 
                              size: 32, 
                              color: AppTheme.kDarkBrown
                            ),
                            const SizedBox(height: 10),
                            Text(type['name_ar'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                      
                      // ✅ خيارات التعديل والحذف (فقط لمن يملك إدارة الهيكل)
                      if (_canManageStructure)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showStructureDialog(itemToEdit: type);
                              } else if (value == 'delete') _confirmDelete(type['code'], type['name_ar']);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16, color: Colors.blue), SizedBox(width: 5), Text("تعديل")])),
                              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 5), Text("حذف")])),
                            ],
                          ),
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