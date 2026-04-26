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
          bottom: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: onMenuTap,
              splashRadius: 20,
            ),
          if (isMobile) const SizedBox(width: 8),

          // Search Bar (Shadcn style)
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: SizedBox(
                height: 36,
                child: TextField(
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search anything...',
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
                    fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.04), // subtle gray fill
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),

          // Actions
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded, size: 20),
            tooltip: 'Notifications',
            splashRadius: 20,
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline_rounded, size: 20),
            tooltip: 'Help',
            splashRadius: 20,
          ),
          const SizedBox(width: 16),

          // Profile
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

