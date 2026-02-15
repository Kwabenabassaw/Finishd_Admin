import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:finishd_admin/core/mock_data.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  late List<Map<String, dynamic>> _communities;

  @override
  void initState() {
    super.initState();
    // Mutable copy
    _communities = MockData.communities.map((c) => Map<String, dynamic>.from(c)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Communities Management',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DataTable2(
                   columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 800,
                  columns: const [
                    DataColumn2(label: Text('Community Name'), size: ColumnSize.L),
                    DataColumn(label: Text('Members')),
                    DataColumn(label: Text('Posts/Day')),
                    DataColumn(label: Text('Toxicity Score')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _communities.map((c) {
                    final toxicity = c['toxicity'] as int;
                    final isToxic = toxicity > 50;
                    return DataRow(
                      cells: [
                        DataCell(Text(c['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(c['members'].toString())),
                        DataCell(Text(c['posts_per_day'].toString())),
                        DataCell(
                          Row(
                            children: [
                              SizedBox(
                                width: 100,
                                child: LinearProgressIndicator(
                                  value: toxicity / 100,
                                  color: isToxic ? Colors.red : Colors.green,
                                  backgroundColor: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('$toxicity%'),
                            ],
                          ),
                        ),
                        DataCell(
                          Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                             decoration: BoxDecoration(
                               color: c['status'] == 'Flagged' ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                               borderRadius: BorderRadius.circular(12),
                             ),
                             child: Text(c['status'], style: TextStyle(color: c['status'] == 'Flagged' ? Colors.red : Colors.green)),
                          ),
                        ),
                        DataCell(
                           Switch(
                             value: c['status'] == 'Active',
                             onChanged: (val) {
                               setState(() {
                                 c['status'] = val ? 'Active' : 'Flagged';
                               });
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
