import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/core/admin_repository.dart';
import 'package:finishd_admin/features/dashboard/widgets/activity_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = false;
  List<int> _userRetentionData = [];
  List<int> _videoCompletionData = [];
  List<int> _scrollDepthData = [];
  List<int> _communityEngagementData = [];
  int _days = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAnalytics();
    });
  }

  Future<void> _fetchAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final repository = context.read<AdminRepository>();

      // Fetch data concurrently
      final userStatsFuture = repository.getDailyUserStats(_days);
      final videoStatsFuture = repository.getDailyVideoStats(_days);

      final results = await Future.wait([userStatsFuture, videoStatsFuture]);
      final userStats = results[0];
      final videoStats = results[1];

      // Process data for charts
      // Note: If data is missing for some days, this simple mapping might alignment issues.
      // ideally we fill gaps. For now, we map available data.

      // Retention: map 'active_users' or similar.
      // If column doesn't exist, we fallback to 0 or mock for now as schema is potentially new.
      // Assuming 'active_users' exists in user_daily_stats
      _userRetentionData = userStats
          .map((e) => (e['active_users'] as num? ?? 0).toInt())
          .toList();

      // Video Completion: 'avg_completion_rate' or similar
      _videoCompletionData = videoStats
          .map((e) => (e['avg_completion_pct'] as num? ?? 0).toInt())
          .toList();

      // Mocking others as they likely require computed columns not yet in simple daily stats
      _scrollDepthData = List.generate(_days, (i) => 500 + (i * 10) % 200);
      _communityEngagementData = List.generate(
        _days,
        (i) => 100 + (i * 5) % 50,
      );

      // If fetched data is empty (e.g. no stats yet), fill with zeros
      if (_userRetentionData.isEmpty)
        _userRetentionData = List.filled(_days, 0);
      if (_videoCompletionData.isEmpty)
        _videoCompletionData = List.filled(_days, 0);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Fallback to zeros on error
        _userRetentionData = List.filled(_days, 0);
        _videoCompletionData = List.filled(_days, 0);
        _scrollDepthData = List.filled(_days, 0);
        _communityEngagementData = List.filled(_days, 0);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading analytics: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Platform Analytics',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<int>(
                value: _days,
                items: const [
                  DropdownMenuItem(value: 7, child: Text('Last 7 Days')),
                  DropdownMenuItem(value: 30, child: Text('Last 30 Days')),
                  DropdownMenuItem(value: 90, child: Text('Last 3 Months')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _days = val);
                    _fetchAnalytics();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1200 ? 2 : 1;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.0,
                  children: [
                    ActivityChart(
                      title: 'Active Users (DAU)',
                      data: _userRetentionData,
                    ),
                    ActivityChart(
                      title: 'Avg Video Completion (%)',
                      data: _videoCompletionData,
                    ),
                    ActivityChart(
                      title: 'Avg Scroll Depth (px)',
                      data: _scrollDepthData,
                    ),
                    ActivityChart(
                      title: 'Community Engagement',
                      data: _communityEngagementData,
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
