//1. تصحيح ملف lib/core/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // تأكد من كتابة القيم الخاصة بك هنا
  static const String supabaseUrl = 'https://eolgkpyuemovyhworcxd.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVvbGdrcHl1ZW1vdnlod29yY3hkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU4OTkxMDIsImV4cCI6MjA4MTQ3NTEwMn0.G718ZzO6yqFn-JFLlr1RnwBa5iqSerSpqaspU-B-ljM';

  static SupabaseClient get client => Supabase.instance.client;

  // دالة تهيئة اختيارية إذا كنت تفضل استخدامها
  static Future<void> init() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}