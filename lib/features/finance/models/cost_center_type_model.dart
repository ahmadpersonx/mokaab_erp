// [كود رقم 9 - المعدل] - cost_center_type_model.dart

class CostCenterTypeModel {
  int? id;
  String code;
  String nameAr;
  String? nameEn;

  CostCenterTypeModel({
    this.id,
    required this.code,
    required this.nameAr,
    this.nameEn,
  });

  factory CostCenterTypeModel.fromMap(Map<String, dynamic> map) {
    return CostCenterTypeModel(
      id: map['id'],
      code: map['code'],
      nameAr: map['name_ar'],
      nameEn: map['name_en'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name_ar': nameAr,
      'name_en': nameEn,
    };
  }

  // ---------------------------------------------------------
  // الإضافة الجديدة لحل مشكلة القائمة المنسدلة (Equality Override)
  // ---------------------------------------------------------
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true; // نفس الكائن في الذاكرة
  
    // أو كائن مختلف لكن يحمل نفس الـ ID والكود
    return other is CostCenterTypeModel &&
      other.id == id &&
      other.code == code;
  }

  @override
  int get hashCode => id.hashCode ^ code.hashCode;
}