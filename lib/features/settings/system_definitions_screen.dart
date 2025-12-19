// FileName: lib/features/settings/system_definitions_screen.dart
// Revision: 10.0 (Merged UI V2.1 with Logic V9.0 - Fixed Aspect Ratio & Navigation)
// Date: 2025-12-19

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/permissions.dart';
import '../../core/widgets/draggable_popup.dart';
import '../finance/services/finance_service.dart';
import 'generic_definitions_screen.dart';

class SystemDefinitionsScreen extends StatefulWidget {
  const SystemDefinitionsScreen({super.key});

  @override
  State<SystemDefinitionsScreen> createState() => _SystemDefinitionsScreenState();
}

class _SystemDefinitionsScreenState extends State<SystemDefinitionsScreen> {
  final FinanceService _service = FinanceService();
  List<Map<String, dynamic>> _types = [];
  bool _isLoading = true;
  bool _canManageStructure = false;

  // تعريف الألوان الخاصة بالثيم الجديد
  final primaryColor = const Color(0xFF5D4037); // بني غامق
  final secondaryColor = const Color(0xFF8D6E63); // بني فاتح
  final cardBgColor = Colors.white;
  final pageBgColor = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLoad();
  }

  Future<void> _checkPermissionsAndLoad() async {
    await _service.loadUserPermissions();
    if (mounted) {
      setState(() {
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
  // منطق الديالوج (تم الاحتفاظ به كما هو)
  // ==========================================
  void _showStructureDialog({Map<String, dynamic>? itemToEdit}) {
    final bool isEditing = itemToEdit != null;
    final nameController = TextEditingController(text: itemToEdit?['name_ar']);
    
    Map<String, dynamic> config = itemToEdit?['field_config'] ?? {};
    bool hasCode = config['has_code'] ?? true;
    bool hasColor = config['has_color'] ?? false;
    bool hasPhone = config['has_phone'] ?? false;
    bool hasNote = config['has_note'] ?? false;
    String selectedIconKey = config['icon'] ?? 'list';

    final List<Map<String, dynamic>> availableIcons = [
      {'key': 'list', 'icon': LucideIcons.list, 'label': 'قائمة'},
      {'key': 'box', 'icon': LucideIcons.box, 'label': 'أصناف'},
      {'key': 'ruler', 'icon': LucideIcons.ruler, 'label': 'وحدات'},
      {'key': 'warehouse', 'icon': LucideIcons.warehouse, 'label': 'مستودع'},
      {'key': 'palette', 'icon': LucideIcons.palette, 'label': 'ألوان'},
      {'key': 'truck', 'icon': LucideIcons.truck, 'label': 'نقل'},
      {'key': 'users', 'icon': LucideIcons.users, 'label': 'أشخاص'},
      {'key': 'user_cog', 'icon': LucideIcons.userCog, 'label': 'موظفين'},
      {'key': 'landmark', 'icon': LucideIcons.landmark, 'label': 'بنوك'},
      {'key': 'wallet', 'icon': LucideIcons.wallet, 'label': 'مالية'},
      {'key': 'tags', 'icon': LucideIcons.tags, 'label': 'وسوم'},
      {'key': 'map_pin', 'icon': LucideIcons.mapPin, 'label': 'مناطق'},
      {'key': 'calendar', 'icon': LucideIcons.calendar, 'label': 'تواريخ'},
      {'key': 'file_text', 'icon': LucideIcons.fileText, 'label': 'مستندات'},
      {'key': 'hammer', 'icon': LucideIcons.hammer, 'label': 'إنتاج'},
      {'key': 'shapes', 'icon': LucideIcons.shapes, 'label': 'أشكال'},
      {'key': 'gem', 'icon': LucideIcons.gem, 'label': 'حجر'},
      {'key': 'settings', 'icon': LucideIcons.settings, 'label': 'إعدادات'},
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return DraggablePopup(
            title: isEditing ? "تعديل خصائص القائمة" : "تعريف قائمة جديدة",
            onClose: () => Navigator.pop(context),
            width: 550,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("بيانات القائمة", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.kDarkBrown)),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "اسم القائمة",
                    hintText: "مثال: أنواع الحجر، السائقين...",
                    prefixIcon: Icon(LucideIcons.type),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("اختر أيقونة معبرة:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 10),
                Container(
                  height: 150,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: availableIcons.length,
                    itemBuilder: (context, index) {
                      final iconData = availableIcons[index];
                      final bool isSelected = iconData['key'] == selectedIconKey;
                      return InkWell(
                        onTap: () => setStateDialog(() => selectedIconKey = iconData['key']),
                        child: Tooltip(
                          message: iconData['label'],
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.kDarkBrown : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppTheme.kDarkBrown : Colors.grey.shade300,
                              ),
                            ),
                            child: Icon(
                              iconData['icon'],
                              size: 20,
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 30),
                const Text("ما هي الحقول الإضافية المطلوبة للعنصر؟", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.kDarkBrown)),
                CheckboxListTile(title: const Text("رمز / كود"), value: hasCode, onChanged: (v) => setStateDialog(() => hasCode = v!)),
                CheckboxListTile(title: const Text("لون تمييز"), value: hasColor, onChanged: (v) => setStateDialog(() => hasColor = v!)),
                CheckboxListTile(title: const Text("رقم هاتف"), value: hasPhone, onChanged: (v) => setStateDialog(() => hasPhone = v!)),
                CheckboxListTile(title: const Text("ملاحظات / وصف"), value: hasNote, onChanged: (v) => setStateDialog(() => hasNote = v!)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty) return;
                  
                  try {
                    final newConfig = {
                      'has_code': hasCode,
                      'has_color': hasColor,
                      'has_phone': hasPhone,
                      'has_note': hasNote,
                      'icon': selectedIconKey,
                    };

                    if (isEditing) {
                      await _service.updateDefinitionType(
                        code: itemToEdit['code'], 
                        nameAr: nameController.text, 
                        config: newConfig
                      );
                    } else {
                      String autoGeneratedCode = 'list_${DateTime.now().millisecondsSinceEpoch}';
                      await _service.createDefinitionType(
                        code: autoGeneratedCode, 
                        nameAr: nameController.text, 
                        config: newConfig
                      );
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      _loadTypes();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الحفظ بنجاح"), backgroundColor: Colors.green));
                    }
                  } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("حدث خطأ: $e"), backgroundColor: Colors.red));
                  }
                },
                child: Text(isEditing ? "حفظ التعديلات" : "إنشاء القائمة"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(String code, String name) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تحذير هام"),
        content: Text("سيتم حذف قائمة ($name) وجميع البيانات بداخلها!\nهل أنت متأكد؟"),
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

  IconData _getIconFromKey(String key) {
    switch (key) {
      case 'box': return LucideIcons.box;
      case 'ruler': return LucideIcons.ruler;
      case 'warehouse': return LucideIcons.warehouse;
      case 'palette': return LucideIcons.palette;
      case 'truck': return LucideIcons.truck;
      case 'users': return LucideIcons.users;
      case 'user_cog': return LucideIcons.userCog;
      case 'landmark': return LucideIcons.landmark;
      case 'wallet': return LucideIcons.wallet;
      case 'tags': return LucideIcons.tags;
      case 'map_pin': return LucideIcons.mapPin;
      case 'calendar': return LucideIcons.calendar;
      case 'file_text': return LucideIcons.fileText;
      case 'hammer': return LucideIcons.hammer;
      case 'shapes': return LucideIcons.shapes;
      case 'gem': return LucideIcons.gem;
      case 'settings': return LucideIcons.settings;
      default: return LucideIcons.list;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // --- 1. Header Section (تصميم V2.1 الجديد مع زر الإضافة) ---
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // النصوص
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "تعريفات النظام",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo', 
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "إدارة القوائم والخصائص العامة",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    // الأزرار (العودة + إضافة جديد)
                    Row(
                      children: [
                        if (_canManageStructure)
                          Container(
                            margin: const EdgeInsets.only(left: 12),
                            child: ElevatedButton.icon(
                              onPressed: () => _showStructureDialog(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text("إضافة قائمة"),
                            ),
                          ),
                        
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- 2. Grid Section (الشبكة المعدلة) ---
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: _isLoading
                  ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                  : _types.isEmpty
                      ? SliverFillRemaining(child: Center(child: Text("لا توجد بيانات", style: TextStyle(color: Colors.grey.shade600))))
                      : SliverGrid(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 250, // عرض أقصى للبطاقة لتصبح صغيرة ومناسبة
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.4, // نسبة 1.4 تعني عرض أكبر من الارتفاع (شكل مستطيل)
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final type = _types[index];
                              final config = type['field_config'] ?? {};
                              final String code = type['code'];

                              // التحقق من الصلاحيات
                              if (!_service.hasPermission('def.view.$code') && !_canManageStructure) {
                                return const SizedBox.shrink();
                              }

                              IconData icon = _getIconFromKey(config['icon'] ?? 'list');

                              return _buildCleanCard(
                                title: type['name_ar'],
                                icon: icon,
                                onTap: () {
                                  // استعادة وظيفة التنقل
                                  final bool canAddItems = _service.hasPermission('def.create.$code') || _canManageStructure;
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => GenericDefinitionsScreen(
                                    definitionType: code, 
                                    title: type['name_ar'], 
                                    config: Map<String, dynamic>.from(config), 
                                    canAdd: canAddItems
                                  )));
                                },
                                onEdit: _canManageStructure ? () => _showStructureDialog(itemToEdit: type) : null,
                                onDelete: _canManageStructure ? () => _confirmDelete(type['code'], type['name_ar']) : null,
                              );
                            },
                            childCount: _types.length,
                          ),
                        ),
            ),
            
            // مساحة في الأسفل لضمان عدم التصاق العناصر
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // --- 3. Clean Material Card Widget ---
  // تم فصل تصميم البطاقة ليكون نظيفاً وموحداً
  Widget _buildCleanCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          hoverColor: primaryColor.withOpacity(0.04),
          child: Stack(
            children: [
              // المحتوى الرئيسي
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF9F8), // لون خلفية الأيقونة
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Icon(icon, size: 28, color: primaryColor),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // أزرار التحكم (تظهر فقط للمدير)
              if (onEdit != null || onDelete != null)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Row(
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(LucideIcons.edit, size: 16, color: Colors.grey),
                          onPressed: onEdit,
                          tooltip: 'تعديل',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      const SizedBox(width: 8),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
                          onPressed: onDelete,
                          tooltip: 'حذف',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}