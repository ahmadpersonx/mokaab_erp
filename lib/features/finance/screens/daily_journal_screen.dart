// FileName: lib/features/finance/screens/daily_journal_screen.dart
// Revision: 4.0 (Updated to use JournalEntryModel)
// Date: 2025-12-20

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_theme.dart';
import '../services/finance_service.dart';
import '../models/journal_entry_model.dart'; // استيراد الموديل
import 'add_journal_entry_screen.dart';

class DailyJournalScreen extends StatefulWidget {
  const DailyJournalScreen({super.key});

  @override
  State<DailyJournalScreen> createState() => _DailyJournalScreenState();
}

class _DailyJournalScreenState extends State<DailyJournalScreen> {
  final FinanceService _service = FinanceService();
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  // Data (Updated to use Model)
  List<JournalEntryModel> _entries = [];
  Map<String, dynamic> _summary = {'count': 0, 'total_debit': 0.0, 'total_credit': 0.0};
  bool _isLoading = true;

  // Filters
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Load Entries (Returns List<JournalEntryModel>)
      final entries = await _service.getFilteredJournalEntries(
        from: _fromDate,
        to: _toDate,
      );

      // 2. Load Summary
      final summary = await _service.getJournalEntriesSummary();

      if (mounted) {
        setState(() {
          _entries = entries;
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading journal entries: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        title: const Text("اليومية العامة"),
        backgroundColor: AppTheme.kDarkBrown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.filter),
            onPressed: () {
              // TODO: Open Filter Dialog
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddJournalEntryScreen()),
          );
          _loadData();
        },
        backgroundColor: AppTheme.kDarkBrown,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Summary Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem("عدد القيود", "${_entries.length}"),
                _buildSummaryItem("إجمالي مدين", _currencyFormat.format(_summary['total_debit'] ?? 0)),
                _buildSummaryItem("إجمالي دائن", _currencyFormat.format(_summary['total_credit'] ?? 0)),
              ],
            ),
          ),
          
          // Entries List
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? Center(child: Text("لا توجد قيود", style: TextStyle(color: Colors.grey.shade500)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddJournalEntryScreen(entryNumber: entry.entryNumber),
                                  ),
                                );
                                _loadData();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "#${entry.entryNumber}", 
                                          style: const TextStyle(fontWeight: FontWeight.bold)
                                        ),
                                        Text(
                                          _dateFormat.format(entry.entryDate),
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      entry.description ?? 'لا يوجد بيان',
                                      style: TextStyle(color: Colors.grey.shade800),
                                      maxLines: 2, 
                                      overflow: TextOverflow.ellipsis
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _currencyFormat.format(entry.totalDebit),
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.kDarkBrown),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: entry.status == 'posted' ? Colors.green.shade50 : Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: entry.status == 'posted' ? Colors.green : Colors.orange),
                                          ),
                                          child: Text(
                                            entry.status == 'posted' ? "مرحل" : "مسودة",
                                            style: TextStyle(fontSize: 10, color: entry.status == 'posted' ? Colors.green : Colors.orange),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}