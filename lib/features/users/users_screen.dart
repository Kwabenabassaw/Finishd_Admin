import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:finishd_admin/core/mock_data.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  // Use mock data - Deep copy to allow modification
  late List<Map<String, dynamic>> _users;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _users = MockData.users.map((u) => Map<String, dynamic>.from(u)).toList();
  }

  // Filtering logic
  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      final username = user['username'].toString().toLowerCase();
      final email = user['email'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return username.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'User Management',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Search Bar
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search users...',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () {
                   // Add user logic
                },
                icon: const Icon(Icons.add),
                label: const Text('Add User'),
              ),
            ],
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
                    DataColumn2(label: Text('User'), size: ColumnSize.L),
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Reports')),
                    DataColumn(label: Text('Joined')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _filteredUsers.map((user) {
                    return DataRow(
                      onSelectChanged: (selected) {
                        if (selected == true) {
                          _showUserDetails(context, user);
                        }
                      },
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(user['avatar']),
                                radius: 16,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(user['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(user['email'], style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(user['role'])),
                        DataCell(_StatusBadge(status: user['status'])),
                        DataCell(Text(user['reports'].toString())),
                        DataCell(Text(user['join_date'])),
                        DataCell(
                          PopupMenuButton(
                            icon: const Icon(Icons.more_vert),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'ban',
                                child: Text(
                                  user['status'] == 'Banned' ? 'Unban' : 'Ban',
                                  style: TextStyle(
                                    color: user['status'] == 'Banned' ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'ban') {
                                setState(() {
                                   if (user['status'] == 'Banned') {
                                     user['status'] = 'Active';
                                   } else {
                                     user['status'] = 'Banned';
                                   }
                                });
                              }
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

  void _showUserDetails(BuildContext context, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UserDetailSheet(user: user),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        break;
      case 'banned':
        color = Colors.red;
        break;
      case 'shadowbanned':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _UserDetailSheet extends StatelessWidget {
  final Map<String, dynamic> user;

  const _UserDetailSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 400,
          height: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black54)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBar(
                title: const Text('User Profile'),
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(user['avatar']),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user['username'],
                      style: theme.textTheme.headlineSmall,
                    ),
                    Text(
                      user['email'],
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('Activity History'),
                      subtitle: const Text('Last active: 2 hours ago'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                     ListTile(
                      leading: const Icon(Icons.gavel),
                      title: const Text('Moderation Log'),
                      subtitle: Text('${user['reports']} reports filed against user'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                     ListTile(
                      leading: const Icon(Icons.movie),
                      title: const Text('Watchlist'),
                      subtitle: const Text('45 movies, 12 shows'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
