// lib/core/models/account_model.dart
class AccountModel {
  final int id;
  final String code;
  final String nameAr;
  final String? nameEn;
  final String nature; // 'debit' or 'credit'
  final String? parentCode;
  
  final bool isParent; 
  final bool requireCostCenter;
  final bool isContra;
  final bool isActive;

  // ✅ الحقول التي كانت مفقودة وأعدناها لتجنب الأخطاء
  final int level;
  final double currentBalance;

  // ✅ Getter ذكي لحل مشكلة 'isTransaction'
  // (إذا كان أباً فهو ليس معاملة، والعكس صحيح)
  bool get isTransaction => !isParent;

  AccountModel({
    required this.id,
    required this.code,
    required this.nameAr,
    this.nameEn,
    this.nature = 'debit',
    this.parentCode,
    this.isParent = false,
    this.requireCostCenter = false,
    this.isContra = false,
    this.isActive = true,
    // ✅ قيم افتراضية للحقول الجديدة
    this.level = 1,
    this.currentBalance = 0.0,
  });

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] is int ? map['id'] : 0,
      code: map['code']?.toString() ?? '',
      nameAr: map['name_ar']?.toString() ?? '',
      nameEn: map['name_en']?.toString(),
      nature: map['nature']?.toString() ?? 'debit',
      parentCode: map['parent_code']?.toString(),
      isParent: map['is_parent'] ?? false,
      requireCostCenter: map['require_cost_center'] ?? false,
      isContra: map['is_contra'] ?? false,
      isActive: map['is_active'] ?? true,
      
      // ✅ قراءة الحقول الجديدة (مع حماية من القيم الفارغة)
      level: map['level'] is int ? map['level'] : 1,
      currentBalance: (map['current_balance'] is num) 
          ? (map['current_balance'] as num).toDouble() 
          : 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name_ar': nameAr,
      'name_en': nameEn,
      'nature': nature,
      'parent_code': parentCode,
      'is_parent': isParent,
      'require_cost_center': requireCostCenter,
      'is_contra': isContra,
      'is_active': isActive,
      // 'level': level, // عادة المستوى يحسب ولا يخزن، لكن يمكن إرساله إذا لزم الأمر
      // 'current_balance': currentBalance, // الرصيد لا يرسل عند التعديل عادة
    };
  }
}