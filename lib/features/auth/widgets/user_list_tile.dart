// File: lib/features/auth/widgets/user_list_tile.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class UserListTile extends StatelessWidget {
  final String name;
  final String email;
  final String? phone;
  final VoidCallback onTap;

  const UserListTile({
    super.key,
    required this.name,
    required this.email,
    this.phone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // 1. السهم (على اليسار في RTL)
                Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.grey.shade400),
                
                const Spacer(), // مسافة مرنة لدفع المحتوى لليمين

                // 2. النصوص (الاسم والايميل)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$email ${phone != null ? '• $phone' : ''}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 16),

                // 3. الصورة الرمزية (Avatar)
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.brown.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.brown.shade100),
                  ),
                  child: Icon(LucideIcons.user, color: Colors.brown.shade400, size: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}