import 'package:flutter/material.dart';
import 'package:team_manage_frontend/api_service.dart';
import 'package:team_manage_frontend/screens/modules/module_tree_widget.dart';
import 'package:team_manage_frontend/screens/project/create_project_page.dart';

class Sidebar extends StatelessWidget {
  bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 768;
  bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 768 && MediaQuery.of(context).size.width < 1024;

  final List<dynamic> projects;
  final int? selectedProjectId;
  final List<Map<String, dynamic>> projectMembers;
  final Map<String, dynamic>? treeModulesData;
  final Function(int) onProjectChanged;
  final Function(Map<String, dynamic>) onModuleSelected;
  final VoidCallback? onRefresh;
  

  const Sidebar({
    Key? key,
    required this.projects,
    required this.selectedProjectId,
    required this.projectMembers,
    required this.treeModulesData,
    required this.onProjectChanged,
    required this.onModuleSelected,
    this.onRefresh,
  }) : super(key: key);

  double getSidebarWidth(BuildContext context) {
    if (isMobile(context)) return MediaQuery.of(context).size.width * 0.85;
    if (isTablet(context)) return MediaQuery.of(context).size.width * 0.35;
    return MediaQuery.of(context).size.width * 0.23;
  }

  Future<String?> getCurrentUserName() async {
    final profile = await ApiService.getProfile();
    return profile != null ? profile['fullName'] as String? : null;
  }
  

  Widget _buildStatusIndicator(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = getSidebarWidth(context);
    final mobile = isMobile(context);
    
    return Container(
      width: sidebarWidth,
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.dashboard, color: Colors.white, size: mobile ? 28 : 36),
                      SizedBox(width: mobile ? 8 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "SThink",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: mobile ? 18 : 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Team Management",
                              style: TextStyle(
                                color: Colors.white, 
                                fontSize: mobile ? 12 : 16
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  FutureBuilder<String?>(
                    future: getCurrentUserName(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text(
                          'Đang tải tên...',
                          style: TextStyle(
                            color: Colors.white70, 
                            fontSize: mobile ? 14 : 18
                          ),
                        );
                      }
                      final name = snapshot.data ?? 'Không rõ tên';
                      return mobile 
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () => ApiService.logout(context),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                  ),
                                  child: const Text(
                                    'Đăng xuất',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              const Icon(
                                Icons.person,
                                color: Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton(
                                onPressed: () => ApiService.logout(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                child: const Text(
                                  'Đăng xuất',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          );
                    },
                  ),
                ],
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Trang chủ'),
              dense: mobile,
              onTap: () => Navigator.pushNamed(context, '/home'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Hồ sơ cá nhân'),
              dense: mobile,
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            FutureBuilder<int?>(
              future: ApiService.getStoredRole(),
              builder: (context, snapshot){
                if (!snapshot.hasData || snapshot.data != 0) return const SizedBox();

                return ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('Quản lý người dùng'),
                  dense: mobile,
                  onTap: () => Navigator.pushNamed(context, '/user'),
                );
              },
            ),
            const Divider(),
            
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: mobile ? 12 : 16,
                vertical: mobile ? 6 : 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(4), 
                    ),
                    child: Text(
                      "Chọn Dự án",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: mobile ? 13 : 14,
                        backgroundColor: Colors.white70,
                      ),
                    ),
                  ),
                  SizedBox(height: mobile ? 6 : 8),
                  mobile
                      ? Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white, // White background for dropdown
                                borderRadius: BorderRadius.circular(4), // Optional: slight rounding
                                border: Border.all(color: Colors.grey.shade300), // Optional: subtle border
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: selectedProjectId,
                                  isExpanded: true,
                                  items: projects.map((p) {
                                    return DropdownMenuItem<int>(
                                      value: p['id'],
                                      child: Text(
                                        p['name'],
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (int? newProjectId) {
                                    if (newProjectId != null) {
                                      onProjectChanged(newProjectId);
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CreateProjectPage(),
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      border: Border.all(color: Colors.green.shade300),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.add, color: Colors.green, size: 20),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white, // White background for dropdown
                                  borderRadius: BorderRadius.circular(4), // Optional: slight rounding
                                  border: Border.all(color: Colors.grey.shade300), // Optional: subtle border
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: selectedProjectId,
                                    isExpanded: true,
                                    items: projects.map((p) {
                                      return DropdownMenuItem<int>(
                                        value: p['id'],
                                        child: Text(p['name']),
                                      );
                                    }).toList(),
                                    onChanged: (int? newProjectId) {
                                      if (newProjectId != null) {
                                        onProjectChanged(newProjectId);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CreateProjectPage(),
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    border: Border.all(color: Colors.green.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.add, color: Colors.green),
                                ),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
            const Divider(),
            
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: mobile ? 12 : 16, 
                vertical: mobile ? 6 : 8
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Danh sách module",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: mobile ? 13 : 14,
                    ),
                  ),
                  SizedBox(height: mobile ? 6 : 8),
                  Wrap(
                    spacing: mobile ? 6 : 8,
                    runSpacing: 4,
                    children: [
                      _buildStatusIndicator("Xong", Colors.green),
                      _buildStatusIndicator("Đang làm", Colors.orange),
                      _buildStatusIndicator("Chưa làm", Colors.grey),
                    ],
                  ),
                ],
              ),
            ),

            if (selectedProjectId != null && treeModulesData != null)
              ModuleDropdownWidget(
                projectId: selectedProjectId!,
                modules: treeModulesData!,
                projectMembers: projectMembers,
                onModuleSelected: onModuleSelected,
                onRefresh: onRefresh,
              )
            else
              Padding(
                padding: EdgeInsets.all(mobile ? 12 : 16),
                child: Text(
                  "Vui lòng chọn một project để xem modules.",
                  style: TextStyle(fontSize: mobile ? 12 : 14),
                ),
              )
          ],
        ),
      ),
    );
  }
}