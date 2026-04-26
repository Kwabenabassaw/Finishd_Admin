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

  Future<void> _suspendUser(String userId, bool isCurrentlySuspended) async {
    try {
      final repository = context.read<AdminRepository>();
      await repository.updateUserStatus(userId, 'suspend', !isCurrentlySuspended);
      await _fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isCurrentlySuspended ? 'User unsuspended' : 'User suspended for 7 days')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _shadowbanUser(String userId, bool isCurrentlyShadowbanned) async {
    try {
      final repository = context.read<AdminRepository>();
      await repository.updateUserStatus(userId, 'shadowban', !isCurrentlyShadowbanned);
      await _fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isCurrentlyShadowbanned ? 'Shadowban removed' : 'User shadowbanned')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to permanently delete this user? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repository = context.read<AdminRepository>();
      await repository.deleteUser(userId);
      await _fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User account permanently deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
              // Search Bar (Shadcn style)
              SizedBox(
                width: 300,
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      filled: true,
                      fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                      ),
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
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () {
                  // Placeholder for add user
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add User'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Expanded(
                          child: DataTable2(
                            columnSpacing: 16,
                            horizontalMargin: 24,
                            minWidth: 800,
                            headingRowHeight: 48,
                            dataRowHeight: 56,
                            headingRowColor: WidgetStatePropertyAll(
                              theme.colorScheme.onSurface.withValues(alpha: 0.02)
                            ),
                            headingTextStyle: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                            columns: const [
                              DataColumn2(
                                label: Text('User'),
                                size: ColumnSize.L,
                              ),
                              DataColumn(label: Text('Role')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Reports')),
                              DataColumn(label: Text('Joined')),
                              DataColumn(label: Text(''), numeric: true), // Actions
                            ],
                              rows: _users.map((user) {
                                final isBanned =
                                    user['status'] == 'Banned' ||
                                    user['is_banned'] == true;
                                final isSuspended = user['status'] == 'Suspended';
                                final isShadowbanned = user['status'] == 'Shadowbanned';

                                // Normalize status string
                                String status = user['status'] ?? 'Active';
                                if (user['is_banned'] == true) {
                                  status = 'Banned';
                                }

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
                                                user['avatar_url'] != null && user['avatar_url'].toString().isNotEmpty
                                                ? NetworkImage(
                                                    user['avatar_url'].toString(),
                                                  )
                                                : null,
                                            radius: 16,
                                            child: (user['avatar_url'] == null || user['avatar_url'].toString().isEmpty)
                                                ? Text(
                                                    (user['username']?.toString().isNotEmpty == true)
                                                        ? user['username'].toString()[0].toUpperCase()
                                                        : 'U',
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
                                        icon: const Icon(Icons.more_horiz_rounded, size: 20),
                                        splashRadius: 20,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'ban',
                                            child: Text(
                                              isBanned ? 'Unban User' : 'Ban User',
                                              style: TextStyle(
                                                color: isBanned
                                                    ? Colors.green.shade600
                                                    : Colors.red.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'suspend',
                                            child: Text(
                                              isSuspended ? 'Unsuspend User' : 'Suspend User (7 Days)',
                                              style: TextStyle(color: isSuspended ? Colors.green.shade600 : Colors.orange.shade700),
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'shadowban',
                                            child: Text(
                                              isShadowbanned ? 'Remove Shadowban' : 'Shadowban User',
                                              style: TextStyle(color: isShadowbanned ? Colors.green.shade600 : Colors.blueGrey),
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text(
                                              'Delete User',
                                              style: TextStyle(color: Colors.red.shade900),
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) {
                                          if (value == 'ban') {
                                            _banUser(user['id'], isBanned);
                                          } else if (value == 'suspend') {
                                            _suspendUser(user['id'], isSuspended);
                                          } else if (value == 'shadowban') {
                                            _shadowbanUser(user['id'], isShadowbanned);
                                          } else if (value == 'delete') {
                                            _deleteUser(user['id']);
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Showing page $_currentPage',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Row(
                                  children: [
                                    OutlinedButton(
                                      onPressed: _currentPage > 1
                                          ? () {
                                              setState(() => _currentPage--);
                                              _fetchUsers();
                                            }
                                          : null,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      child: const Text('Previous'),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: _users.length == _pageSize
                                          ? () {
                                              setState(() => _currentPage++);
                                              _fetchUsers();
                                            }
                                          : null,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      child: const Text('Next'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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
                      backgroundImage: user['avatar_url'] != null && user['avatar_url'].toString().isNotEmpty
                          ? NetworkImage(user['avatar_url'].toString())
                          : null,
                      child: (user['avatar_url'] == null || user['avatar_url'].toString().isEmpty)
                          ? Text(
                              (user['username']?.toString().isNotEmpty == true)
                                  ? user['username'].toString()[0].toUpperCase()
                                  : 'U',
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
