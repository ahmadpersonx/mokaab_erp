// FileName: lib/core/constants/app_theme.dart
// Revision: 3.0 (Added Dropdown & Popup Logic)
// Date: 2025-12-19

import 'package:flutter/material.dart';

class AppTheme {
  // 1. تعريف الألوان المستخرجة من هوية "مكعب"
  static const Color kDarkBrown = Color(0xFF4A3F35);
  static const Color kLightBeige = Color(0xFFD2B48C);
  static const Color kOffWhite = Color(0xFFF8F5F0);
  static const Color kWhite = Color(0xFFFFFFFF);
  
  static const Color kSuccess = Color(0xFF52C41A);
  static const Color kWarning = Color(0xFFFAAD14);
  static const Color kError = Color(0xFFFF4D4F);
  static const Color kInfo = Color(0xFF1890FF);
  static const Color kBorder = Color(0xFFD9D9D9);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: kDarkBrown,
        primary: kDarkBrown,
        onPrimary: kWhite,
        secondary: kLightBeige,
        onSecondary: kDarkBrown,
        surface: kWhite,
        onSurface: kDarkBrown,
        error: kError,
        background: kOffWhite,
        outline: kBorder,
      ),

      scaffoldBackgroundColor: kOffWhite,
      fontFamily: 'Segoe UI',
      
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: kDarkBrown),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: kDarkBrown),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kDarkBrown),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: kDarkBrown),
        bodySmall: TextStyle(fontSize: 12, color: Colors.black54),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: kDarkBrown,
        foregroundColor: kWhite,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: kWhite,
          fontFamily: 'Segoe UI',
        ),
        iconTheme: IconThemeData(color: kWhite),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kDarkBrown,
          foregroundColor: kWhite,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), // تقليل الارتفاع قليلاً للقوائم
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: kBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: kDarkBrown, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: kError, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: kError, width: 1.5),
        ),
        labelStyle: TextStyle(color: kDarkBrown.withOpacity(0.7)),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      ),

      cardTheme: CardThemeData(
        color: kWhite,
        surfaceTintColor: kWhite,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFF0F0F0), width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),

      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(kOffWhite),
        dataRowColor: WidgetStateProperty.all(kWhite),
        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: kDarkBrown),
        dataTextStyle: const TextStyle(color: kDarkBrown),
        dividerThickness: 0.5,
        horizontalMargin: 16,
        columnSpacing: 24,
      ),

      // --- إعدادات القوائم المنسدلة (Dropdowns & Popups) ---
      
      // إعداد القائمة المنسدلة (M3 DropdownMenu)
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(kWhite),
          surfaceTintColor: WidgetStateProperty.all(kWhite),
          elevation: WidgetStateProperty.all(4),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          // التحكم في الحد الأقصى للارتفاع لضمان عدم تغطية الشاشة بالكامل
          maximumSize: WidgetStateProperty.all(const Size(double.infinity, 300)), 
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kWhite,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),

      // إعداد القوائم المنبثقة العامة (مثل DropdownButton)
      popupMenuTheme: PopupMenuThemeData(
        color: kWhite,
        surfaceTintColor: kWhite,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: kBorder, width: 0.5),
        ),
        textStyle: const TextStyle(color: kDarkBrown),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: kWhite,
        surfaceTintColor: kWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        titleTextStyle: const TextStyle(
          color: kDarkBrown,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kLightBeige,
        foregroundColor: kDarkBrown,
        elevation: 3,
        shape: CircleBorder(), 
      ),
    );
  }
}