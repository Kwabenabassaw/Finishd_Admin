import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  final VoidCallback onMenuTap;
  final bool isMobile;

  const TopBar({super.key, required this.onMenuTap, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenuTap,
            ),

          // Search Bar
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search anything...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  fillColor: theme.colorScheme.surface, // Match background for minimal look
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),

          // Actions
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
          ),
          const SizedBox(width: 16),

          // Profile
          Container(
            height: 32,
            width: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey,
            ),
            child: const Icon(Icons.person, size: 20, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
