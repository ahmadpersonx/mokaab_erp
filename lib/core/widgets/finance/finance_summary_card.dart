// FileName: lib/core/widgets/finance/finance_summary_card.dart
// Purpose: Unified summary card for displaying financial totals
// Features: Dynamic labels, color-coded by type, real-time calculation
// Used in: All finance list screens (Vouchers, Invoices, etc.)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../constants/app_theme.dart';

class FinanceSummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color? backgroundColor;
  final Color? textColor;
  final String currency;
  final bool showIcon;
  final IconData? icon;
  final int itemCount;

  const FinanceSummaryCard({
    super.key,
    required this.label,
    required this.amount,
    this.backgroundColor,
    this.textColor,
    this.currency = 'د.أ',
    this.showIcon = true,
    this.icon,
    this.itemCount = 0,
  });

  String _formatAmount(double value) {
    final formatter = intl.NumberFormat('#,##0.000', 'ar_JO');
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppTheme.kOffWhite;
    final textCol = textColor ?? AppTheme.kDarkBrown;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          // Label row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (itemCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: textCol.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$itemCount بند',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textCol,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          // Amount row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${_formatAmount(amount)} $currency',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: textCol,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Horizontal summary bar showing multiple summaries
class FinanceSummaryBar extends StatelessWidget {
  final List<FinanceSummaryData> items;
  final EdgeInsetsGeometry padding;

  const FinanceSummaryBar({
    super.key,
    required this.items,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: padding,
        child: Row(
          spacing: 12,
          children: items
              .map((item) => SizedBox(
                width: 180,
                child: FinanceSummaryCard(
                  label: item.label,
                  amount: item.amount,
                  backgroundColor: item.backgroundColor,
                  textColor: item.textColor,
                  itemCount: item.itemCount,
                ),
              ))
              .toList(),
        ),
      ),
    );
  }
}

/// Data model for summary items
class FinanceSummaryData {
  final String label;
  final double amount;
  final Color? backgroundColor;
  final Color? textColor;
  final int itemCount;

  FinanceSummaryData({
    required this.label,
    required this.amount,
    this.backgroundColor,
    this.textColor,
    this.itemCount = 0,
  });
}
