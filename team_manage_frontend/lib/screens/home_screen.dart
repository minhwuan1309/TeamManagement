import 'package:flutter/material.dart';
import 'package:team_manage_frontend/api_service.dart';
import 'package:team_manage_frontend/layouts/common_layout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  Future<String?> getCurrentUserName() async {
    final profile = await ApiService.getProfile();
    return profile != null ? profile['fullName'] as String? : null;
  }

  List<Widget> _buildContent(String name, bool isMobile) {
    return [
      if (isMobile)
        const Icon(
          Icons.dashboard_customize_rounded,
          size: 80,
          color: Colors.blue,
        ),
      if (isMobile) const SizedBox(height: 24),
      Text(
        'Chào mừng ${name.isNotEmpty ? name : 'bạn'}',
        style: TextStyle(
          fontSize: isMobile ? 22 : 28,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
        textAlign: isMobile ? TextAlign.center : TextAlign.left,
      ),
      const SizedBox(height: 8),
      const Text(
        'đến với hệ thống TeamManage!',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 24),
      const Text(
        'Quản lý dự án và đội nhóm hiệu quả',
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    ];
  }

  Widget _buildCardContent(String name, bool isMobileLayout) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobileLayout ? 20 : 40),
        child:
            isMobileLayout
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildContent(name, isMobileLayout),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.dashboard_customize_rounded,
                        size: 120,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 40),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildContent(name, isMobileLayout),
                      ),
                    ],
                  ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      title: 'Team Manage',
      appBarActions: [
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
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
      child: Center(
        child: FutureBuilder<String?>(
          future: getCurrentUserName(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            final name = snapshot.data ?? '';
            
            // Get the current screen width to determine layout
            final isMobile = MediaQuery.of(context).size.width < 600;
            return _buildCardContent(name, isMobile);
          },
        ),
      ),
    );
  }
}