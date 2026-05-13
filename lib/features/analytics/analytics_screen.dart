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

      // userStats contains per-user rows: { user_id, date, videos_watched, ... }
      // Group by date and count unique users to get 'active_users'
      final Map<String, Set<String>> activeUsersByDate = {};
      for (final row in userStats) {
        final date = row['date'] as String;
        final userId = row['user_id'] as String;
        activeUsersByDate.putIfAbsent(date, () => {}).add(userId);
      }

      // videoStats contains per-video rows: { video_id, date, total_views, sum_completion_pct }
      // Group by date and compute average completion percentage
      final Map<String, double> completionSumByDate = {};
      final Map<String, int> completionCountByDate = {};
      for (final row in videoStats) {
        final date = row['date'] as String;
        final sumCompletion = (row['sum_completion_pct'] as num? ?? 0).toDouble();
        final views = (row['total_views'] as num? ?? 0).toInt();
        
        if (views > 0) {
          completionSumByDate[date] = (completionSumByDate[date] ?? 0) + sumCompletion;
          completionCountByDate[date] = (completionCountByDate[date] ?? 0) + views;
        }
      }

      // Generate the last `_days` dates to ensure contiguous data
      final now = DateTime.now();
      _userRetentionData = [];
      _videoCompletionData = [];
      
      for (int i = _days - 1; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        // Format as YYYY-MM-DD
        final dateStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        
        // Active Users
        _userRetentionData.add(activeUsersByDate[dateStr]?.length ?? 0);
        
        // Avg Completion
        final sum = completionSumByDate[dateStr] ?? 0;
        final count = completionCountByDate[dateStr] ?? 0;
        _videoCompletionData.add(count > 0 ? (sum / count).toInt() : 0);
      }

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
