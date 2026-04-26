import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:finishd_admin/core/mock_data.dart';
import 'package:finishd_admin/features/dashboard/widgets/stat_card.dart';
import 'package:finishd_admin/features/dashboard/widgets/activity_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/core/admin_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = context.read<AdminRepository>().getDashboardStats();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = ResponsiveBreakpoints.of(context).largerThan(TABLET);

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
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Export Report'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
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
          FutureBuilder<Map<String, dynamic>>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading stats: ${snapshot.error}'),
                );
              }

              final stats = snapshot.data ?? {};

              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: [
                  StatCard(
                    title: 'Daily Active Users',
                    value: (stats['daily_active_users'] ?? 0).toString(),
                    trend: '+0%', // Trends require historical data comparison
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                  StatCard(
                    title: 'New Users Today',
                    value: (stats['new_users_today'] ?? 0).toString(),
                    trend: '+0%',
                    icon: Icons.person_add,
                    color: Colors.green,
                  ),
                  StatCard(
                    title: 'Videos Uploaded',
                    value: (stats['videos_uploaded_today'] ?? 0).toString(),
                    trend: '+0%',
                    isPositive: false,
                    icon: Icons.video_library,
                    color: Colors.purple,
                  ),
                  StatCard(
                    title: 'Pending Reports',
                    value: (stats['pending_reports'] ?? 0).toString(),
                    trend: '+12%',
                    isPositive: false,
                    icon: Icons.flag_rounded,
                    color: Colors.orange,
                    onTap: () => context.go('/reports'),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Charts
          LayoutBuilder(
            builder: (context, constraints) {
              if (ResponsiveBreakpoints.of(context).largerThan(TABLET)) {
                return SizedBox(
                  height: 400,
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
                    SizedBox(
                      height: 400,
                      child: ActivityChart(
                        title: 'User Growth (30 Days)',
                        data: MockData.generateChartData(30, max: 50),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 400,
                      child: ActivityChart(
                        title: 'Feed Engagement',
                        data: MockData.generateChartData(30, max: 100),
                      ),
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
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.warning_amber_rounded, size: 18, color: theme.colorScheme.error),
          ),
          const SizedBox(width: 16),
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
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Investigate', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
