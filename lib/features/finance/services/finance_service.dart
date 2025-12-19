// FileName: lib/features/finance/services/finance_service.dart
// Revision: 1.2 (Updated Imports after restructuring)
// Date: 2025-12-19

import 'finance_base.dart';
import 'finance_auth_service.dart';
import 'system_definitions_service.dart';
import 'finance_core_service.dart';

/// الكلاس الرئيسي لإدارة خدمات المالية والمحاسبة.
/// [FinanceBase]: يحتوي على عميل السوبابيز الأساسي.
/// [FinanceAuthService]: مسؤول عن التحقق من الصلاحيات والمستخدمين.
/// [SystemDefinitionsService]: مسؤول عن جلب القوائم العامة (التعريفات).
/// [FinanceCoreService]: مسؤول عن العمليات الجوهرية (سندات، قيود، بنوك).
class FinanceService extends FinanceBase 
    with FinanceAuthService, SystemDefinitionsService, FinanceCoreService {
  
  // ملاحظة للمبرمج: لا تضع أي كود هنا مباشرة.
  // إذا أردت إضافة وظيفة جديدة، أضفها في Mixin المناسب أو أنشئ Mixin جديد.

  // سيقوم هذا الكلاس تلقائياً بجمع كافة الدوال مثل:
  // getBanks(), getVouchers(), addDefinition(), etc.
}