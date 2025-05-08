import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/layouts/common_layout.dart';
import 'package:team_manage_frontend/screens/tasks/create_task_page.dart';
import 'package:team_manage_frontend/screens/tasks/task_detail_page.dart';
import 'package:team_manage_frontend/api_service.dart';


class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  List projects = [];
  List modules = [];
  List tasks = [];

  int? selectedProjectId;
  int? selectedModuleId;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchProjects();
  }

  Future<void> fetchProjects() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/project'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List<dynamic> projectList =
            decoded is Map && decoded.containsKey(r'$values')
                ? decoded[r'$values']
                : (decoded is List ? decoded : []);

        setState(() {
          projects = projectList.where((p) => p['isDeleted'] == false).toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải project: ${res.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
    }
  }

  Future<void> fetchModules(int projectId) async {
    setState(() {
      isLoading = true;
      modules = [];
      selectedModuleId = null;
      tasks = [];
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/module?projectId=$projectId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List moduleList =
            decoded is Map && decoded.containsKey(r'$values')
                ? decoded[r'$values']
                : (decoded is List ? decoded : []);

        setState(() {
          modules = moduleList;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải module: ${res.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
    }
  }

  Future<void> fetchTasks(int moduleId) async {
    setState(() {
      isLoading = true;
      tasks = [];
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/task/module/$moduleId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List taskList =
            decoded is Map && decoded.containsKey(r'$values')
                ? decoded[r'$values']
                : (decoded is List ? decoded : []);

        setState(() {
          tasks = taskList;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải task: ${res.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
    }
  }

  String _getStatusText(dynamic status) {
    if (status is int) {
      switch (status) {
        case 0:
          return 'Chưa bắt đầu';
        case 1:
          return 'Đang tiến hành';
        case 2:
          return 'Hoàn thành';
        default:
          return 'Không xác định';
      }
    } else if (status is String) {
      switch (status.toLowerCase()) {
        case 'none':
          return 'Chưa bắt đầu';
        case 'inprogress':
        case 'in_progress':
          return 'Đang tiến hành';
        case 'done':
          return 'Hoàn thành';
        default:
          return 'Không xác định';
      }
    }
    return 'Không xác định';
  }

  Color getStatusColor(dynamic status) {
    switch (status) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      default:
        return Colors.black45;
    }
  }

  Widget buildTaskCard(dynamic task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(task['title'] ?? 'Không có tiêu đề'),
        subtitle: Text(
          'Người đảm nhiệm: ${task['assignedUserName'] ?? 'Không rõ'}',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: getStatusColor(task['status']),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _getStatusText(task['status']),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailPage(taskId: task['id']),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      title: 'Quản lý task',
      child: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Chọn Project',
                border: OutlineInputBorder(),
              ),
              value: selectedProjectId,
              items:
                  projects.map<DropdownMenuItem<int>>((project) {
                    return DropdownMenuItem<int>(
                      value: project['id'],
                      child: Text(project['name'] ?? '---'),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedProjectId = value;
                  selectedModuleId = null;
                  modules = [];
                  tasks = [];
                });
                if (value != null) fetchModules(value);
              },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Chọn Module',
                border: OutlineInputBorder(),
              ),
              value: selectedModuleId,
              items:
                  modules.map<DropdownMenuItem<int>>((module) {
                    return DropdownMenuItem<int>(
                      value: module['id'],
                      child: Text(module['name'] ?? '---'),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedModuleId = value;
                });
                if (value != null) fetchTasks(value);
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : tasks.isEmpty
                    ? const Center(child: Text('Không có task nào.'))
                    : ListView(
                      children: tasks.map<Widget>(buildTaskCard).toList(),
                    ),
          ),
        ],
      ),
      floatingActionButton:
          (selectedModuleId != null)
              ? FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => CreateTaskPage(moduleId: selectedModuleId!),
                    ),
                  );
                  if (result == true) fetchTasks(selectedModuleId!);
                },
                child: const Icon(Icons.add),
                tooltip: 'Tạo task mới',
                backgroundColor: Colors.blue.shade700,
              )
              : null,
    );
  }
}
