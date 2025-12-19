// [كود رقم 15 - الصحيح] - cost_center_service.dart
// لتوليد الأرقام العشوائية
import 'package:flutter/foundation.dart'; // لعمل debugPrint
import '../../../core/services/supabase_service.dart';
import '../models/cost_center_model.dart';


class CostCenterService {
  
  // دالة لجلب المراكز بناءً على كود الأب
  Future<List<CostCenterModel>> getCostCentersByParent(String? parentCode) async {
    try {
      // ✅ التصحيح: استخدام SupabaseService.client.from
      var query = SupabaseService.client.from('cost_centers').select();

      if (parentCode == null) {
        // الفلتر الصحيح للقيم الفارغة (الجذور)
        query = query.filter('parent_code', 'is', null);
      } else {
        // جلب الأبناء
        query = query.eq('parent_code', parentCode);
      }

      // الترتيب
      final response = await query.order('code', ascending: true);

      List<CostCenterModel> centers = [];
      for (var item in response) {
        centers.add(CostCenterModel.fromMap(item));
      }
      return centers;
    } catch (e) {
      debugPrint('Error fetching cost centers: $e');
      rethrow;
    }
  }

  // فحص وجود أبناء
  Future<bool> hasChildren(String code) async {
    // ✅ التصحيح: استخدام SupabaseService.client.from
    final response = await SupabaseService.client
        .from('cost_centers')
        .select('id')
        .eq('parent_code', code)
        .limit(1);
    return (response as List).isNotEmpty;
  }

  // إضافة
  Future<void> addCostCenter(CostCenterModel cc) async {
    try {
      var data = cc.toMap();
      data.remove('id'); 
      // ✅ التصحيح: استخدام SupabaseService.client.from
      await SupabaseService.client.from('cost_centers').insert(data);
    } catch (e) {
      debugPrint('Error adding cost center: $e');
      rethrow;
    }
  }

  // تعديل
  Future<void> updateCostCenter(int id, String name, String code) async {
    try {
      // ✅ التصحيح: استخدام SupabaseService.client.from
      await SupabaseService.client
          .from('cost_centers')
          .update({'name': name})
          .eq('id', id);
    } catch (e) {
      debugPrint('Error updating cost center: $e');
      rethrow;
    }
  }

  // حذف
  Future<void> deleteCostCenter(int id) async {
    try {
      // ✅ التصحيح: استخدام SupabaseService.client.from
      await SupabaseService.client.from('cost_centers').delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting cost center: $e');
      rethrow;
    }
  }
}