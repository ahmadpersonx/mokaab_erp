// File: lib/core/models/definition_model.dart
class DefinitionModel {
  final int id;
  final String type;
  final String nameAr;
  final String? code;
  final Map<String, dynamic> extraData;
  final bool isActive;

  DefinitionModel({
    required this.id,
    required this.type,
    required this.nameAr,
    this.code,
    required this.extraData,
    required this.isActive,
  });

  factory DefinitionModel.fromJson(Map<String, dynamic> json) {
    return DefinitionModel(
      id: json['id'],
      type: json['type'],
      nameAr: json['name_ar'],
      code: json['code'],
      extraData: json['extra_data'] ?? {},
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 'id': id, // عادة لا نرسل الآيدي عند الإضافة
      'type': type,
      'name_ar': nameAr,
      'code': code,
      'extra_data': extraData,
      'is_active': isActive,
    };
  }
}