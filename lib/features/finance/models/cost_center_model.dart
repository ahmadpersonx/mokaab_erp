// [كود محدث] - cost_center_model.dart
class CostCenterModel {
  int? id;
  String code;
  String name;
  String? parentCode;
  bool isActive;
  
  // الحقل الجديد: مجموع المصاريف (حالياً صفر حتى نبني القيود)
  double balance; 

  CostCenterModel({
    this.id,
    required this.code,
    required this.name,
    this.parentCode,
    this.isActive = true,
    this.balance = 0.0,
  });

  factory CostCenterModel.fromMap(Map<String, dynamic> map) {
    return CostCenterModel(
      id: map['id'],
      code: map['code'],
      name: map['name'],
      parentCode: map['parent_code'],
      isActive: map['is_active'] ?? true,
      // لاحقاً سنربط هذا الحقل بجدول العمليات المالية
      balance: 0.0, 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'parent_code': parentCode,
      'is_active': isActive,
      // لا نرسل balance للقاعدة لأنه حقل محسوب وليس مخزن
    };
  }
}