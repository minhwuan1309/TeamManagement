import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/api_service.dart';
import 'package:team_manage_frontend/layouts/common_layout.dart';
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
  TextEditingController searchController = TextEditingController();
  List<dynamic> filteredProjects = [];

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
      // Apply text search filter if search text is not empty
      if (searchController.text.isNotEmpty) {
        filteredProjects = projects.where((project) {
          final name = project['name'] ?? '';
          final description = project['description'] ?? '';
          final searchTerm = searchController.text.toLowerCase();
          return name.toLowerCase().contains(searchTerm) || 
                 description.toLowerCase().contains(searchTerm);
        }).toList();
      } else {
        filteredProjects = projects;
      }
      isLoading = false;
    });
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
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.2),
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
                        builder:
                            (context) =>
                                ProjectDetailPage(projectId: project['id']),
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

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      title: 'Quản lý dự án',
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
            child: Container(
        decoration: BoxDecoration(color: Colors.grey[50]),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter section similar to user management page
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Bộ lọc',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Search field with rounded border
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm theo tên, mô tả...',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            applyFilter();
                          });
                        },
                      ),
                    ),
                  ),
                  
                  // Filter buttons similar to user management UI
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              showDeletedOnly = false;
                              applyFilter();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: !showDeletedOnly ? Colors.grey.shade200 : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: Text('Hoạt động'),
                        ),
                        SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              showDeletedOnly = true;
                              applyFilter();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: showDeletedOnly ? Colors.grey.shade200 : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: Text('Đã xoá'),
                        ),
                      ],
                    ),
                  ),

                  // Projects list/table with responsive layout
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 600) {
                          // Mobile view - cards
                          return filteredProjects.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.folder_off,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      showDeletedOnly
                                          ? "Không có dự án nào đã xoá"
                                          : "Chưa có dự án nào",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.only(
                                  bottom: 80,
                                ), // Space for FAB
                                itemCount: filteredProjects.length,
                                itemBuilder:
                                    (context, index) =>
                                        buildProjectMobileCard(
                                          filteredProjects[index],
                                        ),
                              );
                        } else {
                          // Desktop view - table
                          return filteredProjects.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.folder_off,
                                      size: 72,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      showDeletedOnly
                                          ? "Không có dự án nào đã xoá"
                                          : "Chưa có dự án nào",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : Card(
                                margin: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(0),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columnSpacing: 20,
                                      headingRowColor:
                                          MaterialStateProperty.all(
                                            Color(0xFF6A5ACD), // Purple color similar to user management
                                          ),
                                      headingTextStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      horizontalMargin: 12,
                                      columns: const [
                                        DataColumn(
                                          label: SizedBox(
                                            width: 200,
                                            child: Text('Tên dự án'),
                                          ),
                                        ),
                                        DataColumn(
                                          label: SizedBox(
                                            width: 150,
                                            child: Text('Ngày bắt đầu'),
                                          ),
                                        ),
                                        DataColumn(
                                          label: SizedBox(
                                            width: 250,
                                            child: Text('Mô tả'),
                                          ),
                                        ),
                                        DataColumn(
                                          label: SizedBox(
                                            width: 120,
                                            child: Text('Trạng thái'),
                                          ),
                                        ),
                                        DataColumn(
                                          label: SizedBox(
                                            width: 150,
                                            child: Text('Thao tác'),
                                          ),
                                        ),
                                      ],
                                      rows:
                                          filteredProjects.map((project) {
                                            final bool isDeleted =
                                                project['isDeleted'] ?? false;

                                            return DataRow(
                                              cells: [
                                                DataCell(
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 16,
                                                        backgroundColor:
                                                            Theme.of(context)
                                                                .primaryColor
                                                                .withOpacity(
                                                                  0.2,
                                                                ),
                                                        child: Icon(
                                                          Icons.folder,
                                                          color:
                                                              Theme.of(
                                                                context,
                                                              ).primaryColor,
                                                          size: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 10,
                                                      ),
                                                      Text(
                                                        project['name'] ?? '',
                                                        style:
                                                            const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    project['startDate']
                                                            ?.split('T')[0] ??
                                                        '---',
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    project['description'] ??
                                                        '',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 2,
                                                  ),
                                                ),
                                                DataCell(
                                                  Center(
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            isDeleted
                                                                ? Colors.red
                                                                    .withOpacity(
                                                                      0.2,
                                                                    )
                                                                : Colors.green
                                                                    .withOpacity(
                                                                      0.2,
                                                                    ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        isDeleted
                                                            ? 'Đã xoá'
                                                            : 'Hoạt động',
                                                        style: TextStyle(
                                                          color:
                                                              isDeleted
                                                                  ? Colors.red
                                                                  : Colors
                                                                      .green,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.visibility,
                                                          color: Colors.blue,
                                                        ),
                                                        tooltip:
                                                            'Xem chi tiết',
                                                        onPressed: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (
                                                                    context,
                                                                  ) => ProjectDetailPage(
                                                                    projectId:
                                                                        project['id'],
                                                                  ),
                                                            ),
                                                          ).then((
                                                            shouldRefresh,
                                                          ) {
                                                            if (shouldRefresh ==
                                                                true)
                                                              fetchProjects();
                                                          });
                                                        },
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.red,
                                                        ),
                                                        tooltip: 'Xoá',
                                                        onPressed: () {
                                                          // Implement delete logic
                                                        },
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.people,
                                                          color: Colors.blue,
                                                        ),
                                                        tooltip: 'Quản lý thành viên',
                                                        onPressed: () {
                                                          // Implement team management
                                                        },
                                                      ),
                                                    ],
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
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}