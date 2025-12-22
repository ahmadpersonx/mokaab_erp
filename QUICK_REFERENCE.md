# مرجع سريع | Quick Reference

**mokaab_erp** | نسخة طباعية سريعة | 2025-01-15

---

## 🚀 أوامر سريعة

```bash
# تحديث الحزم
flutter pub get

# تشغيل التطبيق
flutter run

# تنسيق الكود
dart format .

# تحليل الأخطاء
dart analyze

# الاختبارات
flutter test

# بناء الويب
flutter build web

# بناء APK
flutter build apk
```

---

## 📁 المسارات المهمة

```
lib/core/constants/app_theme.dart       → الألوان والأنماط
lib/core/services/finance_formatter.dart → تنسيق موحد
lib/core/widgets/finance/                → المكونات الموحدة
lib/features/finance/screens/            → شاشات المالية
lib/features/finance/services/           → خدمات المالية
lib/features/finance/models/             → نماذج المالية
```

---

## 🎨 المكونات الموحدة

### الاستيراد السريع
```dart
import 'package:mokaab_erp/core/widgets/finance/index.dart';
```

### المكونات المتاحة
```
FinanceSearchBar       → بحث وفلترة
FinanceFilterPanel     → فلاتر متقدمة
FinanceExportImportMenu → Excel
FinancePrintMenu       → طباعة
FinanceSummaryCard     → ملخصات
FinanceSummaryBar      → صف ملخصات
FinanceListItem        → عناصر
```

---

## 🎨 الألوان

```dart
import 'package:mokaab_erp/core/constants/app_theme.dart';

AppTheme.kDarkBrown     // اللون الأساسي
AppTheme.kSuccess       // أخضر (استخدمات إيجابية)
AppTheme.kError         // أحمر (استخدمات سلبية)
AppTheme.kWarning       // برتقالي (تحذيرات)
AppTheme.kInfo          // أزرق (معلومات)
AppTheme.kLightBeige    // بيج فاتح
AppTheme.kOffWhite      // أبيض كريمي
AppTheme.kWhite         // أبيض
AppTheme.kBorder        // لون الحدود
```

---

## 📊 تنسيق البيانات

```dart
import 'package:mokaab_erp/core/services/finance_formatter.dart';

final fmt = financeFormatter;

// العملات
fmt.formatCurrency(15000.50)        // د.أ 15,000.500

// الأرقام
fmt.formatNumber(15000.50)          // 15,000.500

// التواريخ
fmt.formatDate(DateTime.now())      // 2025-01-15
fmt.formatDateShort(DateTime.now()) // 15/01/2025

// الشهور والأيام
fmt.getMonthName(1)                 // يناير
fmt.getDayName(2)                   // الثلاثاء

// الحسابات
fmt.calculateDays(fromDate, toDate) // عدد الأيام
fmt.getQuarter(3)                   // الربع الثالث
```

---

## 🔧 مثال على شاشة بحث وفلترة

```dart
class MyListScreen extends StatefulWidget {
  @override
  State<MyListScreen> createState() => _MyListScreenState();
}

class _MyListScreenState extends State<MyListScreen> {
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  DateTime? _fromDate;
  DateTime? _toDate;
  String _searchText = '';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await service.getItems();
    setState(() {
      _allItems = items;
      _filteredItems = items;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredItems = _allItems.where((item) {
        if (_searchText.isNotEmpty && 
            !item['name'].contains(_searchText)) {
          return false;
        }
        if (_fromDate != null && 
            item['date'].isBefore(_fromDate!)) {
          return false;
        }
        if (_toDate != null && 
            item['date'].isAfter(_toDate!)) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('القائمة')),
      body: Column(
        children: [
          // بحث
          FinanceSearchBar(
            onSearchChanged: (text) {
              setState(() => _searchText = text);
              _applyFilters();
            },
            onAdvancedFiltersTap: () {
              setState(() => _showFilters = !_showFilters);
            },
          ),

          // فلاتر
          if (_showFilters)
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
                  _searchText = '';
                });
                _applyFilters();
              },
              onApplyFilters: _applyFilters,
            ),

          // ملخص
          FinanceSummaryBar(
            items: [
              FinanceSummaryData(
                label: 'الإجمالي',
                amount: _filteredItems.fold(
                  0,
                  (sum, item) => sum + item['amount'],
                ),
                itemCount: _filteredItems.length,
              ),
            ],
          ),

          // قائمة
          Expanded(
            child: ListView.builder(
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return FinanceListItem(
                  itemId: item['id'],
                  itemNumber: item['number'],
                  itemDate: financeFormatter
                      .formatDateShort(item['date']),
                  accountName: item['account'],
                  amount: item['amount'],
                  amountLabel: 'المبلغ',
                  amountColor: AppTheme.kDarkBrown,
                  onEditPressed: (id) => print('Edit: $id'),
                  onPrintPressed: (id) => print('Print: $id'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 📖 روابط التوثيق السريعة

| الملف | الموضوع | الرابط |
|------|---------|--------|
| البداية | ابدأ هنا | [START_HERE.md](START_HERE.md) |
| الفهرس | الملفات والملاحظ | [INDEX.md](INDEX.md) |
| البنية | المعمارية الكاملة | [ARCHITECTURE.md](ARCHITECTURE.md) |
| المكونات | توثيق شامل | [COMPONENTS.md](COMPONENTS.md) |
| التطوير | كيفية التطوير | [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) |
| التحديثات | سجل التطورات | [UPDATES.md](UPDATES.md) |
| المهام | ما يتبقى | [TODO.md](TODO.md) |

---

## 🎯 أنماط شائعة

### نمط 1: البحث والفلترة
```dart
// في initState
final items = await service.getItems();

// في applyFilters
filteredItems = allItems.where((item) {
  if (!_searchText.isEmpty && 
      !item.name.contains(_searchText)) return false;
  if (_fromDate != null && 
      item.date.isBefore(_fromDate!)) return false;
  return true;
}).toList();
```

### نمط 2: Excel Export
```dart
Future<void> _exportToExcel() async {
  final excel = Excel.createExcel();
  final sheet = excel['Sheet1'];
  
  // إضافة الرؤوس والبيانات
  // ...
  
  final fileBytes = excel.encode()!;
  final file = XFile.fromData(
    Uint8List.fromList(fileBytes),
    mimeType: 'application/vnd.ms-excel',
    name: 'export.xlsx',
  );
  
  await Share.shareXFiles([file]);
}
```

### نمط 3: الملخصات
```dart
final total = _filteredItems.fold<double>(
  0,
  (sum, item) => sum + item['amount'],
).toDouble();

FinanceSummaryBar(
  items: [
    FinanceSummaryData(
      label: 'الإجمالي',
      amount: total,
      textColor: AppTheme.kSuccess,
      itemCount: _filteredItems.length,
    ),
  ],
)
```

---

## ⚠️ أخطاء شائعة وحلولها

### خطأ: Uint8List type mismatch
```dart
// ❌ خطأ
final bytes = excel.encode();
XFile.fromData(bytes); // Error: expected Uint8List

// ✅ صحيح
final bytes = excel.encode()!;
XFile.fromData(Uint8List.fromList(bytes));
```

### خطأ: fold type mismatch
```dart
// ❌ خطأ
final sum = items.fold(0, (s, i) => s + i.amount);

// ✅ صحيح
final sum = items.fold<double>(0, (s, i) => s + i.amount);
```

### خطأ: DropdownSearch missing compareFn
```dart
// ❌ خطأ
DropdownSearch<AccountModel>(
  items: accounts,
  // Missing compareFn
)

// ✅ صحيح
DropdownSearch<AccountModel>(
  items: accounts,
  compareFn: (a, b) => a.id == b.id,
)
```

---

## 🎓 نصائح وحيل

### Tip 1: استخدام AppTheme دائماً
```dart
// ✅ استخدم الثوابت
color: AppTheme.kSuccess,

// ❌ تجنب الألوان المباشرة
color: Color(0xFF388E3C),
```

### Tip 2: تنسيق البيانات موحد
```dart
// ✅ استخدم الخدمة
financeFormatter.formatCurrency(amount)

// ❌ تجنب التنسيق المباشر
amount.toStringAsFixed(3)
```

### Tip 3: المكونات الموحدة
```dart
// ✅ استخدم المكونات الموحدة
FinanceListItem(...)

// ❌ تجنب إنشاء مكونات جديدة
Column(...)
```

---

## 🔍 البحث السريع

| تريد | ابحث عن |
|------|---------|
| اسم لون | AppTheme.k... |
| تنسيق عملة | financeFormatter.formatCurrency |
| مكون بحث | FinanceSearchBar |
| مكون فلترة | FinanceFilterPanel |
| مكون قائمة | FinanceListItem |
| مثال شامل | vouchers_list_screen.dart |

---

## 📞 طلب المساعدة السريع

```
سؤال                          → الجواب
"كيف أستخدم مكون X؟"        → اقرأ COMPONENTS.md
"كيف أطور شاشة جديدة؟"      → اقرأ INTEGRATION_GUIDE.md
"ما البنية المعمارية؟"      → اقرأ ARCHITECTURE.md
"أين هو الملف X؟"           → اقرأ INDEX.md
"ما التالي؟"                 → اقرأ TODO.md
"ملخص بسيط"                   → اقرأ START_HERE.md
```

---

## 🎯 الخطوات الأولى

### 1. فهم المشروع (5 دقائق)
اقرأ: [START_HERE.md](START_HERE.md)

### 2. فهم البنية (15 دقيقة)
اقرأ: [ARCHITECTURE.md](ARCHITECTURE.md)

### 3. تعلم المكونات (20 دقيقة)
اقرأ: [COMPONENTS.md](COMPONENTS.md)

### 4. البدء في التطوير (15 دقيقة)
اقرأ: [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)

### 5. دراسة مثال (15 دقيقة)
ادرس: [vouchers_list_screen.dart](lib/features/finance/screens/vouchers_list_screen.dart)

---

## ⏱️ وقت المراجع

| الملف | الوقت |
|------|-------|
| START_HERE.md | 5 دقائق |
| ARCHITECTURE.md | 15 دقيقة |
| COMPONENTS.md | 20 دقيقة |
| INTEGRATION_GUIDE.md | 15 دقيقة |
| مثال عملي | 15 دقيقة |
| **الإجمالي** | **1 ساعة** |

---

## 🎊 نقاط المراجعة

- [ ] قرأت START_HERE.md
- [ ] فهمت ARCHITECTURE.md
- [ ] درست COMPONENTS.md
- [ ] فهمت INTEGRATION_GUIDE.md
- [ ] شغلت المشروع بنجاح
- [ ] استطعت كتابة شاشة بسيطة

---

**آخر تحديث**: 2025-01-15 | اطبع هذا الملف للمرجعية السريعة 🖨️
