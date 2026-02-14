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
      width: 250,
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Finishd',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _NavItem(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            label: 'Dashboard',
            isSelected: selectedIndex == 0,
            onTap: () => context.go('/'),
          ),
          _NavItem(
            icon: Icons.verified_user_outlined,
            selectedIcon: Icons.verified_user,
            label: 'Applications',
            isSelected: selectedIndex == 1,
            onTap: () => context.go('/applications'),
          ),
          _NavItem(
            icon: Icons.video_library_outlined,
            selectedIcon: Icons.video_library,
            label: 'Video Review',
            isSelected: selectedIndex == 2,
            onTap: () => context.go('/videos'),
          ),
          _NavItem(
            icon: Icons.flag_outlined,
            selectedIcon: Icons.flag,
            label: 'Reports',
            isSelected: selectedIndex == 3,
            onTap: () => context.go('/reports'),
          ),
          const Spacer(),
          const Divider(height: 1),
          _NavItem(
            icon: Icons.logout,
            selectedIcon: Icons.logout,
            label: 'Sign Out',
            isSelected: false,
            onTap: () {
              context.read<AuthService>().signOut();
            },
            isDestructive: true,
          ),
          const SizedBox(height: 16),
        ],
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
              : theme.colorScheme.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(isSelected ? selectedIcon : icon, color: color, size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: isSelected
                        ? FontWeight.bold
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
