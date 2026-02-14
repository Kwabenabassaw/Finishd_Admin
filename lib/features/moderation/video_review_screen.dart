import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:intl/intl.dart';

class VideoReviewScreen extends StatefulWidget {
  const VideoReviewScreen({super.key});

  @override
  State<VideoReviewScreen> createState() => _VideoReviewScreenState();
}

class _VideoReviewScreenState extends State<VideoReviewScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _videos = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingVideos();
  }

  Future<void> _fetchPendingVideos() async {
    try {
      final data = await _supabase
          .from('creator_videos')
          .select(
            '*, profiles!creator_videos_creator_id_fkey(username, avatar_url)',
          )
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _videos = List<Map<String, dynamic>>.from(data);
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

  Future<void> _updateStatus(
    String videoId,
    String newStatus, [
    String? reason,
  ]) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      await _supabase
          .from('creator_videos')
          .update({
            'status': newStatus,
            'reviewed_by': userId,
            'reviewed_at': DateTime.now().toIso8601String(),
            'rejection_reason': reason,
          })
          .eq('id', videoId);

      _fetchPendingVideos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video $newStatus'),
            backgroundColor: newStatus == 'approved'
                ? Colors.green
                : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }

  void _openReviewDialog(Map<String, dynamic> video) {
    showDialog(
      context: context,
      builder: (context) => _VideoReviewDialog(
        video: video,
        onApprove: () => _updateStatus(video['id'], 'approved'),
        onReject: (reason) => _updateStatus(video['id'], 'rejected', reason),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_videos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('All caught up! No pending videos.'),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending Videos (${_videos.length})',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              itemCount: _videos.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                childAspectRatio: 0.7, // Vertical video aspect
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final video = _videos[index];
                final profile = video['profiles'] ?? {};

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _openReviewDialog(video),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              video['thumbnail_url'] != null
                                  ? Image.network(
                                      video['thumbnail_url'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Container(color: Colors.grey),
                                    )
                                  : Container(color: Colors.black),
                              const Center(
                                child: Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white70,
                                  size: 48,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video['title'] ?? 'Untitled',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@${profile['username'] ?? 'unknown'}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (video['spoiler'] == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.red),
                                      ),
                                      child: const Text(
                                        'Spoiler',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoReviewDialog extends StatefulWidget {
  final Map<String, dynamic> video;
  final Future<void> Function() onApprove;
  final Future<void> Function(String) onReject;

  const _VideoReviewDialog({
    required this.video,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_VideoReviewDialog> createState() => _VideoReviewDialogState();
}

class _VideoReviewDialogState extends State<_VideoReviewDialog> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    String? videoUrl = widget.video['video_url'];
    if (videoUrl == null) return;

    // Check if it's a relative path (not starting with http)
    if (!videoUrl.startsWith('http')) {
      try {
        // Generate signed URL for private bucket
        videoUrl = await Supabase.instance.client.storage
            .from('creator-videos')
            .createSignedUrl(videoUrl, 60 * 60); // 1 hour expiry
      } catch (e) {
        debugPrint('Error generating signed URL: $e');
        return;
      }
    }

    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl!));

    try {
      await _videoController!.initialize();
      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: true,
        aspectRatio: _videoController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error playing video: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600),
        child: Row(
          children: [
            // Video Player Side
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.black,
                child:
                    _chewieController != null &&
                        _chewieController!
                            .videoPlayerController
                            .value
                            .isInitialized
                    ? Chewie(controller: _chewieController!)
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),

            // Details Side
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.video['title'] ?? 'Untitled',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Posted by @${widget.video['profiles']?['username'] ?? 'User'}',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Description:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.video['description'] ?? 'No description'),

                    const SizedBox(height: 16),
                    if (widget.video['tags'] != null) ...[
                      const Text(
                        'Tags:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: (widget.video['tags'] as List)
                            .map((t) => Chip(label: Text(t)))
                            .toList(),
                      ),
                    ],

                    const Spacer(),

                    const Divider(),
                    const Text(
                      'Actions',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showRejectDialog(context),
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () async {
                              await widget.onApprove();
                              if (mounted) Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Video'),
        content: TextField(
          controller: _reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'e.g. Inappropriate content, Low quality...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context); // Close reject dialog
              await widget.onReject(_reasonController.text);
              if (mounted) Navigator.of(context).pop(); // Close review dialog
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
