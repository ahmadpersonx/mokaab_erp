// FileName: lib/features/finance/models/journal_entry_model.dart

class JournalEntryModel {
  final int id;
  final String entryNumber;
  final DateTime entryDate;
  final String? reference;
  final String? description;
  final String status; // 'draft', 'posted', 'void'
  final double totalDebit;
  final double totalCredit;
  final List<JournalLineModel> lines;

  JournalEntryModel({
    required this.id,
    required this.entryNumber,
    required this.entryDate,
    this.reference,
    this.description,
    this.status = 'draft',
    this.totalDebit = 0.0,
    this.totalCredit = 0.0,
    this.lines = const [],
  });

  factory JournalEntryModel.fromJson(Map<String, dynamic> json) {
    var linesList = (json['journal_lines'] as List?)
            ?.map((e) => JournalLineModel.fromJson(e))
            .toList() ??
        [];

    return JournalEntryModel(
      id: json['id'] ?? 0,
      entryNumber: json['entry_number'] ?? '',
      entryDate: DateTime.parse(json['entry_date']),
      reference: json['reference'],
      description: json['description'],
      status: json['status'] ?? 'draft',
      totalDebit: (linesList.fold(0.0, (sum, item) => sum + (item.debit ?? 0.0))),
      totalCredit: (linesList.fold(0.0, (sum, item) => sum + (item.credit ?? 0.0))),
      lines: linesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entry_number': entryNumber,
      'entry_date': entryDate.toIso8601String(),
      'reference': reference,
      'description': description,
      'status': status,
    };
  }
}

class JournalLineModel {
  final int id;
  final int accountId;
  final String? accountName; // For display purposes
  final int? costCenterId;
  final String? description;
  final double? debit;
  final double? credit;

  JournalLineModel({
    required this.id,
    required this.accountId,
    this.accountName,
    this.costCenterId,
    this.description,
    this.debit,
    this.credit,
  });

  factory JournalLineModel.fromJson(Map<String, dynamic> json) {
    return JournalLineModel(
      id: json['id'] ?? 0,
      accountId: json['account_id'] ?? 0,
      // accountName might need to be fetched separately or joined
      costCenterId: json['cost_center_id'],
      description: json['description'],
      debit: (json['debit'] as num?)?.toDouble(),
      credit: (json['credit'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_id': accountId,
      'cost_center_id': costCenterId,
      'description': description,
      'debit': debit ?? 0.0,
      'credit': credit ?? 0.0,
    };
  }
}