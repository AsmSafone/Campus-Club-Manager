import 'package:flutter/material.dart';

class FinancialReportGenerationScreen extends StatefulWidget {
  @override
  _FinancialReportGenerationScreenState createState() => _FinancialReportGenerationScreenState();
}

class _FinancialReportGenerationScreenState extends State<FinancialReportGenerationScreen> {
  String _selectedClub = 'Knitting Club';
  String _reportType = 'Custom Range';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _filterIncome = true;
  bool _filterExpense = true;

  final List<String> _clubs = ['Knitting Club', 'Debate Society', 'Robotics Team'];

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
                      child: DropdownButton<String>(
                        value: _selectedClub,
                        isExpanded: true,
                        underline: const SizedBox(),
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: const Color(0xFF192734),
                        items: _clubs.map((club) {
                          return DropdownMenuItem(
                            value: club,
                            child: Text(club),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedClub = value!;
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
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Report generated')),
                          );
                        },
                        icon: const Icon(Icons.summarize),
                        label: const Text('Generate Report'),
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

              // Empty State
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                  color: const Color(0xFF192734),
                ),
                padding: const EdgeInsets.all(40.0),
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
