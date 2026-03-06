import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/core/admin_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchReports();
    });
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final repository = context.read<AdminRepository>();
      final reports = await repository.getReports();
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading reports: $e')));
      }
    }
  }

  Future<void> _updateReportStatus(String reportId, String status) async {
    try {
      await context.read<AdminRepository>().resolveReport(
        reportId,
        status,
        'Updated via Admin Panel',
      );
      await _fetchReports();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Report marked as $status')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating report: $e')));
      }
    }
  }

  Future<void> _banUser(String userId, String reason, String reportId) async {
    try {
      await context.read<AdminRepository>().banUser(userId, reason);
      await context.read<AdminRepository>().resolveReport(
        reportId,
        'Resolved',
        'User banned: $reason',
      );
      await _fetchReports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User banned and report resolved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error banning user: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int pendingCount = _reports
        .where((r) => r['status'] == 'pending' || r['status'] == 'Pending')
        .length;

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
              if (pendingCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pendingCount Pending',
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
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _reports.isEmpty
                    ? const Center(child: Text('No reports found.'))
                    : DataTable2(
                        columnSpacing: 12,
                        horizontalMargin: 12,
                        minWidth: 800,
                        columns: const [
                          DataColumn2(label: Text('Type'), size: ColumnSize.S),
                          DataColumn(label: Text('Reason')),
                          DataColumn(
                            label: Text('Reported User'),
                          ), // Adjusted from Severity to Reported User for better utility
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _reports.map((report) {
                          final reportedUser = report['reported_user'] ?? {};
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(report['report_type'] ?? 'General'),
                              ), // Use report_type
                              DataCell(Text(report['reason'] ?? 'No reason')),
                              DataCell(
                                Text(reportedUser['username'] ?? 'Unknown'),
                              ),
                              DataCell(
                                Text(
                                  report['created_at']?.split('T')[0] ?? '-',
                                ),
                              ),
                              DataCell(Text(report['status'] ?? 'Pending')),
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
    );
  }

  void _showReportDetails(BuildContext context, Map<String, dynamic> report) {
    final reportedUser = report['reported_user'] ?? {};
    final reportedUserId = report['reported_user_id'];
    final reportId = report['id'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Details'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(
                label: 'Reported User',
                value: reportedUser['username'] ?? 'Unknown',
              ),
              _DetailRow(label: 'Reason', value: report['reason'] ?? '-'),
              _DetailRow(
                label: 'Date',
                value: report['created_at']?.split('T')[0] ?? '-',
              ),
              const Divider(),
              const Text(
                'Context:',
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
                  report['description'] ?? 'No description provided.',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _updateReportStatus(reportId, 'Resolved');
              Navigator.pop(context);
            },
            child: const Text('Mark Resolved'),
          ),
          TextButton(
            onPressed: () {
              _updateReportStatus(reportId, 'Dismissed');
              Navigator.pop(context);
            },
            child: const Text('Dismiss'),
          ),
          if (reportedUserId != null)
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                _banUser(
                  reportedUserId,
                  report['reason'] ?? 'Reported',
                  reportId,
                );
                Navigator.pop(context);
              },
              child: const Text('Ban User'),
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
            width: 120,
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
