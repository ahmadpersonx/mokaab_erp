// File: lib/features/finance/widgets/finance_dashboard_header.dart
// Description: A curved header with pattern, matching Home Screen style but for Finance context.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_theme.dart';

class FinanceDashboardHeader extends StatelessWidget {
  final VoidCallback onBack;

  const FinanceDashboardHeader({
    super.key, 
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
        decoration: BoxDecoration(
          color: AppTheme.kDarkBrown,
          // إضافة النقش للحفاظ على هوية الشاشة الرئيسية
          image: const DecorationImage(
            image: AssetImage('assets/images/pattern.jpg'), 
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
          // نفس الانحناء الموجود في الشاشة الرئيسية
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // زر الرجوع
            InkWell(
              onTap: onBack,
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
            
            const SizedBox(width: 20),

            // العنوان والأيقونة
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end, // محاذاة لليسار (أو اليمين حسب اللغة)
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "الإدارة المالية",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        "إدارة السندات والعمليات المحاسبية",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  
                  // أيقونة المالية
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(LucideIcons.banknote, color: AppTheme.kLightBeige, size: 28),
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