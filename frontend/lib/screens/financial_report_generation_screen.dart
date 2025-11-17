import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FinancialReportGenerationScreen extends StatefulWidget {
  final String? token;
  final int? clubId;
  
  const FinancialReportGenerationScreen({Key? key, this.token, this.clubId}) : super(key: key);
  @override
  _FinancialReportGenerationScreenState createState() => _FinancialReportGenerationScreenState();
}

class _FinancialReportGenerationScreenState extends State<FinancialReportGenerationScreen> {
  String _reportType = 'Custom Range';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _filterIncome = true;
  bool _filterExpense = true;
  List<Map<String, dynamic>> _clubs = [];
  int? _selectedClubId;
  bool _loadingClubs = false;
  bool _generating = false;

  // generated report results
  double _genIncome = 0.0;
  double _genExpense = 0.0;
  double _genNet = 0.0;
  List<Map<String, dynamic>> _generatedRecords = [];
  String? _errorMessage;

  final String _apiBaseUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    _loadClubs();
    // default dates
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();
  }

  Future<void> _loadClubs() async {
    setState(() {
      _loadingClubs = true;
      _errorMessage = null;
    });
    try {
      final uri = Uri.parse('$_apiBaseUrl/api/clubs/list');
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List<dynamic>;
        final clubs = data.map((c) => Map<String, dynamic>.from(c as Map)).toList();
        setState(() {
          _clubs = clubs;
          if (widget.clubId != null && clubs.any((c) => c['club_id'] == widget.clubId)) {
            _selectedClubId = widget.clubId;
          } else if (clubs.isNotEmpty) {
            _selectedClubId = clubs[0]['club_id'] as int;
          }
        });
      } else {
        setState(() => _errorMessage = 'Failed to load clubs');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error loading clubs: $e');
    } finally {
      setState(() => _loadingClubs = false);
    }
  }

  Future<void> _generateReport() async {
    if (_selectedClubId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a club')));
      return;
    }
    setState(() {
      _generating = true;
      _errorMessage = null;
      _generatedRecords = [];
      _genIncome = 0.0;
      _genExpense = 0.0;
      _genNet = 0.0;
    });

    try {
      final uri = Uri.parse('$_apiBaseUrl/api/clubs/${_selectedClubId}/finance');
      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };
      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body);
        final records = List<Map<String, dynamic>>.from((body['records'] as List<dynamic>).map((r) => Map<String, dynamic>.from(r as Map)));

        // apply date range
        final start = _startDate ?? DateTime.now().subtract(const Duration(days: 30));
        final end = (_endDate ?? DateTime.now()).add(const Duration(hours: 23, minutes: 59, seconds: 59));
        final filtered = <Map<String, dynamic>>[];
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
            final type = (r['type'] ?? '').toString().toLowerCase();
            final isIncome = type.contains('income');
            if ((isIncome && _filterIncome) || (!isIncome && _filterExpense)) {
              filtered.add(r);
              if (isIncome) income += amt; else expense += amt;
            }
          } catch (_) {}
        }

        setState(() {
          _generatedRecords = filtered;
          _genIncome = income;
          _genExpense = expense;
          _genNet = income - expense;
        });
      } else {
        setState(() => _errorMessage = 'Failed to fetch finance records');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error generating report: $e');
    } finally {
      setState(() => _generating = false);
    }
  }

  String _generateCsvContent() {
    final sb = StringBuffer();
    // Header
    sb.writeln('date,type,description,amount');
    for (var r in _generatedRecords) {
      final date = (r['date'] ?? '').toString();
      final type = (r['type'] ?? '').toString().replaceAll(',', ' ');
      final desc = (r['description'] ?? r['desc'] ?? '').toString().replaceAll(',', ' ');
      final amtRaw = r['amount'] ?? 0;
      final amt = amtRaw is String ? double.tryParse(amtRaw) ?? 0.0 : (amtRaw as num).toDouble();
      sb.writeln('$date,$type,$desc,${amt.toStringAsFixed(2)}');
    }
    // Summary footer
    sb.writeln();
    sb.writeln('Income,${_genIncome.toStringAsFixed(2)}');
    sb.writeln('Expense,${_genExpense.toStringAsFixed(2)}');
    sb.writeln('Net,${_genNet.toStringAsFixed(2)}');
    return sb.toString();
  }

  Future<void> _exportCsv() async {
    if (_generatedRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No records to export')));
      return;
    }
    try {
      final csv = _generateCsvContent();
      final dir = await getApplicationDocumentsDirectory();
      final filename = 'financial_report_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv';
      final file = File('${dir.path}/$filename');
      await file.writeAsString(csv);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV saved: ${file.path}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save CSV: $e')));
    }
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
            color: const Color(0xFF192734),
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
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Configure Report Card
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                  color: const Color(0xFF192734),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configure Report',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Select Club
                    Text(
                      'Select Club',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[800]!),
                        color: const Color(0xFF101922),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _loadingClubs
                          ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(color: Color(0xFF137FEC))))
                          : DropdownButton<int>(
                              value: _selectedClubId,
                              isExpanded: true,
                              underline: const SizedBox(),
                              style: const TextStyle(color: Colors.white),
                              dropdownColor: const Color(0xFF192734),
                              items: _clubs.map((club) {
                                return DropdownMenuItem<int>(
                                  value: club['club_id'] as int,
                                  child: Text(club['name'] ?? 'Unnamed'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedClubId = value;
                                });
                              },
                            ),
                    ),

                    const SizedBox(height: 20),

                    // Report Type
                    Text(
                      'Report Type',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[800]!),
                        color: const Color(0xFF101922),
                      ),
                      child: Row(
                        children: [
                          _buildReportTypeButton('Monthly', 'Monthly'),
                          _buildReportTypeButton('Annual', 'Annual'),
                          _buildReportTypeButton('Custom', 'Custom Range'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Date Pickers
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Date',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setState(() => _startDate = picked);
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[800]!),
                                    color: const Color(0xFF101922),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  child: Text(
                                    _startDate?.toString().split(' ')[0] ?? 'DD/MM/YYYY',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'End Date',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setState(() => _endDate = picked);
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[800]!),
                                    color: const Color(0xFF101922),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  child: Text(
                                    _endDate?.toString().split(' ')[0] ?? 'DD/MM/YYYY',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Filter by
                    Text(
                      'Filter by',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildFilterChip('Income', _filterIncome, () {
                          setState(() => _filterIncome = !_filterIncome);
                        }),
                        const SizedBox(width: 12),
                        _buildFilterChip('Expense', _filterExpense, () {
                          setState(() => _filterExpense = !_filterExpense);
                        }),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Generate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _generating ? null : _generateReport,
                        icon: _generating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.summarize),
                        label: Text(_generating ? 'Generating...' : 'Generate Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF137FEC),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Report Summary Section
              Text(
                'Report Summary',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // Report Summary / Results
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                  color: const Color(0xFF192734),
                ),
                padding: const EdgeInsets.all(16.0),
                child: _errorMessage != null
                    ? Column(
                        children: [
                          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 8),
                          ElevatedButton(onPressed: _generateReport, child: const Text('Retry')),
                        ],
                      )
                    : _generatedRecords.isEmpty
                        ? SizedBox(
                            height: 200,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.ballot,
                                  size: 64,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Ready to Generate',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Configure your report options above and tap \'Generate\' to see the results.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: const Color(0xFF101922)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Income', style: TextStyle(color: Colors.grey[500])),
                                          const SizedBox(height: 8),
                                          Text('\$${_genIncome.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: const Color(0xFF101922)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Expenses', style: TextStyle(color: Colors.grey[500])),
                                          const SizedBox(height: 8),
                                          Text('\$${_genExpense.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: const Color(0xFF101922)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Net', style: TextStyle(color: Colors.grey[500])),
                                          const SizedBox(height: 8),
                                          Text('\$${_genNet.toStringAsFixed(2)}', style: TextStyle(color: _genNet >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Transactions', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ElevatedButton.icon(
                                    onPressed: _exportCsv,
                                    icon: const Icon(Icons.download, size: 16),
                                    label: const Text('Export CSV'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF137FEC),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Column(
                                children: List.generate(_generatedRecords.length, (i) {
                                  final r = _generatedRecords[i];
                                  final isIncome = (r['type'] ?? '').toString().toLowerCase().contains('income');
                                  return ListTile(
                                    tileColor: const Color(0xFF101922),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    title: Text(r['description'] ?? r['type'] ?? '', style: const TextStyle(color: Colors.white)),
                                    subtitle: Text(r['date'] ?? '', style: TextStyle(color: Colors.grey[500])),
                                    trailing: Text('${isIncome ? '+' : '-'}\$${r['amount']}', style: TextStyle(color: isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                                  );
                                }),
                              ),
                            ],
                          ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportTypeButton(String label, String value) {
    bool isSelected = _reportType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _reportType = value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF137FEC) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[500],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isChecked, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isChecked ? const Color(0xFF137FEC) : Colors.grey[800]!,
          ),
          color: isChecked
              ? const Color(0xFF137FEC).withOpacity(0.2)
              : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isChecked
                      ? const Color(0xFF137FEC)
                      : Colors.grey[700]!,
                ),
                color: isChecked ? const Color(0xFF137FEC) : Colors.transparent,
              ),
              child: isChecked
                  ? const Icon(Icons.check,
                      size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isChecked
                    ? const Color(0xFF137FEC)
                    : Colors.grey[500],
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
