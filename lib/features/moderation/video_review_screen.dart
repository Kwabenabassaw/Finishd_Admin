import 'package:flutter/material.dart';

class VideoReviewScreen extends StatelessWidget {
  const VideoReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 64, color: Theme.of(context).disabledColor),
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
}
