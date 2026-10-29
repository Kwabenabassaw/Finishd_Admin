import 'dart:math';
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

    if (confirm != true || !mounted) return;

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

  void _showAddUserDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AddUserDialog(
        onUserCreated: _fetchUsers,
      ),
    );
  }

  void _showChangeRoleDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => _ChangeRoleDialog(
        user: user,
        onRoleChanged: _fetchUsers,
      ),
    );
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
                onPressed: _showAddUserDialog,
                icon: const Icon(Icons.person_add_rounded, size: 18),
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
                                          Expanded(
                                            child: Column(
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
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                                Text(
                                                  user['email'] ?? 'No Email',
                                                  style:
                                                      theme.textTheme.bodySmall,
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(_RoleBadge(role: user['role'] ?? 'user')),
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
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_horiz_rounded, size: 20),
                                        splashRadius: 20,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        itemBuilder: (context) => <PopupMenuEntry<String>>[
                                          PopupMenuItem<String>(
                                            value: 'role',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.manage_accounts_outlined,
                                                  size: 18,
                                                  color: theme.colorScheme.primary,
                                                ),
                                                const SizedBox(width: 10),
                                                const Text(
                                                  'Change Role',
                                                  style: TextStyle(fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuDivider(),
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
                                          if (value == 'role') {
                                            _showChangeRoleDialog(user);
                                          } else if (value == 'ban') {
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
      builder: (context) => _UserDetailSheet(
        user: user,
        onRoleChangeRequested: () => _showChangeRoleDialog(user),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (role.toLowerCase()) {
      case 'admin':
        color = const Color(0xFF8B5CF6);
        icon = Icons.shield_rounded;
        label = 'Admin';
        break;
      case 'reviewer':
        color = const Color(0xFF0EA5E9);
        icon = Icons.verified_user_rounded;
        label = 'Reviewer';
        break;
      case 'creator':
        color = const Color(0xFFF59E0B);
        icon = Icons.video_collection_rounded;
        label = 'Creator';
        break;
      case 'user':
      default:
        color = const Color(0xFF64748B);
        icon = Icons.person_rounded;
        label = 'User';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
  final VoidCallback onRoleChangeRequested;

  const _UserDetailSheet({
    required this.user,
    required this.onRoleChangeRequested,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = user['status'] ?? (user['is_banned'] == true ? 'Banned' : 'Active');
    final role = user['role'] ?? 'user';

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Material(
          color: theme.colorScheme.surface,
          elevation: 20,
          shadowColor: Colors.black54,
          child: SizedBox(
            width: 420,
            height: double.infinity,
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user['email'] ?? 'No Email',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _RoleBadge(role: role),
                            _StatusBadge(status: status),
                          ],
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onRoleChangeRequested();
                          },
                          icon: const Icon(Icons.manage_accounts_outlined, size: 16),
                          label: const Text('Change Role'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.history),
                          title: const Text('Activity History'),
                          subtitle: const Text('Last active: -'),
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
                          subtitle: const Text('- movies, - shows'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add User Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _AddUserDialog extends StatefulWidget {
  final VoidCallback onUserCreated;
  const _AddUserDialog({required this.onUserCreated});

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  String _selectedRole = 'user';
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const List<Map<String, dynamic>> _roleOptions = [
    {
      'role': 'user',
      'label': 'User',
      'desc': 'Standard consumer. Can watch videos, react, and participate in communities.',
      'icon': Icons.person_rounded,
      'color': Color(0xFF64748B),
    },
    {
      'role': 'creator',
      'label': 'Creator',
      'desc': 'Verified creator. Can upload videos, view creator analytics, and manage profile.',
      'icon': Icons.video_collection_rounded,
      'color': Color(0xFFF59E0B),
    },
    {
      'role': 'reviewer',
      'label': 'Reviewer',
      'desc': 'Content moderator. Can review pending videos and triage reports.',
      'icon': Icons.verified_user_rounded,
      'color': Color(0xFF0EA5E9),
    },
    {
      'role': 'admin',
      'label': 'Admin',
      'desc': 'Full platform administration. Has unrestricted access to all data and settings.',
      'icon': Icons.shield_rounded,
      'color': Color(0xFF8B5CF6),
    },
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789!@#%*';
    final rand = Random.secure();
    final pass = List.generate(12, (_) => chars[rand.nextInt(chars.length)]).join();
    setState(() {
      _passwordController.text = pass;
      _obscurePassword = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repository = context.read<AdminRepository>();
      await repository.createUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
        role: _selectedRole,
        firstName: _firstNameController.text.trim().isNotEmpty ? _firstNameController.text.trim() : null,
        lastName: _lastNameController.text.trim().isNotEmpty ? _lastNameController.text.trim() : null,
        emailConfirm: true,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onUserCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text(
              'User @${_usernameController.text.trim()} created successfully with role "$_selectedRole"',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.person_add_rounded, color: theme.colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New User',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Create a platform account and assign their authorization role',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Error banner if any
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Form fields
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username & Email
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Username *', style: theme.textTheme.labelMedium),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _usernameController,
                                    decoration: InputDecoration(
                                      prefixText: '@',
                                      hintText: 'alex_doe',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Username is required';
                                      }
                                      if (val.trim().length < 3) {
                                        return 'Min 3 characters';
                                      }
                                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(val.trim())) {
                                        return 'Letters, numbers, underscores only';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Email Address *', style: theme.textTheme.labelMedium),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.email_outlined, size: 18),
                                      hintText: 'alex@example.com',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Email is required';
                                      }
                                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val.trim())) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Password with Generator
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Initial Password *', style: theme.textTheme.labelMedium),
                                TextButton.icon(
                                  onPressed: _generatePassword,
                                  icon: const Icon(Icons.autorenew_rounded, size: 14),
                                  label: const Text('Generate Random', style: TextStyle(fontSize: 12)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    size: 18,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                hintText: 'At least 6 characters',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Password is required';
                                }
                                if (val.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // First and Last Name
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('First Name (Optional)', style: theme.textTheme.labelMedium),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _firstNameController,
                                    decoration: InputDecoration(
                                      hintText: 'Alex',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Last Name (Optional)', style: theme.textTheme.labelMedium),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _lastNameController,
                                    decoration: InputDecoration(
                                      hintText: 'Doe',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Role Selection
                        Text(
                          'Assign Role *',
                          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: _roleOptions.map((opt) {
                            final role = opt['role'] as String;
                            final isSelected = _selectedRole == role;
                            final color = opt['color'] as Color;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                color: isSelected
                                    ? theme.colorScheme.primary.withValues(alpha: 0.04)
                                    : theme.colorScheme.surface,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => setState(() => _selectedRole = role),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 18,
                                        height: 18,
                                        margin: const EdgeInsets.only(top: 2, right: 8),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                                            width: isSelected ? 5 : 1.5,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(opt['icon'] as IconData, size: 18, color: color),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              opt['label'] as String,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isSelected ? theme.colorScheme.primary : null,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              opt['desc'] as String,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(_isSubmitting ? 'Creating...' : 'Create User'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Change Role Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _ChangeRoleDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onRoleChanged;

  const _ChangeRoleDialog({
    required this.user,
    required this.onRoleChanged,
  });

  @override
  State<_ChangeRoleDialog> createState() => _ChangeRoleDialogState();
}

class _ChangeRoleDialogState extends State<_ChangeRoleDialog> {
  late String _selectedRole;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const List<Map<String, dynamic>> _roles = [
    {
      'role': 'user',
      'label': 'User',
      'desc': 'Standard consumer. Standard permissions.',
      'icon': Icons.person_rounded,
      'color': Color(0xFF64748B),
    },
    {
      'role': 'creator',
      'label': 'Creator',
      'desc': 'Verified creator. Video uploading, analytics, and creator dashboard.',
      'icon': Icons.video_collection_rounded,
      'color': Color(0xFFF59E0B),
    },
    {
      'role': 'reviewer',
      'label': 'Reviewer',
      'desc': 'Content moderator. Video review, queue management, and report handling.',
      'icon': Icons.verified_user_rounded,
      'color': Color(0xFF0EA5E9),
    },
    {
      'role': 'admin',
      'label': 'Admin',
      'desc': 'Full administrative access across all sections, users, and platform settings.',
      'icon': Icons.shield_rounded,
      'color': Color(0xFF8B5CF6),
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedRole = (widget.user['role'] as String?)?.toLowerCase() ?? 'user';
  }

  Future<void> _submit() async {
    final currentRole = (widget.user['role'] as String?)?.toLowerCase() ?? 'user';
    if (_selectedRole == currentRole) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repository = context.read<AdminRepository>();
      await repository.updateUserRole(widget.user['id'], _selectedRole);

      if (mounted) {
        Navigator.pop(context);
        widget.onRoleChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text(
              'Role for @${widget.user['username'] ?? 'user'} updated to "$_selectedRole"',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final username = widget.user['username'] ?? 'User';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.manage_accounts_rounded, color: theme.colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change Role',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Updating role for @$username',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Role Options
              ..._roles.map((opt) {
                final role = opt['role'] as String;
                final isSelected = _selectedRole == role;
                final color = opt['color'] as Color;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                      width: isSelected ? 1.5 : 1,
                    ),
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.04)
                        : theme.colorScheme.surface,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _selectedRole = role),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                                width: isSelected ? 5 : 1.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(opt['icon'] as IconData, size: 18, color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt['label'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? theme.colorScheme.primary : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  opt['desc'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              if (_selectedRole == 'admin') ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Caution: Admins have unrestricted access to all data, moderation, analytics, and platform settings.',
                          style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(_isSubmitting ? 'Saving...' : 'Save Role'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
