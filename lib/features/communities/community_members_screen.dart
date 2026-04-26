import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/core/admin_repository.dart';
import 'package:go_router/go_router.dart';

class CommunityMembersScreen extends StatefulWidget {
  final String communityId;
  const CommunityMembersScreen({super.key, required this.communityId});

  @override
  State<CommunityMembersScreen> createState() => _CommunityMembersScreenState();
}

class _CommunityMembersScreenState extends State<CommunityMembersScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMembers();
    });
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    try {
      final repository = context.read<AdminRepository>();
      final members = await repository.getCommunityMembers(widget.communityId);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading members: $e')),
        );
      }
    }
  }

  Future<void> _updateRole(String userId, String newRole) async {
    try {
      await context.read<AdminRepository>().updateCommunityMemberRole(widget.communityId, userId, newRole);
      _fetchMembers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating role: $e')),
        );
      }
    }
  }

  Future<void> _removeMember(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text('Are you sure you want to remove this member from the community?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<AdminRepository>().removeCommunityMember(widget.communityId, userId);
        _fetchMembers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing member: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Members'),
        leading: BackButton(
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/communities');
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _members.isEmpty
                          ? const Center(child: Text('No members found.'))
                          : DataTable2(
                              columnSpacing: 12,
                              horizontalMargin: 12,
                              minWidth: 800,
                              columns: const [
                                DataColumn2(label: Text('User'), size: ColumnSize.L),
                                DataColumn(label: Text('Joined Timestamp')),
                                DataColumn(label: Text('Role')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: _members.map((member) {
                                final userStr = member['user']?['display_name'] ?? member['user']?['username'] ?? member['user_id'] ?? 'Unknown';
                                final role = member['role'] ?? 'member';

                                return DataRow(
                                  cells: [
                                    DataCell(Text(userStr)),
                                    DataCell(Text(member['joined_at']?.toString() ?? '')),
                                    DataCell(
                                      DropdownButton<String>(
                                        value: role,
                                        items: const [
                                          DropdownMenuItem(value: 'member', child: Text('Member')),
                                          DropdownMenuItem(value: 'moderator', child: Text('Moderator')),
                                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                        ],
                                        onChanged: (val) {
                                          if (val != null && val != role) {
                                            _updateRole(member['user_id'], val);
                                          }
                                        },
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        tooltip: 'Remove',
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                        onPressed: () => _removeMember(member['user_id']),
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
      ),
    );
  }
}
