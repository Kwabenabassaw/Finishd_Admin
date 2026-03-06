import 'package:flutter/material.dart';

class DeepLinksScreen extends StatelessWidget {
  const DeepLinksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link, size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          Text(
            'Deep Links Management',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage platform specific deep links and streaming availability.',
          ),
          const SizedBox(height: 24),
          const Chip(label: Text('Coming Soon')),
        ],
      ),
    );
  }
}
