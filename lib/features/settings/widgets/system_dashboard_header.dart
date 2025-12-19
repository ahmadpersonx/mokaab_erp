// File: lib/features/settings/widgets/system_dashboard_header.dart
// Description: Updated to include a Back Button for consistent navigation.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_theme.dart';

class SystemDashboardHeader extends StatelessWidget {
  final VoidCallback? onBack; // إضافة دالة الرجوع كخيار

  const SystemDashboardHeader({
    super.key,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.kDarkBrown,
          image: const DecorationImage(
            image: AssetImage('assets/images/pattern.jpg'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // --- زر الرجوع (جديد) ---
            InkWell(
              onTap: onBack ?? () => Navigator.maybePop(context), // الرجوع الافتراضي
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 16),

            // الأيقونة الكبيرة
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(LucideIcons.settings, color: AppTheme.kLightBeige, size: 32),
            ),
            const SizedBox(width: 16),
            
            // النصوص
            Expanded( // استخدام Expanded لتجنب مشاكل المساحة مع الزر الجديد
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "التحكم في النظام",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Segoe UI',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "لوحة التحكم الرئيسية لإعدادات النظام والصلاحيات",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}