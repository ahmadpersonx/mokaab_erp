# المكونات المالية الموحدة | Finance Components

**اللغة**: العربية (RTL) | **الموقع الجغرافي**: الأردن | **العملة**: د.أ (دينار أردني)

---

## 📋 نظرة عامة

مجموعة شاملة من **المكونات القابلة لإعادة الاستخدام** المصممة للقطاع المالي في تطبيق mokaab_erp. كل مكون متخصص في مهمة واحدة وقابل للتخصيص والتوسع.

**المسار**: `lib/core/widgets/finance/`

**الاستيراد السريع**:
```dart
import 'package:mokaab_erp/core/widgets/finance/index.dart';
// يستيراد جميع المكونات في سطر واحد
```

---

## 📦 المكونات المتاحة

### 1️⃣ FinanceSearchBar
**الملف**: `finance_search_bar.dart`

**الغرض**: عنصر بحث موحد لجميع شاشات القوائم المالية

**الميزات**:
- 📝 حقل بحث برقم، وصف، مبلغ
- 🔍 أيقونة بحث
- ⚙️ زر فلاتر متقدمة اختياري

**الاستخدام**:
```dart
FinanceSearchBar(
  onSearchChanged: (searchText) {
    // تطبيق البحث
    _applyFilters(searchText);
  },
  onAdvancedFiltersTap: () {
    // فتح لوحة الفلاتر المتقدمة
    setState(() => _showAdvancedFilters = !_showAdvancedFilters);
  },
  showAdvancedFiltersButton: true,
)
```

**الخصائص**:
| الخاصية | النوع | المتطلب | الوصف |
|--------|------|--------|-------|
| `onSearchChanged` | `ValueChanged<String>` | ✅ | معالج تغير النص |
| `onAdvancedFiltersTap` | `VoidCallback` | ✅ | معالج الضغط على الفلاتر |
| `showAdvancedFiltersButton` | `bool` | ❌ | إظهار زر الفلاتر (افتراضي: true) |

---

### 2️⃣ FinanceFilterPanel
**الملف**: `finance_filter_panel.dart`

**الغرض**: لوحة فلاتر متقدمة موحدة لنطاق التاريخ وحقول إضافية

**الميزات**:
- 📅 منتقي نطاق التاريخ (من - إلى)
- 🔧 دعم حقول فلاتر إضافية (حساب، مبلغ، إلخ)
- 🚀 أزرار تطبيق/مسح
- 🎨 تصميم موحد مع AppTheme

**الاستخدام**:
```dart
FinanceFilterPanel(
  initialFromDate: _fromDate,
  initialToDate: _toDate,
  onFromDateChanged: (date) {
    setState(() => _fromDate = date);
  },
  onToDateChanged: (date) {
    setState(() => _toDate = date);
  },
  onClearFilters: () {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _selectedAccount = null;
    });
  },
  onApplyFilters: () {
    _loadVouchers(); // إعادة تحميل البيانات
  },
  // فلاتر إضافية (حساب مثلاً)
  additionalFiltersWidget: DropdownSearch<AccountModel>(
    // ...
  ),
)
```

**الخصائص**:
| الخاصية | النوع | المتطلب | الوصف |
|--------|------|--------|-------|
| `initialFromDate` | `DateTime?` | ❌ | تاريخ البداية الأولي |
| `initialToDate` | `DateTime?` | ❌ | تاريخ النهاية الأولي |
| `onFromDateChanged` | `ValueChanged<DateTime?>` | ✅ | معالج تغير تاريخ البداية |
| `onToDateChanged` | `ValueChanged<DateTime?>` | ✅ | معالج تغير تاريخ النهاية |
| `onClearFilters` | `VoidCallback` | ✅ | معالج مسح الفلاتر |
| `onApplyFilters` | `VoidCallback` | ✅ | معالج تطبيق الفلاتر |
| `additionalFiltersWidget` | `Widget?` | ❌ | مكون فلاتر إضافي |

---

### 3️⃣ FinanceExportImportMenu
**الملف**: `finance_export_import_menu.dart`

**الغرض**: قائمة موحدة لتصدير واستيراد Excel

**الميزات**:
- 💾 تصدير الكل
- 📦 تصدير المحدد (مع عدد العناصر المحددة)
- 📥 استيراد من Excel
- 🔒 تعطيل "تصدير المحدد" إذا لم يتم اختيار عناصر

**الاستخدام**:
```dart
FinanceExportImportMenu(
  onExport: (isSelected) async {
    if (isSelected) {
      // تصدير العناصر المحددة فقط
      await _executeExport(_selectedVoucherNumbers.toList());
    } else {
      // تصدير الكل
      await _executeExport(_allVouchers.keys.toList());
    }
  },
  onImport: () async {
    await _executeImport();
  },
  enableExportSelected: true,
  selectedItemsCount: _selectedVoucherNumbers.length,
)
```

**الخصائص**:
| الخاصية | النوع | المتطلب | الوصف |
|--------|------|--------|-------|
| `onExport` | `ExportCallback` | ✅ | معالج التصدير (isSelected: bool) |
| `onImport` | `ImportCallback` | ✅ | معالج الاستيراد |
| `enableExportSelected` | `bool` | ❌ | تفعيل تصدير المحدد (افتراضي: true) |
| `selectedItemsCount` | `int` | ❌ | عدد العناصر المحددة (افتراضي: 0) |

---

### 4️⃣ FinancePrintMenu
**الملف**: `finance_print_menu.dart`

**الغرض**: قائمة موحدة للطباعة

**الميزات**:
- 🖨️ طباعة الكل
- 🎯 طباعة المحدد
- 📊 عداد العناصر المحددة

**الاستخدام**:
```dart
FinancePrintMenu(
  onPrint: (isSelected) async {
    if (isSelected) {
      // طباعة العناصر المحددة فقط
      await _executePrint(_selectedVoucherNumbers.toList());
    } else {
      // طباعة الكل
      await _executePrint(_allVouchers.keys.toList());
    }
  },
  enablePrintSelected: true,
  selectedItemsCount: _selectedVoucherNumbers.length,
)
```

**الخصائص**:
| الخاصية | النوع | المتطلب | الوصف |
|--------|------|--------|-------|
| `onPrint` | `PrintCallback` | ✅ | معالج الطباعة |
| `enablePrintSelected` | `bool` | ❌ | تفعيل طباعة المحدد (افتراضي: true) |
| `selectedItemsCount` | `int` | ❌ | عدد العناصر المحددة |
| `tooltipText` | `String` | ❌ | نص التلميح (افتراضي: 'طباعة') |

---

### 5️⃣ FinanceSummaryCard
**الملف**: `finance_summary_card.dart`

**الغرض**: بطاقة ملخص لعرض الإجماليات المالية

**الميزات**:
- 💰 عرض المبلغ بتنسيق محلي (دينار أردني)
- 🎨 ألوان قابلة للتخصيص
- 📊 عداد العناصر
- 🏷️ تسميات مخصصة

**الاستخدام**:
```dart
// بطاقة واحدة
FinanceSummaryCard(
  label: 'إجمالي القبوض',
  amount: 15000.500,
  backgroundColor: AppTheme.kSuccess.withOpacity(0.1),
  textColor: AppTheme.kSuccess,
  itemCount: _filteredVouchers.length,
)

// صف من البطاقات
FinanceSummaryBar(
  items: [
    FinanceSummaryData(
      label: 'إجمالي القبوض',
      amount: 15000.500,
      textColor: AppTheme.kSuccess,
      itemCount: receipts.length,
    ),
    FinanceSummaryData(
      label: 'إجمالي الصرف',
      amount: 8000.250,
      textColor: AppTheme.kError,
      itemCount: payments.length,
    ),
  ],
)
```

**الخصائص** (FinanceSummaryCard):
| الخاصية | النوع | المتطلب | الوصف |
|--------|------|--------|-------|
| `label` | `String` | ✅ | اسم الملخص |
| `amount` | `double` | ✅ | المبلغ |
| `backgroundColor` | `Color?` | ❌ | لون الخلفية |
| `textColor` | `Color?` | ❌ | لون النص |
| `currency` | `String` | ❌ | رمز العملة (افتراضي: 'د.أ') |
| `itemCount` | `int` | ❌ | عدد العناصر |

---

### 6️⃣ FinanceListItem
**الملف**: `finance_list_item.dart`

**الغرض**: بطاقة موحدة لعرض عنصر واحد في القائمة

**الميزات**:
- ☑️ خانة اختيار متعددة الاختيار
- 🏷️ شارة برقم البند
- 📅 التاريخ والحساب
- 💰 المبلغ بلون مخصص
- 🏢 حالة + طريقة دفع + وصف
- ⚡ أزرار إجراء (تعديل، طباعة، حذف)

**الاستخدام**:
```dart
FinanceListItem(
  itemId: voucher['id'],
  itemNumber: voucher['number'],
  itemDate: _formatDate(voucher['date']),
  accountName: voucher['accountName'],
  amount: voucher['amount'],
  amountLabel: 'مبلغ القبض',
  amountColor: AppTheme.kSuccess, // أخضر للقبوض
  statusLabel: 'موثق',
  statusColor: AppTheme.kSuccess,
  paymentMethod: 'نقد',
  description: voucher['description'],
  isSelected: _selectedVoucherNumbers.contains(voucher['id']),
  onSelectedChanged: (value) {
    setState(() {
      if (value ?? false) {
        _selectedVoucherNumbers.add(voucher['id']);
      } else {
        _selectedVoucherNumbers.remove(voucher['id']);
      }
    });
  },
  onEditPressed: (id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SmartVoucherScreen(voucherId: id),
      ),
    );
  },
  onPrintPressed: (id) {
    _executePrint([id]);
  },
)
```

**الخصائص**:
| الخاصية | النوع | المتطلب | الوصف |
|--------|------|--------|-------|
| `itemId` | `String` | ✅ | معرف فريد للعنصر |
| `itemNumber` | `String` | ✅ | رقم البند |
| `itemDate` | `String` | ✅ | تاريخ البند |
| `accountName` | `String` | ✅ | اسم الحساب |
| `amount` | `double` | ✅ | المبلغ |
| `amountLabel` | `String` | ✅ | تسمية المبلغ |
| `amountColor` | `Color` | ✅ | لون المبلغ |
| `statusLabel` | `String?` | ❌ | حالة البند |
| `statusColor` | `Color?` | ❌ | لون الحالة |
| `paymentMethod` | `String?` | ❌ | طريقة الدفع |
| `description` | `String?` | ❌ | الوصف |
| `isSelected` | `bool` | ❌ | هل محدد |
| `onSelectedChanged` | `ValueChanged<bool?>?` | ❌ | معالج تغير التحديد |
| `onEditPressed` | `ItemActionCallback?` | ❌ | معالج الضغط على تعديل |
| `onPrintPressed` | `ItemActionCallback?` | ❌ | معالج الضغط على طباعة |
| `onDeletePressed` | `ItemActionCallback?` | ❌ | معالج الضغط على حذف |
| `padding` | `EdgeInsetsGeometry?` | ❌ | الحشو الداخلي |

---

## 🎯 أفضل الممارسات

### 1. العمل مع الألوان
استخدم **AppTheme** دائماً بدلاً من الألوان المحددة مسبقاً:

```dart
// ✅ صحيح
amountColor: AppTheme.kSuccess,      // أخضر للقبوض
amountColor: AppTheme.kError,        // أحمر للصرف

// ❌ خاطئ
amountColor: Color(0xFF388E3C),      // ألوان محددة مسبقاً
```

### 2. توضيب التاريخ
استخدم `intl` مع locale `ar_JO`:

```dart
import 'package:intl/intl.dart' as intl;

final dateFormat = intl.DateFormat('yyyy-MM-dd', 'ar_JO');
final formatted = dateFormat.format(DateTime.now());
```

### 3. تنسيق المبالغ
استخدم `NumberFormat` للعملات:

```dart
final formatter = intl.NumberFormat('#,##0.000', 'ar_JO');
final formatted = formatter.format(15000.50);  // 15,000.500
```

### 4. الاستيراد الموحد
استخدم ملف `index.dart` للاستيراد السريع:

```dart
// ✅ صحيح
import 'package:mokaab_erp/core/widgets/finance/index.dart';

// ❌ تجنب
import 'package:mokaab_erp/core/widgets/finance/finance_search_bar.dart';
import 'package:mokaab_erp/core/widgets/finance/finance_filter_panel.dart';
// ... إلخ
```

---

## 🔧 أمثلة تكامل سريعة

### مثال 1: قائمة سندات القبض
```dart
class VouchersListScreen extends StatefulWidget {
  @override
  State<VouchersListScreen> createState() => _VouchersListScreenState();
}

class _VouchersListScreenState extends State<VouchersListScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // شريط البحث
        FinanceSearchBar(
          onSearchChanged: _applyAllFilters,
          onAdvancedFiltersTap: () {
            setState(() => _showAdvancedFilters = !_showAdvancedFilters);
          },
        ),

        // لوحة الفلاتر (اختيارية)
        if (_showAdvancedFilters)
          FinanceFilterPanel(
            initialFromDate: _filterFromDate,
            initialToDate: _filterToDate,
            onFromDateChanged: (date) {
              setState(() => _filterFromDate = date);
            },
            onToDateChanged: (date) {
              setState(() => _filterToDate = date);
            },
            onClearFilters: () => setState(() {
              _filterFromDate = null;
              _filterToDate = null;
            }),
            onApplyFilters: _loadVouchers,
          ),

        // شريط الملخص
        FinanceSummaryBar(
          items: [
            FinanceSummaryData(
              label: 'إجمالي القبوض',
              amount: _filteredVouchers.values
                  .fold(0, (sum, v) => sum + v['amount']),
              textColor: AppTheme.kSuccess,
              itemCount: _filteredVouchers.length,
            ),
          ],
        ),

        // قائمة السندات
        Expanded(
          child: ListView.builder(
            itemCount: _filteredVouchers.length,
            itemBuilder: (context, index) {
              final voucher = _filteredVouchers.values.elementAt(index);
              return FinanceListItem(
                itemId: voucher['id'],
                itemNumber: voucher['number'],
                itemDate: _formatDate(voucher['date']),
                accountName: voucher['accountName'],
                amount: voucher['amount'],
                amountLabel: 'مبلغ القبض',
                amountColor: AppTheme.kSuccess,
                statusLabel: 'موثق',
                statusColor: AppTheme.kSuccess,
                paymentMethod: 'نقد',
                isSelected: _selectedVoucherNumbers
                    .contains(voucher['id']),
                onSelectedChanged: (value) {
                  setState(() {
                    if (value ?? false) {
                      _selectedVoucherNumbers.add(voucher['id']);
                    } else {
                      _selectedVoucherNumbers
                          .remove(voucher['id']);
                    }
                  });
                },
                onPrintPressed: (id) => _executePrint([id]),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

---

## 📝 الخطوات التالية

✅ **تم إنجازه**:
- 6 مكونات موحدة وكاملة
- توثيق شامل وأمثلة استخدام
- أفضل ممارسات و guidelines

⏳ **المطلوب قادماً**:
1. دمج المكونات في `vouchers_list_screen.dart` الموجود
2. إنشاء `invoices_list_screen.dart` باستخدام نفس المكونات
3. تطبيق التصميم المتجاوب (LayoutBuilder)
4. إنشاء dashboard مع KPI cards

---

**الإصدار**: 1.0 | **التاريخ**: 2025-01-15 | **الحالة**: جاهز للاستخدام ✅
