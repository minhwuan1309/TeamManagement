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
    if (status is int) {
      switch (status) {
        case 0:
          return Colors.blueGrey.shade300;
        case 1:
          return Colors.blue.shade300;
        case 2:
          return Colors.green.shade600;
        default:
          return Colors.red.shade300;
      }
    }
    else if(status is String) {
      switch (status.toLowerCase()) {
        case 'none':
          return Colors.blueGrey.shade300;
        case 'inprogress':
        case 'in_progress':
          return Colors.blue.shade300;
        case 'done':
          return Colors.green.shade600;
        default:
          return Colors.red.shade300;
      }
    }
    return Colors.red.shade300;
  }


  Map<String, dynamic> getStatusColorMap(dynamic status) {
    switch (status) {
      case 0:
        return {'color': Colors.grey, 'text': 'Chưa bắt đầu'};
      case 1:
        return {'color': Colors.orange, 'text': 'Đang tiến hành'};
      case 2:
        return {'color': Colors.green, 'text': 'Hoàn tích'};
      default:
        return {'color': Colors.black45, 'text': 'Không xác định'};
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return CommonLayout(
      title: 'Quản lý task',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and filter section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            margin: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bộ lọc',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Project dropdown
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Chọn Project',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    prefixIcon: const Icon(Icons.folder_outlined),
                  ),
                  value: selectedProjectId,
                  items: projects.map<DropdownMenuItem<int>>((project) {
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
                
                const SizedBox(height: 16),
                
                // Module dropdown
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Chọn Module',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    prefixIcon: const Icon(Icons.view_module_outlined),
                  ),
                  value: selectedModuleId,
                  items: modules.map<DropdownMenuItem<int>>((module) {
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
              ],
            ),
          ),
          
          // Task list section
          Expanded(
            child: isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : tasks.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không có task nào',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (selectedModuleId != null)
                        TextButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateTaskPage(moduleId: selectedModuleId!),
                              ),
                            );
                            if (result == true) fetchTasks(selectedModuleId!);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Tạo task mới'),
                        ),
                    ],
                  ),
                )
              : isMobile
                ? _buildMobileTaskList()
                : _buildDesktopTaskList(),
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
                        builder: (_) => CreateTaskPage(moduleId: selectedModuleId!),
                      ),
                    );
                    if (result == true) fetchTasks(selectedModuleId!);
                  },
                  child: const Icon(Icons.add),
                  tooltip: 'Tạo task mới',
                  backgroundColor: Colors.blue,
                )
              : null,
    );
  }

  Widget _buildMobileTaskList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              task['title'] ?? 'Không có tiêu đề',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16, 
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        task['assignedUserName'] ?? 'Không rõ',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: getStatusColor(task['status']),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusText(task['status']),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskDetailPage(taskId: task['id']),
                ),
              );
            },
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTaskList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.indigo[600],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Tiêu đề',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Người đảm nhiệm',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Trạng thái',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 50),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Table body
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailPage(taskId: task['id']),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            task['title'] ?? 'Không có tiêu đề',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(task['assignedUserName'] ?? 'Không rõ'),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: getStatusColor(task['status']),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _getStatusText(task['status']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: IconButton(
                            icon: Icon(Icons.arrow_forward_ios, size: 16),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TaskDetailPage(taskId: task['id']),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
