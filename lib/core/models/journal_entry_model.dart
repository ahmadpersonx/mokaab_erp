// [كود مصحح نهائي] - journal_entry_model.dart
class JournalEntryLine {
  int? id;
  int? journalEntryId;
  String accountId;
  int? costCenterId;
  String description;
  double debit;
  double credit;
  String? accountName;
  String? costCenterName;

  JournalEntryLine({
    this.id,
    this.journalEntryId,
    required this.accountId,
    this.costCenterId,
    this.description = '',
    this.debit = 0.0,
    this.credit = 0.0,
    this.accountName,
    this.costCenterName,
  });

  factory JournalEntryLine.fromMap(Map<String, dynamic> map) {
    final accountMap = map['accounts'] as Map<String, dynamic>?;
    final costCenterMap = map['cost_centers'] as Map<String, dynamic>?;

    return JournalEntryLine(
      id: map['id'],
      journalEntryId: map['journal_entry_id'],
      accountId: map['account_id'] ?? '',
      costCenterId: map['cost_center_id'],
      description: map['description'] ?? '',
      debit: (map['debit'] ?? 0.0).toDouble(),
      credit: (map['credit'] ?? 0.0).toDouble(),
      accountName: accountMap?['name_ar'],
      costCenterName: costCenterMap?['name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'account_id': accountId,
      'cost_center_id': costCenterId,
      'description': description,
      'debit': debit,
      'credit': credit,
    };
  }
}

class JournalEntryModel {
  int? id;
  String entryNumber;
  DateTime entryDate;
  String? reference;
  String? description;
  String status;
  List<JournalEntryLine> lines;

  JournalEntryModel({
    this.id,
    required this.entryNumber,
    required this.entryDate,
    this.reference,
    this.description,
    this.status = 'posted',
    this.lines = const [],
  });

  factory JournalEntryModel.fromMap(Map<String, dynamic> map) {
    final linesData = map['journal_entry_lines'];
    List<JournalEntryLine> parsedLines = [];
    if (linesData is List) {
      parsedLines = linesData.map((e) {
        if (e is Map<String, dynamic>) {
          return JournalEntryLine.fromMap(e);
        } else {
          return e as JournalEntryLine;
        }
      }).toList();
    }
    return JournalEntryModel(
      id: map['id'],
      entryNumber: map['entry_number'] ?? '',
      entryDate: map['entry_date'] is String 
          ? DateTime.parse(map['entry_date']) 
          : map['entry_date'] as DateTime,
      reference: map['reference'],
      description: map['description'],
      status: map['status'] ?? 'posted',
      lines: parsedLines,
    );
  }

  Map<String, dynamic> toMap() => {
    'entry_number': entryNumber,
    'entry_date': entryDate.toIso8601String(),
    'reference': reference,
    'description': description,
    'status': status,
  };
}