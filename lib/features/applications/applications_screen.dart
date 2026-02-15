import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:finishd_admin/core/mock_data.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  late List<Map<String, dynamic>> _applications;

  @override
  void initState() {
    super.initState();
    // In a real app, we would fetch from Supabase.
    // For this design implementation, we use mock data.
    _applications = MockData.creators.where((c) => c['status'] == 'Pending').toList();
  }

  @override
  Widget build(BuildContext context) {
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
              return DataRow(
                cells: [
                   DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(app['avatar']),
                        ),
                        const SizedBox(width: 12),
                        Text(app['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  DataCell(Text(app['followers'].toString())),
                  DataCell(Text(app['videos'].toString())),
                  DataCell(
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                        ),
                        child: Text(app['status'], style: const TextStyle(color: Colors.orange, fontSize: 12)),
                      ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          tooltip: 'Approve',
                          onPressed: () {
                            setState(() {
                              _applications.remove(app);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Creator Approved')));
                          },
                        ),
                         IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          tooltip: 'Reject',
                          onPressed: () {
                             setState(() {
                              _applications.remove(app);
                            });
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Creator Rejected')));
                          },
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
