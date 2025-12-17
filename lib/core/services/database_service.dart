import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // الوصول للعميل (Client) الذي تم تهيئته في main.dart
  static final SupabaseClient client = Supabase.instance.client;

  // دالة مساعدة للحصول على جدول معين
  static SupabaseQueryBuilder from(String table) {
    return client.from(table);
  }
}