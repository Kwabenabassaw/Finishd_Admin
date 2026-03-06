import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/core/admin_repository.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoReviewScreen extends StatefulWidget {
  const VideoReviewScreen({super.key});

  @override
  State<VideoReviewScreen> createState() => _VideoReviewScreenState();
}

class _VideoReviewScreenState extends State<VideoReviewScreen> {
  List<Map<String, dynamic>> _videos = [];
  bool _isLoading = false;

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
      final videos = await repository.getPendingVideos();
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

  Future<void> _rejectVideo(String videoId) async {
    try {
      await context.read<AdminRepository>().rejectVideo(
        videoId,
        'Violates guidelines',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Video Rejected')));
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

  void _playVideo(String url) {
    showDialog(
      context: context,
      builder: (context) => _VideoPlayerDialog(videoUrl: url),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Video Review Queue',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text('No videos pending review.'),
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
            'Video Review Queue (${_videos.length})',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                final video = _videos[index];
                final profile = video['profiles'] ?? {};
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (video['thumbnail_url'] != null)
                              Image.network(
                                video['thumbnail_url'],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: Colors.grey),
                              )
                            else
                              Container(
                                color: Colors.black,
                                child: const Icon(
                                  Icons.play_circle,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),

                            Center(
                              child: IconButton(
                                icon: const Icon(
                                  Icons.play_circle_fill,
                                  size: 48,
                                  color: Colors.white,
                                ),
                                onPressed: () => _playVideo(video['video_url']),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'by ${profile['username'] ?? 'Unknown'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  onPressed: () => _approveVideo(video['id']),
                                  tooltip: 'Approve',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _rejectVideo(video['id']),
                                  tooltip: 'Reject',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoPlayerController.value.aspectRatio,
    );

    if (mounted) setState(() {});
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
        child:
            _chewieController != null &&
                _videoPlayerController.value.isInitialized
            ? Chewie(controller: _chewieController!)
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
