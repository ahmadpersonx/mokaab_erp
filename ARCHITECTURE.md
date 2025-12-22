# معمارية نظام ERP - تصنيع الحجر الصناعي
## Finance Module Architecture (القسم المالي)

---

## 1️⃣ الهيكل الأساسي (Feature-Based)

```
lib/
├── features/
│   ├── finance/
│   │   ├── models/                    # نماذج البيانات
│   │   │   ├── voucher_model.dart
│   │   │   ├── invoice_model.dart
│   │   │   ├── transaction_model.dart
│   │   │   └── account_model.dart
│   │   │
│   │   ├── services/                  # منطق الأعمال
│   │   │   ├── finance_service.dart        # قاعدة الخدمات
│   │   │   ├── voucher_service.dart        # متخصصة للسندات
│   │   │   ├── invoice_service.dart        # متخصصة للفواتير
│   │   │   └── finance_repository.dart     # تفاعلات الBD
│   │   │
│   │   ├── widgets/                   # مكونات قابلة لإعادة الاستخدام
│   │   │   ├── common/
│   │   │   │   ├── finance_search_bar.dart           # بحث موحد
│   │   │   │   ├── finance_filter_panel.dart         # فلاتر موحدة
│   │   │   │   ├── finance_export_menu.dart          # تصدير موحد
│   │   │   │   ├── finance_print_menu.dart           # طباعة موحدة
│   │   │   │   ├── finance_summary_card.dart         # بطاقة ملخص
│   │   │   │   ├── finance_list_item.dart            # عنصر قائمة موحد
│   │   │   │   └── finance_date_range_picker.dart    # منتقي التواريخ
│   │   │   │
│   │   │   ├── vouchers/
│   │   │   │   ├── voucher_card.dart
│   │   │   │   └── voucher_batch_actions.dart
│   │   │   │
│   │   │   └── invoices/
│   │   │       ├── invoice_card.dart
│   │   │       └── invoice_line_item.dart
│   │   │
│   │   ├── screens/                   # شاشات العرض
│   │   │   ├── vouchers_list_screen.dart     # ✅ تم
│   │   │   ├── voucher_detail_screen.dart    # قيد التطوير
│   │   │   ├── invoices_list_screen.dart
│   │   │   ├── invoice_detail_screen.dart
│   │   │   ├── finance_dashboard_screen.dart
│   │   │   └── report_screen.dart
│   │   │
│   │   └── providers/                 # State Management (riverpod)
│   │       ├── finance_providers.dart
│   │       ├── voucher_providers.dart
│   │       └── filter_providers.dart
│   │
│   └── home/                          # ملخص سريع
│
├── core/
│   ├── constants/
│   │   ├── app_theme.dart             # ✅ ثيم موحد
│   │   ├── currency_format.dart        # تنسيق العملات (دينار أردني)
│   │   └── date_format.dart            # تنسيق التواريخ (الأردن)
│   │
│   ├── widgets/
│   │   ├── base_list_screen.dart       # قاعدة لجميع شاشات القوائم
│   │   ├── responsive_layout.dart      # تصميم متجاوب
│   │   └── dialogs/
│   │
│   ├── models/
│   │   ├── base_model.dart
│   │   └── filter_model.dart
│   │
│   └── services/
│       ├── pdf_service.dart            # ✅ PDF والطباعة
│       └── excel_service.dart          # Excel والتصدير
```

---

## 2️⃣ مبادئ التصميم الموحد

### 🎨 نمط التصميم (Design Pattern)
- **Unified Color Scheme**: استخدام `AppTheme` لجميع الألوان
- **Consistent Spacing**: `AppSpacing.small`, `AppSpacing.medium`, etc.
- **Uniform Border Radius**: 6-8px لجميع العناصر
- **Consistent Elevation**: 0-2 للبطاقات، 3-4 للقوائم المنسدلة

### 🔄 المكونات القابلة لإعادة الاستخدام
```dart
// مثال على المكون الموحد
class FinanceListItem<T> extends StatelessWidget {
  final T item;
  final bool isSelected;
  final VoidCallback onTap;
  final List<Widget> actions;
  
  const FinanceListItem({...});
  
  // يتم استخدامه في السندات والفواتير بنفس الطريقة
}
```

### 📋 هياكل موحدة
```
جميع شاشات القوائم (List Screens):
├── AppBar (موحد)
├── SearchBar (موحد)
├── FilterPanel (موحد - collapsible)
├── SummaryBar (ملخص الإجماليات)
├── ListView/GridView (متجاوب)
└── FloatingActionButton (موحد)

جميع شاشات التفاصيل (Detail Screens):
├── AppBar + Back Button
├── Tabs (معلومات، تفاصيل، مرفقات)
├── EditButton + PrintButton
└── BottomSheet Actions
```

---

## 3️⃣ الاستجابة (Responsive Design)

### استراتيجية التصميم المتجاوب:

```dart
// Mobile (< 600px): 1 column
// Tablet (600-1000px): 2 columns
// Desktop (> 1000px): 3 columns

LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 600) {
      return MobileLayout();
    } else if (constraints.maxWidth < 1000) {
      return TabletLayout();
    } else {
      return DesktopLayout();
    }
  },
);
```

### قائمة العرض (List):
- **Mobile**: عمود واحد (SingleChildScrollView)
- **Tablet**: عمودين بـ GridView.count(crossAxisCount: 2)
- **Desktop**: جدول DataTable أو GridView.extent

---

## 4️⃣ معايير العملات والتواريخ (الأردن 🇯🇴)

```dart
// العملة: دينار أردني
final currencyFormat = NumberFormat.simpleCurrency(
  locale: 'ar_JO',
  name: 'د.أ',
  decimalDigits: 2,
);

// التاريخ: عربي، هجري اختياري
final dateFormat = DateFormat('dd/MM/yyyy', 'ar_JO');

// أمثلة:
// المبلغ: 1,250.50 د.أ
// التاريخ: 19/12/2025
```

---

## 5️⃣ تدفق البيانات (Data Flow)

```
UI (Screens) 
  ↓
Riverpod Providers (State Management)
  ↓
Services (FinanceService, VoucherService)
  ↓
Repository (FinanceRepository)
  ↓
Supabase API
```

### مثال على Provider:
```dart
// riverpod provider للسندات
final vouchersProvider = FutureProvider.family<List<Voucher>, VoucherFilter>((ref, filter) async {
  final service = ref.watch(financeServiceProvider);
  return service.getVouchers(filter);
});
```

---

## 6️⃣ ميزات القسم المالي

### 📊 الشاشات الأساسية:

| الشاشة | الميزات | الحالة |
|------|--------|--------|
| **Vouchers List** | البحث، الفلاتر، التحديد، الطباعة، التصدير | ✅ 90% |
| **Voucher Detail** | عرض، تعديل، حذف، طباعة مفصلة | ⏳ |
| **Invoices List** | مشابهة للسندات | ⏳ |
| **Invoice Detail** | مع أسطر الفاتورة | ⏳ |
| **Dashboard** | KPIs يومية وشهرية | ⏳ |
| **Reports** | تقارير مالية | ⏳ |

### 🔧 الميزات الموحدة في كل شاشة:

```
✅ البحث النصي (في 3 حقول)
✅ الفلترة المتقدمة (التاريخ + الحساب)
✅ الفرز (حسب التاريخ، المبلغ، الحالة)
✅ التحديد المتعدد والإجراءات الجماعية
✅ الطباعة (PDF + WhatsApp + Save)
✅ التصدير (Excel)
✅ الاستيراد (Excel)
✅ الملخصات الإجمالية
✅ تصميم متجاوب (موبايل + تابلت + سطح مكتب)
✅ RTL كامل (عربي)
```

---

## 7️⃣ معايير الكود

### 📝 تسمية الملفات والمتغيرات:
```dart
// المكونات: (عنصر)_widget.dart
finance_search_bar.dart
finance_filter_panel.dart

// الشاشات: (اسم)_screen.dart
vouchers_list_screen.dart
voucher_detail_screen.dart

// الخدمات: (اسم)_service.dart
finance_service.dart
voucher_service.dart

// النماذج: (اسم)_model.dart
voucher_model.dart
invoice_model.dart
```

### 📐 بنية الملف الواحد:
```dart
// 1. Imports
// 2. Constants & Enums
// 3. Model/Widget/Service Class
// 4. Private Helper Classes
// 5. Private Helper Functions
```

---

## 8️⃣ الاختبار والجودة

```bash
# تشغيل الاختبارات
flutter test

# التحليل الثابت
flutter analyze

# تنسيق الكود
dart format .
```

---

## تم! 🎉

هذه المعمارية توفر:
✅ **قابلية إعادة الاستخدام** (Component-Based)
✅ **سهولة الصيانة** (Feature-Based Structure)
✅ **توسع سهل** (نفس النمط لكل الأقسام)
✅ **استجابة كاملة** (موبايل + تابلت + ديسك)
✅ **احترافية** (AppTheme + التنسيق الموحد)

