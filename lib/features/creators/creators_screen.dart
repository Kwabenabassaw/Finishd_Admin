import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/core/admin_repository.dart';
import 'package:finishd_admin/features/applications/applications_screen.dart';

class CreatorsScreen extends StatefulWidget {
  const CreatorsScreen({super.key});

  @override
  State<CreatorsScreen> createState() => _CreatorsScreenState();
}

class _CreatorsScreenState extends State<CreatorsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Approved Creators'),
              Tab(text: 'Applications'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [_CreatorList(), ApplicationsScreen()],
          ),
        ),
      ],
    );
  }
}

class _CreatorList extends StatefulWidget {
  const _CreatorList();

  @override
  State<_CreatorList> createState() => _CreatorListState();
}

class _CreatorListState extends State<_CreatorList> {
  List<Map<String, dynamic>> _creators = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Defer fetch to ensure provider context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCreators();
    });
  }

  Future<void> _fetchCreators() async {
    setState(() => _isLoading = true);
    try {
      final repository = context.read<AdminRepository>();
      final creators = await repository.getApprovedCreators();
      if (mounted) {
        setState(() {
          _creators = creators;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Silently fail or show simple error?
        debugPrint('Error loading creators: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_creators.isEmpty) {
      return const Center(child: Text('No approved creators yet.'));
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
              DataColumn2(label: Text('Creator'), size: ColumnSize.L),
              DataColumn(label: Text('Followers')),
              DataColumn(label: Text('Videos')),
              DataColumn(label: Text('Engagement')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _creators.map((creator) {
              final stats = creator['stats'] ?? {};
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: creator['avatar_url'] != null
                              ? NetworkImage(creator['avatar_url'])
                              : null,
                          child: creator['avatar_url'] == null
                              ? Text(
                                  (creator['username'] ?? 'U')[0].toUpperCase(),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          creator['username'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text((stats['followers'] ?? 0).toString())),
                  DataCell(Text((stats['videos'] ?? 0).toString())),
                  DataCell(Text((stats['engagement'] ?? 0).toString())),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        // Implement dropdown for creator actions (e.g. view details, ban)
                      },
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
