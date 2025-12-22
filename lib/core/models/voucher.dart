import 'voucher_line.dart';

/// نموذج الحوالة (Voucher Model)
/// يمثل حوالة من الحوالات المالية (قبض أو دفع)

class Voucher {
  final int? id; // معرّف فريد (اختياري عند الإنشاء)
  final String voucherNumber; // رقم الحوالة الفريد
  final String type; // نوع الحوالة: receipt, disbursement, transfer
  final DateTime date; // تاريخ الحوالة
  final String paymentMethod; // طريقة الدفع: cash, check, transfer
  final String? treasuryAccountCode; // رمز حساب الخزينة
  final String? description; // الوصف
  final double amount; // المبلغ الإجمالي
  final List<VoucherLine> lines; // بنود الحوالة
  
  // حقول الشيك (اختيارية)
  final String? checkNo; // رقم الشيك
  final DateTime? checkDueDate; // تاريخ استحقاق الشيك
  final String? bankName; // اسم البنك
  final int? bankId; // معرّف البنك
  final String? checkStatus; // حالة الشيك: pending, collected
  final DateTime? checkCollectedDate; // تاريخ استلام الشيك

  // حقول العلاقة
  final int? linkedJournalEntryId; // معرّف القيد المرتبط (اختياري)
  final DateTime? createdAt; // تاريخ الإنشاء
  final String? createdBy; // معرّف المستخدم الذي أنشأ السند

  Voucher({
    this.id,
    required this.voucherNumber,
    required this.type,
    required this.date,
    required this.paymentMethod,
    this.treasuryAccountCode,
    this.description,
    required this.amount,
    this.lines = const [],
    this.checkNo,
    this.checkDueDate,
    this.bankName,
    this.bankId,
    this.checkStatus,
    this.checkCollectedDate,
    this.linkedJournalEntryId,
    this.createdAt,
    this.createdBy,
  });

  /// تحويل من JSON
  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'],
      voucherNumber: json['voucher_number'] ?? '',
      type: json['type'] ?? 'receipt',
      date: json['date'] is String
          ? DateTime.parse(json['date'])
          : json['date'] ?? DateTime.now(),
      paymentMethod: json['payment_method'] ?? 'cash',
      treasuryAccountCode: json['treasury_account_id'],
      description: json['description'],
      amount: (json['amount'] ?? 0).toDouble(),
      lines: (json['voucher_lines'] as List?)
              ?.map((line) => VoucherLine.fromJson(line))
              .toList() ??
          [],
      checkNo: json['check_no'],
      checkDueDate: json['check_due_date'] is String
          ? DateTime.parse(json['check_due_date'])
          : json['check_due_date'],
      bankName: json['bank_name'],
      bankId: json['bank_id'],
      checkStatus: json['check_status'],
      checkCollectedDate: json['check_collected_date'] is String
          ? DateTime.parse(json['check_collected_date'])
          : json['check_collected_date'],
      linkedJournalEntryId: json['linked_journal_entry_id'],
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'])
          : json['created_at'],
      createdBy: json['created_by'],
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'voucher_number': voucherNumber,
    'type': type,
    'date': date.toIso8601String().split('T')[0],
    'payment_method': paymentMethod,
    'treasury_account_id': treasuryAccountCode,
    'description': description,
    'amount': amount,
    'lines': lines.map((line) => line.toJson()).toList(),
    'check_no': checkNo,
    'check_due_date': checkDueDate?.toIso8601String().split('T')[0],
    'bank_name': bankName,
    'bank_id': bankId,
    'check_status': checkStatus,
    'check_collected_date': checkCollectedDate?.toIso8601String().split('T')[0],
    'linked_journal_entry_id': linkedJournalEntryId,
    'created_at': createdAt?.toIso8601String(),
    'created_by': createdBy,
  };

  /// نسخ مع تعديل
  Voucher copyWith({
    int? id,
    String? voucherNumber,
    String? type,
    DateTime? date,
    String? paymentMethod,
    String? treasuryAccountCode,
    String? description,
    double? amount,
    List<VoucherLine>? lines,
    String? checkNo,
    DateTime? checkDueDate,
    String? bankName,
    int? bankId,
    String? checkStatus,
    DateTime? checkCollectedDate,
    int? linkedJournalEntryId,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Voucher(
      id: id ?? this.id,
      voucherNumber: voucherNumber ?? this.voucherNumber,
      type: type ?? this.type,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      treasuryAccountCode: treasuryAccountCode ?? this.treasuryAccountCode,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      lines: lines ?? this.lines,
      checkNo: checkNo ?? this.checkNo,
      checkDueDate: checkDueDate ?? this.checkDueDate,
      bankName: bankName ?? this.bankName,
      bankId: bankId ?? this.bankId,
      checkStatus: checkStatus ?? this.checkStatus,
      checkCollectedDate: checkCollectedDate ?? this.checkCollectedDate,
      linkedJournalEntryId: linkedJournalEntryId ?? this.linkedJournalEntryId,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// حساب الإجمالي من البنود
  double get totalFromLines => lines.fold(0, (sum, line) => sum + line.amount);

  /// هل هذه حوالة قبض؟
  bool get isReceipt => type == 'receipt';

  /// هل هذه حوالة دفع؟
  bool get isDisbursement => type == 'disbursement';

  /// هل طريقة الدفع نقدي؟
  bool get isCash => paymentMethod == 'cash';

  /// هل طريقة الدفع شيك؟
  bool get isCheck => paymentMethod == 'check';

  /// هل طريقة الدفع حوالة بنكية؟
  bool get isTransfer => paymentMethod == 'transfer';

  /// هل الشيك معلق الاستلام؟
  bool get isCheckPending => isCheck && checkStatus == 'pending';

  /// هل الشيك تم استلامه؟
  bool get isCheckCollected => isCheck && checkStatus == 'collected';

  @override
  String toString() => 'Voucher(number: $voucherNumber, type: $type, amount: $amount)';
}
