import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/core/admin_repository.dart';
import 'package:go_router/go_router.dart';

class CommunityPostsScreen extends StatefulWidget {
  final String communityId;
  const CommunityPostsScreen({super.key, required this.communityId});

  @override
  State<CommunityPostsScreen> createState() => _CommunityPostsScreenState();
}

class _CommunityPostsScreenState extends State<CommunityPostsScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPosts();
    });
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    try {
      final repository = context.read<AdminRepository>();
      final posts = await repository.getCommunityPosts(widget.communityId);
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading posts: $e')),
        );
      }
    }
  }

  Future<void> _toggleLock(String postId, bool isLocked) async {
    try {
      await context.read<AdminRepository>().lockCommunityPost(postId, !isLocked);
      _fetchPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error locking post: $e')),
        );
      }
    }
  }

  Future<void> _togglePin(String postId, bool isPinned) async {
    try {
      await context.read<AdminRepository>().pinCommunityPost(postId, !isPinned);
      _fetchPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error pinning post: $e')),
        );
      }
    }
  }

  Future<void> _toggleHide(String postId, bool isHidden) async {
    try {
      await context.read<AdminRepository>().hideCommunityPost(postId, !isHidden);
      _fetchPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error hiding post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Posts'),
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
                      : _posts.isEmpty
                          ? const Center(child: Text('No posts found for this community.'))
                          : DataTable2(
                              columnSpacing: 12,
                              horizontalMargin: 12,
                              minWidth: 1000,
                              columns: const [
                                DataColumn2(label: Text('Content'), size: ColumnSize.L),
                                DataColumn(label: Text('Author')),
                                DataColumn2(label: Text('Metrics'), size: ColumnSize.S),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Moderation')),
                                DataColumn(label: Text('Comments')),
                              ],
                              rows: _posts.map((post) {
                                final isLocked = post['is_locked'] == true;
                                final isPinned = post['pinned_at'] != null;
                                final isHidden = post['deleted_at'] != null;
                                final authorName = post['author']?['display_name'] ?? post['author']?['username'] ?? 'Unknown';

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        post['content']?.toString() ?? '(Media Only)',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DataCell(Text(authorName)),
                                    DataCell(
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Score: ${post['score']}'),
                                          Text('Views: ${post['view_count']}'),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Wrap(
                                        spacing: 4,
                                        children: [
                                          if (isLocked) const Chip(label: Text('Locked'), padding: EdgeInsets.all(0)),
                                          if (isPinned) const Chip(label: Text('Pinned'), padding: EdgeInsets.all(0)),
                                          if (isHidden) const Chip(label: Text('Hidden'), backgroundColor: Colors.redAccent, padding: EdgeInsets.all(0)),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            tooltip: isLocked ? 'Unlock' : 'Lock',
                                            icon: Icon(isLocked ? Icons.lock : Icons.lock_open),
                                            onPressed: () => _toggleLock(post['id'], isLocked),
                                          ),
                                          IconButton(
                                            tooltip: isPinned ? 'Unpin' : 'Pin',
                                            icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                                            onPressed: () => _togglePin(post['id'], isPinned),
                                          ),
                                          IconButton(
                                            tooltip: isHidden ? 'Restore' : 'Hide',
                                            icon: Icon(isHidden ? Icons.visibility : Icons.visibility_off),
                                            onPressed: () => _toggleHide(post['id'], isHidden),
                                            color: isHidden ? Colors.green : Colors.red,
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.comment),
                                        label: Text('${post['comment_count'] ?? 0}'),
                                        onPressed: () {
                                          context.go(
                                            '/communities/${widget.communityId}/posts/${post['id']}/comments',
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
      ),
    );
  }
}
