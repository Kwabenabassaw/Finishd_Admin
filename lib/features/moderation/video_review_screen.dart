import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/core/admin_repository.dart';
import 'package:finishd_admin/core/admin_badge_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:data_table_2/data_table_2.dart';

class VideoReviewScreen extends StatefulWidget {
  const VideoReviewScreen({super.key});

  @override
  State<VideoReviewScreen> createState() => _VideoReviewScreenState();
}

class _VideoReviewScreenState extends State<VideoReviewScreen> {
  List<Map<String, dynamic>> _videos = [];
  bool _isLoading = false;
  String _selectedStatus = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchVideos();
    });
  }

  Future<void> _fetchVideos() async {
    setState(() => _isLoading = true);
    try {
      final repository = context.read<AdminRepository>();
      final videos = await repository.getAllVideos();
      if (mounted) {
        setState(() {
          _videos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading videos: $e')));
      }
    }
  }

  Future<void> _approveVideo(String videoId) async {
    try {
      await context.read<AdminRepository>().approveVideo(videoId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Video Approved')));
        try {
          context.read<AdminBadgeProvider>().fetchCounts();
        } catch (_) {}
        _fetchVideos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error approving: $e')));
      }
    }
  }

  Future<void> _rejectVideoWithReason(String videoId, String reason) async {
    try {
      await context.read<AdminRepository>().rejectVideo(videoId, reason);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Video Rejected')));
        try {
          context.read<AdminBadgeProvider>().fetchCounts();
        } catch (_) {}
        _fetchVideos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error rejecting: $e')));
      }
    }
  }

  Future<void> _deleteVideo(String videoId) async {
    try {
      await context.read<AdminRepository>().deleteVideo(videoId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Video Deleted')));
        try {
          context.read<AdminBadgeProvider>().fetchCounts();
        } catch (_) {}
        _fetchVideos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  Future<void> _showRejectDialog(BuildContext context, String videoId) async {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Video'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Enter rejection reason...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final reason = reasonController.text.trim();
              Navigator.pop(dialogContext);
              await _rejectVideoWithReason(videoId, reason.isNotEmpty ? reason : 'Violates guidelines');
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteVideo(BuildContext context, String videoId) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Video'),
        content: const Text('Are you sure you want to delete this video? This action will set its status to removed and mark it deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deleteVideo(videoId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _playVideo(String url) async {
    String playableUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      try {
        playableUrl = await context.read<AdminRepository>().getSignedVideoUrl(url);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error generating signed URL: $e')),
          );
        }
        return;
      }
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => _VideoPlayerDialog(videoUrl: playableUrl),
      );
    }
  }

  Widget _buildStatusBadge(String status) {
    final statusLower = status.toLowerCase();
    final Color color;
    final Color textColor;

    switch (statusLower) {
      case 'approved':
        color = Colors.green.withValues(alpha: 0.12);
        textColor = Colors.green;
        break;
      case 'rejected':
        color = Colors.orange.withValues(alpha: 0.12);
        textColor = Colors.orange;
        break;
      case 'removed':
        color = Colors.red.withValues(alpha: 0.12);
        textColor = Colors.red;
        break;
      case 'pending':
      default:
        color = Colors.amber.withValues(alpha: 0.12);
        textColor = Colors.amber;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredVideos = _videos.where((video) {
      final status = (video['status'] ?? 'pending').toString().toLowerCase();
      final title = (video['title'] ?? '').toString().toLowerCase();
      final username = (video['profiles']?['username'] ?? '').toString().toLowerCase();

      if (_selectedStatus != 'All') {
        if (status != _selectedStatus.toLowerCase()) return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!title.contains(query) && !username.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Content Management',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by title or creator...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: ['All', 'Pending', 'Approved', 'Rejected', 'Removed'].map((status) {
              final isSelected = _selectedStatus == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(status),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedStatus = status;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredVideos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.video_library_outlined,
                                  size: 48,
                                  color: Theme.of(context).disabledColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No videos found',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          )
                        : DataTable2(
                            columnSpacing: 12,
                            horizontalMargin: 12,
                            minWidth: 900,
                            columns: const [
                              DataColumn2(label: Text('Video'), size: ColumnSize.L),
                              DataColumn2(label: Text('Status & Tags'), size: ColumnSize.M),
                              DataColumn(label: Text('Likes')),
                              DataColumn(label: Text('Comments')),
                              DataColumn(label: Text('Avg Play Time')),
                              DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                            ],
                            rows: filteredVideos.map((video) {
                              final profile = video['profiles'] ?? {};
                              final status = (video['status'] ?? 'pending').toString();
                              final tags = List<String>.from(video['tags'] ?? []);
                              final likes = video['like_count'] ?? 0;
                              final comments = video['comment_count'] ?? 0;
                              final views = video['view_count'] ?? 0;
                              final watchTime = video['total_watch_time_seconds'] ?? 0;
                              final avgPlayTime = views > 0 ? watchTime / views : 0.0;

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            final muxId = video['mux_playback_id']?.toString() ?? '';
                                            final rawUrl = video['video_url']?.toString() ?? '';
                                            final resolvedUrl = muxId.isNotEmpty
                                                ? 'https://stream.mux.com/$muxId.m3u8'
                                                : rawUrl;
                                            _playVideo(resolvedUrl);
                                          },
                                          child: MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: Container(
                                              width: 64,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: Colors.grey.shade800),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  if (video['thumbnail_url'] != null)
                                                    Image.network(
                                                      video['thumbnail_url'],
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => const Icon(
                                                        Icons.video_library,
                                                        color: Colors.grey,
                                                        size: 16,
                                                      ),
                                                    )
                                                  else
                                                    const Icon(
                                                      Icons.video_library,
                                                      color: Colors.grey,
                                                      size: 16,
                                                    ),
                                                  Container(
                                                    color: Colors.black.withValues(alpha: 0.3),
                                                    child: const Icon(
                                                      Icons.play_arrow,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                video['title'] ?? 'Untitled',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                '@${profile['username'] ?? 'unknown'}',
                                                style: Theme.of(context).textTheme.bodySmall,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildStatusBadge(status),
                                        if (tags.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              children: tags.map((t) => Padding(
                                                    padding: const EdgeInsets.only(right: 4),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withValues(alpha: 0.08),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        t,
                                                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                                                      ),
                                                    ),
                                                  )).toList(),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        const Icon(Icons.favorite, size: 16, color: Colors.redAccent),
                                        const SizedBox(width: 6),
                                        Text('$likes'),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        const Icon(Icons.comment, size: 16, color: Colors.blueAccent),
                                        const SizedBox(width: 6),
                                        Text('$comments'),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                                            const SizedBox(width: 6),
                                            Text('${avgPlayTime.toStringAsFixed(1)}s'),
                                          ],
                                        ),
                                        Text(
                                          '$views views',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: (value) async {
                                        if (value == 'play') {
                                          final muxId = video['mux_playback_id']?.toString() ?? '';
                                          final rawUrl = video['video_url']?.toString() ?? '';
                                          final resolvedUrl = muxId.isNotEmpty
                                              ? 'https://stream.mux.com/$muxId.m3u8'
                                              : rawUrl;
                                          _playVideo(resolvedUrl);
                                        } else if (value == 'approve') {
                                          await _approveVideo(video['id']);
                                        } else if (value == 'reject') {
                                          _showRejectDialog(context, video['id']);
                                        } else if (value == 'delete') {
                                          _confirmDeleteVideo(context, video['id']);
                                        }
                                      },
                                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(
                                          value: 'play',
                                          child: Row(
                                            children: [
                                              Icon(Icons.play_arrow, size: 18),
                                              SizedBox(width: 8),
                                              Text('Play Video'),
                                            ],
                                          ),
                                        ),
                                        if (status != 'approved')
                                          const PopupMenuItem<String>(
                                            value: 'approve',
                                            child: Row(
                                              children: [
                                                Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                                                SizedBox(width: 8),
                                                Text('Approve'),
                                              ],
                                            ),
                                          ),
                                        if (status != 'rejected')
                                          const PopupMenuItem<String>(
                                            value: 'reject',
                                            child: Row(
                                              children: [
                                                Icon(Icons.highlight_off, size: 18, color: Colors.orange),
                                                SizedBox(width: 8),
                                                Text('Reject'),
                                              ],
                                            ),
                                          ),
                                        if (status != 'removed')
                                          const PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Delete', style: TextStyle(color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                      ],
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

class _VideoPlayerDialog extends StatefulWidget {
  final String videoUrl;

  const _VideoPlayerDialog({required this.videoUrl});

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  String? _errorMessage;

  Future<void> _initializePlayer() async {
    debugPrint('Attempting to play video URL: ${widget.videoUrl}');
    if (widget.videoUrl.isEmpty) {
      setState(() => _errorMessage = 'Video URL is empty');
      return;
    }

    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        formatHint: widget.videoUrl.contains('.m3u8') ? VideoFormat.hls : VideoFormat.other,
      );
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load video: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        color: Colors.black,
        child: _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : _chewieController != null &&
                    _videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
