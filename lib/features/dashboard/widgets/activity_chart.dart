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
    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.toDouble());
    }).toList();

    // Determine max value dynamically for scaling the grid
    double maxY = 10;
    if (data.isNotEmpty) {
      final maxVal = data.reduce((a, b) => a > b ? a : b);
      if (maxVal > 0) {
        maxY = maxVal.toDouble() * 1.1; // Add 10% headroom
      }
    }

    final double verticalInterval = (data.length / 6).clamp(1.0, double.infinity);
    final double horizontalInterval = (maxY / 4).clamp(1.0, double.infinity);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B2339), // Dark card background from Sample 2
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E3B52), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.only(right: 24, left: 16, top: 24, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              title, 
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              )
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: horizontalInterval,
                  verticalInterval: verticalInterval,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: Color(0xFF2E3B52),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return const FlLine(
                      color: Color(0xFF2E3B52),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: horizontalInterval,
                      getTitlesWidget: leftTitleWidgets,
                      reservedSize: 36,
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: verticalInterval,
                      getTitlesWidget: bottomTitleWidgets,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xFF2E3B52), width: 1),
                ),
                minX: 0,
                maxX: (data.length - 1).toDouble().clamp(0.0, double.infinity),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF50E4FF), // Cyan glow
                        Color(0xFF2196F3), // Blue glow
                      ],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF50E4FF).withOpacity(0.3),
                          const Color(0xFF2196F3).withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 10,
      color: Color(0xFF67727E),
    );
    String text;
    if (value >= 1000) {
      text = '${(value / 1000).toStringAsFixed(0)}k';
    } else {
      text = value.toInt().toString();
    }
    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(text, style: style, textAlign: TextAlign.right),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 10,
      color: Color(0xFF67727E),
    );
    final index = value.toInt();
    if (index >= 0 && index < labels.length) {
      return SideTitleWidget(
        meta: meta,
        space: 10,
        child: Text(labels[index], style: style),
      );
    }

    return const SizedBox.shrink();
  }
}

