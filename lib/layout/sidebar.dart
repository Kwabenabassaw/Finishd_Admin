import 'package:flutter/material.dart';
import 'package:finishd_admin/features/auth/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;

  const Sidebar({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(right: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    color: theme.colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Finishd',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                const _SectionHeader(title: 'Overview'),
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: selectedIndex == 0,
                  onTap: () => context.go('/'),
                ),
                _NavItem(
                  icon: Icons.analytics_outlined,
                  selectedIcon: Icons.analytics_rounded,
                  label: 'Analytics',
                  isSelected: selectedIndex == 8,
                  onTap: () => context.go('/analytics'),
                ),
                const SizedBox(height: 24),
                
                const _SectionHeader(title: 'Management'),
                _NavItem(
                  icon: Icons.people_outline,
                  selectedIcon: Icons.people_rounded,
                  label: 'Users',
                  isSelected: selectedIndex == 1,
                  onTap: () => context.go('/users'),
                ),
                _NavItem(
                  icon: Icons.verified_user_outlined,
                  selectedIcon: Icons.verified_user_rounded,
                  label: 'Creators',
                  isSelected: selectedIndex == 2,
                  onTap: () => context.go('/creators'),
                ),
                _NavItem(
                  icon: Icons.groups_outlined,
                  selectedIcon: Icons.groups_rounded,
                  label: 'Communities',
                  isSelected: selectedIndex == 4,
                  onTap: () => context.go('/communities'),
                ),
                const SizedBox(height: 24),
                
                const _SectionHeader(title: 'Content & Moderation'),
                _NavItem(
                  icon: Icons.video_library_outlined,
                  selectedIcon: Icons.video_library_rounded,
                  label: 'Content',
                  isSelected: selectedIndex == 3,
                  onTap: () => context.go('/videos'),
                ),
                _NavItem(
                  icon: Icons.gavel_outlined,
                  selectedIcon: Icons.gavel_rounded,
                  label: 'Moderation',
                  isSelected: selectedIndex == 6,
                  onTap: () => context.go('/reports'),
                ),
                _NavItem(
                  icon: Icons.history_outlined,
                  selectedIcon: Icons.history_rounded,
                  label: 'Audit Logs',
                  isSelected: selectedIndex == 7,
                  onTap: () => context.go('/logs'),
                ),
                _NavItem(
                  icon: Icons.tune_outlined,
                  selectedIcon: Icons.tune_rounded,
                  label: 'Feed Control',
                  isSelected: selectedIndex == 5,
                  onTap: () => context.go('/feed'),
                ),
                const SizedBox(height: 24),
                
                const _SectionHeader(title: 'System'),
                _NavItem(
                  icon: Icons.model_training_outlined,
                  selectedIcon: Icons.model_training_rounded,
                  label: 'ML & AI',
                  isSelected: selectedIndex == 9,
                  onTap: () => context.go('/ml'),
                ),
                _NavItem(
                  icon: Icons.campaign_outlined,
                  selectedIcon: Icons.campaign_rounded,
                  label: 'Announcements',
                  isSelected: selectedIndex == 12,
                  onTap: () => context.go('/announcements'),
                ),
                _NavItem(
                  icon: Icons.link_outlined,
                  selectedIcon: Icons.link_rounded,
                  label: 'Deep Links',
                  isSelected: selectedIndex == 10,
                  onTap: () => context.go('/deeplinks'),
                ),
                _NavItem(
                  icon: Icons.view_column_outlined,
                  selectedIcon: Icons.view_column_rounded,
                  label: 'User Reports',
                  isSelected: selectedIndex == 13,
                  onTap: () => context.go('/user-reports'),
                ),

                _NavItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings_rounded,
                  label: 'Settings',
                  isSelected: selectedIndex == 11,
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: _NavItem(
              icon: Icons.logout_rounded,
              selectedIcon: Icons.logout_rounded,
              label: 'Sign Out',
              isSelected: false,
              onTap: () => context.read<AuthService>().signOut(),
              isDestructive: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDestructive;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = widget.isSelected;
    final isDestructive = widget.isDestructive;

    Color fgColor = theme.colorScheme.onSurface;
    if (isDestructive) fgColor = Colors.redAccent.shade200;
    if (isSelected) fgColor = theme.colorScheme.onPrimaryContainer;

    Color bgColor = Colors.transparent;
    if (isSelected) {
      bgColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.15);
    } else if (_isHovered) {
      if (isDestructive) {
        bgColor = Colors.redAccent.shade200.withValues(alpha: 0.1);
      } else {
        bgColor = theme.colorScheme.onSurface.withValues(alpha: 0.05);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? widget.selectedIcon : widget.icon,
                  color: fgColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: fgColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

