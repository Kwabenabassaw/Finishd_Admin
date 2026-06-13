import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ActivityChart extends StatelessWidget {
  final List<int> data;
  final List<String> labels;
  final String title;

  const ActivityChart({
    super.key,
    required this.data,
    required this.labels,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title, 
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            )
          ),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: bottomTitleWidgets,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 10,
      color: Colors.grey,
    );
    final index = value.toInt();
    if (index >= 0 && index < labels.length) {
      // Sparsify labels to avoid overlapping on UI: show ~5 labels across the chart width
      final labelInterval = (labels.length / 5).ceil();
      if (index % labelInterval == 0 || index == labels.length - 1) {
        return SideTitleWidget(
          meta: meta,
          space: 10,
          child: Text(labels[index], style: style),
        );
      }
    }

    return const SizedBox.shrink();
  }
}

