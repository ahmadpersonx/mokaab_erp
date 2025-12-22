//finance_base.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart'; // ✅ هنا خطوتين فقط لأن الملف لم يدخل مجلد services
class FinanceBase {
  final SupabaseClient supabase = SupabaseService.client;
}