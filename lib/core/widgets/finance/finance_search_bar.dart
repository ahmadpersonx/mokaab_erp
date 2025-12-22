// FileName: lib/core/widgets/finance/finance_search_bar.dart
// Purpose: Unified search bar for all finance list screens
// Used in: Vouchers, Invoices, Transactions

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/app_theme.dart';

/// Unified search bar widget for all finance screens
/// Supports 3 search fields: number, description, amount
class FinanceSearchBar extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAdvancedFiltersTap;
  final bool showAdvancedFiltersButton;

  const FinanceSearchBar({
    super.key,
    required this.onSearchChanged,
    required this.onAdvancedFiltersTap,
    this.showAdvancedFiltersButton = true,
  });

  @override
  State<FinanceSearchBar> createState() => _FinanceSearchBarState();
}

class _FinanceSearchBarState extends State<FinanceSearchBar> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppTheme.kWhite,
      child: Row(
        children: [
          // Search field
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث برقم، بيان، مبلغ...',
                prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
                filled: true,
                fillColor: AppTheme.kOffWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppTheme.kBorder, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: AppTheme.kDarkBrown,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                isDense: true,
              ),
              onChanged: (value) {
                widget.onSearchChanged(value);
              },
            ),
          ),

          // Advanced filters button
          if (widget.showAdvancedFiltersButton) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(LucideIcons.filter, color: AppTheme.kDarkBrown),
              onPressed: widget.onAdvancedFiltersTap,
              tooltip: 'فلاتر متقدمة',
            ),
          ],
        ],
      ),
    );
  }
}
