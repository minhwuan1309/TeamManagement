import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/api_service.dart';
import 'package:team_manage_frontend/layouts/common_layout.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:team_manage_frontend/screens/tasks/chart_widget.dart';
import 'package:team_manage_frontend/utils/env.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '';
  Map<DateTime, Map<String, int>> issueTrend = {};
  Map<DateTime, Map<String, int>> taskTrend = {};


  final String metabaseUrl = metabasePublicUrl;


  @override
  void initState() {
    super.initState();
    loadUserAndStats();
  }

  Future<Map<String, dynamic>> fetchDashboardTaskAll() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/task/all'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load dashboard task');
    }
  }

  Future<Map<String, dynamic>> fetchDashboardIssueAll() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/issue/all'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load dashboard issue');
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
      final taskData = await fetchIssueTrend();
      final issueData = await fetchTaskTrend();

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
            MultiLineChartWidget(
              title: "Issue",
              timeSeriesData: issueTrend,
            ),
            const SizedBox(height: 16),
            MultiLineChartWidget(
              title: "Task",
              timeSeriesData: taskTrend,
            ),
          ],
        ),
      ),
    );
  }
}