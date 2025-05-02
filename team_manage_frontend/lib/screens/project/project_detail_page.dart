import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_project_page.dart';

class ProjectDetailPage extends StatefulWidget {
  final int projectId;

  const ProjectDetailPage({super.key, required this.projectId});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  final String baseUrl = 'http://localhost:5053/api';
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
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
            Text(
              'Vai trò: $role',
              style: TextStyle(color: roleColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildModuleCard(dynamic module) {
    final statusColors = {
      'completed': Colors.green,
      'in progress': Colors.blue,
      'pending': Colors.orange,
      'cancelled': Colors.red,
    };
    
    final status = module['status']?.toString().toLowerCase() ?? 'pending';
    final statusColor = statusColors[status] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.view_module, color: statusColor),
        ),
        title: Text(
          module['name'],
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: statusColor),
            const SizedBox(width: 4),
            Text(
              'Trạng thái: ${module['status']}',
              style: TextStyle(color: statusColor),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          // Navigate to module detail
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Chức năng xem chi tiết module đang phát triển"))
          );
        },
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
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
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
                              Icon(Icons.calendar_today, 
                                size: 16, 
                                color: Colors.grey[600]
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
            SnackBar(
              content: Text(res.body),
              backgroundColor: Colors.green,
            )
          );
          Navigator.pop(context, true); // Trả về signal để cha refresh
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${res.body}'),
              backgroundColor: Colors.red,
            )
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
            SnackBar(
              content: Text(res.body),
              backgroundColor: Colors.green,
            )
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${res.body}'),
              backgroundColor: Colors.red,
            )
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Project'),
        backgroundColor: Colors.blue.shade700,
        elevation: 2,
        actions: [
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
              color: Colors.white,
            ),
            tooltip:
                project?['isDeleted'] == true ? 'Khôi phục' : 'Xoá Project',
            onPressed: confirmToggleDelete,
          ),
          if (project?['isDeleted'] == true)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Xoá vĩnh viễn',
              onPressed: confirmHardDelete,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.grey[50]),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : project == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, 
                            size: 64, 
                            color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "Không tìm thấy project",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
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
                        buildProjectInfoCard(),
                        
                        buildSectionTitle('Danh sách thành viên', Icons.people),
                        
                        if ((project!['members']?['\$values'] ?? []).isEmpty)
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              children: (project!['members']?['\$values'] ?? [])
                                  .map<Widget>((m) => buildMemberCard(m))
                                  .toList(),
                            ),
                          ),

                        buildSectionTitle('Danh sách module', Icons.view_module),
                        
                        if ((project!['modules']?['\$values'] ?? []).isEmpty)
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              children: (project!['modules']?['\$values'] ?? [])
                                  .map<Widget>((m) => buildModuleCard(m))
                                  .toList(),
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