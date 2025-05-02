import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/api_service.dart';

class HomeScreen extends StatelessWidget {
  
  const HomeScreen({Key? key}) : super(key: key);

  void _navigate(BuildContext context, String route) {
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }
  
  Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return false;

    final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(token.split(".")[1]))));
    final role = prefs.getInt('role');
    return role == 0;
  }

  Future<String?> getCurrentUserName() async {
    final profile = await ApiService.getProfile();
    return profile != null ? profile['fullName'] as String? : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Team Manage',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        actions: [
          FutureBuilder<String?>(
            future: getCurrentUserName(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: Row(
                    children: [
                      const Icon(Icons.account_circle),
                      const SizedBox(width: 8),
                      Text(
                        snapshot.data ?? 'Tài khoản',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        elevation: 8,
        child: FutureBuilder<bool>(
          future: isAdmin(),
          builder: (context, snapshot) {
            final isAdmin = snapshot.data ?? false;
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
                            Icon(
                              Icons.dashboard,
                              color: Colors.white,
                              size: 36,
                            ),
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
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
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
                    leading: const Icon(
                      Icons.home_rounded,
                      color: Colors.blue,
                    ),
                    title: const Text(
                      'Trang chủ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    onTap: () => _navigate(context, '/home'),
                    tileColor: Colors.blue.withOpacity(0.1),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                  ),
                  
                  ListTile(
                    leading: const Icon(
                      Icons.person, 
                      color: Colors.blue
                    ),
                    title: const Text(
                      'Hồ sơ cá nhân',
                      style: TextStyle(fontWeight: FontWeight.w500)  
                    ),
                    onTap: () => _navigate(context, '/profile'),
                  ),

                  if (isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ListTile(
                        leading: const Icon(
                          Icons.people_alt_rounded,
                          color: Colors.blue,
                        ),
                        title: const Text(
                          'Người dùng',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        onTap: () => _navigate(context, '/user'),
                      ),
                    ),

                  ListTile(
                    leading: const Icon(
                      Icons.person, 
                      color: Colors.blue
                    ),
                    title: const Text(
                      'Dự án',
                      style: TextStyle(fontWeight: FontWeight.w500)  
                    ),
                    onTap: () => _navigate(context, '/project'),
                  ),
                  
                  const Divider(thickness: 1, height: 32),
                  ListTile(
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Đăng xuất',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/');
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: FutureBuilder<String?>(
            future: getCurrentUserName(),
            builder: (context, snapshot) {
              String name = snapshot.data ?? '';
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              return Card(
                margin: const EdgeInsets.all(16),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.dashboard_customize_rounded,
                        size: 80,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Chào mừng ${name.isNotEmpty ? name : 'bạn'}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'đến với hệ thống TeamManage!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Quản lý dự án và đội nhóm hiệu quả',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}