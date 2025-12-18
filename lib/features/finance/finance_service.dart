// lib/features/finance/finance_service.dart

import 'package:flutter/foundation.dart'; // ضروري لعمل debugPrint
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/models/account_model.dart';
import '../../core/models/journal_entry_model.dart';
import '../../core/models/cost_center_model.dart';
import '../../core/models/definition_model.dart'; // ✅ هام جداً

class FinanceService {
  final SupabaseClient _supabase = SupabaseService.client;

  // Getter للوصول المباشر
  SupabaseClient get supabase => _supabase;

  // قائمة لتخزين صلاحيات المستخدم المسجل حالياً
  static List<String> _currentUserPermissions = [];

  // ==========================================
  // 1. المصادقة (Auth) وإدارة الجلسة
  // ==========================================
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      return await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      debugPrint("Sign-in error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      _currentUserPermissions = [];
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint("Sign-out error: $e");
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    try {
      return await _supabase.from('profiles').select().eq('id', user.id).single();
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      return null;
    }
  }

  // ==========================================
  // 2. نظام الصلاحيات التفصيلي (Permissions)
  // ==========================================
  Future<void> loadUserPermissions() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _currentUserPermissions = [];
      return;
    }
    try {
      final response = await _supabase
          .from('user_permissions')
          .select('permission_code')
          .eq('user_id', user.id);
      
      _currentUserPermissions = (response as List)
          .map((e) => e['permission_code'] as String)
          .toList();
    } catch (e) {
      debugPrint("Error loading permissions: $e");
      _currentUserPermissions = [];
    }
  }

  bool hasPermission(String permissionCode) {
    return _currentUserPermissions.contains(permissionCode);
  }

  Future<List<Map<String, dynamic>>> getAllPermissionDefinitions() async {
    final response = await _supabase.from('permissions_def').select().order('module');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateUserPermissions(String userId, List<String> newPermissions) async {
    await _supabase.from('user_permissions').delete().eq('user_id', userId);
    if (newPermissions.isNotEmpty) {
      final data = newPermissions.map((code) => {
        'user_id': userId,
        'permission_code': code
      }).toList();
      await _supabase.from('user_permissions').insert(data);
    }
  }

  // ==========================================
  // 3. إدارة المستخدمين
  // ==========================================
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _supabase.from('profiles').select().order('full_name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetching users: $e");
      rethrow;
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _supabase.from('profiles').update({'role': newRole}).eq('id', userId);
    } catch (e) {
      debugPrint("Error updating role: $e");
      rethrow;
    }
  }

  // ==========================================
  // 4. شجرة الحسابات (Accounts)
  // ==========================================
  Future<List<AccountModel>> getAllAccounts() async {
    try {
      final response = await _supabase.from('accounts').select().order('code', ascending: true);
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
      await _supabase.from('accounts').insert(data);
    } catch (e) {
      debugPrint("Error adding account: $e");
      rethrow;
    }
  }

  Future<void> updateAccount(int id, String nameAr, String nature, bool requireCostCenter, bool isContra) async {
    try {
      await _supabase.from('accounts').update({
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
      await _supabase.from('accounts').delete().eq('id', id);
    } catch (e) {
      debugPrint("Error deleting account: $e");
      rethrow;
    }
  }

  // ==========================================
  // 5. القيود اليومية (Journal Entries)
  // ==========================================
  Future<String> saveJournalEntry(JournalEntryModel entry) async {
    try {
      final lastEntry = await _supabase.from('journal_entries').select('entry_number').order('id', ascending: false).limit(1);
      int lastNum = 0;
      if (lastEntry.isNotEmpty) {
        final lastEntryNumber = lastEntry.first['entry_number'] as String;
        lastNum = int.tryParse(lastEntryNumber.split('-').last) ?? 0;
      }
      entry.entryNumber = 'JV-${DateTime.now().year}-${(lastNum + 1).toString().padLeft(3, '0')}';

      final savedHeader = await _supabase.from('journal_entries').insert(entry.toMap()).select('id').single();
      final linesData = entry.lines.map((l) => {...l.toMap(), 'journal_entry_id': savedHeader['id']}).toList();
      await _supabase.from('journal_entry_lines').insert(linesData);
      return entry.entryNumber;
    } catch (e) {
      debugPrint("Error saving entry: $e");
      rethrow;
    }
  }

  Future<String> updateJournalEntry(JournalEntryModel entry) async {
    try {
      await _supabase.from('journal_entries').update(entry.toMap()).eq('id', entry.id!);
      await _supabase.from('journal_entry_lines').delete().eq('journal_entry_id', entry.id!);
      final linesData = entry.lines.map((l) => {...l.toMap(), 'journal_entry_id': entry.id}).toList();
      await _supabase.from('journal_entry_lines').insert(linesData);
      return entry.entryNumber;
    } catch (e) {
      debugPrint("Error updating entry: $e");
      rethrow;
    }
  }

  Future<JournalEntryModel?> getJournalEntryByNumber(String entryNumber) async {
    try {
      final header = await _supabase.from('journal_entries').select().eq('entry_number', entryNumber).single();
      final linesRaw = await _supabase.from('journal_entry_lines')
          .select('*, accounts(name_ar), cost_centers(name)')
          .eq('journal_entry_id', header['id']).order('id', ascending: true);
      return JournalEntryModel.fromMap({...header, 'journal_entry_lines': linesRaw});
    } catch (e) {
      debugPrint("Error fetching entry details: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getJournalEntriesSummary({
    String? accountId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _supabase.from('journal_entries').select('''
        *,
        journal_entry_lines (
          debit,
          credit,
          account_id,
          accounts ( name_ar )
        )
      ''');

      if (fromDate != null) query = query.gte('entry_date', fromDate.toIso8601String());
      if (toDate != null) query = query.lte('entry_date', toDate.toIso8601String());

      if (accountId != null) {
        query = _supabase.from('journal_entries').select('''
          *,
          journal_entry_lines!inner (
            debit,
            credit,
            account_id,
            accounts ( name_ar )
          )
        ''').eq('journal_entry_lines.account_id', accountId);
        
        if (fromDate != null) query = query.gte('entry_date', fromDate.toIso8601String());
        if (toDate != null) query = query.lte('entry_date', toDate.toIso8601String());
      }

      final response = await query.order('id', ascending: false);

      return (response as List).map((entry) {
        final lines = entry['journal_entry_lines'] as List;
        double totalDebit = lines.fold(0.0, (sum, line) => sum + (line['debit'] ?? 0.0));
        double totalCredit = lines.fold(0.0, (sum, line) => sum + (line['credit'] ?? 0.0));
        String allAccountNames = lines.map((l) => l['accounts'] != null ? l['accounts']['name_ar'].toString() : '').join(' ');

        return {
          'id': entry['entry_number'],
          'date': entry['entry_date'],
          'description': entry['description'],
          'debit': totalDebit,
          'credit': totalCredit,
          'status': entry['status'],
          'ref_number': entry['reference'],
          'search_text': allAccountNames,
        };
      }).toList();
    } catch (e) {
      debugPrint("Error fetching entries summary: $e");
      rethrow;
    }
  }

  // ==========================================
  // 6. مراكز التكلفة (Cost Centers)
  // ==========================================
  Future<List<CostCenterModel>> getAllCostCenters() async {
    try {
      final response = await _supabase.from('cost_centers').select().order('code', ascending: true);
      return (response as List).map((e) => CostCenterModel.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint("Error fetching cost centers: $e");
      rethrow;
    }
  }

  // ==========================================
  // 7. نظام السندات الذكي (Vouchers Engine)
  // ==========================================
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
      final lastVoucher = await _supabase.from('vouchers').select('voucher_number').eq('type', type).order('id', ascending: false).limit(1);
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
      final jeIdResponse = await _supabase.from('journal_entries').select('id').eq('entry_number', journalEntryNo).single();
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
        'created_by': _supabase.auth.currentUser?.id,
      };

      final voucherResponse = await _supabase.from('vouchers').insert(voucherData).select('id').single();
      
      final voucherLinesData = lines.map((l) => {
        'voucher_id': voucherResponse['id'],
        'account_id': l['account_id'],
        'amount': l['amount'],
        'cost_center_id': l['cost_center_id'],
        'description': l['description']
      }).toList();

      await _supabase.from('voucher_lines').insert(voucherLinesData);

    } catch (e) {
      debugPrint("Error creating voucher: $e");
      rethrow;
    }
  }

  // ==========================================
  // 8. إدارة البنوك (Banks Management)
  // ==========================================
  Future<List<Map<String, dynamic>>> getBanks() async {
    try {
      final response = await _supabase.from('banks').select().order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetching banks: $e");
      return [];
    }
  }

  Future<void> addBank(String name) async {
    try {
      await _supabase.from('banks').insert({'name': name});
    } catch (e) {
      debugPrint("Error adding bank: $e");
      rethrow;
    }
  }

  Future<void> deleteBank(int id) async {
    try {
      await _supabase.from('banks').delete().eq('id', id);
    } catch (e) {
      debugPrint("Error deleting bank: $e");
      rethrow;
    }
  }

  // ==========================================
  // 9. تقارير السندات والشيكات
  // ==========================================
  Future<List<Map<String, dynamic>>> getVouchers({
    required String type, 
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _supabase.from('vouchers')
          .select('*, banks(name)')
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

  Future<List<Map<String, dynamic>>> getChecks({
    String? type, 
    String? status,
  }) async {
    try {
      var query = _supabase.from('vouchers')
          .select('*, banks(name)')
          .eq('payment_method', 'check');

      if (type != null) query = query.eq('type', type);
      if (status != null) query = query.eq('check_status', status);

      final response = await query.order('check_due_date', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetching checks: $e");
      return [];
    }
  }

  Future<void> updateCheckStatus(int voucherId, String newStatus) async {
    try {
      await _supabase.from('vouchers').update({
        'check_status': newStatus,
        'check_collected_date': newStatus == 'collected' ? DateTime.now().toIso8601String() : null
      }).eq('id', voucherId);
    } catch (e) {
      debugPrint("Error updating check status: $e");
      rethrow;
    }
  }

  // ==========================================
  // 10. نظام التعريفات العامة (General Definitions)
  // ==========================================
  Future<List<DefinitionModel>> getDefinitions(String type, {int? parentId}) async {
    try {
      var query = _supabase
          .from('system_definitions')
          .select()
          .eq('type', type)
          .eq('is_active', true);

      if (parentId != null) {
        query = query.eq('parent_id', parentId);
      }

      final response = await query.order('name_ar', ascending: true);
      return (response as List).map((e) => DefinitionModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint("Error fetching definitions ($type): $e");
      return [];
    }
  }

  // ✅ تم التعديل: إزالة ID قبل الإرسال لضمان نجاح الـ Insert
  Future<void> addDefinition(DefinitionModel definition) async {
    try {
      final data = definition.toMap();
      data.remove('id'); // إزالة الـ ID حتى يقوم السيرفر بتوليده
      await _supabase.from('system_definitions').insert(data);
    } catch (e) {
      debugPrint("Error adding definition: $e");
      rethrow;
    }
  }

  // ✅ تم الإضافة: دالة التعديل
  Future<void> updateDefinition(DefinitionModel definition) async {
    try {
      final data = definition.toMap();
      // التعديل يعتمد على ID
      await _supabase.from('system_definitions').update(data).eq('id', definition.id);
    } catch (e) {
      debugPrint("Error updating definition: $e");
      rethrow;
    }
  }

  Future<void> deleteDefinition(int id) async {
    try {
      await _supabase.from('system_definitions').delete().eq('id', id);
    } catch (e) {
      debugPrint("Error deleting definition: $e");
      rethrow;
    }
  }

  // ==========================================
  // 11. إدارة أنواع القوائم (Dynamic Lists Config)
  // ==========================================
  Future<List<Map<String, dynamic>>> getDefinitionTypes() async {
    try {
      final response = await _supabase.from('definition_types').select().order('name_ar');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetching definition types: $e");
      return [];
    }
  }

  Future<void> createDefinitionType({
    required String code,
    required String nameAr,
    required Map<String, bool> config,
  }) async {
    try {
      // 1. إنشاء القائمة
      await _supabase.from('definition_types').insert({
        'code': code,
        'name_ar': nameAr,
        'field_config': config,
      });

      // 2. إنشاء الصلاحيات التلقائية
      await _supabase.from('permissions_def').insert({
        'code': 'def.view.$code',
        'description': 'عرض قائمة $nameAr',
        'module': 'definitions'
      });
      await _supabase.from('permissions_def').insert({
        'code': 'def.create.$code',
        'description': 'إضافة عناصر في $nameAr',
        'module': 'definitions'
      });

    } catch (e) {
      debugPrint("Error creating definition type: $e");
      rethrow;
    }
  }

  Future<void> updateDefinitionType({
    required String code,
    required String nameAr,
    required Map<String, bool> config,
  }) async {
    try {
      await _supabase.from('definition_types').update({
        'name_ar': nameAr,
        'field_config': config,
      }).eq('code', code);
    } catch (e) {
      debugPrint("Error updating definition type: $e");
      rethrow;
    }
  }

  Future<void> deleteDefinitionType(String code) async {
    try {
      // حذف البيانات
      await _supabase.from('system_definitions').delete().eq('type', code);
      // حذف النوع
      await _supabase.from('definition_types').delete().eq('code', code);
      // تنظيف الصلاحيات
      await _supabase.from('permissions_def').delete().like('code', 'def.%.$code');
    } catch (e) {
      debugPrint("Error deleting definition type: $e");
      rethrow;
    }
  }
}