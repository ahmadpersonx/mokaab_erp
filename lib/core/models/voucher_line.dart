import 'account.dart';

/// نموذج بند الحوالة (Voucher Line Model)
/// يمثل بند واحد من بنود الحوالة

class VoucherLine {
  final int? id; // معرّف فريد (اختياري عند الإنشاء)
  final int? voucherId; // معرّف الحوالة
  final Account account; // الحساب المرتبط
  final double amount; // المبلغ
  final int? costCenterId; // معرّف مركز التكلفة (اختياري)
  final String? description; // الوصف
  final bool isDebit; // هل هو بطرف مدين؟

  VoucherLine({
    this.id,
    this.voucherId,
    required this.account,
    required this.amount,
    this.costCenterId,
    this.description,
    required this.isDebit,
  });

  /// تحويل من JSON
  factory VoucherLine.fromJson(Map<String, dynamic> json) {
    return VoucherLine(
      id: json['id'],
      voucherId: json['voucher_id'],
        account: Account.fromJson(json['accounts']),
      amount: (json['amount'] ?? 0).toDouble(),
      costCenterId: json['cost_center_id'],
      description: json['description'],
      isDebit: json['is_debit'] ?? true,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'voucher_id': voucherId,
    'account_id': account.id,
    'amount': amount,
    'cost_center_id': costCenterId,
    'description': description,
    'is_debit': isDebit,
  };

  /// نسخ مع تعديل
  VoucherLine copyWith({
    int? id,
    int? voucherId,
    Account? account,
    double? amount,
    int? costCenterId,
    String? description,
    bool? isDebit,
  }) {
    return VoucherLine(
      id: id ?? this.id,
      voucherId: voucherId ?? this.voucherId,
      account: account ?? this.account,
      amount: amount ?? this.amount,
      costCenterId: costCenterId ?? this.costCenterId,
      description: description ?? this.description,
      isDebit: isDebit ?? this.isDebit,
    );
  }

  @override
  String toString() => 'VoucherLine(account: ${account.nameAr}, amount: $amount, isDebit: $isDebit)';
}
