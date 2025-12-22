// FileName: lib/core/services/finance_formatter.dart
// Purpose: Centralized formatting service for all financial data
// Ensures consistency across the entire application

import 'package:intl/intl.dart' as intl;

class FinanceFormatter {
  // Singleton instance
  static final FinanceFormatter _instance = FinanceFormatter._internal();

  FinanceFormatter._internal();

  factory FinanceFormatter() {
    return _instance;
  }

  // Locale and formatters
  static const String locale = 'ar_JO';
  static const String currencySymbol = 'د.أ';
  
  // Lazy initialization of formatters to avoid locale data issues
  late final _dateFormatter = intl.DateFormat('yyyy-MM-dd', locale);
  late final _dateTimeFormatter = intl.DateFormat('yyyy-MM-dd HH:mm', locale);
  late final _shortDateFormatter = intl.DateFormat('dd/MM/yyyy', locale);
  late final _numberFormatter = intl.NumberFormat('#,##0.000', locale);
  late final _currencyFormatter = intl.NumberFormat('${currencySymbol} #,##0.000', locale);
  late final _percentageFormatter = intl.NumberFormat('0.00%', locale);

  /// Format amount as currency (د.أ 15,000.000)
  String formatCurrency(double amount) {
    try {
      return _currencyFormatter.format(amount);
    } catch (e) {
      // Fallback if locale data not available
      return '$currencySymbol ${amount.toStringAsFixed(3)}';
    }
  }

  /// Format amount without currency symbol (15,000.000)
  String formatNumber(double amount) {
    try {
      return _numberFormatter.format(amount);
    } catch (e) {
      // Fallback if locale data not available
      return amount.toStringAsFixed(3);
    }
  }

  /// Format date as standard (2025-01-15)
  String formatDate(DateTime date) {
    try {
      return _dateFormatter.format(date);
    } catch (e) {
      // Fallback if locale data not available
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  /// Format date as short (15/01/2025)
  String formatDateShort(DateTime date) {
    try {
      return _shortDateFormatter.format(date);
    } catch (e) {
      // Fallback if locale data not available
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  /// Format date and time (2025-01-15 14:30)
  String formatDateTime(DateTime dateTime) {
    try {
      return _dateTimeFormatter.format(dateTime);
    } catch (e) {
      // Fallback if locale data not available
      return '${formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Format percentage (45.50%)
  String formatPercentage(double value) {
    return _percentageFormatter.format(value);
  }

  /// Parse date from string (2025-01-15)
  DateTime? parseDate(String dateString) {
    try {
      return _dateFormatter.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Get time difference in Arabic
  String getTimeDifference(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'منذ لحظات';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'منذ $weeks أسابيع';
    } else {
      final months = (difference.inDays / 30).floor();
      return 'منذ $months أشهر';
    }
  }

  /// Get month name in Arabic
  String getMonthName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[month - 1];
  }

  /// Get day name in Arabic
  String getDayName(int weekday) {
    const days = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    // weekday: 1 = Monday, 7 = Sunday
    return days[weekday - 1];
  }

  /// Format account balance with color indicator
  String formatAccountBalance(double balance) {
    if (balance > 0) {
      return '+ ${formatCurrency(balance)}';
    } else if (balance < 0) {
      return '- ${formatCurrency(balance.abs())}';
    } else {
      return formatCurrency(0);
    }
  }

  /// Check if amount is debit or credit
  bool isDebit(double amount) => amount > 0;
  bool isCredit(double amount) => amount < 0;

  /// Validate amount (must be positive)
  bool isValidAmount(double? amount) {
    return amount != null && amount > 0;
  }

  /// Validate date (must be in valid range)
  bool isValidDate(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    // Allow dates 5 years back or 1 year forward
    return date.isAfter(now.subtract(const Duration(days: 365 * 5))) &&
        date.isBefore(now.add(const Duration(days: 365)));
  }

  /// Calculate age in days from given date
  int calculateDays(DateTime from, [DateTime? to]) {
    final end = to ?? DateTime.now();
    return end.difference(from).inDays;
  }

  /// Get quarter from month
  int getQuarter(int month) => ((month - 1) ~/ 3) + 1;

  /// Get quarter name
  String getQuarterName(int quarter) {
    const quarters = ['الربع الأول', 'الربع الثاني', 'الربع الثالث', 'الربع الرابع'];
    return quarters[quarter - 1];
  }

  /// Format fiscal year (2025 => 2025/2026)
  String formatFiscalYear(int year) {
    return '$year/${year + 1}';
  }

  /// Check if dates are in same month
  bool isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  /// Check if dates are in same year
  bool isSameYear(DateTime date1, DateTime date2) {
    return date1.year == date2.year;
  }

  /// Get first day of month
  DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get last day of month
  DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Get first day of year
  DateTime getFirstDayOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  /// Get last day of year
  DateTime getLastDayOfYear(DateTime date) {
    return DateTime(date.year, 12, 31);
  }
}

// Global instance for easy access
final financeFormatter = FinanceFormatter();
