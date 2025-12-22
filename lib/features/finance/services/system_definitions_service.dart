// FileName: lib/features/finance/services/system_definitions_service.dart
// Revision: 2.0 (Fixed Type Error: config now accepts dynamic values for icons)
// Date: 2025-12-19

import 'package:flutter/foundation.dart';
// تأكد من صحة مسار المودل حسب هيكلة ملفاتك
import '../../../core/models/definition_model.dart'; 
import 'finance_base.dart';

mixin SystemDefinitionsService on FinanceBase {
  // ==========================================
  // 10. نظام التعريفات العامة (General Definitions)
  // ==========================================
  Future<List<DefinitionModel>> getDefinitions(String definitionType, {int? parentId}) async {
    try {
      var query = supabase
          .from('system_definitions')
          .select()
          .eq('type', definitionType)
          .eq('is_active', true);

      if (parentId != null) {
        query = query.eq('parent_id', parentId);
      }

      final response = await query.order('name_ar', ascending: true);
      return (response as List).map((e) => DefinitionModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error fetching definitions ($definitionType): $e");
      return [];
    }
  }

  Future<void> addDefinition(DefinitionModel definition) async {
    try {
      final data = definition.toJson();
      await supabase.from('system_definitions').insert(data);
    } catch (e) {
      debugPrint("Error adding definition: $e");
      rethrow;
    }
  }

  Future<void> updateDefinition(DefinitionModel definition) async {
    try {
      final data = definition.toJson();
      await supabase.from('system_definitions').update(data).eq('id', definition.id);
    } catch (e) {
      debugPrint("Error updating definition: $e");
      rethrow;
    }
  }

  Future<void> deleteDefinition(int id) async {
    try {
      await supabase.from('system_definitions').delete().eq('id', id);
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
      final response = await supabase.from('definition_types').select().order('name_ar');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetching definition types: $e");
      return [];
    }
  }

  Future<void> createDefinitionType({
    required String code,
    required String nameAr,
    // ✅ تم التعديل: dynamic بدلاً من bool
    required Map<String, dynamic> config,
  }) async {
    try {
      // 1. إنشاء القائمة
      await supabase.from('definition_types').insert({
        'code': code,
        'name_ar': nameAr,
        'field_config': config,
      });

      // 2. إنشاء الصلاحيات التلقائية
      // (إذا فشلت هذه الخطوة بسبب RLS، سيظهر الخطأ لكن القائمة ستكون قد أنشئت)
      await supabase.from('permissions_def').insert({
        'code': 'def.view.$code',
        'description': 'عرض قائمة $nameAr',
        'module': 'definitions'
      });
      await supabase.from('permissions_def').insert({
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
    // ✅ تم التعديل: dynamic بدلاً من bool
    required Map<String, dynamic> config,
  }) async {
    try {
      await supabase.from('definition_types').update({
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
      await supabase.from('system_definitions').delete().eq('type', code);
      // حذف النوع
      await supabase.from('definition_types').delete().eq('code', code);
      // تنظيف الصلاحيات
      await supabase.from('permissions_def').delete().like('code', 'def.%.$code');
    } catch (e) {
      debugPrint("Error deleting definition type: $e");
      rethrow;
    }
  }
}