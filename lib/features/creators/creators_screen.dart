import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:finishd_admin/core/mock_data.dart';
import 'package:finishd_admin/features/applications/applications_screen.dart';

class CreatorsScreen extends StatefulWidget {
  const CreatorsScreen({super.key});

  @override
  State<CreatorsScreen> createState() => _CreatorsScreenState();
}

class _CreatorsScreenState extends State<CreatorsScreen> with SingleTickerProviderStateMixin {
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
            children: const [
              _CreatorList(),
              ApplicationsScreen(),
            ],
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
  late List<Map<String, dynamic>> _creators;

  @override
  void initState() {
    super.initState();
    _creators = MockData.creators.where((c) => c['status'] == 'Approved').toList();
  }

  @override
  Widget build(BuildContext context) {
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
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(creator['avatar']),
                        ),
                        const SizedBox(width: 12),
                        Text(creator['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  DataCell(Text(creator['followers'].toString())),
                  DataCell(Text(creator['videos'].toString())),
                  DataCell(Text(creator['engagement'])),
                  DataCell(
                    IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
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
