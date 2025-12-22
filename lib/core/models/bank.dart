/// نموذج البنك (Bank Model)
/// يمثل بنك من البنوك المسموح به في النظام

class Bank {
  final int id; // معرّف فريد
  final String code; // رمز البنك
  final String nameAr; // اسم البنك بالعربية
  final String? nameEn; // اسم البنك بالإنجليزية
  final bool isActive; // هل البنك فعال؟

  Bank({
    required this.id,
    required this.code,
    required this.nameAr,
    this.nameEn,
    this.isActive = true,
  });

  /// تحويل من JSON
  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      nameAr: json['name_ar'] ?? '',
      nameEn: json['name_en'],
      isActive: json['is_active'] ?? true,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name_ar': nameAr,
    'name_en': nameEn,
    'is_active': isActive,
  };

  /// نسخ مع تعديل
  Bank copyWith({
    int? id,
    String? code,
    String? nameAr,
    String? nameEn,
    bool? isActive,
  }) {
    return Bank(
      id: id ?? this.id,
      code: code ?? this.code,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() => 'Bank(code: $code, nameAr: $nameAr)';
}
