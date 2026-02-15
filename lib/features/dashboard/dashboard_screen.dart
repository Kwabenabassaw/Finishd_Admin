import 'package:flutter/material.dart';
import 'package:finishd_admin/core/mock_data.dart';
import 'package:finishd_admin/features/dashboard/widgets/stat_card.dart';
import 'package:finishd_admin/features/dashboard/widgets/activity_chart.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dashboard',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download),
                label: const Text('Export Report'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Alerts
          _AlertBanner(
            message: 'Unusual spike in reports detected (topic: "Copyright")',
            onAction: () => context.go('/reports'),
          ),
          const SizedBox(height: 24),

          // Stats Grid
          GridView.count(
            crossAxisCount: isWide ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              StatCard(
                title: 'Daily Active Users',
                value: '12,450',
                trend: '+12%',
                icon: Icons.people,
                color: Colors.blue,
              ),
              StatCard(
                title: 'New Users Today',
                value: '342',
                trend: '+5%',
                icon: Icons.person_add,
                color: Colors.green,
              ),
              StatCard(
                title: 'Videos Uploaded',
                value: '1,205',
                trend: '-2%',
                isPositive: false,
                icon: Icons.video_library,
                color: Colors.purple,
              ),
              StatCard(
                title: 'Pending Reports',
                value: '15',
                trend: '+3',
                isPositive: false, // More reports is usually bad
                icon: Icons.report,
                color: Colors.orange,
                onTap: () => context.go('/reports'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Charts
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return SizedBox(
                  height: 400, // Explicit height for Row children if needed, but Chart handles it
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ActivityChart(
                          title: 'User Growth (30 Days)',
                          data: MockData.generateChartData(30, max: 50),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: ActivityChart(
                          title: 'Feed Engagement',
                          data: MockData.generateChartData(30, max: 100),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return Column(
                  children: [
                     ActivityChart(
                        title: 'User Growth (30 Days)',
                        data: MockData.generateChartData(30, max: 50),
                      ),
                      const SizedBox(height: 24),
                      ActivityChart(
                        title: 'Feed Engagement',
                        data: MockData.generateChartData(30, max: 100),
                      ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final String message;
  final VoidCallback onAction;

  const _AlertBanner({required this.message, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: const Text('Investigate'),
          ),
        ],
      ),
    );
  }
}
