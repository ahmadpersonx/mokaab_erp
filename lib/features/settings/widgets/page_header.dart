// File: lib/features/settings/widgets/page_header.dart
// Description: Reusable header widget with gradient background and search field.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Function(String) onSearch;
  final VoidCallback onBack;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onSearch,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    // الألوان الثابتة للهيدر
    const primaryColor = Color(0xFF5D4037);
    const secondaryColor = Color(0xFF8D6E63);

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          
          // العناوين
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // مربع البحث
          Container(
            width: 220,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              onChanged: onSearch,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "بحث...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                border: InputBorder.none,
                prefixIcon: Icon(LucideIcons.search, color: Colors.white.withOpacity(0.7), size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          )
        ],
      ),
    );
  }
}