// [كود رقم 16] - account_model.dart (النسخة المحدثة)
class AccountModel {
  int? id;
  String code;
  String nameAr;
  String? parentCode; // كود الحساب الأب
  String nature;      // debit (مدين) أو credit (دائن)
  bool isTransaction; // هل يقبل قيود؟
  double currentBalance; // الرصيد الحالي
  bool isActive;
  
  // --- الحقول الجديدة ---
  int level;          // مستوى الحساب في الشجرة
  bool requireCostCenter; // هل يتطلب مركز تكلفة إجباري؟
  bool isContra;      // هل هو حساب عكسي (طبيعته عكس الأب)؟

  AccountModel({
    this.id,
    required this.code,
    required this.nameAr,
    this.parentCode,
    required this.nature,
    this.isTransaction = false,
    this.currentBalance = 0.0,
    this.isActive = true,
    this.level = 1, 
    this.requireCostCenter = false,
    this.isContra = false,
  });

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'],
      code: map['code'].toString(),
      nameAr: map['name_ar'] ?? '',
      parentCode: map['parent_code']?.toString(),
      nature: map['nature'] ?? 'debit',
      isTransaction: map['is_transaction'] ?? false,
      currentBalance: (map['current_balance'] ?? 0.0).toDouble(),
      isActive: map['is_active'] ?? true,
      
      // قراءة الحقول الجديدة
      level: map['level'] != null ? int.tryParse(map['level'].toString()) ?? 1 : 1,
      requireCostCenter: map['require_cost_center'] ?? false,
      isContra: map['is_contra'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name_ar': nameAr,
      'parent_code': parentCode,
      'nature': nature,
      'is_transaction': isTransaction,
      'is_active': isActive,
      'level': level,
      'require_cost_center': requireCostCenter,
      'is_contra': isContra,
    };
  }
}