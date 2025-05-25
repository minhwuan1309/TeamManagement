import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/api_service.dart';
import 'package:team_manage_frontend/layouts/common_layout.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '';
  Map<String, dynamic>? taskStats;
  Map<String, dynamic>? issueStats;

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
    final profile = await ApiService.getProfile();
    final task = await fetchDashboardTaskAll();
    final issue = await fetchDashboardIssueAll();

    setState(() {
      userName = profile?['fullName'] ?? '';
      taskStats = task['data'];
      issueStats = issue['data'];
    });
  }


  Widget _buildStatCard(String title, IconData icon, Color color, int value) {
    return Expanded(
      child: Card(
        elevation: 3,
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                value.toString(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardSection(String title, Map<String, dynamic>? data, Color color, IconData icon) {
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard("Tổng", icon, color, data["total${title}"]),
            const SizedBox(width: 12),
            _buildStatCard("Chưa bắt đầu", icon, color, data["total${title}NotStarted"]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard("Đang thực hiện", icon, color, data["total${title}InProgress"]),
            const SizedBox(width: 12),
            _buildStatCard("Hoàn thành", icon, color, data["total${title}Completed"]),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return CommonLayout(
      title: 'SThink',

      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildDashboardSection("Task", taskStats, Colors.blue, Icons.task),
            _buildDashboardSection("Issue", issueStats, Colors.red, Icons.bug_report),
          ],
        ),
      ),
    );
  }
}
