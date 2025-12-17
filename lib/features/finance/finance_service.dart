//الملف الأساسي: lib/features/finance/finance_service.dartimport 'package:flutter/material.dart';import 'package:flutter/foundation.dart'; // ضروري لعمل debugPrint
import 'package:flutter/foundation.dart'; // ✅ هذا السطر ضروري جداً لحل مشكلة debugPrint
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/models/account_model.dart';
import '../../core/models/journal_entry_model.dart';
import '../../core/models/cost_center_model.dart';

class FinanceService {
  final SupabaseClient _supabase = SupabaseService.client;

  // ==========================================
  // 1. المصادقة (Auth) والصلاحيات
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
  // 2. شجرة الحسابات (Accounts)
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
  // 3. القيود اليومية (Journal Entries)
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

  Future<List<Map<String, dynamic>>> getJournalEntriesSummary({String? entryNumber, String? reference, String? status, DateTime? fromDate, DateTime? toDate}) async {
    try {
      final response = await _supabase.rpc('get_journal_summary', params: {
        'p_entry_number': entryNumber, 'p_reference': reference, 'p_status': status,
        'p_from_date': fromDate?.toIso8601String(), 'p_to_date': toDate?.toIso8601String(),
      });
      return (response as List).map((entry) => {
        'id': entry['entry_number'], 'date': entry['entry_date'], 'description': entry['description'],
        'debit': (entry['total_debit'] as num).toDouble(), 'credit': (entry['total_credit'] as num).toDouble(),
        'status': entry['status'], 'ref_number': entry['reference'],
      }).toList();
    } catch (e) {
      debugPrint("Error fetching summary: $e");
      rethrow;
    }
  }

// جلب كافة المستخدمين من جدول البروفايلات
Future<List<Map<String, dynamic>>> getAllUsers() async {
  try {
    final response = await _supabase
        .from('profiles')
        .select()
        .order('full_name', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    debugPrint("Error fetching users: $e");
    rethrow;
  }
}

// تحديث صلاحية مستخدم معين
Future<void> updateUserRole(String userId, String newRole) async {
  try {
    await _supabase
        .from('profiles')
        .update({'role': newRole})
        .eq('id', userId);
  } catch (e) {
    debugPrint("Error updating role: $e");
    rethrow;
  }
}

  // ==========================================
  // 4. مراكز التكلفة (Cost Centers)
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
}