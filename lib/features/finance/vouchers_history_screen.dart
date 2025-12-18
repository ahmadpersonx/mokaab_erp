//lib\features\finance\vouchers_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'finance_service.dart';

class VouchersHistoryScreen extends StatefulWidget {
  final String voucherType; // 'receipt' or 'payment'
  const VouchersHistoryScreen({super.key, required this.voucherType});

  @override
  State<VouchersHistoryScreen> createState() => _VouchersHistoryScreenState();
}

class _VouchersHistoryScreenState extends State<VouchersHistoryScreen> {
  final FinanceService _service = FinanceService();
  List<Map<String, dynamic>> _vouchers = [];
  bool _isLoading = true;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getVouchers(
        type: widget.voucherType,
        fromDate: _fromDate,
        toDate: _toDate,
      );
      setState(() {
        _vouchers = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.voucherType == 'receipt' ? 'أرشيف سندات القبض' : 'أرشيف سندات الصرف';
    Color color = widget.voucherType == 'receipt' ? Colors.green.shade700 : Colors.red.shade700;

    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: color, foregroundColor: Colors.white),
      body: Column(
        children: [
          // فلتر التاريخ السريع
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(LucideIcons.calendar),
                    label: Text(_fromDate == null ? "من تاريخ" : DateFormat('yyyy-MM-dd').format(_fromDate!)),
                    onPressed: () async {
                      final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (d != null) setState(() => _fromDate = d);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(LucideIcons.calendar),
                    label: Text(_toDate == null ? "إلى تاريخ" : DateFormat('yyyy-MM-dd').format(_toDate!)),
                    onPressed: () async {
                      final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (d != null) {
                        setState(() => _toDate = d);
                        _loadVouchers(); // إعادة التحميل عند اختيار التاريخ النهائي
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _vouchers.length,
                    separatorBuilder: (c, i) => const Divider(),
                    itemBuilder: (context, index) {
                      final v = _vouchers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.1),
                          child: Icon(v['payment_method'] == 'check' ? LucideIcons.banknote : LucideIcons.coins, color: color),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${v['voucher_number']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text((v['amount'] as num).toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(LucideIcons.calendarDays, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(v['date'])), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                if (v['payment_method'] == 'check') ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                                    child: Text("شيك: ${v['check_no']}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  )
                                ]
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}