import 'dart:io' as io;
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;

class TrendDataTable extends StatefulWidget {
  final Map<DateTime, Map<String, int>> timeSeriesData;
  final String title;

  const TrendDataTable({
    super.key,
    required this.timeSeriesData,
    this.title = "Dữ liệu",
  });

  @override
  State<TrendDataTable> createState() => _TrendDataTableState();
}

class _TrendDataTableState extends State<TrendDataTable>
    with TickerProviderStateMixin {
  bool _isExporting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final statusVietnameseMap = {
    "Not Started": "Chưa bắt đầu",
    "In Progress": "Đang thực hiện",
    "Completed": "Hoàn thành",
  };

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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> exportCSV(BuildContext context, Map<DateTime, Map<String, int>> data) async {
    setState(() => _isExporting = true);
    
    try {
      final rows = [
        ['Ngày', 'Chưa bắt đầu', 'Đang thực hiện', 'Hoàn thành'],
        ...data.entries.map((entry) => [
              DateFormat('dd/MM/yyyy').format(entry.key),
              entry.value['Not Started'] ?? 0,
              entry.value['In Progress'] ?? 0,
              entry.value['Completed'] ?? 0,
            ]),
      ];

      final csv = const ListToCsvConverter().convert(rows);
      final fileName = 'bao_cao_${widget.title.toLowerCase().replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

      if (kIsWeb) {
        final blob = html.Blob([csv], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        _showSuccessMessage(context, 'Đã xuất CSV thành công!', Icons.file_download);
      } else {
        final dir = await getDownloadsDirectory();
        final file = io.File('${dir!.path}/$fileName');
        await file.writeAsString(csv);
        _showSuccessMessage(context, 'Đã xuất CSV thành công vào thư mục Downloads', Icons.file_download);
      }
    } catch (e) {
      _showErrorMessage(context, 'Lỗi khi xuất CSV: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> exportExcel(BuildContext context, Map<DateTime, Map<String, int>> data) async {
    setState(() => _isExporting = true);
    
    try {
      final excel = excel_lib.Excel.createExcel();
      final sheet = excel['Báo cáo ${widget.title}'];

      // Header với styling
      sheet.appendRow(['Ngày', 'Chưa bắt đầu', 'Đang thực hiện', 'Hoàn thành']);

      for (var entry in data.entries) {
        sheet.appendRow([
          DateFormat('dd/MM/yyyy').format(entry.key),
          entry.value['Not Started'] ?? 0,
          entry.value['In Progress'] ?? 0,
          entry.value['Completed'] ?? 0,
        ]);
      }

      final bytes = excel.encode();
      final fileName = 'bao_cao_${widget.title.toLowerCase().replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

      if (kIsWeb) {
        final blob = html.Blob([Uint8List.fromList(bytes!)]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        _showSuccessMessage(context, 'Đã xuất Excel thành công!', Icons.table_chart);
      } else {
        final dir = await getDownloadsDirectory();
        final file = io.File('${dir!.path}/$fileName');
        await file.writeAsBytes(bytes!);
        _showSuccessMessage(context, 'Đã xuất Excel thành công vào thư mục Downloads', Icons.table_chart);
      }
    } catch (e) {
      _showErrorMessage(context, 'Lỗi khi xuất Excel: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _showSuccessMessage(BuildContext context, String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<io.Directory?> getDownloadsDirectory() async {
    if (io.Platform.isWindows || io.Platform.isMacOS || io.Platform.isLinux) {
      return await getApplicationDocumentsDirectory();
    }
    return await getExternalStorageDirectory();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.timeSeriesData.isEmpty) {
      return _buildEmptyState(isDark);
    }

    final sortedDates = widget.timeSeriesData.keys.toList()..sort();
    
    // Calculate statistics
    final totalEntries = sortedDates.length;
    final statusTotals = <String, int>{};
    for (String status in ["Not Started", "In Progress", "Completed"]) {
      statusTotals[status] = widget.timeSeriesData.values
          .map((data) => data[status] ?? 0)
          .reduce((a, b) => a + b);
    }
    final grandTotal = statusTotals.values.reduce((a, b) => a + b);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
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
                _buildExportButtons(context, isDark),
                const SizedBox(height: 24),
                _buildDataTable(sortedDates, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportButtons(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF4B5563) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.download,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                "Xuất dữ liệu:",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildExportButton(
                  onPressed: _isExporting ? null : () => exportCSV(context, widget.timeSeriesData),
                  icon: Icons.file_download,
                  label: "Xuất CSV",
                  color: Colors.green,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildExportButton(
                  onPressed: _isExporting ? null : () => exportExcel(context, widget.timeSeriesData),
                  icon: Icons.table_chart,
                  label: "Xuất Excel",
                  color: Colors.blue,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          if (_isExporting) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue[600]!,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Đang xuất dữ liệu...",
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: onPressed == null 
                ? (isDark ? Colors.grey[700] : Colors.grey[200])
                : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: onPressed == null 
                  ? (isDark ? Colors.grey[600]! : Colors.grey[300]!)
                  : color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: onPressed == null 
                    ? (isDark ? Colors.grey[500] : Colors.grey[400])
                    : color,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: onPressed == null 
                      ? (isDark ? Colors.grey[500] : Colors.grey[400])
                      : (isDark ? Colors.white : color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable(List<DateTime> sortedDates, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF4B5563) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF4B5563) : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.table_rows,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  "Bảng dữ liệu chi tiết",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 32,
              headingRowColor: WidgetStateProperty.all(
                isDark ? const Color(0xFF374151) : const Color(0xFFF8FAFC),
              ),
              dataRowColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) {
                  return isDark 
                      ? const Color(0xFF4B5563) 
                      : const Color(0xFFF1F5F9);
                }
                return Colors.transparent;
              }),
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
                fontSize: 14,
              ),
              dataTextStyle: TextStyle(
                color: isDark ? Colors.grey[300] : const Color(0xFF374151),
                fontSize: 13,
              ),
              columns: [
                DataColumn(
                  label: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      const Text('Ngày'),
                    ],
                  ),
                ),
                DataColumn(
                  label: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorMap["Not Started"],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Chưa bắt đầu'),
                    ],
                  ),
                ),
                DataColumn(
                  label: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorMap["In Progress"],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Đang thực hiện'),
                    ],
                  ),
                ),
                DataColumn(
                  label: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorMap["Completed"],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Hoàn thành'),
                    ],
                  ),
                ),
              ],
              rows: sortedDates.map((date) {
                final dailyData = widget.timeSeriesData[date]!;
                return DataRow(
                  cells: [
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(date),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    DataCell(_buildStatusCell(dailyData['Not Started'] ?? 0, colorMap["Not Started"]!)),
                    DataCell(_buildStatusCell(dailyData['In Progress'] ?? 0, colorMap["In Progress"]!)),
                    DataCell(_buildStatusCell(dailyData['Completed'] ?? 0, colorMap["Completed"]!)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCell(int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        value.toString(),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
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
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(minHeight: 200),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.table_chart,
                  size: 48,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Không có dữ liệu ${widget.title}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Dữ liệu sẽ xuất hiện khi có thông tin mới",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}