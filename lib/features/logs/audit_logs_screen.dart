import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/core/admin_repository.dart';
import 'package:intl/intl.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await context.read<AdminRepository>().getAuditLogs();
      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading logs: $e')),
        );
      }
    }
  }

  Color _getActionColor(String action) {
    action = action.toLowerCase();
    if (action.contains('ban') || action.contains('reject') || action.contains('suspend')) {
      return Colors.redAccent.shade200;
    }
    if (action.contains('approve') || action.contains('unban') || action.contains('unsuspend')) {
      return Colors.greenAccent;
    }
    if (action.contains('delete') || action.contains('remove')) {
      return Colors.orangeAccent;
    }
    return Colors.blueAccent;
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
                'Audit Logs',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchLogs,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _logs.isEmpty
                        ? const Center(child: Text('No audit logs found.'))
                        : DataTable2(
                            columnSpacing: 12,
                            horizontalMargin: 12,
                            minWidth: 900,
                            columns: const [
                              DataColumn2(label: Text('Admin'), size: ColumnSize.L),
                              DataColumn2(label: Text('Action'), size: ColumnSize.S),
                              DataColumn2(label: Text('Target'), size: ColumnSize.M),
                              DataColumn2(label: Text('Reason'), size: ColumnSize.L),
                              DataColumn2(label: Text('Timestamp'), size: ColumnSize.M),
                            ],
                            rows: _logs.map((log) {
                              final adminName = log['admin_display_name'] ?? log['admin_username'] ?? 'System';
                              final action = log['action'] ?? 'Unknown';
                              final target = '${log['target_type']}: ${log['target_id'] ?? log['target_id_int'] ?? 'N/A'}';
                              final createdAt = DateTime.tryParse(log['created_at'] ?? '') ?? DateTime.now();
                              
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundImage: log['admin_avatar_url'] != null && log['admin_avatar_url'].toString().isNotEmpty
                                            ? NetworkImage(log['admin_avatar_url']) 
                                            : null,
                                          child: (log['admin_avatar_url'] == null || log['admin_avatar_url'].toString().isEmpty)
                                            ? const Icon(Icons.person, size: 14) 
                                            : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(adminName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getActionColor(action).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: _getActionColor(action).withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        action.toUpperCase(),
                                        style: TextStyle(
                                          color: _getActionColor(action),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(target, style: TextStyle(fontSize: 12, color: Colors.grey.shade400))),
                                  DataCell(
                                    Text(
                                      log['reason'] ?? '-',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      DateFormat('MMM d, yyyy • HH:mm').format(createdAt),
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
}
