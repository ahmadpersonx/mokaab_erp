# دليل التكامل | Integration Guide

**اللغة**: العربية (RTL) | **المشروع**: mokaab_erp

---

## 📋 محتويات الدليل

1. [نظرة عامة](#نظرة-عامة)
2. [البنية المعمارية](#البنية-المعمارية)
3. [المكونات الموحدة](#المكونات-الموحدة)
4. [خدمات التنسيق](#خدمات-التنسيق)
5. [أنماط التطوير](#أنماط-التطوير)
6. [خطوات التكامل](#خطوات-التكامل)

---

## 🎯 نظرة عامة

هذا المشروع يستخدم **معمارية موحدة** لضمان:
- ✅ **الاتساق**: نفس الأسلوب والتصميم في كل الشاشات
- ✅ **قابلية إعادة الاستخدام**: مكونات موحدة وخدمات مشتركة
- ✅ **القابلية للصيانة**: كود منظم وسهل الفهم
- ✅ **التوسعية**: سهولة إضافة ميزات جديدة

---

## 🏗️ البنية المعمارية

```
lib/
├── main.dart                           # نقطة البداية
├── core/
│   ├── constants/
│   │   └── app_theme.dart              # ألوان + أنماط موحدة
│   ├── models/
│   │   ├── account_model.dart
│   │   └── ... (نماذج مشتركة)
│   ├── services/
│   │   ├── supabase_service.dart       # خدمة قاعدة البيانات
│   │   ├── finance_formatter.dart      # تنسيق موحد
│   │   └── ... (خدمات أخرى)
│   └── widgets/
│       ├── finance/
│       │   ├── finance_search_bar.dart
│       │   ├── finance_filter_panel.dart
│       │   ├── finance_export_import_menu.dart
│       │   ├── finance_print_menu.dart
│       │   ├── finance_summary_card.dart
│       │   ├── finance_list_item.dart
│       │   └── index.dart
│       └── ... (مكونات أخرى)
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── services/
│   ├── finance/
│   │   ├── models/
│   │   ├── screens/
│   │   │   ├── vouchers_list_screen.dart    # ✅ مثال
│   │   │   ├── invoices_list_screen.dart    # ⏳ قريباً
│   │   │   └── ...
│   │   ├── widgets/
│   │   ├── services/
│   │   │   └── finance_service.dart
│   │   └── providers/ (اختياري - Riverpod)
│   ├── production/
│   ├── inventory/
│   ├── shipping/
│   └── ... (أقسام أخرى)
└── assets/
    ├── fonts/
    │   └── cairo/                      # خط عربي
    └── images/
```

---

## 🎨 المكونات الموحدة

### المسار
```
lib/core/widgets/finance/
├── finance_search_bar.dart
├── finance_filter_panel.dart
├── finance_export_import_menu.dart
├── finance_print_menu.dart
├── finance_summary_card.dart
├── finance_list_item.dart
└── index.dart
```

### الاستيراد السريع
```dart
import 'package:mokaab_erp/core/widgets/finance/index.dart';

// الآن متاح:
// - FinanceSearchBar
// - FinanceFilterPanel
// - FinanceExportImportMenu
// - FinancePrintMenu
// - FinanceSummaryCard / FinanceSummaryBar / FinanceSummaryData
// - FinanceListItem / ItemActionCallback
```

### التفاصيل الكاملة
اطلع على [COMPONENTS.md](COMPONENTS.md) للتفاصيل الشاملة والأمثلة

---

## 🔧 خدمات التنسيق

### FinanceFormatter

**الملف**: `lib/core/services/finance_formatter.dart`

**الاستخدام**:
```dart
import 'package:mokaab_erp/core/services/finance_formatter.dart';

// استخدام الـ singleton
final formatter = FinanceFormatter();
// أو الاختصار
final formatter = financeFormatter;

// أمثلة
financeFormatter.formatCurrency(15000.50)      // د.أ 15,000.500
financeFormatter.formatNumber(15000.50)        // 15,000.500
financeFormatter.formatDate(DateTime.now())    // 2025-01-15
financeFormatter.formatDateShort(...)          // 15/01/2025
financeFormatter.getMonthName(1)               // يناير
financeFormatter.getDayName(2)                 // الثلاثاء
```

**الدوال المتاحة**:
| الدالة | الوصف | مثال |
|--------|-------|------|
| `formatCurrency(double)` | تنسيق العملة | د.أ 15,000.000 |
| `formatNumber(double)` | تنسيق الرقم | 15,000.000 |
| `formatDate(DateTime)` | تنسيق التاريخ | 2025-01-15 |
| `formatDateShort(DateTime)` | تنسيق قصير | 15/01/2025 |
| `formatDateTime(DateTime)` | تنسيق مع الوقت | 2025-01-15 14:30 |
| `parseDate(String)` | تحليل التاريخ | DateTime |
| `getMonthName(int)` | اسم الشهر | يناير |
| `getDayName(int)` | اسم اليوم | الاثنين |
| `getQuarter(int)` | ربع السنة | 1-4 |
| `calculateDays(from, to)` | الفرق بالأيام | 30 |

---

## 🎯 أنماط التطوير

### 1. نمط شاشة القائمة (List Screen)

```dart
class MyListScreen extends StatefulWidget {
  @override
  State<MyListScreen> createState() => _MyListScreenState();
}

class _MyListScreenState extends State<MyListScreen> {
  // البيانات
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  
  // حالة الفلاتر
  String _searchText = '';
  DateTime? _filterFromDate;
  DateTime? _filterToDate;
  bool _showAdvancedFilters = false;
  
  // حالة الاختيار
  Set<String> _selectedItemIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    // تحميل البيانات من الخدمة
    final items = await _service.getItems();
    setState(() {
      _allItems = items;
      _filteredItems = items;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredItems = _allItems.where((item) {
        // فلترة البحث
        if (_searchText.isNotEmpty &&
            !item['number'].contains(_searchText)) {
          return false;
        }
        // فلترة التاريخ
        if (_filterFromDate != null &&
            item['date'].isBefore(_filterFromDate!)) {
          return false;
        }
        if (_filterToDate != null &&
            item['date'].isAfter(_filterToDate!)) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة العناصر'),
        actions: [
          // أزرار الإجراءات
          FinancePrintMenu(
            onPrint: (isSelected) => _executePrint(isSelected),
            selectedItemsCount: _selectedItemIds.length,
            enablePrintSelected: _isSelectionMode,
          ),
          FinanceExportImportMenu(
            onExport: (isSelected) => _executeExport(isSelected),
            onImport: () => _executeImport(),
            selectedItemsCount: _selectedItemIds.length,
            enableExportSelected: _isSelectionMode,
          ),
          // زر تبديل وضع الاختيار
          IconButton(
            icon: Icon(
              _isSelectionMode
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
            ),
            onPressed: () {
              setState(() {
                _isSelectionMode = !_isSelectionMode;
                if (!_isSelectionMode) {
                  _selectedItemIds.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث
          FinanceSearchBar(
            onSearchChanged: (text) {
              setState(() => _searchText = text);
              _applyFilters();
            },
            onAdvancedFiltersTap: () {
              setState(
                () => _showAdvancedFilters = !_showAdvancedFilters,
              );
            },
          ),

          // لوحة الفلاتر المتقدمة
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
              onClearFilters: () {
                setState(() {
                  _filterFromDate = null;
                  _filterToDate = null;
                  _searchText = '';
                });
                _applyFilters();
              },
              onApplyFilters: _applyFilters,
            ),

          // شريط الملخص
          FinanceSummaryBar(
            items: [
              FinanceSummaryData(
                label: 'الإجمالي',
                amount: _filteredItems.fold(
                  0,
                  (sum, item) => sum + item['amount'],
                ),
                textColor: AppTheme.kDarkBrown,
                itemCount: _filteredItems.length,
              ),
            ],
          ),

          // قائمة العناصر
          Expanded(
            child: ListView.builder(
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return FinanceListItem(
                  itemId: item['id'],
                  itemNumber: item['number'],
                  itemDate: financeFormatter.formatDateShort(item['date']),
                  accountName: item['accountName'],
                  amount: item['amount'],
                  amountLabel: 'المبلغ',
                  amountColor: AppTheme.kDarkBrown,
                  isSelected: _selectedItemIds.contains(item['id']),
                  onSelectedChanged: _isSelectionMode
                      ? (value) {
                          setState(() {
                            if (value ?? false) {
                              _selectedItemIds.add(item['id']);
                            } else {
                              _selectedItemIds.remove(item['id']);
                            }
                          });
                        }
                      : null,
                  onEditPressed: (id) {
                    // فتح شاشة التعديل
                  },
                  onPrintPressed: (id) => _executePrint(true),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executePrint(bool isSelected) async {
    // تنفيذ الطباعة
  }

  Future<void> _executeExport(bool isSelected) async {
    // تنفيذ التصدير
  }

  Future<void> _executeImport() async {
    // تنفيذ الاستيراد
  }
}
```

### 2. نمط شاشة التفاصيل (Detail Screen)

```dart
class ItemDetailScreen extends StatefulWidget {
  final String itemId;

  const ItemDetailScreen({required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late Future<Map<String, dynamic>> _itemFuture;

  @override
  void initState() {
    super.initState();
    _itemFuture = _service.getItemDetails(widget.itemId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل العنصر'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _executePrint(),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _itemFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          final item = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // رقم البند
                  Text(
                    'رقم البند: ${item['number']}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  // التاريخ
                  Text(
                    financeFormatter.formatDateShort(item['date']),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  // التفاصيل
                  // ...
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _executePrint() async {
    // تنفيذ الطباعة
  }
}
```

---

## 📋 خطوات التكامل

### الخطوة 1: استيراد المكونات
```dart
import 'package:mokaab_erp/core/widgets/finance/index.dart';
import 'package:mokaab_erp/core/services/finance_formatter.dart';
import 'package:mokaab_erp/core/constants/app_theme.dart';
```

### الخطوة 2: إضافة حالة الفلاتر والبيانات
```dart
// البيانات
List<Map<String, dynamic>> _allItems = [];
List<Map<String, dynamic>> _filteredItems = [];

// الفلاتر
String _searchText = '';
DateTime? _filterFromDate;
DateTime? _filterToDate;

// الاختيار
Set<String> _selectedItemIds = {};
bool _isSelectionMode = false;
```

### الخطوة 3: بناء واجهة المستخدم
```dart
// في build method
FinanceSearchBar(...)
if (_showAdvancedFilters) FinanceFilterPanel(...)
FinanceSummaryBar(...)
ListView.builder(
  itemBuilder: (context, index) {
    return FinanceListItem(...);
  },
)
```

### الخطوة 4: تطبيق الفلاتر والإجراءات
```dart
void _applyFilters() {
  setState(() {
    _filteredItems = _allItems.where((item) {
      // منطق الفلترة
    }).toList();
  });
}

Future<void> _executePrint(bool isSelected) async {
  // منطق الطباعة
}
```

---

## 🔍 قائمة التحقق

قبل نشر شاشة جديدة:

- [ ] استخدام FinanceSearchBar للبحث
- [ ] استخدام FinanceFilterPanel للفلاتر
- [ ] استخدام FinanceSummaryBar للملخصات
- [ ] استخدام FinanceListItem لعناصر القائمة
- [ ] استخدام AppTheme للألوان
- [ ] استخدام FinanceFormatter للتنسيق
- [ ] الأنماط RTL متوافقة
- [ ] الكود منسق (dart format)
- [ ] لا توجد أخطاء تجميع (dart analyze)
- [ ] الاختبارات تمر (flutter test)

---

## 🆘 المساعدة والدعم

### أسئلة شائعة

**س: كيف أضيف فلتر جديد؟**
ج: أضف Widget جديد في `additionalFiltersWidget` في `FinanceFilterPanel`

**س: كيف أغير الألوان؟**
ج: عدّل `AppTheme` في `lib/core/constants/app_theme.dart`

**س: كيف أضيف حقل جديد إلى البطاقة؟**
ج: أضف property جديد إلى `FinanceListItem` والعرض في البناء

**س: كيف أستخدم صيغة مختلفة؟**
ج: استخدم `FinanceFormatter` أو أضف دالة تنسيق جديدة

---

**الإصدار**: 1.0 | **التاريخ**: 2025-01-15 | **الحالة**: جاهز للاستخدام ✅
