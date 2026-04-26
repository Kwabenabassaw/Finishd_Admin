import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/core/admin_repository.dart';

class UserReportsScreen extends StatefulWidget {
  const UserReportsScreen({super.key});

  @override
  State<UserReportsScreen> createState() => _UserReportsScreenState();
}

class _UserReportsScreenState extends State<UserReportsScreen> {
  List<Map<String, dynamic>> _submissions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSubmissions();
    });
  }

  Future<void> _fetchSubmissions() async {
    setState(() => _isLoading = true);
    try {
      final repository = context.read<AdminRepository>();
      final submissions = await repository.getDeletionSubmissions();
      if (mounted) {
        setState(() {
          _submissions = submissions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading submissions: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Deletion Requests & User Reports',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _submissions.isEmpty
                        ? const Center(child: Text('No requests found.'))
                        : DataTable2(
                            columnSpacing: 12,
                            horizontalMargin: 12,
                            minWidth: 800,
                            columns: const [
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Subject')),
                              DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                            ],
                            rows: _submissions.map((sub) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(sub['created_at']?.split('T')[0] ?? '-')),
                                  DataCell(Text(sub['name'] ?? 'Unknown')),
                                  DataCell(Text(sub['email'] ?? 'No email')),
                                  DataCell(Text(sub['subject'] ?? 'No subject')),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.arrow_forward),
                                      tooltip: 'View Details',
                                      onPressed: () {
                                        _showSubmissionDetails(context, sub);
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
    );
  }

  void _showSubmissionDetails(BuildContext context, Map<String, dynamic> sub) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submission Details'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Name', value: sub['name'] ?? 'Unknown'),
              _DetailRow(label: 'Email', value: sub['email'] ?? '-'),
              _DetailRow(label: 'Subject', value: sub['subject'] ?? '-'),
              _DetailRow(
                label: 'Date',
                value: sub['created_at']?.split('T')[0] ?? '-',
              ),
              const Divider(),
              const Text(
                'Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sub['message'] ?? 'No message provided.',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
