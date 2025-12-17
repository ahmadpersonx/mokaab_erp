// ملف الإقلاع: lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/supabase_service.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/finance/journal_entries_screen.dart';

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
      // تحويل اتجاه التطبيق ليدعم العربية بشكل صحيح
      locale: const Locale('ar', 'AE'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      theme: ThemeData(
        fontFamily: 'Cairo', // تأكد من إضافة الخط في pubspec.yaml أو سيستخدم الافتراضي
        primarySwatch: Colors.brown,
        useMaterial3: true,
      ),
      // منطق فحص الجلسة (Session Check)
      home: Supabase.instance.client.auth.currentSession == null 
          ? const LoginScreen() 
          : const HomeScreen(), 
      
      // تعريف المسارات (Routes) لتسهيل التنقل
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/journal_entries': (context) => const JournalEntriesScreen(),
      },
    );
  }
}