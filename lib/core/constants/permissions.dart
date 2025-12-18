// ملف ثوابت الصلاحيات lib/core/constants/permissions.dart
class AppPermissions {
  // الحسابات
  static const String accountsView = 'accounts.view';
  static const String accountsCreate = 'accounts.create';
  static const String accountsEdit = 'accounts.edit';
  static const String accountsDelete = 'accounts.delete';
  static const String accountsExport = 'accounts.export';
  static const String accountsContra = 'accounts.contra'; // ✅ تمت الإضافة (لزر الحساب العكسي)

  // القيود
  static const String entriesView = 'entries.view';     // مشاهدة القيود
  static const String entriesCreate = 'entries.create'; // إنشاء قيد / سند
  static const String entriesEdit = 'entries.edit';
  static const String entriesPost = 'entries.post';     // ترحيل القيود / السندات

  // مراكز التكلفة
  static const String costCentersView = 'cost_centers.view';
  static const String costCentersManage = 'cost_centers.manage';

  // النظام والإدارة
  static const String usersManage = 'users.manage';
  // صلاحيات إعدادات النظام (الهيكل)
  static const String settingsView = 'settings.view'; // الدخول لشاشة لوحة التحكم
  static const String definitionsManage = 'definitions.manage'; // إضافة/حذف/تعديل أنواع القوائم

}