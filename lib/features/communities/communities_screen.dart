import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/core/admin_repository.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  List<Map<String, dynamic>> _communities = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCommunities();
    });
  }

  Future<void> _fetchCommunities() async {
    setState(() => _isLoading = true);
    try {
      final repository = context.read<AdminRepository>();
      final communities = await repository.getCommunities();
      if (mounted) {
        setState(() {
          _communities = communities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading communities: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await context.read<AdminRepository>().updateCommunityStatus(
        id,
        newStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
        _fetchCommunities();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
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
          Row(
            children: [
              Text(
                'Communities Management',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  // Add community logic
                },
                icon: const Icon(Icons.add),
                label: const Text('New Community'),
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
                    : _communities.isEmpty
                    ? const Center(child: Text('No communities found.'))
                    : DataTable2(
                        columnSpacing: 12,
                        horizontalMargin: 12,
                        minWidth: 800,
                        columns: const [
                          DataColumn2(
                            label: Text('Community Name'),
                            size: ColumnSize.L,
                          ),
                          DataColumn(label: Text('Members')), // Placeholder
                          DataColumn(label: Text('Posts/Day')), // Placeholder
                          DataColumn(
                            label: Text('Toxicity Score'),
                          ), // Placeholder/New Column
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _communities.map((c) {
                          final toxicity = (c['toxicity_score'] ?? 0) as num;
                          final isToxic = toxicity > 50;
                          final status = c['status'] ?? 'Active';
                          final isActive = status == 'Active';

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  c['name'] ?? 'Untitled',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text((c['member_count'] ?? '-').toString()),
                              ),
                              DataCell(
                                Text('-'),
                              ), // Posts per day not yet tracked
                              DataCell(
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 100,
                                      child: LinearProgressIndicator(
                                        value: toxicity / 100,
                                        color: isToxic
                                            ? Colors.red
                                            : Colors.green,
                                        backgroundColor: Colors.grey[300],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${toxicity.toStringAsFixed(0)}%'),
                                  ],
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Switch(
                                  value: isActive,
                                  onChanged: (val) {
                                    _updateStatus(
                                      c['id'],
                                      val ? 'Active' : 'Inactive',
                                    );
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
}
