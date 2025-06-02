import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  String userName = '';
  Map<DateTime, Map<String, int>> taskTrend = {};
  Map<DateTime, Map<String, int>> issueTrend = {};

  String selectedType = 'Task';
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = true;
  Map<DateTime, Map<String, int>> timeSeriesData = {};


  final String metabaseUrl = metabasePublicUrl;


  @override
  void initState() {
    super.initState();
    fetchData();
    loadUserAndStats();
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
    }
  }

  Future<void> loadUserAndStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    try {
      final profile = await ApiService.getProfile();
      final taskData = await fetchTaskTrend();
      final issueData = await fetchIssueTrend();

      setState(() {
        userName = profile?['fullName'] ?? '';
        taskTrend = taskData;
        issueTrend = issueData;
      });
    } catch (e) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hãy đăng nhập để tiếp tục!')),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      title: 'SThink',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                DropdownButton<String>(
                  value: selectedType,
                  items: ['Task', 'Issue']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedType = val!;
                    });
                    fetchData(); // gọi API khi đổi loại
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        startDate = picked.start;
                        endDate = picked.end;
                      });
                      fetchData();
                    }
                  },
                  child: Text(
                    startDate != null && endDate != null
                        ? '${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}'
                        : 'Chọn khoảng ngày',
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      startDate = null;
                      endDate = null;
                    });
                    fetchData(); // gọi API để reset khoảng ngày
                  },
                  icon: const Icon(Icons.refresh, size: 18), 
                  label: const Text('Reset bộ lọc'),
                )
              ],
            ),

            const SizedBox(height: 16),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : MultiLineChartWidget(
                    title: selectedType,
                    timeSeriesData: timeSeriesData,
                  ),
                  TrendDataTable(timeSeriesData: timeSeriesData)
          ],
        ),
      ),
    );
  }
}