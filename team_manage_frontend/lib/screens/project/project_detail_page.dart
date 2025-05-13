import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/api_service.dart';
import 'package:team_manage_frontend/layouts/common_layout.dart';
import 'package:team_manage_frontend/screens/modules/module_detail_page.dart';
import 'edit_project_page.dart';

class ProjectDetailPage extends StatefulWidget {
  final int projectId;

  const ProjectDetailPage({super.key, required this.projectId});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  Map<String, dynamic>? project;
  bool isLoading = true;
  final dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    fetchProject();
  }

  Future<void> fetchProject() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.get(
      Uri.parse('$baseUrl/project/${widget.projectId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      setState(() {
        project = jsonDecode(res.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi: ${res.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget buildMemberCard(dynamic member) {
    final avatar = member['avatar'];
    final fullName = member['fullName'] ?? member['userId'] ?? 'Chưa rõ';
    final role = member['roleInProject'] ?? 'viewer';

    final roleColors = {
      'admin': Colors.red,
      'dev': Colors.blue,
      'tester': Colors.green,
      'viewer': Colors.grey,
    };

    final roleColor = roleColors[role.toLowerCase()] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          backgroundImage:
              avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
          child:
              (avatar == null || avatar.isEmpty)
                  ? Text(
                    fullName[0].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  )
                  : null,
        ),
        title: Text(
          fullName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.person_outline, size: 16, color: roleColor),
            const SizedBox(width: 4),
            Text('Vai trò: $role', style: TextStyle(color: roleColor)),
          ],
        ),
      ),
    );
  }

  Widget buildModuleCard(dynamic module) {
    // Chuyển đổi trạng thái từ module sang chuỗi hiển thị
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

    // Lấy màu trạng thái
    Color _getStatusColor(dynamic status) {
      if (status is int) {
        switch (status) {
          case 0:
            return Colors.grey;
          case 1:
            return Colors.blue;
          case 2:
            return Colors.green;
          default:
            return Colors.grey;
        }
      } else if (status is String) {
        switch (status.toLowerCase()) {
          case 'none':
            return Colors.grey;
          case 'inprogress':
          case 'in_progress':
            return Colors.blue;
          case 'done':
            return Colors.green;
          default:
            return Colors.grey;
        }
      }
      return Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          Icons.view_module,
          color: _getStatusColor(module['status']),
        ),
        title: Text(module['name'] ?? 'Không có tên'),
        subtitle: Text("Trạng thái: ${_getStatusText(module['status'])}"),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ModuleDetailPage.withId(moduleId: module['id']),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildProjectInfoCard() {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.2),
                  child: Icon(
                    Icons.folder,
                    color: Theme.of(context).primaryColor,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project!['name'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (project!['startDate'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Ngày bắt đầu: ${dateFormat.format(DateTime.parse(project!['startDate']))}",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            // Description
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.description, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Mô tả:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        project!['description'] ?? 'Không có mô tả',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> confirmToggleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              project!['isDeleted'] ? 'Khôi phục dự án?' : 'Xoá dự án?',
            ),
            content: Text(
              project!['isDeleted']
                  ? 'Bạn có chắc muốn khôi phục dự án này không?'
                  : 'Bạn có chắc chắn muốn xoá dự án này?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Huỷ'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  project!['isDeleted'] ? 'Khôi phục' : 'Xoá',
                  style: TextStyle(
                    color: project!['isDeleted'] ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final res = await http.delete(
        Uri.parse('$baseUrl/project/delete/${widget.projectId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.body), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Trả về signal để cha refresh
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${res.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> confirmHardDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xoá vĩnh viễn'),
            content: const Text(
              'Bạn có chắc muốn xoá dự án này vĩnh viễn? Thao tác không thể hoàn tác.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Huỷ'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Xoá vĩnh viễn',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final res = await http.delete(
        Uri.parse('$baseUrl/project/hard-delete/${widget.projectId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.body), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${res.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      title: 'Chi tiết dự án',
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: 'Chỉnh sửa Project',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => EditProjectPage(projectId: widget.projectId),
              ),
            ).then((shouldReload) {
              if (shouldReload == true) fetchProject();
            });
          },
        ),
        IconButton(
          icon: Icon(
            project?['isDeleted'] == true ? Icons.restore : Icons.delete,
            color: Colors.red,
          ),
          tooltip: project?['isDeleted'] == true ? 'Khôi phục' : 'Xoá Project',
          onPressed: confirmToggleDelete,
        ),
        if (project?['isDeleted'] == true)
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Xoá vĩnh viễn',
            onPressed: confirmHardDelete,
          ),
      ],
      child: Container(
        decoration: BoxDecoration(color: Colors.grey[100]),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : project == null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Không tìm thấy project",
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Quay lại'),
                      ),
                    ],
                  ),
                )
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header card with project info
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor: Colors.blue[600],
                                    child: const Icon(
                                      Icons.folder,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          project!['name'],
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        if (project!['startDate'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 16,
                                                  color: Colors.blue[700],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "Ngày bắt đầu: ${dateFormat.format(DateTime.parse(project!['startDate']))}",
                                                  style: TextStyle(
                                                    color: Colors.blue[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 32),
                              // Description
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.description,
                                    color: Colors.blue[800],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Mô tả:",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[800],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          project!['description'] ??
                                              'Không có mô tả',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Members section
                      Container(
                        color: Colors.white,
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Row(
                                children: [
                                  Icon(Icons.people, color: Colors.blue[700]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Danh sách thành viên',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if ((project!['members']?['\$values'] ?? [])
                                .isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    "Chưa có thành viên",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount:
                                    (project!['members']?['\$values'] ?? [])
                                        .length,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemBuilder: (context, index) {
                                  final member =
                                      (project!['members']?['\$values'] ??
                                          [])[index];
                                  return buildMemberCard(member);
                                },
                              ),
                          ],
                        ),
                      ),

                      // Modules section
                      Container(
                        color: Colors.white,
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.view_module,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Danh sách module',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if ((project!['modules']?['\$values'] ?? [])
                                .isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    "Chưa có module",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount:
                                    (project!['modules']?['\$values'] ?? [])
                                        .length,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemBuilder: (context, index) {
                                  final module =
                                      (project!['modules']?['\$values'] ??
                                          [])[index];
                                  return buildModuleCard(module);
                                },
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
      ),
    );
  }
}
