import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/api_service.dart';

class UserPage extends StatefulWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  List<dynamic> allUsers = [];
  List<dynamic> users = [];
  bool isLoading = true;
  bool showBlockedOnly = false;
  bool showDeletedOnly = false;

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
        users =
            allUsers
                .where(
                  (user) =>
                      user['isActive'] == false && user['isDeleted'] == false,
                )
                .toList();
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
      builder:
          (context) => AlertDialog(
            title: Text(isActive ? 'Khoá người dùng' : 'Mở khoá người dùng'),
            content: Text(
              isActive
                  ? 'Bạn có chắc chắn muốn khoá người dùng này?'
                  : 'Bạn có chắc chắn muốn mở khoá người dùng này?',
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
      builder:
          (context) => AlertDialog(
            title: const Text('Xoá người dùng'),
            content: const Text('Bạn có chắc chắn muốn xoá người dùng này?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Huỷ'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xoá', style: TextStyle(color: Colors.red)),
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

  Future<void> restoreUser(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Khôi phục người dùng'),
            content: const Text('Bạn có chắc muốn khôi phục tài khoản này?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Huỷ'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Khôi phục'),
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

  Future<void> hardDeleteUser(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xoá vĩnh viễn'),
            content: const Text(
              'Bạn có chắc muốn xoá vĩnh viễn người dùng này? Thao tác không thể hoàn tác.',
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
      final token = await getToken();
      await http.delete(
        Uri.parse('$baseUrl/user/hard-delete/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      fetchUsers();
    }
  }

Future<void> updateRole(String userId, int newRole) async {
  final success = await ApiService.updateUserRole(userId, newRole);
  if (success) {
    fetchUsers();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật vai trò thành công")),
      );
    }
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thất bại khi cập nhật vai trò")),
      );
    }
  }
}


  void showRoleDialog(dynamic user) {
    int selectedRole = user['role'] ?? 3; // Default to Viewer if null

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: Text('Cập nhật vai trò cho ${user['fullName']}'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // User info section
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.2),
                        backgroundImage:
                            (user['avatar'] != null &&
                                    user['avatar'].isNotEmpty)
                                ? NetworkImage(user['avatar'])
                                : null,
                        child:
                            (user['avatar'] == null || user['avatar'].isEmpty)
                                ? Text(
                                  (user['fullName'] ?? '?')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                : null,
                      ),
                      title: Text(
                        user['fullName'] ?? 'Unknown',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        user['email'] ?? '',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Role dropdown
                    DropdownButtonFormField<int>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Vai trò mới',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Admin')),
                        DropdownMenuItem(value: 1, child: Text('Dev')),
                        DropdownMenuItem(value: 2, child: Text('Tester')),
                        DropdownMenuItem(value: 3, child: Text('Viewer')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedRole = value);
                        }
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Huỷ'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      updateRole(user['id'], selectedRole);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cập nhật'),
                  ),
                ],
              ),
        );
      },
    );
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
              "Account bị khoá",
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
              "Account đã xoá",
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
    final String? avatar = user['avatar'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                  backgroundImage:
                      (avatar != null && avatar.isNotEmpty)
                          ? NetworkImage(avatar)
                          : null,
                  child:
                      (avatar == null || avatar.isEmpty)
                          ? Text(
                            (user['fullName'] ?? '?')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : null,
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
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'block') toggleBlock(user['id']);
                    if (value == 'delete') deleteUser(user['id']);
                    if (value == 'restore') restoreUser(user['id']);
                    if (value == 'hardDelete') hardDeleteUser(user['id']);
                    if (value == 'role_admin') updateRole(user['id'], 0);
                    if (value == 'update_role') showRoleDialog(user);
                  },
                  itemBuilder: (context) {
                    if (isDeleted) {
                      return [
                        const PopupMenuItem(
                          value: 'restore',
                          child: Row(
                            children: [
                              Icon(
                                Icons.restore,
                                color: Colors.green,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text('Khôi phục'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'hardDelete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_forever,
                                color: Colors.red,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text('Xoá vĩnh viễn'),
                            ],
                          ),
                        ),
                      ];
                    } else {
                      return [
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
                              Icon(Icons.delete, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Xoá'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'update_role',
                          child: Row(
                            children: [
                              Icon(
                                Icons.manage_accounts,
                                color: Colors.blue,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text('Cập nhật Role'),
                            ],
                          ),
                        ),
                      ];
                    }
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            buildInfoRow(
              Icons.phone,
              'Điện thoại',
              user['phone'] ?? 'Chưa cập nhật',
            ),
            buildInfoRow(Icons.badge, 'Vai trò', getRoleName(user['role'])),
            buildInfoRow(
              isActive ? Icons.check_circle : Icons.block,
              'Trạng thái',
              isDeleted ? 'Đã xoá' : (isActive ? 'Hoạt động' : 'Bị khoá'),
              isDeleted
                  ? Colors.red
                  : (isActive ? Colors.green : Colors.orange),
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
            columns: [
              DataColumn(
                label: Container(
                  width: 150,
                  child: const Text(
                    'Họ tên',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              DataColumn(
                label: Container(
                  width: 200,
                  child: const Text(
                    'Email',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              DataColumn(
                label: Container(
                  width: 120,
                  child: const Text(
                    'Điện thoại',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              DataColumn(
                label: Container(
                  width: 100,
                  child: const Text(
                    'Vai trò',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              DataColumn(
                label: Container(
                  width: 120,
                  child: const Text(
                    'Trạng thái',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              DataColumn(
                label: Container(
                  width: 120,
                  child: const Text(
                    'Hành động',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
            rows:
                users.map((user) {
                  final bool isActive = user['isActive'] ?? true;
                  final bool isDeleted = user['isDeleted'] ?? false;

                  return DataRow(
                    cells: [
                      DataCell(
                        Center(
                          child: Text(
                            user['fullName'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataCell(
                        Center(
                          child: Text(
                            user['email'] ?? '',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataCell(
                        Center(
                          child: Text(
                            user['phone'] ?? '',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataCell(
                        Center(
                          child: Text(
                            getRoleName(user['role']),
                            textAlign: TextAlign.center,
                          ),
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
                                  : (isActive
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.orange.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isDeleted
                                  ? 'Đã xoá'
                                  : (isActive ? 'Hoạt động' : 'Bị khoá'),
                              style: TextStyle(
                                color: isDeleted
                                    ? Colors.red
                                    : (isActive ? Colors.green : Colors.orange),
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Xoá người dùng',
                                onPressed: () => deleteUser(user['id']),
                              ),
                              IconButton(
                                icon: const Icon(Icons.manage_accounts, color: Colors.blue),
                                tooltip: 'Vai trò',
                                onPressed: () => showRoleDialog(user),
                              ),
                            ],
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

  String getRoleName(dynamic role) {
    switch (role) {
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
        backgroundColor: Colors.blue.shade700,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.grey[50]),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    buildFilterToggle(),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return constraints.maxWidth < 600
                              ? ListView(
                                children: users.map(buildMobileCard).toList(),
                              )
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
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
      ),
    );
  }
}
