import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/core/admin_repository.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  String _searchQuery = '';
  int _currentPage = 1;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    // Defer fetch to next frame to ensure provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUsers();
    });
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final repository = context.read<AdminRepository>();
      final users = await repository.getUsers(
        page: _currentPage,
        limit: _pageSize,
        search: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading users: $e')));
      }
    }
  }

  Future<void> _banUser(String userId, bool isBanned) async {
    try {
      final repository = context.read<AdminRepository>();
      if (isBanned) {
        await repository.unbanUser(userId);
      } else {
        await repository.banUser(userId, 'Admin action');
      }
      await _fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isBanned ? 'User unbanned' : 'User banned')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating user: $e')));
      }
    }
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
                  onSubmitted: (value) {
                    setState(() {
                      _searchQuery = value;
                      _currentPage = 1;
                    });
                    _fetchUsers();
                  },
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () {
                  // Placeholder for add user
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          Expanded(
                            child: DataTable2(
                              columnSpacing: 12,
                              horizontalMargin: 12,
                              minWidth: 800,
                              columns: const [
                                DataColumn2(
                                  label: Text('User'),
                                  size: ColumnSize.L,
                                ),
                                DataColumn(label: Text('Role')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Reports')),
                                DataColumn(label: Text('Joined')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: _users.map((user) {
                                final isBanned =
                                    user['status'] == 'Banned' ||
                                    user['is_banned'] == true;

                                // Normalize status string
                                String status = user['status'] ?? 'Active';
                                if (user['is_banned'] == true)
                                  status = 'Banned';

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
                                            backgroundImage:
                                                user['avatar_url'] != null
                                                ? NetworkImage(
                                                    user['avatar_url'],
                                                  )
                                                : null,
                                            radius: 16,
                                            child: user['avatar_url'] == null
                                                ? Text(
                                                    (user['username'] ?? 'U')[0]
                                                        .toUpperCase(),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                user['username'] ?? 'Unknown',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                user['email'] ?? 'No Email',
                                                style:
                                                    theme.textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(user['role'] ?? 'user')),
                                    DataCell(_StatusBadge(status: status)),
                                    DataCell(
                                      Text(
                                        (user['report_count'] ?? 0).toString(),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        user['created_at']?.split('T')[0] ??
                                            '-',
                                      ),
                                    ),
                                    DataCell(
                                      PopupMenuButton(
                                        icon: const Icon(Icons.more_vert),
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'ban',
                                            child: Text(
                                              isBanned ? 'Unban' : 'Ban',
                                              style: TextStyle(
                                                color: isBanned
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) {
                                          if (value == 'ban') {
                                            _banUser(user['id'], isBanned);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                          // Simple Pagination Controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _currentPage > 1
                                    ? () {
                                        setState(() => _currentPage--);
                                        _fetchUsers();
                                      }
                                    : null,
                              ),
                              Text('Page $_currentPage'),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: _users.length == _pageSize
                                    ? () {
                                        setState(() => _currentPage++);
                                        _fetchUsers();
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ],
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
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
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
                      backgroundImage: user['avatar_url'] != null
                          ? NetworkImage(user['avatar_url'])
                          : null,
                      child: user['avatar_url'] == null
                          ? Text(
                              (user['username'] ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(fontSize: 24),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user['username'] ?? 'Unknown',
                      style: theme.textTheme.headlineSmall,
                    ),
                    Text(
                      user['email'] ?? 'No Email',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('Activity History'),
                      subtitle: const Text('Last active: -'), // Placeholder
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.gavel),
                      title: const Text('Moderation Log'),
                      subtitle: Text(
                        '${user['report_count'] ?? 0} reports filed against user',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.movie),
                      title: const Text('Watchlist'),
                      subtitle: const Text('- movies, - shows'), // Placeholder
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
