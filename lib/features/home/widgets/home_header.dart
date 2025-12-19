// File: lib/features/home/widgets/home_header.dart
// Description: Custom header for Home Screen with Logo and User Info.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_theme.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final String userRole;
  final VoidCallback onLogout;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.userRole,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
        decoration: BoxDecoration(
          color: AppTheme.kDarkBrown,
          // إضافة نقش خفيف في الخلفية لجمالية أكثر
          image: const DecorationImage(
            image: AssetImage('assets/images/pattern.jpg'), // تأكد من وجود صورة نقش خفيفة أو احذف هذا السطر
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
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
        child: Column(
          children: [
            // --- الصف العلوي: الشعار وزر الخروج ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // زر الخروج
                InkWell(
                  onTap: onLogout,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Icon(LucideIcons.logOut, color: Colors.white, size: 22),
                  ),
                ),

                // الشعار (Logo)
                Container(
                  height: 50, // ارتفاع مناسب للشعار
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9), // خلفية بيضاء خفيفة لإبراز الشعار
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),

            // --- معلومات المستخدم والترحيب ---
            Row(
              children: [
                // الصورة الرمزية (Avatar)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(LucideIcons.user, size: 28, color: AppTheme.kDarkBrown),
                  ),
                ),
                const SizedBox(width: 16),
                
                // النصوص
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "مرحباً بك، $userName",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cairo', // أو الخط المعتمد لديك
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.kLightBeige.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.kLightBeige.withOpacity(0.5)),
                      ),
                      child: Text(
                        userRole,
                        style: const TextStyle(
                          color: AppTheme.kLightBeige,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}