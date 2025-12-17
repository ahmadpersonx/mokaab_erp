// [كود رقم 58] - journal_entries_screen.dart (الكامل مع تعريب الحالة والفلاتر)
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_theme.dart';
import 'add_journal_entry_screen.dart'; 
import 'finance_service.dart';

// تحويل الشاشة إلى StatefulWidget لإدارة حالة جلب البيانات والفلاتر
class JournalEntriesScreen extends StatefulWidget {
  const JournalEntriesScreen({super.key});

  @override
  State<JournalEntriesScreen> createState() => _JournalEntriesScreenState();
}

class _JournalEntriesScreenState extends State<JournalEntriesScreen> {
  final FinanceService _service = FinanceService();
  List<Map<String, dynamic>> _journalEntries = [];
  bool _isLoading = true;
  Map<String, dynamic> _currentFilters = {}; 

  @override
  void initState() {
    super.initState();
    _fetchEntries();
  }

  Future<void> _fetchEntries({Map<String, dynamic>? filters}) async {
    setState(() {
      _isLoading = true;
      if (filters != null) {
        _currentFilters = filters; 
      }
    });
    
    try {
      final data = await _service.getJournalEntriesSummary(
        entryNumber: _currentFilters['entryNumber'],
        reference: _currentFilters['reference'],
        status: _currentFilters['status'],
        fromDate: _currentFilters['fromDate'],
        toDate: _currentFilters['toDate'],
      );
      
      setState(() {
        _journalEntries = data.reversed.toList(); 
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('فشل جلب القيود: ${e.toString()}'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _navigateToAddEntry(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddJournalEntryScreen()),
    ).then((_) {
      _fetchEntries();
    });
  }

  void _navigateToEditEntry(BuildContext context, String entryNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddJournalEntryScreen(entryNumber: entryNumber),
      ),
    ).then((_) {
      _fetchEntries();
    });
  }

  void _showFilterDialog(BuildContext context) {
    String? tempEntryNumber = _currentFilters['entryNumber'];
    String? tempReference = _currentFilters['reference'];
    String? tempStatus = _currentFilters['status'];
    DateTime? tempFromDate = _currentFilters['fromDate'];
    DateTime? tempToDate = _currentFilters['toDate'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصفية القيود اليومية'),
        content: StatefulBuilder( 
          builder: (BuildContext context, StateSetter setStateDialog) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'رقم القيد', border: OutlineInputBorder(), isDense: true),
                    controller: TextEditingController(text: tempEntryNumber),
                    onChanged: (v) => tempEntryNumber = v.isEmpty ? null : v,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(labelText: 'الرقم المرجعي', border: OutlineInputBorder(), isDense: true),
                    controller: TextEditingController(text: tempReference),
                    onChanged: (v) => tempReference = v.isEmpty ? null : v,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'الحالة', border: OutlineInputBorder(), isDense: true),
                    initialValue: tempStatus,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('الكل')),
                      DropdownMenuItem(value: 'Draft', child: Text('مسودة')),
                      DropdownMenuItem(value: 'posted', child: Text('مرحل')), // يجب أن تتطابق القيمة مع المخزنة في DB
                      DropdownMenuItem(value: 'Canceled', child: Text('ملغي')),
                    ],
                    onChanged: (v) => setStateDialog(() => tempStatus = v),
                  ),
                  const SizedBox(height: 10),
                  _buildDateFilterRow(context, 'من تاريخ', tempFromDate, (date) => setStateDialog(() => tempFromDate = date)),
                  _buildDateFilterRow(context, 'إلى تاريخ', tempToDate, (date) => setStateDialog(() => tempToDate = date)),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(onPressed: () {
            Navigator.pop(ctx);
            _fetchEntries(filters: {});
          }, child: const Text('مسح الفلاتر')),
          ElevatedButton(onPressed: () {
            Navigator.pop(ctx);
            _fetchEntries(filters: {
              'entryNumber': tempEntryNumber,
              'reference': tempReference,
              'status': tempStatus,
              'fromDate': tempFromDate, 
              'toDate': tempToDate,
            });
          }, child: const Text('تطبيق الفلتر')),
        ],
      ),
    );
  }

  Widget _buildDateFilterRow(BuildContext context, String label, DateTime? selectedDate, Function(DateTime?) onDateSelected) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        TextButton(
          onPressed: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            onDateSelected(picked);
          },
          child: Text(selectedDate == null ? 'اختر التاريخ' : DateFormat('yyyy-MM-dd').format(selectedDate)),
        ),
        if (selectedDate != null)
          IconButton(
            icon: const Icon(Icons.clear, size: 18),
            onPressed: () => onDateSelected(null),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('القيود اليومية'),
        backgroundColor: AppTheme.kDarkBrown,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true, 
        actions: [
          IconButton(
            onPressed: () => _showFilterDialog(context),
            icon: const FaIcon(FontAwesomeIcons.filter),
            tooltip: 'تصفية متقدمة',
          ),
          IconButton(
            onPressed: () => _navigateToAddEntry(context),
            icon: const FaIcon(FontAwesomeIcons.plus),
            tooltip: 'إضافة قيد جديد',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchEntries, 
              child: _journalEntries.isEmpty
                  ? Center(
                      child: Text('لا توجد قيود يومية تتطابق مع الفلاتر المطبقة. ${_currentFilters.isNotEmpty ? 'مسح الفلاتر؟' : ''}'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _journalEntries.length,
                      itemBuilder: (context, index) {
                        final entry = _journalEntries[index];
                        return InkWell(
                          onTap: () => _navigateToEditEntry(context, entry['id'] as String),
                          child: JournalEntryCard(entry: entry),
                        );
                      },
                    ),
            ),
    );
  }
}

// (JournalEntryCard class - مع تعريب الحالة)
class JournalEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;

  const JournalEntryCard({super.key, required this.entry});

  // دالة تحويل حالة القيد من الإنجليزية إلى العربية
  String _mapStatusToArabic(String? status) {
    switch (status) {
      case 'Draft':
        return 'مسودة';
      case 'posted':
        return 'مرحل';
      case 'Canceled':
        return 'ملغي';
      default:
        return 'غير محدد';
    }
  }

  @override
  Widget build(BuildContext context) {
    // تحديد اللون (باستخدام القيمة المخزنة في DB)
    Color statusColor = entry['status'] == 'posted' 
        ? Colors.green 
        : entry['status'] == 'Canceled' 
            ? Colors.red 
            : Colors.amber;

    // تحويل الحالة للعرض
    final arabicStatus = _mapStatusToArabic(entry['status'] as String?);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصف الأول: رقم القيد والتاريخ والحالة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry['id'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.kDarkBrown),
                ),
                _buildStatusTag(arabicStatus, statusColor), // استخدام الحالة المعربة
              ],
            ),
            const SizedBox(height: 4),

            // الصف الثاني: الوصف
            Text(
              entry['description'],
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            // الصف الثالث: التاريخ والرقم المرجعي
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.calendarDay, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'التاريخ: ${entry['date']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.tag, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'مرجع: ${entry['ref_number']}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),

            // الصف الرابع: الإجمالي المدين والدائن
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTotalRow(
                    'المدين', entry['debit'], Colors.green.shade700),
                _buildTotalRow(
                    'الدائن', entry['credit'], Colors.red.shade700),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTag(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          '${amount.toStringAsFixed(2)} \$', 
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}