// FileName: lib/core/widgets/finance/finance_list_item.dart
// Purpose: Generic, reusable list item widget for all finance items
// Features: Checkbox, header, amounts, status badge, actions
// Used in: Vouchers, Invoices, Transactions, etc.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/app_theme.dart';

typedef ItemActionCallback = void Function(String itemId);

class FinanceListItem extends StatelessWidget {
  final String itemId;
  final String itemNumber;
  final String itemDate;
  final String accountName;
  final double amount;
  final String amountLabel;
  final Color amountColor;
  final String? statusLabel;
  final Color? statusColor;
  final String? paymentMethod;
  final String? description;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectedChanged;
  final ItemActionCallback? onEditPressed;
  final ItemActionCallback? onPrintPressed;
  final ItemActionCallback? onDeletePressed;
  final EdgeInsetsGeometry? padding;

  const FinanceListItem({
    super.key,
    required this.itemId,
    required this.itemNumber,
    required this.itemDate,
    required this.accountName,
    required this.amount,
    required this.amountLabel,
    required this.amountColor,
    this.statusLabel,
    this.statusColor,
    this.paymentMethod,
    this.description,
    this.isSelected = false,
    this.onSelectedChanged,
    this.onEditPressed,
    this.onPrintPressed,
    this.onDeletePressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  String _formatAmount(double value) {
    return value.toStringAsFixed(3).replaceAll(',', '');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: padding as EdgeInsets,
      decoration: BoxDecoration(
        color: AppTheme.kWhite,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        spacing: 10,
        children: [
          // Header row: Checkbox, number badge, date, status
          Row(
            spacing: 8,
            children: [
              // Checkbox
              if (onSelectedChanged != null)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: onSelectedChanged,
                    side: const BorderSide(color: AppTheme.kDarkBrown),
                    activeColor: AppTheme.kDarkBrown,
                  ),
                ),

              // Number badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.kLightBeige,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  itemNumber,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.kDarkBrown,
                  ),
                ),
              ),

              // Date and account
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      itemDate,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      accountName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Status badge
              if (statusLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (statusColor ?? AppTheme.kInfo).withOpacity(0.1),
                    border: Border.all(color: statusColor ?? AppTheme.kInfo),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontSize: 11,
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
                  '${_formatAmount(amount)} د.أ',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Actions
              Row(
                spacing: 4,
                children: [
                  if (onEditPressed != null)
                    InkWell(
                      onTap: () => onEditPressed!(itemId),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          LucideIcons.edit,
                          size: 16,
                          color: AppTheme.kDarkBrown,
                        ),
                      ),
                    ),
                  if (onPrintPressed != null)
                    InkWell(
                      onTap: () => onPrintPressed!(itemId),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          LucideIcons.printer,
                          size: 16,
                          color: AppTheme.kDarkBrown,
                        ),
                      ),
                    ),
                  if (onDeletePressed != null)
                    InkWell(
                      onTap: () => onDeletePressed!(itemId),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          LucideIcons.trash2,
                          size: 16,
                          color: AppTheme.kError,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Payment method and description
          if (paymentMethod != null || description != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.kOffWhite,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                spacing: 8,
                children: [
                  if (paymentMethod != null)
                    Row(
                      spacing: 4,
                      children: [
                        const Icon(
                          LucideIcons.creditCard,
                          size: 14,
                          color: Colors.grey,
                        ),
                        Text(
                          paymentMethod!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  if (description != null && description!.isNotEmpty)
                    Expanded(
                      child: Text(
                        description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
