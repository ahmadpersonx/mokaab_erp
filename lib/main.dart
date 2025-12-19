// FileName: lib/main.dart
// Revision: 1.1 (Updated routes after finance restructuring)
// Date: 2025-12-19

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/supabase_service.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';

// ✅ تحديث الاستيراد ليشير إلى الملف الجديد المدمج والموقع الصحيح
import 'features/finance/screens/daily_journal_screen.dart'; 

void main() async {
  // التأكد من تهيئة أجزاء Flutter قبل البدء
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة اتصال Supabase باستخدام المفاتيح الحقيقية من ملف السيرفس
  await Supabase.initialize(
    url: SupabaseService.supabaseUrl,
    anonKey: SupabaseService.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مكعب ERP',
      // دعم اللغة العربية والاتجاه من اليمين لليسار بشكل أساسي
      locale: const Locale('ar', 'JO'), // تم تغيير AE إلى JO (الأردن) بناءً على منطقة العمل
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      theme: ThemeData(
        fontFamily: 'Cairo', 
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      // منطق فحص الجلسة (Session Check) للدخول التلقائي
      home: Supabase.instance.client.auth.currentSession == null 
          ? const LoginScreen() 
          : const HomeScreen(), 
      
      // ✅ تحديث المسارات (Routes) لتطابق الهيكلية الجديدة
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        // تم تغيير journal_entries لتفتح الشاشة الجديدة المدمجة
        '/journal_entries': (context) => const DailyJournalScreen(), 
      },
    );
  }
}