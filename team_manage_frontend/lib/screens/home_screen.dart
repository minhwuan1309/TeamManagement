import 'dart:io';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/api_service.dart';
import 'package:team_manage_frontend/layouts/common_layout.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:team_manage_frontend/screens/dashboard/chart_widget.dart';
import 'package:team_manage_frontend/screens/dashboard/trend_data_table.dart';
import 'package:team_manage_frontend/utils/env.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  String userName = '';
  Map<DateTime, Map<String, int>> taskTrend = {};
  Map<DateTime, Map<String, int>> issueTrend = {};
  bool isDownloading = false;

  String selectedType = 'Task';
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = true;
  Map<DateTime, Map<String, int>> timeSeriesData = {};

  final String metabaseUrl = metabasePublicUrl;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    loadUserAndStats();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    String url = '$baseUrl/dashboard/${selectedType.toLowerCase()}/trend';

    if (startDate != null && endDate != null){
      final sdf = DateFormat('yyyy-MM-dd');
      url += '?startDate=${sdf.format(startDate!)}&endDate=${sdf.format(endDate!)}';
    }

    final response = await http.get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});

    if(response.statusCode == 200){
      final raw = jsonDecode(response.body);
      final List<dynamic> data = raw[r'$values'] ?? [];
      final parsed = <DateTime, Map<String, int>>{};

      for (var item in data){
        final date = DateTime.parse(item['date']);
        parsed[date] = {
          "Not Started": item['notStarted'] ?? 0,
          "In Progress": item['inProgress'] ?? 0,
          "Completed": item['completed'] ?? 0,
        };
      }
      setState(() {
        timeSeriesData = parsed;
        isLoading = false;
      });
    }else{
      print('Lỗi fetching data: ${response.statusCode}');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadUserAndStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      _redirectToLogin(message: 'Vui lòng đăng nhập.');
      return;
    }

    try {
      final profile = await ApiService.getProfile();

      if (profile == null || profile['fullName'] == null) {
        _redirectToLogin(message: 'Phiên đăng nhập đã hết. Đăng nhập lại để tiếp tục.');
        return;
      }

      final taskData = await fetchTaskTrend();
      final issueData = await fetchIssueTrend();

      setState(() {
        userName = profile['fullName'];
        taskTrend = taskData;
        issueTrend = issueData;
      });

      fetchData();
      
    } catch (e) {
      print('Lỗi lấy thông tin người dùng: $e');
      _redirectToLogin(message: 'Có lỗi xảy ra. Đăng nhập lại để tiếp tục.');
    }
  }

  void _redirectToLogin({required String message}) {
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Map<DateTime, Map<String, int>> parseTimeSeriesData(dynamic json) {
    final rawList = json['\$values'] as List<dynamic>;

    final result = <DateTime, Map<String, int>>{};

    for (var item in rawList) {
      final date = DateTime.parse(item['date']);
      result[date] = {
        "Not Started": item['notStarted'],
        "In Progress": item['inProgress'],
        "Completed": item['completed'],
      };
    }

    return result;
  }

  Future<Map<DateTime, Map<String, int>>> fetchIssueTrend() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/issue/trend'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return parseTimeSeriesData(jsonData);
    } else {
      throw Exception('Failed to load issue trend');
    }
  }

  Future<Map<DateTime, Map<String, int>>> fetchTaskTrend() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/task/trend'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return parseTimeSeriesData(jsonData);
    } else {
      throw Exception('Failed to load task trend');
    }
  }

  void downloadTxtWeb(Uint8List bytes, String filename) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> downloadCrawlFile() async {
    setState(() {
      isDownloading = true;
    });

    try {
      final response = await http.get(Uri.parse('https://crawlflow.xyz/webhook/crawl-download'));
      if (response.statusCode == 200) {
        final now = DateTime.now();
        final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(now);
        final fileName = 'data_$formattedDate.txt';
        downloadTxtWeb(response.bodyBytes, fileName);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Tải xuống thành công!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        print('Download failed: ${response.statusCode}');
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Tải xuống thất bại!'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      print('Lỗi khi tải file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Có lỗi xảy ra khi tải file!'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      setState(() {
        isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return CommonLayout(
      title: 'SThink Dashboard',
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [              
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.filter_list_rounded, color: colorScheme.primary),
                        SizedBox(width: 8),
                        Text(
                          'Bộ lọc dữ liệu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.start,
                      children: [
                        // Type Selector
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: DropdownButton<String>(
                            value: selectedType,
                            underline: SizedBox(),
                            icon: Icon(Icons.arrow_drop_down_rounded, color: colorScheme.primary),
                            dropdownColor: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            items: ['Task', 'Issue']
                                .map((e) => DropdownMenuItem(
                                  value: e, 
                                  child: Text(
                                    e,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedType = val!;
                              });
                              fetchData();
                            },
                          ),
                        ),
                        
                        // Date Range Picker
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2023),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: theme.copyWith(
                                      colorScheme: colorScheme.copyWith(
                                        primary: colorScheme.primary,
                                        onPrimary: colorScheme.onPrimary,
                                        surface: colorScheme.surface,
                                        onSurface: colorScheme.onSurface,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  startDate = picked.start;
                                  endDate = picked.end;
                                });
                                fetchData();
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: colorScheme.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.secondary.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.date_range_rounded, 
                                    color: colorScheme.secondary, 
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    startDate != null && endDate != null
                                        ? '${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}'
                                        : 'Chọn khoảng ngày',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Reset Button
                        if (startDate != null || endDate != null)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                startDate = null;
                                endDate = null;
                              });
                              fetchData();
                            },
                            icon: Icon(Icons.refresh_rounded, size: 20),
                            label: Text('Reset bộ lọc'),
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              // Chart Section
              AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: isLoading
                    ? Container(
                        height: 400,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Đang tải dữ liệu...',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: MultiLineChartWidget(
                            title: '$selectedType Trend Analysis',
                            timeSeriesData: timeSeriesData,
                          ),
                        ),
                      ),
              ),
              
              const SizedBox(height: 24),
              
              // Data Table Section
              if (!isLoading && timeSeriesData.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(Icons.table_chart_rounded, color: colorScheme.primary),
                            SizedBox(width: 8),
                            Text(
                              'Chi tiết dữ liệu',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        child: TrendDataTable(timeSeriesData: timeSeriesData),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}