// FileName: lib/main.dart
// Revision: 1.3 (Added Localization Delegates & Unified App Theme)
// Date: 2025-12-20

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ضروري جداً للتقويم العربي
import 'package:supabase_flutter/supabase_flutter.dart';

// Services & Constants
import 'core/services/supabase_service.dart';

// Features
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';

void main() async {
  // التأكد من تهيئة أجزاء Flutter قبل البدء
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة اتصال Supabase
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
      
      // --- 1. إعدادات اللغة (Localization) ---
      // هذا الجزء ضروري لعمل DatePicker والقوائم باللغة العربية
      locale: const Locale('ar', 'JO'),
      supportedLocales: const [
        Locale('ar', 'JO'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // --- 2. الثيم العام (Global Theme) ---
      theme: ThemeData(
        fontFamily: 'Cairo', // الخط الموحد
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5D4037), // اللون البني الأساسي (kDarkBrown)
          primary: const Color(0xFF5D4037),
          secondary: const Color(0xFF8D6E63),
          surface: const Color(0xFFF5F5FA), // لون الخلفية الرمادي الفاتح المعتمد
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5FA),
        
        // توحيد شكل الـ AppBar في حال استخدامه بدون الهيدر المخصص
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF5D4037),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
      ),

      // --- 3. التوجيه (Routing) ---
      // فحص الجلسة لتحديد شاشة البداية
      home: Supabase.instance.client.auth.currentSession == null 
          ? const LoginScreen() 
          : const HomeScreen(), 
      
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}