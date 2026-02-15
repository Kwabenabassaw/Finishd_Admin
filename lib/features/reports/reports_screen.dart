import 'package:flutter/material.dart';
import 'package:finishd_admin/core/mock_data.dart';
import 'package:data_table_2/data_table_2.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late List<Map<String, dynamic>> _reports;

  @override
  void initState() {
    super.initState();
    // Use mutable copy
    _reports = MockData.reports.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Moderation Queue',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_reports.where((r) => r['status'] == 'Pending').length} Pending',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // List of reports
                Expanded(
                  flex: 3,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DataTable2(
                        columnSpacing: 12,
                        horizontalMargin: 12,
                        minWidth: 600,
                        columns: const [
                          DataColumn2(label: Text('Type'), size: ColumnSize.S),
                          DataColumn(label: Text('Reason')),
                          DataColumn(label: Text('Severity')),
                          DataColumn(label: Text('Reported User')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _reports.map((report) {
                          return DataRow(
                            cells: [
                              DataCell(Text(report['type'])),
                              DataCell(Text(report['reason'])),
                              DataCell(_SeverityBadge(severity: report['severity'])),
                              DataCell(Text(report['reported_user'])),
                              DataCell(Text(report['date'].toString().split(' ')[0])),
                              DataCell(Text(report['status'])),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward),
                                  onPressed: () {
                                     _showReportDetails(context, report);
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDetails(BuildContext context, Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${report['type']} Report: ${report['reason']}'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Reported User', value: report['reported_user']),
              _DetailRow(label: 'Reporter', value: report['reporter']),
              _DetailRow(label: 'Date', value: report['date']),
              const Divider(),
              const Text('Content Preview:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(report['content'] ?? 'No content preview'),
              ),
              const SizedBox(height: 24),
              const Text('AI Analysis:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Chip(label: Text('Toxic (85%)'), backgroundColor: Colors.red),
                  SizedBox(width: 8),
                  Chip(label: Text('Hate Speech (92%)'), backgroundColor: Colors.red),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ignore'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
               // Ban logic mock
               setState(() {
                 report['status'] = 'Resolved (Banned)';
               });
               Navigator.pop(context);
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User Banned & Content Removed')));
            },
            child: const Text('Ban User & Remove'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;
  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (severity.toLowerCase()) {
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'low':
        color = Colors.yellow;
        break;
      default:
        color = Colors.grey;
    }
    return Text(severity, style: TextStyle(color: color, fontWeight: FontWeight.bold));
  }
}
