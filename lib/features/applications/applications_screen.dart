import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/core/admin_repository.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchApplications();
    });
  }

  Future<void> _fetchApplications() async {
    setState(() => _isLoading = true);
    try {
      final repository = context.read<AdminRepository>();
      final applications = await repository.getPendingApplications();
      if (mounted) {
        setState(() {
          _applications = applications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // debugPrint('Error loading applications: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading applications: $e')),
        );
      }
    }
  }

  Future<void> _approveApplication(String applicationId) async {
    try {
      await context.read<AdminRepository>().approveCreator(applicationId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Creator Approved')));
        _fetchApplications(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error approving: $e')));
      }
    }
  }

  Future<void> _rejectApplication(String applicationId) async {
    // Ideally user inputs a reason. We'll use a default for now or show dialog.
    // For simplicity:
    try {
      await context.read<AdminRepository>().rejectCreator(
        applicationId,
        'Does not meet criteria',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Creator Rejected')));
        _fetchApplications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error rejecting: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_applications.isEmpty) {
      return const Center(child: Text('No pending applications'));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DataTable2(
            columnSpacing: 12,
            horizontalMargin: 12,
            minWidth: 800,
            columns: const [
              DataColumn2(label: Text('Applicant'), size: ColumnSize.L),
              DataColumn(label: Text('Followers (Current)')),
              DataColumn(label: Text('Sample Videos')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _applications.map((app) {
              final metadata = app['metadata'] ?? {};
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: app['avatar_url'] != null
                              ? NetworkImage(app['avatar_url'])
                              : null,
                          child: app['avatar_url'] == null
                              ? Text((app['username'] ?? 'U')[0].toUpperCase())
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          app['username'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text((metadata['followers_count'] ?? '-').toString()),
                  ),
                  DataCell(Text((metadata['sample_videos'] ?? '-').toString())),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        app['status'] ?? 'Pending',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          tooltip: 'Approve',
                          onPressed: () => _approveApplication(app['id']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          tooltip: 'Reject',
                          onPressed: () => _rejectApplication(app['id']),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
