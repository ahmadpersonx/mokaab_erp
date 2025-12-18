class DefinitionModel {
  final int id;
  final String type;
  final String nameAr;
  final String? code;
  final bool isActive;
  final Map<String, dynamic> extraData;

  DefinitionModel({
    required this.id,
    required this.type,
    required this.nameAr,
    this.code,
    this.isActive = true,
    this.extraData = const {},
  });

  factory DefinitionModel.fromMap(Map<String, dynamic> map) {
    return DefinitionModel(
      // استخدام القيمة 0 إذا كان الـ id فارغاً لتجنب الكراش
      id: map['id'] is int ? map['id'] : 0, 
      
      type: map['type']?.toString() ?? '',
      
      nameAr: map['name_ar']?.toString() ?? 'بدون اسم',
      
      code: map['code']?.toString(),
      
      // إذا لم يكن الحقل موجوداً في القاعدة، نعتبره true
      isActive: map['is_active'] == null ? true : map['is_active'] as bool,
      
      // ✅ تحويل آمن للـ JSON حتى لو كان العمود غير موجود أو قيمته null
      extraData: (map['extra_data'] != null && map['extra_data'] is Map)
          ? Map<String, dynamic>.from(map['extra_data'])
          : {},
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'type': type,
      'name_ar': nameAr,
      'code': code,
      'is_active': isActive,
      'extra_data': extraData,
    };
    if (id != 0) {
      map['id'] = id;
    }
    return map;
  }
}