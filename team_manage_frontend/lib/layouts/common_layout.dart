import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/api_service.dart';

class CommonLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final bool showAppBar;
  final List<Widget>? appBarActions;
  final Widget? floatingActionButton;

  const CommonLayout({
    Key? key,
    required this.child,
    required this.title,
    this.showAppBar = true,
    this.appBarActions,
    this.floatingActionButton,
  }) : super(key: key);

  void _navigate(BuildContext context, String route) {
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }

  Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getInt('role');
    return role == 0;
  }

  Future<String?> getCurrentUserName() async {
    final profile = await ApiService.getProfile();
    return profile != null ? profile['fullName'] as String? : null;
  }

  Widget _buildDrawerContent(BuildContext context, bool isAdmin) {
    return Container(
      color: Colors.white,
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Row(
                  children: [
                    Icon(Icons.dashboard, color: Colors.white, size: 36),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SThink",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Team Management",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FutureBuilder<String?>(
                  future: getCurrentUserName(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text(
                        'Đang tải tên...',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      );
                    }
                    final name = snapshot.data ?? 'Không rõ tên';
                    return Row(
                      children: [
                        const Icon(
                          Icons.person,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
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
            leading: const Icon(Icons.home_rounded, color: Colors.blue),
            title: const Text(
              'Trang chủ',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            onTap: () => _navigate(context, '/'),
            tileColor:
                title == 'Trang chủ' ? Colors.blue.withOpacity(0.1) : null,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.blue),
            title: const Text(
              'Hồ sơ cá nhân',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            onTap: () => _navigate(context, '/profile'),
            tileColor:
                title == 'Hồ sơ cá nhân' ? Colors.blue.withOpacity(0.1) : null,
          ),
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.people, color: Colors.blue),
              title: const Text(
                'Quản lý người dùng',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () => _navigate(context, '/user'),
              tileColor:
                  title == 'Quản lý người dùng'
                      ? Colors.blue.withOpacity(0.1)
                      : null,
            ),
          ListTile(
            leading: const Icon(Icons.folder, color: Colors.blue),
            title: const Text(
              'Dự án (Projects)',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            onTap: () => _navigate(context, '/project'),
            tileColor: title == 'Dự án' ? Colors.blue.withOpacity(0.1) : null,
          ),
          ListTile(
            leading: const Icon(Icons.view_module, color: Colors.blue),
            title: const Text(
              'Nhóm chức năng (Modules)',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            onTap: () => _navigate(context, '/module'),
            tileColor:
                title == 'Nhóm chức năng' ? Colors.blue.withOpacity(0.1) : null,
          ),
          ListTile(
            leading: const Icon(Icons.task, color: Colors.blue),
            title: const Text(
              'Công việc (Tasks)',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            onTap: () => _navigate(context, '/task'),
            tileColor:
                title == 'Công việc' ? Colors.blue.withOpacity(0.1) : null,
          ),
          const Divider(thickness: 1, height: 32),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),

            onTap: () {
              ApiService.logout(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar:
          isMobile && showAppBar
              ? AppBar(
                title: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                elevation: 1,
                backgroundColor: Colors.grey.shade100,
                actions: appBarActions,
                leading:
                    showAppBar &&
                            Navigator.canPop(context) &&
                            title != 'Trang chủ'
                        ? IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                        : null,
              )
              : null,
      drawer:
          isMobile
              ? Drawer(
                elevation: 8,
                child: FutureBuilder<bool>(
                  future: isAdmin(),
                  builder: (context, snapshot) {
                    final isAdminUser = snapshot.data ?? false;
                    return _buildDrawerContent(context, isAdminUser);
                  },
                ),
              )
              : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          if (isMobile) {
            // Mobile layout
            return Container(
              decoration: const BoxDecoration(color: Colors.white),
              child: child,
            );
          } else {
            // Desktop layout with fixed sidebar
            return Row(
              children: [
                SizedBox(
                  width: constraints.maxWidth / 5,
                  child: Container(
                    color: Colors.white,
                    child: FutureBuilder<bool>(
                      future: isAdmin(),
                      builder: (context, snapshot) {
                        final isAdminUser = snapshot.data ?? false;
                        return _buildDrawerContent(context, isAdminUser);
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Scaffold(
                    appBar:
                        showAppBar
                            ? AppBar(
                              title: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              elevation: 1,
                              backgroundColor: Colors.white,
                              actions: appBarActions,
                              automaticallyImplyLeading: false,
                              leading:
                                  Navigator.canPop(context)
                                      ? IconButton(
                                        icon: const Icon(Icons.arrow_back),
                                        onPressed:
                                            () => Navigator.of(context).pop(),
                                      )
                                      : null,
                            )
                            : null,
                    body: Container(
                      decoration: const BoxDecoration(color: Colors.white),
                      child: child,
                    ),
                    floatingActionButton: floatingActionButton,
                  ),
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: isMobile ? floatingActionButton : null,
    );
  }
}
