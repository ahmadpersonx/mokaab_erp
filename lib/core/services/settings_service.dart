import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class SettingsService {
  final SupabaseClient _supabase = SupabaseService.client;
  final String _tableName = 'system_settings';

  // ✅ تحويل الخدمة إلى Singleton
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // ذاكرة تخزين مؤقت بسيطة لتقليل الطلبات على قاعدة البيانات
  final Map<String, String> _cache = {};

  /// جلب قيمة إعداد معين مع قيمة افتراضية
  Future<String> get(String key, {required String defaultValue, bool forceRefresh = false}) async {
    if (!forceRefresh && _cache.containsKey(key)) {
      return _cache[key]!;
    }

    try {
      final response = await _supabase
          .from(_tableName)
          .select('value')
          .eq('key', key)
          .single();
      
      final value = response['value'] as String;
      _cache[key] = value;
      return value;
    } catch (e) {
      // إذا كان الخطأ بسبب عدم وجود الجدول (PGRST205)، نرجع القيمة الافتراضية فوراً
      if (e.toString().contains('PGRST205')) {
        return defaultValue;
      }

      // إذا لم يتم العثور على المفتاح، قم بإنشائه بالقيمة الافتراضية
      try {
        await set(key, defaultValue);
      } catch (_) {} // تجاهل أخطاء الكتابة (مثل مشاكل الصلاحيات)
      _cache[key] = defaultValue;
      return defaultValue;
    }
  }

  /// حفظ أو تحديث قيمة إعداد معين
  Future<void> set(String key, String value) async {
    await _supabase.from(_tableName).upsert({'key': key, 'value': value});
    _cache[key] = value; // تحديث الذاكرة المؤقتة
  }

  /// مسح الذاكرة المؤقتة
  void clearCache() {
    _cache.clear();
  }
}