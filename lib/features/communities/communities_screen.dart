import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/core/admin_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:finishd_admin/features/communities/widgets/community_form_dialog.dart';

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

  void _showEditDialog(BuildContext context, Map<String, dynamic> c) {
    showDialog(
      context: context,
      builder: (context) => CommunityFormDialog(
        initialData: c,
        onSubmit: (data) async {
          try {
            await context.read<AdminRepository>().updateCommunity(c['id'].toString(), data);
            _fetchCommunities();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
        },
      ),
    );
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
                  showDialog(
                    context: context,
                    builder: (context) => CommunityFormDialog(
                      onSubmit: (data) async {
                        try {
                          await context.read<AdminRepository>().createCommunity(data);
                          _fetchCommunities();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                    ),
                  );
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
                          DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                        ],
                        rows: _communities.map((c) {
                          final toxicity = (c['toxicity_score'] ?? 0) as num;
                          final isToxic = toxicity > 50;
                          final status = c['status']?.toString() ?? 'active';
                          final isActive = status.toLowerCase() == 'active';

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  c['title'] ?? 'Untitled',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text((c['member_count'] ?? '-').toString()),
                              ),
                              DataCell(
                                Text(
                                  c['posts_per_day'] != null
                                      ? (c['posts_per_day'] as num).toStringAsFixed(1)
                                      : '0.0',
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    Expanded(
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
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Transform.scale(
                                      scale: 0.8,
                                      child: Switch(
                                        value: isActive,
                                        onChanged: (val) {
                                          _updateStatus(
                                            c['id'].toString(),
                                            val ? 'active' : 'suspended',
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert_rounded, size: 20),
                                      splashRadius: 20,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_rounded, size: 16),
                                              SizedBox(width: 12),
                                              Text('Edit Details'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'members',
                                          child: Row(
                                            children: [
                                              Icon(Icons.people_alt_rounded, size: 16),
                                              SizedBox(width: 12),
                                              Text('Manage Members'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'posts',
                                          child: Row(
                                            children: [
                                              Icon(Icons.movie_filter_rounded, size: 16),
                                              SizedBox(width: 12),
                                              Text('View Posts'),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showEditDialog(context, c);
                                        } else if (value == 'members') {
                                          context.go('/communities/${c['id']}/members');
                                        } else if (value == 'posts') {
                                          context.go('/communities/${c['id']}/posts');
                                        }
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
          ),
        ],
      ),
    );
  }
}
