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
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Finishd',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
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
              children: [
                const _SectionHeader(title: 'Overview'),
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard,
                  label: 'Dashboard',
                  isSelected: selectedIndex == 0,
                  onTap: () => context.go('/'),
                ),
                _NavItem(
                  icon: Icons.analytics_outlined,
                  selectedIcon: Icons.analytics,
                  label: 'Analytics',
                  isSelected: selectedIndex == 8,
                  onTap: () => context.go('/analytics'),
                ),

                const SizedBox(height: 24),
                const _SectionHeader(title: 'Management'),
                _NavItem(
                  icon: Icons.people_outline,
                  selectedIcon: Icons.people,
                  label: 'Users',
                  isSelected: selectedIndex == 1,
                  onTap: () => context.go('/users'),
                ),
                _NavItem(
                  icon: Icons.verified_user_outlined,
                  selectedIcon: Icons.verified_user,
                  label: 'Creators',
                  isSelected: selectedIndex == 2,
                  onTap: () => context.go('/creators'),
                ),
                _NavItem(
                  icon: Icons.groups_outlined,
                  selectedIcon: Icons.groups,
                  label: 'Communities',
                  isSelected: selectedIndex == 4,
                  onTap: () => context.go('/communities'),
                ),

                const SizedBox(height: 24),
                const _SectionHeader(title: 'Content & Moderation'),
                _NavItem(
                  icon: Icons.video_library_outlined,
                  selectedIcon: Icons.video_library,
                  label: 'Content',
                  isSelected: selectedIndex == 3,
                  onTap: () => context.go('/videos'),
                ),
                _NavItem(
                  icon: Icons.gavel_outlined,
                  selectedIcon: Icons.gavel,
                  label: 'Moderation',
                  isSelected: selectedIndex == 6,
                  onTap: () => context.go('/reports'),
                ),
                _NavItem(
                  icon: Icons.tune_outlined,
                  selectedIcon: Icons.tune,
                  label: 'Feed Control',
                  isSelected: selectedIndex == 5,
                  onTap: () => context.go('/feed'),
                ),

                const SizedBox(height: 24),
                const _SectionHeader(title: 'System'),
                _NavItem(
                  icon: Icons.model_training_outlined,
                  selectedIcon: Icons.model_training,
                  label: 'ML & AI',
                  isSelected: selectedIndex == 9,
                  onTap: () => context.go('/ml'),
                ),
                 _NavItem(
                  icon: Icons.link_outlined,
                  selectedIcon: Icons.link,
                  label: 'Deep Links',
                  isSelected: selectedIndex == 10,
                  onTap: () => context.go('/deeplinks'),
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  label: 'Settings',
                  isSelected: selectedIndex == 11,
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _NavItem(
              icon: Icons.logout,
              selectedIcon: Icons.logout,
              label: 'Sign Out',
              isSelected: false,
              onTap: () {
                context.read<AuthService>().signOut();
              },
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
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive
        ? theme.colorScheme.error
        : (isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(isSelected ? selectedIcon : icon, color: color, size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
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
