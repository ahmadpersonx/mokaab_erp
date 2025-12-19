// File: lib/features/auth/widgets/users_management_header.dart
// Description: Unified curved header for Users Management screen.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_theme.dart';

class UsersManagementHeader extends StatelessWidget {
  final VoidCallback onBack;

  const UsersManagementHeader({
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
          // النقش الخلفي الموحد
          image: const DecorationImage(
            image: AssetImage('assets/images/pattern.jpg'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
          // الحواف المنحنية
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "المستخدمون",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        "إدارة الموظفين والصلاحيات",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  
                  // الأيقونة المعبرة
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(LucideIcons.users, color: AppTheme.kLightBeige, size: 28),
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