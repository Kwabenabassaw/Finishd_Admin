import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/core/admin_repository.dart';
import 'package:go_router/go_router.dart';

class PostCommentsScreen extends StatefulWidget {
  final String postId;
  const PostCommentsScreen({super.key, required this.postId});

  @override
  State<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends State<PostCommentsScreen> {
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchComments();
    });
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoading = true);
    try {
      final repository = context.read<AdminRepository>();
      final comments = await repository.getCommunityComments(widget.postId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading comments: $e')),
        );
      }
    }
  }

  Future<void> _toggleHide(String commentId, bool isHidden) async {
    try {
      await context.read<AdminRepository>().hideCommunityComment(commentId, !isHidden);
      _fetchComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error hiding comment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Comments'),
        leading: BackButton(
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              // Not the best fallback, but works if deep linked
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
                      : _comments.isEmpty
                          ? const Center(child: Text('No comments found for this post.'))
                          : DataTable2(
                              columnSpacing: 12,
                              horizontalMargin: 12,
                              minWidth: 800,
                              columns: const [
                                DataColumn2(label: Text('Comment'), size: ColumnSize.L),
                                DataColumn(label: Text('Author')),
                                DataColumn(label: Text('Votes (Up/Down)')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: _comments.map((comment) {
                                final isHidden = comment['deleted_at'] != null;
                                final authorName = comment['author']?['display_name'] ?? comment['author']?['username'] ?? 'Unknown';

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        comment['content']?.toString() ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DataCell(Text(authorName)),
                                    DataCell(
                                      Text('${comment['upvotes']} / ${comment['downvotes']}'),
                                    ),
                                    DataCell(
                                      isHidden
                                          ? const Chip(label: Text('Hidden'), backgroundColor: Colors.redAccent)
                                          : const Text('Visible'),
                                    ),
                                    DataCell(
                                      IconButton(
                                        tooltip: isHidden ? 'Restore' : 'Hide',
                                        icon: Icon(isHidden ? Icons.visibility : Icons.visibility_off),
                                        onPressed: () => _toggleHide(comment['id'], isHidden),
                                        color: isHidden ? Colors.green : Colors.red,
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
