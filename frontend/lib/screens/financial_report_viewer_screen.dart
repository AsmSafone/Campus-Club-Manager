import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class FinancialReportViewerScreen extends StatefulWidget {
  final String? token;
  final int? clubId;
  const FinancialReportViewerScreen({Key? key, this.token, this.clubId}) : super(key: key);

  @override
  _FinancialReportViewerScreenState createState() => _FinancialReportViewerScreenState();
}

class _FinancialReportViewerScreenState extends State<FinancialReportViewerScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<FinancialReport> _reports = [];
  late Future<void> _loadFuture;
  // Api base URL provided by ApiConfig

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadReports();
  }

  Future<List<Map<String, dynamic>>> _fetchFinanceRecords() async {
    try {
      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/clubs/${widget.clubId}/finance');
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        print(response.body);
        final data = json.decode(response.body) as Map<String, dynamic>;
        final records = data['records'] as List? ?? [];
        return List<Map<String, dynamic>>.from(records.map((r) => Map<String, dynamic>.from(r)));
      }
      // throw Exception('Failed to fetch finance records');
    } catch (e) {
      print('Error fetching finance records: $e');
      rethrow;
    }
    return [];
  }

  Future<void> _loadReports() async {
    try {
      final records = await _fetchFinanceRecords();

      // Generate monthly Profit & Loss for last 3 months (including current)
      final now = DateTime.now();
      final generated = <FinancialReport>[];
      for (int i = 0; i < 3; i++) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final start = DateTime(monthDate.year, monthDate.month, 1);
        final end = DateTime(monthDate.year, monthDate.month + 1, 1).subtract(const Duration(days: 1));
        final totals = _computeTotalsForRange(records, start, end);
        final title = '${start.year}-${start.month.toString().padLeft(2, '0')} P&L';
        final dateRange = '${start.toIso8601String().split('T')[0]} - ${end.toIso8601String().split('T')[0]}';
        generated.add(FinancialReport(type: 'Profit & Loss', title: title, dateRange: dateRange, income: totals['income']!, expenses: totals['expense']!, net: totals['income']! - totals['expense']!));
      }

      // Add an overall Balance Sheet (current)
      final totalsAll = _computeTotalsForRange(records, DateTime(2000), DateTime.now());
      generated.add(FinancialReport(type: 'Balance Sheet', title: 'Current Balance Sheet', dateRange: 'Generated: ${DateTime.now().toIso8601String().split('T')[0]}', income: totalsAll['income']!, expenses: totalsAll['expense']!, net: totalsAll['income']! - totalsAll['expense']!));

      setState(() => _reports = generated);
    } catch (e) {
      // keep existing empty list and rethrow for UI to show
      rethrow;
    }
  }

  Map<String, double> _computeTotalsForRange(List<Map<String, dynamic>> records, DateTime start, DateTime end) {
    double income = 0.0;
    double expense = 0.0;
    for (var r in records) {
      try {
        final raw = r['date']?.toString();
        if (raw == null) continue;
        final dt = DateTime.parse(raw).toLocal();
        if (dt.isBefore(start) || dt.isAfter(end)) continue;
        final amtRaw = r['amount'] ?? 0;
        final amt = amtRaw is String ? double.tryParse(amtRaw) ?? 0.0 : (amtRaw as num).toDouble();
        final type = (r['type'] ?? '').toString();
        if (type.toLowerCase().contains('income')) income += amt; else expense += amt;
      } catch (_) {}
    }
    return {'income': income, 'expense': expense};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101922),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
            color: const Color(0xFF101922),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Financial Reports',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Color(0xFF4A90E2)),
                    onPressed: () => _showCreateReportSheet(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF137FEC)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading reports: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => setState(() => _loadFuture = _loadReports()),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF137FEC)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final query = _searchController.text.trim().toLowerCase();
          final filtered = _reports.where((r) {
            if (query.isEmpty) return true;
            return r.title.toLowerCase().contains(query) || r.type.toLowerCase().contains(query) || r.dateRange.toLowerCase().contains(query);
          }).toList();

          return RefreshIndicator(
            color: const Color(0xFF137FEC),
            onRefresh: _loadReports,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF1C2127),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Icon(Icons.search, color: Colors.grey[600]),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Search by name...',
                                hintStyle: TextStyle(color: Colors.grey[600]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Filter Chips (kept as-is)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('Date Range', Icons.expand_more),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFF4A90E2).withOpacity(0.2),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              children: [
                                const Text(
                                  'P&L',
                                  style: TextStyle(
                                    color: Color(0xFF4A90E2),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {},
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Color(0xFF4A90E2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip('Sort By: Newest', Icons.expand_more),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Report Cards
                    Column(
                      children: List.generate(
                        filtered.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildReportCard(filtered[index]),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
        color: const Color(0xFF1C2127),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(FinancialReport report) {
    bool isPositive = report.net >= 0;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF1C2127),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.type,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.dateRange,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                onPressed: () {
                  _showReportMenu(context, report);
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Stats
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Income: ',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '\$${report.income}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Expenses: ',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '\$${report.expenses}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Net: ',
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${report.net}',
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReportMenu(BuildContext context, FinancialReport report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2127),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Download'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showCreateReportSheet(BuildContext ctx) {
    String _type = 'Profit & Loss';
    DateTime _start = DateTime.now().subtract(const Duration(days: 30));
    DateTime _end = DateTime.now();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101922),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create Report', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _type,
                  dropdownColor: const Color(0xFF1E1E1E),
                  decoration: InputDecoration(filled: true, fillColor: const Color(0xFF1E1E1E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                  items: const [DropdownMenuItem(value: 'Profit & Loss', child: Text('Profit & Loss')), DropdownMenuItem(value: 'Balance Sheet', child: Text('Balance Sheet'))],
                  onChanged: (v) => setModalState(() => _type = v ?? 'Profit & Loss'),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey[800]!), backgroundColor: const Color(0xFF1E1E1E)),
                    onPressed: () async {
                      final picked = await showDatePicker(context: context, initialDate: _start, firstDate: DateTime(2000), lastDate: DateTime(2100), builder: (c, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark()), child: child ?? const SizedBox()));
                      if (picked != null) setModalState(() => _start = picked);
                    },
                    child: Text('From: ${_start.toIso8601String().split('T')[0]}', style: const TextStyle(color: Colors.white)),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton(
                    style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey[800]!), backgroundColor: const Color(0xFF1E1E1E)),
                    onPressed: () async {
                      final picked = await showDatePicker(context: context, initialDate: _end, firstDate: DateTime(2000), lastDate: DateTime(2100), builder: (c, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark()), child: child ?? const SizedBox()));
                      if (picked != null) setModalState(() => _end = picked);
                    },
                    child: Text('To: ${_end.toIso8601String().split('T')[0]}', style: const TextStyle(color: Colors.white)),
                  )),
                ],),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF137FEC)),
                    onPressed: () {
                      // generate report
                      final start = DateTime(_start.year, _start.month, _start.day);
                      final end = DateTime(_end.year, _end.month, _end.day, 23, 59, 59);
                      // fetch records and compute
                      _fetchFinanceRecords().then((records) {
                        final totals = _computeTotalsForRange(List<Map<String, dynamic>>.from(records), start, end);
                        final title = _type == 'Profit & Loss' ? '${start.year}-${start.month.toString().padLeft(2, '0')} P&L' : 'Balance Sheet ${start.toIso8601String().split('T')[0]}';
                        final dateRange = '${start.toIso8601String().split('T')[0]} - ${end.toIso8601String().split('T')[0]}';
                        final newReport = FinancialReport(type: _type, title: title, dateRange: dateRange, income: totals['income']!, expenses: totals['expense']!, net: totals['income']! - totals['expense']!);
                        setState(() => _reports.insert(0, newReport));
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Report generated')));
                      }).catchError((e) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed to generate: $e')));
                      });
                    },
                    child: const Text('Generate'),
                  )),
                ],),
                const SizedBox(height: 12),
              ],
            ),
          );
        });
      }
    );
  }
}

class FinancialReport {
  final String type;
  final String title;
  final String dateRange;
  final double income;
  final double expenses;
  final double net;

  FinancialReport({
    required this.type,
    required this.title,
    required this.dateRange,
    required this.income,
    required this.expenses,
    required this.net,
  });
}
