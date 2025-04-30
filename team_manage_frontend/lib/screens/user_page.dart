import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserPage extends StatefulWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  List<dynamic> allUsers = []; // chứa tất cả users
  List<dynamic> users = []; // chứa users sau khi lọc
  bool isLoading = true;
  bool showBlockedOnly = false;
  bool showDeletedOnly = false; 

  final String baseUrl = 'http://localhost:5053/api';

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchUsers() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      allUsers = jsonDecode(response.body);
      applyFilter();
    }
    setState(() => isLoading = false);
  }

  void applyFilter() {
    setState(() {
      if (showDeletedOnly) {
        users = allUsers.where((user) => user['isDeleted'] == true).toList();
      } else if (showBlockedOnly) {
        users = allUsers.where((user) => user['isActive'] == false && user['isDeleted'] == false).toList();
      } else {
        users = allUsers.where((user) => user['isDeleted'] == false).toList();
      }
    });
  }

  Future<void> toggleBlock(String id) async {
    final user = users.firstWhere((u) => u['id'] == id);
    final bool isActive = user['isActive'] ?? true;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isActive ? 'Khoá người dùng' : 'Mở khoá người dùng'),
        content: Text(isActive 
          ? 'Bạn có chắc chắn muốn khoá người dùng này?'
          : 'Bạn có chắc chắn muốn mở khoá người dùng này?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              isActive ? 'Khoá' : 'Mở khoá',
              style: TextStyle(color: isActive ? Colors.red : Colors.green),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final token = await getToken();
      await http.put(
        Uri.parse('$baseUrl/user/toggle-block/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      fetchUsers();
    }
  }

  Future<void> deleteUser(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá người dùng'),
        content: const Text('Bạn có chắc chắn muốn xoá người dùng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Xoá',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final token = await getToken();
      await http.delete(
        Uri.parse('$baseUrl/user/delete/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      fetchUsers();
    }
  }

  Widget buildFilterToggle() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              "Chỉ người dùng bị khoá",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Switch(
              value: showBlockedOnly,
              activeColor: Theme.of(context).primaryColor,
              onChanged: (value) {
                setState(() {
                  showBlockedOnly = value;
                  if (value) showDeletedOnly = false; // không cho bật cả 2
                  applyFilter();
                });
              },
            ),
            const SizedBox(width: 20),
            const Text(
              "Chỉ người dùng đã xoá",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Switch(
              value: showDeletedOnly,
              activeColor: Theme.of(context).primaryColor,
              onChanged: (value) {
                setState(() {
                  showDeletedOnly = value;
                  if (value) showBlockedOnly = false; // không cho bật cả 2
                  applyFilter();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMobileCard(dynamic user) {
    final bool isActive = user['isActive'] ?? true;
    final bool isDeleted = user['isDeleted'] ?? false;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
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
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  child: Text(
                    (user['fullName'] ?? '?').substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['fullName'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['email'] ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'block') toggleBlock(user['id']);
                    if (value == 'delete') deleteUser(user['id']);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(
                            isActive ? Icons.block : Icons.check_circle,
                            color: isActive ? Colors.red : Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(isActive ? 'Khoá' : 'Mở khoá'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text('Xoá'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            buildInfoRow(Icons.phone, 'Điện thoại', user['phone'] ?? 'Chưa cập nhật'),
            buildInfoRow(Icons.badge, 'Vai trò', getRoleName(user['role'])),
            buildInfoRow(
              isActive ? Icons.check_circle : Icons.block,
              'Trạng thái',
              isDeleted ? 'Đã xoá' : (isActive ? 'Hoạt động' : 'Bị khoá'),
              isDeleted ? Colors.red : (isActive ? Colors.green : Colors.orange),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(IconData icon, String label, String value, [Color? iconColor]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor ?? Colors.grey[600],
          ),
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
              style: TextStyle(
                color: iconColor ?? Colors.grey[800],
              ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20,
            headingRowColor: MaterialStateProperty.all(
              Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            columns: [
              const DataColumn(label: Text('Họ tên', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Điện thoại', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Vai trò', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: users.map((user) {
              final bool isActive = user['isActive'] ?? true;
              final bool isDeleted = user['isDeleted'] ?? false;
              
              return DataRow(cells: [
                DataCell(Text(
                  user['fullName'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                )),
                DataCell(Text(user['email'] ?? '')),
                DataCell(Text(user['phone'] ?? '')),
                DataCell(Text(getRoleName(user['role']))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDeleted
                          ? Colors.red.withOpacity(0.2)
                          : (isActive
                              ? Colors.green.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isDeleted ? 'Đã xoá' : (isActive ? 'Hoạt động' : 'Bị khoá'),
                      style: TextStyle(
                        color: isDeleted
                            ? Colors.red
                            : (isActive ? Colors.green : Colors.orange),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isActive ? Icons.block : Icons.check_circle,
                        color: isActive ? Colors.red : Colors.green,
                      ),
                      tooltip: isActive ? 'Khoá người dùng' : 'Mở khoá người dùng',
                      onPressed: () => toggleBlock(user['id']),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      tooltip: 'Xoá người dùng',
                      onPressed: () => deleteUser(user['id']),
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  String getRoleName(dynamic role) {
    switch(role){
      case 0:
        return 'Admin';
      case 1:
        return 'Dev';
      case 2:
        return 'Tester';
      default:
        return 'Viewer';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  buildFilterToggle(),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return constraints.maxWidth < 600
                            ? ListView(children: users.map(buildMobileCard).toList())
                            : buildDesktopTable();
                      },
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/user/create'),
        child: const Icon(Icons.add),
        tooltip: 'Tạo người dùng mới',
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
      ),
    );
  }
}