/// نموذج الحساب (Account Model)
/// يمثل حساب من حسابات المحاسبة

class Account {
  final String code; // رمز الحساب
  final String nameAr; // اسم الحساب بالعربية
  final String? parentCode; // رمز الحساب الأب (للحسابات الهرمية)
  final String nature; // طبيعة الحساب: debit أو credit
  final bool isTransaction; // هل يمكن الترحيل له؟
  final String? nameEn; // اسم الحساب بالإنجليزية (للعرض)
  final String type; // نوع الحساب (للعرض)
  final double balance; // الرصيد (للعرض)
  final int level; // مستوى العمق في الهرمية
  final bool requireCostCenter; // هل يتطلب مركز تكلفة؟
  final bool isContra; // هل حساب مقابل؟
  final bool isParent; // هل هو حساب أب؟
  final int id; // معرّف فريد

  Account({
    required this.code,
    required this.nameAr,
    this.parentCode,
    required this.nature,
    required this.isTransaction,
    this.nameEn,
    this.type = 'asset',
    this.balance = 0.0,
    required this.level,
    required this.requireCostCenter,
    required this.isContra,
    required this.isParent,
    required this.id,
  });

  /// تحويل من JSON
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      code: json['code'] ?? '',
      nameAr: json['name_ar'] ?? '',
      parentCode: json['parent_code'],
      nature: json['nature'] ?? 'debit',
      isTransaction: json['is_transaction'] ?? false,
      nameEn: json['name_en'], // Not in DB, for UI
      type: json['type'] ?? 'asset', // Not in DB, for UI
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0, // From computed column
      level: json['level'] ?? 0,
      requireCostCenter: json['require_cost_center'] ?? false,
      isContra: json['is_contra'] ?? false,
      isParent: json['is_parent'] ?? false,
      id: json['id'] ?? 0,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() => {
    'code': code,
    'name_ar': nameAr,
    'parent_code': parentCode,
    'nature': nature,
    'is_transaction': isTransaction,
    'level': level,
    'require_cost_center': requireCostCenter,
    'is_contra': isContra,
    'is_parent': isParent,
    'id': id,
  };

  /// نسخ مع تعديل
  Account copyWith({
    String? code,
    String? nameAr,
    String? parentCode,
    String? nature,
    bool? isTransaction,
    int? level,
    bool? requireCostCenter,
    bool? isContra,
    bool? isParent,
    int? id,
  }) {
    return Account(
      code: code ?? this.code,
      nameAr: nameAr ?? this.nameAr,
      parentCode: parentCode ?? this.parentCode,
      nature: nature ?? this.nature,
      isTransaction: isTransaction ?? this.isTransaction,
      level: level ?? this.level,
      requireCostCenter: requireCostCenter ?? this.requireCostCenter,
      isContra: isContra ?? this.isContra,
      isParent: isParent ?? this.isParent,
      id: id ?? this.id,
    );
  }

  /// هل الحساب للصندوق؟
  bool get isCashBox => code.startsWith('101'); // حسب البيانات المتوقعة

  /// هل الحساب للبنك؟
  bool get isBank => code.startsWith('102'); // حسب البيانات المتوقعة

  /// هل الحساب عميل؟
  bool get isCustomer => code.startsWith('121'); // حسب البيانات المتوقعة

  @override
  String toString() => 'Account(code: $code, nameAr: $nameAr, nature: $nature)';
}
