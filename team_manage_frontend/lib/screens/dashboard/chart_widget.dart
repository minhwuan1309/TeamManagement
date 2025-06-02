import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MultiLineChartWidget extends StatefulWidget {
  final Map<DateTime, Map<String, int>> timeSeriesData;
  final String title;

  const MultiLineChartWidget({
    super.key,
    required this.timeSeriesData,
    required this.title,
  });

  @override
  State<MultiLineChartWidget> createState() => _MultiLineChartWidgetState();
}

class _MultiLineChartWidgetState extends State<MultiLineChartWidget>
    with TickerProviderStateMixin {
  Set<String> hiddenLines = {};
  int? touchedIndex;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final statusVietnameseMap = {
    "Not Started": "Chưa bắt đầu",
    "In Progress": "Đang thực hiện",
    "Completed": "Hoàn thành",
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (widget.timeSeriesData.isEmpty) {
      return _buildEmptyState(isDark);
    }

    final sortedDates = widget.timeSeriesData.keys.toList()..sort();
    final labels = sortedDates.map((d) => DateFormat('MM/dd').format(d)).toList();

    final statusList = ["Not Started", "In Progress", "Completed"];
    
    final colorMap = {
      "Not Started": const Color(0xFF64748B), // Slate-500
      "In Progress": const Color(0xFFF59E0B), // Amber-500
      "Completed": const Color(0xFF10B981), // Emerald-500
    };

    final iconMap = {
      "Not Started": Icons.pause_circle_outline,
      "In Progress": Icons.schedule,
      "Completed": Icons.check_circle,
    };

    // Calculate statistics
    final totalValues = <String, int>{};
    final averageValues = <String, double>{};
    for (String status in statusList) {
      final values = widget.timeSeriesData.values
          .map((data) => data[status] ?? 0)
          .toList();
      totalValues[status] = values.reduce((a, b) => a + b);
      averageValues[status] = values.isNotEmpty 
          ? values.reduce((a, b) => a + b) / values.length 
          : 0.0;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, sortedDates, totalValues, isDark),
              const SizedBox(height: 24),
              _buildStatsRow(averageValues, colorMap, isDark),
              const SizedBox(height: 20),
              _buildLegend(statusList, colorMap, iconMap, totalValues, isDark),
              const SizedBox(height: 24),
              _buildChart(sortedDates, labels, statusList, colorMap, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, List<DateTime> sortedDates, 
      Map<String, int> totalValues, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.1),
                    Colors.purple.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.trending_up,
                color: Colors.blue[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Biểu đồ ${widget.title} theo thời gian",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${sortedDates.length} ngày • ${DateFormat('dd/MM/yyyy').format(sortedDates.first)} - ${DateFormat('dd/MM/yyyy').format(sortedDates.last)}",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.8),
                Colors.purple.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.analytics,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Tổng: ${totalValues.values.reduce((a, b) => a + b)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(Map<String, double> averageValues, 
      Map<String, Color> colorMap, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF4B5563) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bar_chart,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            "Trung bình mỗi ngày:",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(width: 16),
          ...averageValues.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorMap[entry.key],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "${entry.value.toStringAsFixed(1)}",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorMap[entry.key],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildLegend(List<String> statusList, Map<String, Color> colorMap,
      Map<String, IconData> iconMap, Map<String, int> totalValues, bool isDark) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: statusList.map((status) {
        final isHidden = hiddenLines.contains(status);
        final color = colorMap[status]!;
        final icon = iconMap[status]!;
        final total = totalValues[status] ?? 0;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isHidden) {
                    hiddenLines.remove(status);
                  } else {
                    hiddenLines.add(status);
                  }
                });
              },
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isHidden 
                      ? (isDark ? Colors.grey[800] : Colors.grey[100])
                      : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isHidden 
                        ? (isDark ? Colors.grey[600]! : Colors.grey[300]!)
                        : color.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        icon,
                        size: 18,
                        color: isHidden 
                            ? (isDark ? Colors.grey[500] : Colors.grey[400])
                            : color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: isHidden 
                            ? (isDark ? Colors.grey[500] : Colors.grey[400])
                            : (isDark ? Colors.white : color),
                        fontWeight: FontWeight.w600,
                        decoration: isHidden ? TextDecoration.lineThrough : null,
                      ),
                      child: Text(statusVietnameseMap[status] ?? status),
                    ),
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isHidden 
                            ? (isDark ? Colors.grey[600] : Colors.grey[400])
                            : color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        total.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChart(List<DateTime> sortedDates, List<String> labels,
      List<String> statusList, Map<String, Color> colorMap, bool isDark) {
    final maxValue = widget.timeSeriesData.values
        .expand((data) => data.values)
        .reduce((a, b) => a > b ? a : b);
    final yAxisMax = (maxValue * 1.2).ceil().toDouble();

    List<LineChartBarData> buildLines() {
      return statusList
          .where((status) => !hiddenLines.contains(status))
          .map((status) {
        final color = colorMap[status]!;
        final spots = sortedDates.asMap().entries.map((entry) {
          final index = entry.key;
          final date = entry.value;
          final value = widget.timeSeriesData[date]?[status] ?? 0;
          return FlSpot(index.toDouble(), value.toDouble());
        }).toList();

        return LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          barWidth: 3.5,
          color: color,
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 5,
                color: color,
                strokeWidth: 3,
                strokeColor: isDark ? const Color(0xFF1F2937) : Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        );
      }).toList();
    }

    return Container(
      height: 340,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          lineBarsData: buildLines(),
          minY: 0,
          maxY: yAxisMax > 0 ? yAxisMax : 10,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: labels.length > 10 ? 2 : 1,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: yAxisMax > 10 ? (yAxisMax / 5).ceil().toDouble() : 1,
                getTitlesWidget: (value, _) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            drawHorizontalLine: true,
            horizontalInterval: yAxisMax > 10 ? (yAxisMax / 5).ceil().toDouble() : 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark 
                  ? Colors.grey.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: isDark 
                  ? Colors.grey.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: isDark 
                  ? Colors.grey.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => isDark 
                  ? Colors.grey[800]!
                  : Colors.black87,
              tooltipPadding: const EdgeInsets.all(12),
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              tooltipMargin: 16,
              maxContentWidth: 200,
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final dateIndex = touchedSpot.x.toInt();
                  final status = statusList.where((s) => !hiddenLines.contains(s)).elementAt(touchedSpot.barIndex);
                  final statusVietnamese = statusVietnameseMap[status] ?? status;
                  final date = sortedDates[dateIndex];
                  
                  return LineTooltipItem(
                    '${DateFormat('dd/MM/yyyy').format(date)}\n$statusVietnamese: ${touchedSpot.y.toInt()}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
            touchSpotThreshold: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.show_chart,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Không có dữ liệu ${widget.title}",
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Dữ liệu sẽ xuất hiện khi có thông tin mới",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}