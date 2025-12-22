// FileName: lib/core/widgets/finance/finance_filter_panel.dart
// Purpose: Unified filter panel for all finance list screens
// Features: Date range, Account selection, Amount range, Payment method
// Used in: Vouchers, Invoices, Transactions

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/app_theme.dart';

class FinanceFilterPanel extends StatefulWidget {
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final ValueChanged<DateTime?> onFromDateChanged;
  final ValueChanged<DateTime?> onToDateChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onApplyFilters;
  final Widget? additionalFiltersWidget;

  const FinanceFilterPanel({
    super.key,
    this.initialFromDate,
    this.initialToDate,
    required this.onFromDateChanged,
    required this.onToDateChanged,
    required this.onClearFilters,
    required this.onApplyFilters,
    this.additionalFiltersWidget,
  });

  @override
  State<FinanceFilterPanel> createState() => _FinanceFilterPanelState();
}

class _FinanceFilterPanelState extends State<FinanceFilterPanel> {
  late DateTime? _fromDate;
  late DateTime? _toDate;
  final _dateFormat = intl.DateFormat('yyyy-MM-dd', 'ar_JO');

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
  }

  Future<void> _selectDate(bool isFromDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? (_fromDate ?? DateTime.now()) : (_toDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar', 'JO'),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          widget.onFromDateChanged(_fromDate);
        } else {
          _toDate = picked;
          widget.onToDateChanged(_toDate);
        }
      });
    }
  }

  void _clearDates() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      widget.onFromDateChanged(null);
      widget.onToDateChanged(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.kOffWhite,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        spacing: 12,
        children: [
          // Date range section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(
                'نطاق التاريخ',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                spacing: 8,
                children: [
                  // From date
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(true),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.kBorder),
                          borderRadius: BorderRadius.circular(6),
                          color: AppTheme.kWhite,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _fromDate == null
                                  ? 'من التاريخ'
                                  : _dateFormat.format(_fromDate!),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const Icon(LucideIcons.calendar, size: 16, color: AppTheme.kDarkBrown),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // To date
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(false),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.kBorder),
                          borderRadius: BorderRadius.circular(6),
                          color: AppTheme.kWhite,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _toDate == null
                                  ? 'إلى التاريخ'
                                  : _dateFormat.format(_toDate!),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const Icon(LucideIcons.calendar, size: 16, color: AppTheme.kDarkBrown),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Additional filters (for subclasses to add account, amount, etc.)
          if (widget.additionalFiltersWidget != null)
            widget.additionalFiltersWidget!,

          // Action buttons
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _clearDates();
                    widget.onClearFilters();
                  },
                  icon: const Icon(LucideIcons.x, size: 16),
                  label: const Text('مسح'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.kDarkBrown),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onApplyFilters,
                  icon: const Icon(LucideIcons.check, size: 16),
                  label: const Text('تطبيق'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.kDarkBrown,
                    foregroundColor: Colors.white,
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
