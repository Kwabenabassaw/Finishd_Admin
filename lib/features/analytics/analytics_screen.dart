import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/core/admin_repository.dart';
import 'package:finishd_admin/features/dashboard/widgets/activity_chart.dart';
import 'package:intl/intl.dart';

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
  
  List<String> _userRetentionLabels = [];
  List<String> _videoCompletionLabels = [];
  List<String> _scrollDepthLabels = [];
  List<String> _communityEngagementLabels = [];
  
  int _days = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAnalytics();
    });
  }

  String _formatDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('MMM dd').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _fetchAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final repository = context.read<AdminRepository>();

      final results = await Future.wait([
        repository.getDailyActiveUsers(_days),
        repository.getDailyVideoCompletion(_days),
        repository.getDailyScrollDepth(_days),
        repository.getDailyCommunityEngagement(_days),
      ]);

      final activeUsers = results[0];
      final videoCompletion = results[1];
      final scrollDepth = results[2];
      final communityEngagement = results[3];

      _userRetentionData = activeUsers.map<int>((r) => (r['active_users'] as num? ?? 0).toInt()).toList();
      _userRetentionLabels = activeUsers.map<String>((r) => _formatDate(r['date']?.toString() ?? '')).toList();

      _videoCompletionData = videoCompletion.map<int>((r) => (r['avg_completion'] as num? ?? 0).toInt()).toList();
      _videoCompletionLabels = videoCompletion.map<String>((r) => _formatDate(r['date']?.toString() ?? '')).toList();

      _scrollDepthData = scrollDepth.map<int>((r) => (r['avg_scroll_depth'] as num? ?? 0).toInt()).toList();
      _scrollDepthLabels = scrollDepth.map<String>((r) => _formatDate(r['date']?.toString() ?? '')).toList();

      _communityEngagementData = communityEngagement.map<int>((r) => (r['engagement_count'] as num? ?? 0).toInt()).toList();
      _communityEngagementLabels = communityEngagement.map<String>((r) => _formatDate(r['date']?.toString() ?? '')).toList();

      if (_userRetentionData.isEmpty) {
        _userRetentionData = List.filled(_days, 0);
        _userRetentionLabels = List.generate(_days, (i) => '');
      }
      if (_videoCompletionData.isEmpty) {
        _videoCompletionData = List.filled(_days, 0);
        _videoCompletionLabels = List.generate(_days, (i) => '');
      }
      if (_scrollDepthData.isEmpty) {
        _scrollDepthData = List.filled(_days, 0);
        _scrollDepthLabels = List.generate(_days, (i) => '');
      }
      if (_communityEngagementData.isEmpty) {
        _communityEngagementData = List.filled(_days, 0);
        _communityEngagementLabels = List.generate(_days, (i) => '');
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _userRetentionData = List.filled(_days, 0);
        _userRetentionLabels = List.generate(_days, (i) => '');
        _videoCompletionData = List.filled(_days, 0);
        _videoCompletionLabels = List.generate(_days, (i) => '');
        _scrollDepthData = List.filled(_days, 0);
        _scrollDepthLabels = List.generate(_days, (i) => '');
        _communityEngagementData = List.filled(_days, 0);
        _communityEngagementLabels = List.generate(_days, (i) => '');

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
          if (!_isLoading &&
              _userRetentionData.every((val) => val == 0) &&
              _videoCompletionData.every((val) => val == 0) &&
              _scrollDepthData.every((val) => val == 0) &&
              _communityEngagementData.every((val) => val == 0))
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'Analytics Setup Required',
                        style: TextStyle(
                          color: Colors.amber.shade200,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No interaction metrics were detected in the database. To populate these platform charts, ensure that the mobile application logs events like "scroll_depth" and community activities to Supabase.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
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
                      labels: _userRetentionLabels,
                    ),
                    ActivityChart(
                      title: 'Avg Video Completion (%)',
                      data: _videoCompletionData,
                      labels: _videoCompletionLabels,
                    ),
                    ActivityChart(
                      title: 'Avg Scroll Depth (px)',
                      data: _scrollDepthData,
                      labels: _scrollDepthLabels,
                    ),
                    ActivityChart(
                      title: 'Community Engagement',
                      data: _communityEngagementData,
                      labels: _communityEngagementLabels,
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
