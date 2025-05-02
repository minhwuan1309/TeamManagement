import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/screens/project/project_detail_page.dart';

class ProjectPage extends StatefulWidget {
  const ProjectPage({super.key});

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  List projects = [];
  bool isLoading = true;
  List<dynamic> allProjects = [];
  bool showDeletedOnly = false;

  final String baseUrl = 'http://localhost:5053/api';

  @override
  void initState() {
    super.initState();
    fetchProjects();
  }

  Future<void> fetchProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.get(
      Uri.parse('$baseUrl/project'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded.containsKey(r'$values')) {
        allProjects = decoded[r'$values'];
        applyFilter(); // gọi sau khi fetch
      } else {
        setState(() => isLoading = false);
      }
    }
  }

  void applyFilter() {
    setState(() {
      if (showDeletedOnly) {
        projects = allProjects.where((p) => p['isDeleted'] == true).toList();
      } else {
        projects = allProjects.where((p) => p['isDeleted'] == false).toList();
      }
      isLoading = false;
    });
  }

  Widget buildFilterToggle() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              "Hiển thị project đã xoá",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Switch(
              value: showDeletedOnly,
              activeColor: Theme.of(context).primaryColor,
              onChanged: (val) {
                setState(() {
                  showDeletedOnly = val;
                  applyFilter();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProjectMobileCard(dynamic project) {
    final bool isDeleted = project['isDeleted'] ?? false;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  child: Icon(
                    Icons.folder,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project['name'] ?? 'Không có tên',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (project['startDate'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Bắt đầu: ${project['startDate']?.split('T')[0] ?? '---'}",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProjectDetailPage(projectId: project['id']),
                      ),
                    ).then((shouldRefresh) {
                      if (shouldRefresh == true) fetchProjects();
                    });
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            buildInfoRow(
              Icons.description,
              'Mô tả',
              project['description'] ?? 'Không có mô tả',
            ),
            buildInfoRow(
              isDeleted ? Icons.delete : Icons.check_circle,
              'Trạng thái',
              isDeleted ? 'Đã xoá' : 'Đang hoạt động',
              isDeleted ? Colors.red : Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(
    IconData icon,
    String label,
    String value, [
    Color? iconColor,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: iconColor ?? Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDesktopTable() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20,
            headingRowColor: MaterialStateProperty.all(
              Colors.blue.shade700.withOpacity(0.1),
            ),
            columns: const [
              DataColumn(
                label: SizedBox(
                  width: 200,
                  child: Text(
                    'Tên dự án',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: 150,
                  child: Text(
                    'Ngày bắt đầu',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: 250,
                  child: Text(
                    'Mô tả',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: 120,
                  child: Text(
                    'Trạng thái',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: 100,
                  child: Text(
                    'Chi tiết',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
            rows: projects.map((project) {
              final bool isDeleted = project['isDeleted'] ?? false;

              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      project['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  DataCell(
                    Text(
                      project['startDate']?.split('T')[0] ?? '---',
                    ),
                  ),
                  DataCell(
                    Text(
                      project['description'] ?? '',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  DataCell(
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDeleted
                              ? Colors.red.withOpacity(0.2)
                              : Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isDeleted ? 'Đã xoá' : 'Hoạt động',
                          style: TextStyle(
                            color: isDeleted ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Center(
                      child: IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'Xem chi tiết',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProjectDetailPage(projectId: project['id']),
                            ),
                          ).then((shouldRefresh) {
                            if (shouldRefresh == true) fetchProjects();
                          });
                        },
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách dự án'),
        backgroundColor: Colors.blue.shade700,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.grey[50]),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  buildFilterToggle(),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return constraints.maxWidth < 600
                            ? ListView(
                                children: projects.map(buildProjectMobileCard).toList(),
                              )
                            : buildDesktopTable();
                      },
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/project/create').then((shouldReload) {
            if (shouldReload == true) fetchProjects();
          });
        },
        child: const Icon(Icons.add),
        tooltip: 'Tạo dự án mới',
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
      ),
    );
  }
}