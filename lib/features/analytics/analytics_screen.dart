import 'package:flutter/material.dart';
import 'package:finishd_admin/core/mock_data.dart';
import 'package:finishd_admin/features/dashboard/widgets/activity_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

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
              DropdownButton<String>(
                value: 'Last 30 Days',
                items: const [
                  DropdownMenuItem(value: 'Last 7 Days', child: Text('Last 7 Days')),
                  DropdownMenuItem(value: 'Last 30 Days', child: Text('Last 30 Days')),
                  DropdownMenuItem(value: 'Last 3 Months', child: Text('Last 3 Months')),
                ],
                onChanged: (_) {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          GridView.count(
             crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 2 : 1,
             crossAxisSpacing: 24,
             mainAxisSpacing: 24,
             shrinkWrap: true,
             physics: const NeverScrollableScrollPhysics(),
             childAspectRatio: 2.0,
             children: [
               ActivityChart(
                 title: 'Retention Rates (D1/D7/D30)',
                 data: MockData.generateChartData(30, max: 100),
               ),
               ActivityChart(
                 title: 'Video Completion Rate',
                 data: MockData.generateChartData(30, max: 100),
               ),
               ActivityChart(
                 title: 'Scroll Depth (Avg)',
                 data: MockData.generateChartData(30, max: 1000),
               ),
               ActivityChart(
                 title: 'Community Engagement',
                 data: MockData.generateChartData(30, max: 500),
               ),
             ],
          ),
        ],
      ),
    );
  }
}
