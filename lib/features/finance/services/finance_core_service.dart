// FileName: lib/features/finance/services/finance_core_service.dart
// Revision: 5.0 (Restored getVouchers & Merged All Logic)
// Date: 2025-12-19

import 'package:flutter/foundation.dart';
import '../models/account_model.dart';
import '../models/journal_entry_model.dart';
import '../models/cost_center_model.dart';
import 'finance_base.dart';

mixin FinanceCoreService on FinanceBase {
  // ==========================================
  // 1. شجرة الحسابات (Accounts)
  // ==========================================
  Future<List<AccountModel>> getAllAccounts() async {
    try {
      final response = await supabase
          .from('accounts_with_balance') 
          .select()
          .order('code', ascending: true);
          
      return (response as List).map((e) => AccountModel.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint("Error fetching accounts: $e");
      rethrow;
    }
  }

  Future<void> addAccount(AccountModel account) async {
    try {
      final data = account.toMap();
      data.remove('id');
      await supabase.from('accounts').insert(data);
    } catch (e) {
      debugPrint("Error adding account: $e");
      rethrow;
    }
  }

  Future<void> updateAccount(int id, String nameAr, String nature, bool requireCostCenter, bool isContra) async {
    try {
      await supabase.from('accounts').update({
        'name_ar': nameAr,
        'nature': nature,
        'require_cost_center': requireCostCenter,
        'is_contra': isContra,
      }).eq('id', id);
    } catch (e) {
      debugPrint("Error updating account: $e");
      rethrow;
    }
  }

  Future<void> deleteAccount(int id) async {
    try {
      await supabase.from('accounts').delete().eq('id', id);
    } catch (e) {
      debugPrint("Error deleting account: $e");
      rethrow;
    }
  }

  // ==========================================
  // 2. القيود اليومية (Journal Entries)
  // ==========================================
  Future<String> saveJournalEntry(JournalEntryModel entry) async {
    try {
      final lastEntry = await supabase.from('journal_entries').select('entry_number').order('id', ascending: false).limit(1);
      int lastNum = 0;
      if (lastEntry.isNotEmpty) {
        final lastEntryNumber = lastEntry.first['entry_number'] as String;
        lastNum = int.tryParse(lastEntryNumber.split('-').last) ?? 0;
      }
      entry.entryNumber = 'JV-${DateTime.now().year}-${(lastNum + 1).toString().padLeft(3, '0')}';

      final savedHeader = await supabase.from('journal_entries').insert(entry.toMap()).select('id').single();
      
      final linesData = entry.lines.map((l) => {
        ...l.toMap(), 
        'journal_entry_id': savedHeader['id']
      }).toList();
      
      await supabase.from('journal_entry_lines').insert(linesData);
      
      return entry.entryNumber;
    } catch (e) {
      debugPrint("Error saving entry: $e");
      rethrow;
    }
  }

  Future<String> updateJournalEntry(JournalEntryModel entry) async {
    try {
      await supabase.from('journal_entries').update(entry.toMap()).eq('id', entry.id!);
      await supabase.from('journal_entry_lines').delete().eq('journal_entry_id', entry.id!);
      
      final linesData = entry.lines.map((l) => {
        ...l.toMap(), 
        'journal_entry_id': entry.id
      }).toList();
      
      await supabase.from('journal_entry_lines').insert(linesData);
      
      return entry.entryNumber;
    } catch (e) {
      debugPrint("Error updating entry: $e");
      rethrow;
    }
  }

  Future<JournalEntryModel?> getJournalEntryByNumber(String entryNumber) async {
    try {
      final header = await supabase.from('journal_entries').select().eq('entry_number', entryNumber).single();
      final linesRaw = await supabase.from('journal_entry_lines')
          .select('*, accounts(id, code, name_ar), cost_centers(name)')
          .eq('journal_entry_id', header['id'])
          .order('id', ascending: true);
          
      List<Map<String, dynamic>> processedLines = [];
      for (var line in linesRaw) {
         Map<String, dynamic> l = Map.from(line);
         if (l['accounts'] != null) {
           l['account_id'] = l['accounts']['code']; 
         }
         processedLines.add(l);
      }

      return JournalEntryModel.fromMap({...header, 'journal_entry_lines': processedLines});
    } catch (e) {
      debugPrint("Error fetching entry details: $e");
      rethrow;
    }
  }

  // ✅ دالة الفلترة المتقدمة (للشاشة الجديدة)
  Future<List<Map<String, dynamic>>> getFilteredJournalEntries({
    DateTime? fromDate,
    DateTime? toDate,
    String? debitAccount,
    String? creditAccount,
    String? status,
    String? searchQuery,
  }) async {
    try {
      var query = supabase.from('journal_entries').select('''
        id, entry_number, entry_date, status, reference, description,
        journal_entry_lines!inner ( debit, credit, account_id, accounts ( name_ar ) )
      ''');

      if (fromDate != null) query = query.gte('entry_date', fromDate.toIso8601String());
      if (toDate != null) {
        final endOfDay = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59);
        query = query.lte('entry_date', endOfDay.toIso8601String());
      }
      if (status != null && status.isNotEmpty) query = query.eq('status', status);
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('description.ilike.%$searchQuery%,entry_number.ilike.%$searchQuery%');
      }

      final response = await query.order('id', ascending: false);

      return (response as List).map((entry) {
        final lines = entry['journal_entry_lines'] as List;
        double totalAmount = lines.fold(0.0, (sum, line) => sum + (line['debit'] ?? 0));
        return {
          'id': entry['entry_number'],
          'date': entry['entry_date'],
          'description': entry['description'],
          'amount': totalAmount,
          'status': entry['status'],
          'ref_number': entry['reference'],
        };
      }).toList();
    } catch (e) {
      debugPrint("Error filtering entries: $e");
      return [];
    }
  }

  // دالة لجلب الملخص (للشاشات القديمة - Backward Compatibility)
  Future<List<Map<String, dynamic>>> getJournalEntriesSummary({
    String? accountId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    return getFilteredJournalEntries(fromDate: fromDate, toDate: toDate);
  }

  // ==========================================
  // 3. مراكز التكلفة
  // ==========================================
  Future<List<CostCenterModel>> getAllCostCenters() async {
    try {
      final response = await supabase.from('cost_centers').select().order('code', ascending: true);
      return (response as List).map((e) => CostCenterModel.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint("Error fetching cost centers: $e");
      rethrow;
    }
  }

  // ==========================================
  // 4. نظام السندات الذكي (Vouchers Engine)
  // ==========================================
  Future<Map<String, dynamic>?> getVoucherByNumber(String voucherNumber) async {
    try {
      final response = await supabase
          .from('vouchers')
          .select('''
            *,
            voucher_lines (
              amount,
              description,
              cost_center_id,
              account_id,
              accounts ( id, code, name_ar ),
              cost_centers ( id, name )
            )
          ''')
          .eq('voucher_number', voucherNumber)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint("Error fetching voucher: $e");
      return null;
    }
  }

  Future<void> createVoucher({
    required String type,
    required String paymentMethod,
    required DateTime date,
    required String treasuryAccountId,
    required double totalAmount,
    required String description,
    required List<Map<String, dynamic>> lines,
    String? checkNo,
    DateTime? checkDueDate,
    int? bankId,
  }) async {
    try {
      final lastVoucher = await supabase.from('vouchers').select('voucher_number').eq('type', type).order('id', ascending: false).limit(1);
      int lastNum = 0;
      if (lastVoucher.isNotEmpty) {
        lastNum = int.tryParse(lastVoucher.first['voucher_number'].split('-').last) ?? 0;
      }
      String prefix = type == 'receipt' ? 'RV' : 'PV';
      String voucherNumber = '$prefix-${DateTime.now().year}-${(lastNum + 1).toString().padLeft(4, '0')}';

      String fullDescription = "$description - (سند رقم: $voucherNumber)";

      List<JournalEntryLine> journalLines = [];
      journalLines.add(JournalEntryLine(
        accountId: treasuryAccountId,
        description: fullDescription,
        debit: type == 'receipt' ? totalAmount : 0,
        credit: type == 'payment' ? totalAmount : 0,
      ));

      for (var line in lines) {
        journalLines.add(JournalEntryLine(
          accountId: line['account_id'],
          description: line['description']?.isNotEmpty == true ? "${line['description']} - $voucherNumber" : fullDescription,
          costCenterId: line['cost_center_id'],
          debit: type == 'payment' ? line['amount'] : 0,
          credit: type == 'receipt' ? line['amount'] : 0,
        ));
      }

      final journalEntry = JournalEntryModel(
        entryNumber: '',
        entryDate: date,
        reference: voucherNumber,
        description: fullDescription,
        status: 'posted',
        lines: journalLines,
      );
      
      String journalEntryNo = await saveJournalEntry(journalEntry);
      final jeIdResponse = await supabase.from('journal_entries').select('id').eq('entry_number', journalEntryNo).single();
      int jeId = jeIdResponse['id'];

      final voucherData = {
        'voucher_number': voucherNumber,
        'type': type,
        'date': date.toIso8601String(),
        'payment_method': paymentMethod,
        'treasury_account_id': treasuryAccountId,
        'description': description,
        'amount': totalAmount,
        'check_no': checkNo,
        'check_due_date': checkDueDate?.toIso8601String(),
        'bank_id': bankId,
        'linked_journal_entry_id': jeId,
        'created_by': supabase.auth.currentUser?.id,
      };

      final voucherResponse = await supabase.from('vouchers').insert(voucherData).select('id').single();
      
      final voucherLinesData = lines.map((l) => {
        'voucher_id': voucherResponse['id'],
        'account_id': l['account_id'],
        'amount': l['amount'],
        'cost_center_id': l['cost_center_id'],
        'description': l['description']
      }).toList();

      await supabase.from('voucher_lines').insert(voucherLinesData);

    } catch (e) {
      debugPrint("Error creating voucher: $e");
      rethrow;
    }
  }

  Future<void> updateVoucher({
    required int voucherId,
    required String type,
    required String paymentMethod,
    required DateTime date,
    required String treasuryAccountId,
    required double totalAmount,
    required String description,
    required List<Map<String, dynamic>> lines,
    String? checkNo,
    DateTime? checkDueDate,
    int? bankId,
  }) async {
    try {
      final oldVoucher = await supabase
          .from('vouchers')
          .select('linked_journal_entry_id, voucher_number')
          .eq('id', voucherId)
          .single();
          
      int jeId = oldVoucher['linked_journal_entry_id'];
      String voucherNumber = oldVoucher['voucher_number'];

      await supabase.from('vouchers').update({
        'date': date.toIso8601String(),
        'payment_method': paymentMethod,
        'treasury_account_id': treasuryAccountId,
        'description': description,
        'amount': totalAmount,
        'check_no': checkNo,
        'check_due_date': checkDueDate?.toIso8601String(),
        'bank_id': bankId,
      }).eq('id', voucherId);

      await supabase.from('voucher_lines').delete().eq('voucher_id', voucherId);
      final voucherLinesData = lines.map((l) => {
        'voucher_id': voucherId,
        'account_id': l['account_id'],
        'amount': l['amount'],
        'cost_center_id': l['cost_center_id'],
        'description': l['description']
      }).toList();
      await supabase.from('voucher_lines').insert(voucherLinesData);

      String fullDescription = "$description - (سند رقم: $voucherNumber)";
      List<JournalEntryLine> journalLines = [];
      
      journalLines.add(JournalEntryLine(
        accountId: treasuryAccountId,
        description: fullDescription,
        debit: type == 'receipt' ? totalAmount : 0,
        credit: type == 'payment' ? totalAmount : 0,
      ));

      for (var line in lines) {
        journalLines.add(JournalEntryLine(
          accountId: line['account_id'],
          description: line['description']?.isNotEmpty == true ? "${line['description']} - $voucherNumber" : fullDescription,
          costCenterId: line['cost_center_id'],
          debit: type == 'payment' ? line['amount'] : 0,
          credit: type == 'receipt' ? line['amount'] : 0,
        ));
      }

      final journalEntry = JournalEntryModel(
        id: jeId,
        entryNumber: '', 
        entryDate: date,
        reference: voucherNumber,
        description: fullDescription,
        status: 'posted',
        lines: journalLines,
      );
      
      await updateJournalEntry(journalEntry);

    } catch (e) {
      debugPrint("Error updating voucher: $e");
      rethrow;
    }
  }

  // ==========================================
  // 5. إدارة البنوك (النظام الجديد الموحد)
  // ==========================================
  Future<List<Map<String, dynamic>>> getBanks() async {
    try {
      final response = await supabase
          .from('system_definitions')
          .select('id, name_ar, code')
          .eq('type', 'banks') 
          .eq('is_active', true)
          .order('name_ar');
      
      return List<Map<String, dynamic>>.from(response).map((e) => {
        'id': e['id'],
        'name': e['name_ar'], 
        'code': e['code']
      }).toList();
    } catch (e) {
      debugPrint("Error fetching banks: $e");
      return [];
    }
  }

  // ==========================================
  // 6. إدارة الشيكات (تحديث وفلترة)
  // ==========================================
  
  // ✅ دالة التوافق مع الكود القديم (getChecks)
  Future<List<Map<String, dynamic>>> getChecks({String? type}) async {
    return getFilteredChecks(isIncoming: type == 'receipt');
  }

  // ✅ دالة الفلترة المتقدمة للشيكات
  Future<List<Map<String, dynamic>>> getFilteredChecks({
    required bool isIncoming,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
  }) async {
    try {
      // استخدام العلاقة مع الجدول الجديد (إذا كانت متوفرة) أو بدونها إذا لم تكن العلاقة معرفة بعد
      // لضمان العمل، سنجلب البيانات الخام ثم نقوم بالربط إذا لزم الأمر، 
      // ولكن هنا نفترض أن العلاقة banks موجودة في Supabase أو سنستخدم bank_id
      
      var query = supabase
          .from('vouchers')
          .select('''
             *,
             banks:bank_id ( name_ar ) 
          ''') // نحتاج تعريف Foreign Key في Supabase ليعمل هذا
          .eq('payment_method', 'check')
          .eq('type', isIncoming ? 'receipt' : 'payment');

      if (fromDate != null) query = query.gte('check_due_date', fromDate.toIso8601String());
      if (toDate != null) query = query.lte('check_due_date', toDate.toIso8601String());
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('check_no', '%$searchQuery%');
      }

      final response = await query.order('check_due_date', ascending: true);
      
      return List<Map<String, dynamic>>.from(response).map((check) {
        // معالجة اسم البنك بأمان
        String bankName = 'غير محدد';
        if (check['banks'] != null) {
           bankName = check['banks']['name_ar'] ?? '';
        }

        return {
          'id': check['id'],
          'check_no': check['check_no'],
          'amount': check['amount'],
          'check_due_date': check['check_due_date'],
          'check_status': check['check_status'],
          'banks': {'name': bankName}, // تنسيق موحد للواجهة
        };
      }).toList();
    } catch (e) {
      debugPrint("Error filtering checks: $e");
      return [];
    }
  }

  Future<void> updateCheckStatus(int voucherId, String newStatus) async {
    try {
      await supabase.from('vouchers').update({
        'check_status': newStatus,
        'check_collected_date': newStatus == 'collected' ? DateTime.now().toIso8601String() : null
      }).eq('id', voucherId);
    } catch (e) {
      debugPrint("Error updating check status: $e");
      rethrow;
    }
  }

  // ==========================================
  // 7. التقارير وقوائم السندات (تمت استعادة الدالة المفقودة)
  // ==========================================
  // ✅✅✅ تم استعادة الدالة لإصلاح خطأ VouchersListScreen ✅✅✅
  Future<List<Map<String, dynamic>>> getVouchers({
    required String type, 
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = supabase.from('vouchers')
          .select('''
            *, 
            voucher_lines (
              amount,
              account_id,
              accounts ( name_ar )
            )
          ''')
          .eq('type', type);

      if (fromDate != null) query = query.gte('date', fromDate.toIso8601String());
      if (toDate != null) query = query.lte('date', toDate.toIso8601String());

      final response = await query.order('date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetching vouchers: $e");
      return [];
    }
  }
}