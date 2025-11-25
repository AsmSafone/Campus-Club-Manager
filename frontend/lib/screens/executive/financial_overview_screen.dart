import 'package:flutter/material.dart';
import 'package:campus_club_manager/config/api_config.dart';
import 'package:campus_club_manager/screens/executive/financial_report_generation_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class FinancialOverviewScreen extends StatefulWidget {
  final String? token;
  final int? clubId;
  const FinancialOverviewScreen({Key? key, this.token, this.clubId}) : super(key: key);

  @override
  _FinancialOverviewScreenState createState() => _FinancialOverviewScreenState();
}

class _FinancialOverviewScreenState extends State<FinancialOverviewScreen> {
  late Future<Map<String, dynamic>> _financeFuture;
  final String _apiBaseUrl = ApiConfig.baseUrl;
  final double _chartMaxHeight = 120; // px for chart scaling
  String _chartPeriod = 'month';

  @override
  void initState() {
    super.initState();
    _financeFuture = _fetchFinance();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchFinance() async {
    try {
      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/clubs/${widget.clubId}/finance'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load finance data');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _refreshFinance() async {
    setState(() {
      _financeFuture = _fetchFinance();
    });
    try {
      await _financeFuture;
    } catch (_) {
      // swallow here; FutureBuilder will show error state
    }
  }

  DateTime _latestRecordDate(List records) {
    DateTime latest = DateTime.now();
    for (var rec in records) {
      try {
        final rawDate = rec['date']?.toString();
        if (rawDate == null) continue;
        final dt = DateTime.parse(rawDate).toLocal();
        if (dt.isAfter(latest)) latest = dt;
      } catch (_) {}
    }
    return latest;
  }

  List<Map<String, double>> _computeWeeklyData(List records, DateTime endDate) {
    final now = endDate;
    // initialize 4 week buckets
    final weeks = List.generate(4, (_) => {'income': 0.0, 'expense': 0.0});

    for (var rec in records) {
      try {
        final rawDate = rec['date']?.toString();
        if (rawDate == null) continue;
        final dt = DateTime.parse(rawDate).toLocal();
        final diffDays = now.difference(dt).inDays;
        final weekIndex = (diffDays / 7).floor();
        if (weekIndex >= 0 && weekIndex < 4) {
          final amtRaw = rec['amount'] ?? 0;
          final amt = amtRaw is String ? double.tryParse(amtRaw) ?? 0.0 : (amtRaw as num).toDouble();
          final type = (rec['type'] ?? '').toString().toLowerCase();
          if (type.contains('income')) {
            weeks[weekIndex]['income'] = weeks[weekIndex]['income']! + amt.abs();
          } else {
            // treat expense as positive magnitude for charting
            weeks[weekIndex]['expense'] = weeks[weekIndex]['expense']! + amt.abs();
          }
        }
      } catch (_) {
        // ignore parsing errors for individual records
      }
    }

    // Return reversed so chart shows older -> newer left->right
    return weeks.reversed.toList();
  }

  List<Map<String, double>> _computeMonthlyData(List records, DateTime endDate) {
    final months = List.generate(12, (_) => {'income': 0.0, 'expense': 0.0});
    for (var rec in records) {
      try {
        final rawDate = rec['date']?.toString();
        if (rawDate == null) continue;
        final dt = DateTime.parse(rawDate).toLocal();
        final diffMonths = (endDate.year - dt.year) * 12 + (endDate.month - dt.month);
        if (diffMonths >= 0 && diffMonths < 12) {
          final amtRaw = rec['amount'] ?? 0;
          final amt = amtRaw is String ? double.tryParse(amtRaw) ?? 0.0 : (amtRaw as num).toDouble();
          final type = (rec['type'] ?? '').toString().toLowerCase();
          if (type.contains('income')) {
            months[diffMonths]['income'] = months[diffMonths]['income']! + amt.abs();
          } else {
            months[diffMonths]['expense'] = months[diffMonths]['expense']! + amt.abs();
          }
        }
      } catch (_) {}
    }
    return months.reversed.toList();
  }

  Future<void> _addTransaction(String type, double amount, String date, String? description) async {
    final url = Uri.parse('$_apiBaseUrl/api/clubs/${widget.clubId}/finance');
    try {
      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };
      final body = json.encode({
        'type': type,
        'amount': amount.toStringAsFixed(2),
        'date': date,
        'description': description,
      });

      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 201) {
        return;
      } else {
        throw Exception('Failed to add transaction: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  void _showAddTransactionSheet(BuildContext ctx) {
    final _amountController = TextEditingController();
    final _descController = TextEditingController();
    String _type = 'Income';
    DateTime _selectedDate = DateTime.now();
    bool _submitting = false;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101922),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
                Text('Add Transaction', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _type,
                        dropdownColor: const Color(0xFF1E1E1E),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF1E1E1E),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Income', child: Text('Income')),
                          DropdownMenuItem(value: 'Expense', child: Text('Expense')),
                        ],
                        onChanged: (v) => setModalState(() => _type = v ?? 'Income'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Amount',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: const Color(0xFF1E1E1E),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Description (optional)',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[800]!),
                          backgroundColor: const Color(0xFF1E1E1E),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark()), child: child ?? const SizedBox()),
                          );
                          if (picked != null) setModalState(() => _selectedDate = picked);
                        },
                        child: Text('Date: ${_selectedDate.toIso8601String().split('T')[0]}', style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF137FEC)),
                        onPressed: _submitting
                            ? null
                            : () async {
                                // validate
                                final amtText = _amountController.text.trim();
                                final amt = double.tryParse(amtText);
                                if (amt == null || amt <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
                                  return;
                                }

                                setModalState(() => _submitting = true);
                                try {
                                  await _addTransaction(_type, amt, _selectedDate.toIso8601String().split('T')[0], _descController.text.trim().isEmpty ? null : _descController.text.trim());
                                  Navigator.of(context).pop();
                                  await _refreshFinance();
                                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Transaction added')));
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}')));
                                } finally {
                                  // if still mounted update
                                  try { setModalState(() => _submitting = false); } catch (_) {}
                                }
                              },
                        child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101922),
      appBar: AppBar(
        backgroundColor: Color(0xFF101922),
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Column(
        children: [
          // Gradient Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF137FEC).withOpacity(0.2),
                  Color(0xFF1E3A8A).withOpacity(0.15),
                  Color(0xFF101922),
                ],
              ),
            ),
            padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      padding: EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Club Treasury',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white70),
                    onPressed: () => _showAddTransactionSheet(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      padding: EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _financeFuture,
              builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF137FEC)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _financeFuture = _fetchFinance();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF137FEC),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data ?? {};
          final records = data['records'] ?? [];
          final summary = data['summary'] ?? {};

          double totalIncome = 0;
          double totalExpense = 0;
          double balance = 0;

          if (summary.isNotEmpty) {
            var incomeValue = summary['totalIncome'] ?? 0;
            var expenseValue = summary['totalExpense'] ?? 0;
            totalIncome = incomeValue is String ? double.parse(incomeValue) : (incomeValue as num).toDouble();
            totalExpense = expenseValue is String ? double.parse(expenseValue) : (expenseValue as num).toDouble();
            balance = totalIncome - totalExpense;
          }

          // Get recent transactions (limit to 4)
          final recentTransactions = records.length > 4 ? records.sublist(0, 4) : records;

          return RefreshIndicator(
            color: const Color(0xFF137FEC),
            onRefresh: _refreshFinance,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Current Balance Card
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[800]!),
                      color: const Color(0xFF1E1E1E),
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Balance',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${balance.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Income and Expenses Cards
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[800]!),
                            color: const Color(0xFF1E1E1E),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Income',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${totalIncome.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[800]!),
                            color: const Color(0xFF1E1E1E),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expenses',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${totalExpense.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Cashflow Section
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[800]!),
                      color: const Color(0xFF1E1E1E),
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with period selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Cashflow',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() => _chartPeriod = 'month');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _chartPeriod == 'month' ? const Color(0xFF137FEC) : Colors.grey[800],
                                    minimumSize: const Size(60, 32),
                                  ),
                                  child: const Text('Month', style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() => _chartPeriod = 'year');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _chartPeriod == 'year' ? const Color(0xFF137FEC) : Colors.grey[800],
                                    minimumSize: const Size(60, 32),
                                  ),
                                  child: const Text('Year', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Net Profit
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Net Profit',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '\$${balance.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  balance > 0 ? '+${(balance / (totalIncome > 0 ? totalIncome : 1) * 100).toStringAsFixed(1)}%' : '0%',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: balance > 0 ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Chart representation (dynamic from records)
                        SizedBox(
                          height: 160,
                          child: Builder(builder: (context) {
                            final latest = _latestRecordDate(records);
                            final buckets = _chartPeriod == 'month'
                                ? _computeWeeklyData(records, latest)
                                : _computeMonthlyData(records, latest);
                            double maxVal = 1;
                            for (var b in buckets) {
                              maxVal = max(maxVal, b['income']!.abs());
                              maxVal = max(maxVal, b['expense']!.abs());
                            }
                            final monthLabels = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: List.generate(buckets.length, (i) {
                                final w = buckets[i];
                                double incomeH = max(0.0, (w['income']! / maxVal) * _chartMaxHeight);
                                double expenseH = max(0.0, (w['expense']! / maxVal) * _chartMaxHeight);
                                if (w['income']! > 0 && incomeH < 4) incomeH = 4;
                                if (w['expense']! > 0 && expenseH < 4) expenseH = 4;
                                final label = _chartPeriod == 'month'
                                    ? 'Wk ${i + 1}'
                                    : monthLabels[DateTime(latest.year, latest.month - (buckets.length - 1 - i)).month - 1];
                                return _buildBarChart(incomeH, expenseH, label);
                              }),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                      Expanded(
                        child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF137FEC),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size.fromHeight(96),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                          builder: (context) => FinancialReportGenerationScreen(token: widget.token, clubId: widget.clubId),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                          Icon(Icons.assessment, color: Colors.white, size: 28),
                          SizedBox(height: 8),
                          Text(
                            'Generate Report',
                            style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          ],
                        ),
                        ),
                      ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Recent Transactions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('View All', style: TextStyle(color: Color(0xFF137FEC))),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Dynamic Transaction items
                  if (recentTransactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No transactions yet',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: List.generate(
                        recentTransactions.length,
                        (index) {
                          final transaction = recentTransactions[index];
                          final isIncome = transaction['type'] == 'Income';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                final isInc = transaction['type'] == 'Income';
                                final amtRaw = transaction['amount'] ?? 0;
                                final amt = amtRaw is String ? double.tryParse(amtRaw) ?? 0.0 : (amtRaw as num).toDouble();
                                DateTime? dt;
                                try { dt = DateTime.parse((transaction['date'] ?? '').toString()).toLocal(); } catch (_) {}
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    backgroundColor: const Color(0xFF1E1E1E),
                                    title: const Text('Transaction Details', style: TextStyle(color: Colors.white)),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isInc ? const Color(0xFF137FEC).withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                              ),
                                              child: Icon(isInc ? Icons.trending_up : Icons.trending_down, color: isInc ? const Color(0xFF137FEC) : Colors.red, size: 18),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(transaction['description']?.toString() ?? '—', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                                  const SizedBox(height: 4),
                                                  Text(transaction['type']?.toString() ?? '', style: TextStyle(color: isInc ? Colors.green : Colors.red)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Amount', style: TextStyle(color: Colors.grey[400])),
                                            Text('${isInc ? '+' : '-'}\$${amt.toStringAsFixed(2)}', style: TextStyle(color: isInc ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Date', style: TextStyle(color: Colors.grey[400])),
                                            Text(dt != null ? dt.toString().split(' ').first : (transaction['date']?.toString() ?? '—'), style: const TextStyle(color: Colors.white)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Description', style: TextStyle(color: Colors.grey[400])),
                                            Expanded(child: Text(transaction['description']?.toString() ?? '—', textAlign: TextAlign.end, style: const TextStyle(color: Colors.white))),
                                          ],
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: _buildTransactionItem(
                                transaction['description'] ?? transaction['type'],
                                transaction['date'] ?? 'No date',
                                '${isIncome ? '+' : '-'}\$${transaction['amount']}',
                                isIncome ? Colors.green : Colors.red,
                                isIncome ? Icons.trending_up : Icons.trending_down,
                              ),
                            ),
                          );
                        },
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
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(double incomeHeight, double expenseHeight, String label) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Reserve space for label and spacing (approximately 20px)
        final availableHeight = constraints.maxHeight - 20;
        final totalBarHeight = incomeHeight + 4 + expenseHeight;
        
        // Scale bars if they exceed available space
        double scale = 1.0;
        if (totalBarHeight > availableHeight && availableHeight > 0) {
          scale = availableHeight / totalBarHeight;
        }
        
        final scaledIncomeHeight = incomeHeight * scale;
        final scaledExpenseHeight = expenseHeight * scale;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: scaledIncomeHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFF137FEC).withOpacity(0.2),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 30,
                    height: scaledExpenseHeight,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey[500],
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton(String label, IconData icon) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
        color: const Color(0xFF1E1E1E),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF137FEC), size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String title, String date, String amount, Color amountColor, IconData icon) {
    bool isIncome = amount.startsWith('+');
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
        color: const Color(0xFF1E1E1E),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isIncome
                  ? const Color(0xFF137FEC).withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
            ),
            child: Icon(
              icon,
              color: isIncome ? const Color(0xFF137FEC) : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
