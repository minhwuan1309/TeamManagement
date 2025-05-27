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

class _MultiLineChartWidgetState extends State<MultiLineChartWidget> {
  Set<String> hiddenLines = {};
  int? touchedIndex;

  final statusList = ["Not Started", "In Progress", "Completed"];
    
  final statusVietnameseMap = {
    "Not Started": "Chưa bắt đầu",
    "In Progress": "Đang thực hiện",
    "Completed": "Hoàn thành",
  };
    
  final colorMap = {
    "Not Started": const Color(0xFF6B7280), // Gray-500
    "In Progress": const Color(0xFFF59E0B), // Amber-500
    "Completed": const Color(0xFF10B981), // Emerald-500
  };

  final iconMap = {
    "Not Started": Icons.pause_circle_outline,
    "In Progress": Icons.access_time,
    "Completed": Icons.check_circle,
  };

  Widget _buildDataTable(List<DateTime> sortedDates, List<String> statusList, Map<String, Color> colorMap) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 80,
                  child: Text(
                    'Ngày',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...statusList.map((status) => Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colorMap[status],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusVietnameseMap[status]?.split(' ').first ?? status.split(' ').first,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          // Data rows
          ...sortedDates.take(5).map((date) {
            final data = widget.timeSeriesData[date]!;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      DateFormat('dd/MM').format(date),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  ...statusList.map((status) => Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorMap[status]!.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (data[status] ?? 0).toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorMap[status],
                          ),
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            );
          }),
          if (sortedDates.length > 5)
            Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                '... và ${sortedDates.length - 5} ngày khác',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.timeSeriesData.isEmpty) {
      return _buildEmptyState();
    }

    final sortedDates = widget.timeSeriesData.keys.toList()..sort();
    final labels = sortedDates.map((d) => DateFormat('MM/dd').format(d)).toList();


    // Calculate total values for each status
    final totalValues = <String, int>{};
    for (String status in statusList) {
      totalValues[status] = widget.timeSeriesData.values
          .map((data) => data[status] ?? 0)
          .reduce((a, b) => a + b);
    }

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
          curveSmoothness: 0.3,
          barWidth: 3,
          color: color,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: color,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: color.withOpacity(0.1),
          ),
        );
      }).toList();
    }

    // Find max value for Y axis
    final maxValue = widget.timeSeriesData.values
        .expand((data) => data.values)
        .reduce((a, b) => a > b ? a : b);
    final yAxisMax = (maxValue * 1.2).ceil().toDouble();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Biểu đồ ${widget.title} theo thời gian",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${sortedDates.length} ngày • ${DateFormat('dd/MM/yyyy').format(sortedDates.first)} - ${DateFormat('dd/MM/yyyy').format(sortedDates.last)}",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Total summary
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Tổng: ${totalValues.values.reduce((a, b) => a + b)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Legend with toggle functionality
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: statusList.map((status) {
                final isHidden = hiddenLines.contains(status);
                final color = colorMap[status]!;
                final icon = iconMap[status]!;
                final total = totalValues[status] ?? 0;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isHidden) {
                        hiddenLines.remove(status);
                      } else {
                        hiddenLines.add(status);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isHidden ? Colors.grey[100] : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isHidden ? Colors.grey[300]! : color.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: isHidden ? Colors.grey : color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusVietnameseMap[status] ?? status,
                          style: TextStyle(
                            color: isHidden ? Colors.grey : color,
                            fontWeight: FontWeight.w500,
                            decoration: isHidden ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isHidden ? Colors.grey[300] : color,
                            borderRadius: BorderRadius.circular(10),
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
                );
              }).toList(),
            ),
            
            const SizedBox(height: 20),
            
            // Chart
            SizedBox(
              height: 320,
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
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
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
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => Colors.black87,
                      tooltipPadding: const EdgeInsets.all(8),
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
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Data summary table
            _buildDataTable(sortedDates, statusList, colorMap),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "Không có dữ liệu ${widget.title}",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}