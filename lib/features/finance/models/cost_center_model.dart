// FileName: lib/features/finance/models/cost_center_model.dart

class CostCenterModel {
  final int id;
  final String code;
  final String name;
  final String? parentCode;
  final String? type;
  final double balance;
  final bool isActive;

  CostCenterModel({
    required this.id,
    required this.code,
    required this.name,
    this.parentCode,
    this.type,
    this.balance = 0.0,
    this.isActive = true,
  });

  factory CostCenterModel.fromMap(Map<String, dynamic> map) {
    return CostCenterModel(
      id: map['id'] ?? 0,
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      parentCode: map['parent_code'],
      type: map['type'],
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'parent_code': parentCode,
      'type': type,
      'balance': balance,
      'is_active': isActive,
    };
  }

  // For compatibility with older code that might use fromJson/toJson
  factory CostCenterModel.fromJson(Map<String, dynamic> json) => CostCenterModel.fromMap(json);
  Map<String, dynamic> toJson() => toMap();
}