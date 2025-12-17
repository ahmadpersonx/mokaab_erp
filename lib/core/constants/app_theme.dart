// [كود رقم 11 - النسخة المتوافقة] - lib/core/constants/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // 1. تعريف الألوان المستخرجة من اللوجو
  static const Color kDarkBrown = Color(0xFF4A3F35); // البني الغامق
  static const Color kLightBeige = Color(0xFFD2B48C); // البيج/الذهبي الفاتح
  static const Color kOffWhite = Color(0xFFF8F5F0);   // أبيض كريمي فاتح

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // 2. إعداد مخطط الألوان الرئيسي
      colorScheme: ColorScheme.fromSeed(
        seedColor: kDarkBrown,
        primary: kDarkBrown,       
        onPrimary: kLightBeige,    
        secondary: kLightBeige,    
        onSecondary: kDarkBrown,   
        surface: kOffWhite,        
        onSurface: kDarkBrown,     
        background: kOffWhite,     
      ),

      // خلفية التطبيق
      scaffoldBackgroundColor: kOffWhite,

      // الخطوط
      fontFamily: 'Segoe UI',

      // 3. تصميم الشريط العلوي (AppBar)
      appBarTheme: const AppBarTheme(
        backgroundColor: kDarkBrown,
        foregroundColor: kLightBeige,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: kLightBeige,
        ),
      ),

      // 4. تصميم الأزرار الرئيسية
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kDarkBrown,
          foregroundColor: kLightBeige,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 3,
        ),
      ),

      // 5. تصميم الزر العائم
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kLightBeige,
        foregroundColor: kDarkBrown,
        elevation: 4,
      ),

      // 6. تصميم حقول الإدخال
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: kLightBeige.withOpacity(0.7), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kDarkBrown, width: 2),
        ),
        labelStyle: TextStyle(color: kDarkBrown.withOpacity(0.8)),
        hintStyle: TextStyle(color: kDarkBrown.withOpacity(0.5)),
        prefixIconColor: kDarkBrown,
        suffixIconColor: kDarkBrown,
      ),

      // 7. تصميم القوائم (ListTile)
      listTileTheme: ListTileThemeData(
        tileColor: Colors.white,
        textColor: kDarkBrown,
        iconColor: kLightBeige,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: kOffWhite, width: 1),
        ),
        selectedColor: kLightBeige,
        selectedTileColor: kDarkBrown.withOpacity(0.1),
      ),
      
      // 8. البطاقات (تم التعديل ليتوافق مع نسختك)
      cardTheme: CardThemeData( // <-- لاحظ الإضافة هنا Data
        color: Colors.white,
        surfaceTintColor: Colors.white, 
        elevation: 2,
        shadowColor: kDarkBrown.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      ),

      // 9. النوافذ المنبثقة (تم التعديل ليتوافق مع نسختك)
      dialogTheme: DialogThemeData( // <-- لاحظ الإضافة هنا Data
        backgroundColor: kOffWhite,
        surfaceTintColor: kOffWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          color: kDarkBrown,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: kDarkBrown,
          fontSize: 16,
        ),
      ),
      
      // تصميم القوائم المنسدلة
      popupMenuTheme: PopupMenuThemeData(
        color: kOffWhite,
        surfaceTintColor: kOffWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(color: kDarkBrown),
      ),
    );
  }
}