import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/api_service.dart';
import 'package:team_manage_frontend/layouts/common_layout.dart';

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
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

      // Apply search filter if there's a query
      if (searchQuery.isNotEmpty) {
        users =
            users.where((user) {
              final name = (user['fullName'] ?? '').toLowerCase();
              final email = (user['email'] ?? '').toLowerCase();
              final phone = (user['phone'] ?? '').toLowerCase();
              final query = searchQuery.toLowerCase();
              return name.contains(query) ||
                  email.contains(query) ||
                  phone.contains(query);
            }).toList();
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
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(isActive ? 'Khoá' : 'Mở khoá'),
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
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Xoá'),
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
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
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
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Xoá vĩnh viễn'),
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
          const SnackBar(
            content: Text("Cập nhật vai trò thành công"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Thất bại khi cập nhật vai trò"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  //Get Role Color
  Color getRoleColor(int? role) {
    switch (role) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      default:
        return Colors.grey;
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Cập nhật vai trò cho ${user['fullName']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // User info section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 28,
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
                                      fontSize: 18,
                                    ),
                                  )
                                  : null,
                        ),
                        title: Text(
                          user['fullName'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          user['email'] ?? '',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Role dropdown
                    DropdownButtonFormField<int>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Vai trò mới',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        prefixIcon: const Icon(Icons.badge),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 0,
                          child: Text(
                            'Admin',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text(
                            'Dev',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text(
                            'Tester',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text(
                            'Viewer',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
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
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      updateRole(user['id'], selectedRole);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Cập nhật'),
                  ),
                ],
              ),
        );
      },
    );
  }

  Widget buildFilterSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bộ lọc',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          // Responsive search field
          LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: constraints.maxWidth < 600 
                          ? 'Tìm kiếm...' 
                          : 'Tìm kiếm theo tên, email, số điện thoại...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  searchQuery = '';
                                  applyFilter();
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        applyFilter();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Responsive filter chips
                  constraints.maxWidth < 600
                      ? Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: FilterChip(
                                label: Text(
                                  'Bị khoá',
                                  style: TextStyle(
                                    color: showBlockedOnly ? Colors.white : Colors.black87,
                                  ),
                                ),
                                selected: showBlockedOnly,
                                checkmarkColor: Colors.white,
                                selectedColor: Theme.of(context).primaryColor,
                                backgroundColor: Colors.white,
                                onSelected: (value) {
                                  setState(() {
                                    showBlockedOnly = value;
                                    if (value) showDeletedOnly = false;
                                    applyFilter();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: FilterChip(
                                label: Text(
                                  'Đã xoá',
                                  style: TextStyle(
                                    color: showDeletedOnly ? Colors.white : Colors.black87,
                                  ),
                                ),
                                selected: showDeletedOnly,
                                checkmarkColor: Colors.white,
                                selectedColor: Colors.red,
                                backgroundColor: Colors.white,
                                onSelected: (value) {
                                  setState(() {
                                    showDeletedOnly = value;
                                    if (value) showBlockedOnly = false;
                                    applyFilter();
                                  });
                                },
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            FilterChip(
                              label: Text(
                                'Bị khoá',
                                style: TextStyle(
                                  color: showBlockedOnly ? Colors.white : Colors.black87,
                                ),
                              ),
                              selected: showBlockedOnly,
                              checkmarkColor: Colors.white,
                              selectedColor: Theme.of(context).primaryColor,
                              backgroundColor: Colors.white,
                              onSelected: (value) {
                                setState(() {
                                  showBlockedOnly = value;
                                  if (value) showDeletedOnly = false;
                                  applyFilter();
                                });
                              },
                            ),
                            const SizedBox(width: 12),
                            FilterChip(
                              label: Text(
                                'Đã xoá',
                                style: TextStyle(
                                  color: showDeletedOnly ? Colors.white : Colors.black87,
                                ),
                              ),
                              selected: showDeletedOnly,
                              checkmarkColor: Colors.white,
                              selectedColor: Colors.red,
                              backgroundColor: Colors.white,
                              onSelected: (value) {
                                setState(() {
                                  showDeletedOnly = value;
                                  if (value) showBlockedOnly = false;
                                  applyFilter();
                                });
                              },
                            ),
                          ],
                        ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildMobileCard(dynamic user) {
    final bool isActive = user['isActive'] ?? true;
    final bool isDeleted = user['isDeleted'] ?? false;
    final String? avatar = user['avatar'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  backgroundImage: (avatar != null && avatar.isNotEmpty)
                      ? NetworkImage(avatar)
                      : null,
                  child: (avatar == null || avatar.isEmpty)
                      ? Text(
                          (user['fullName'] ?? '?').substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['email'] ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'block') toggleBlock(user['id']);
                    if (value == 'delete') deleteUser(user['id']);
                    if (value == 'restore') restoreUser(user['id']);
                    if (value == 'hardDelete') hardDeleteUser(user['id']);
                    if (value == 'update_role') showRoleDialog(user);
                  },
                  itemBuilder: (context) {
                    if (isDeleted) {
                      return [
                        const PopupMenuItem(
                          value: 'restore',
                          child: Row(
                            children: [
                              Icon(Icons.restore, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text('Khôi phục'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'hardDelete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_forever, color: Colors.red, size: 20),
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
                              Icon(Icons.manage_accounts, color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Text('Cập nhật vai trò'),
                            ],
                          ),
                        ),
                      ];
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Status and role chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDeleted
                        ? Colors.red.withOpacity(0.1)
                        : (isActive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isDeleted ? 'Đã xoá' : (isActive ? 'Hoạt động' : 'Bị khoá'),
                    style: TextStyle(
                      color: isDeleted
                          ? Colors.red
                          : (isActive ? Colors.green : Colors.orange),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: getRoleColor(user['role']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    getRoleName(user['role']),
                    style: TextStyle(
                      color: getRoleColor(user['role']),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            if (user['phone'] != null && user['phone'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      user['phone'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? Theme.of(context).primaryColor).withOpacity(
                0.1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor ?? Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 12),
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
                fontWeight: FontWeight.w500,
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: const [
                Expanded(flex: 2, child: Text('Thông tin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Vai trò', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Trạng thái', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Hành động', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final bool isActive = user['isActive'] ?? true;
                final bool isDeleted = user['isDeleted'] ?? false;
                final String? avatar = user['avatar'];
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                              backgroundImage: (avatar != null && avatar.isNotEmpty)
                                  ? NetworkImage(avatar)
                                  : null,
                              child: (avatar == null || avatar.isEmpty)
                                  ? Text(
                                      (user['fullName'] ?? '?').substring(0, 1).toUpperCase(),
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['fullName'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (user['phone'] != null && user['phone'].isNotEmpty)
                                    Text(
                                      user['phone'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          user['email'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: getRoleColor(user['role']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            getRoleName(user['role']),
                            style: TextStyle(
                              color: getRoleColor(user['role']),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDeleted
                                ? Colors.red.withOpacity(0.1)
                                : (isActive
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isDeleted ? 'Đã xoá' : (isActive ? 'Hoạt động' : 'Bị khoá'),
                            style: TextStyle(
                              color: isDeleted
                                  ? Colors.red
                                  : (isActive ? Colors.green : Colors.orange),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: isDeleted
                              ? [
                                  IconButton(
                                    icon: const Icon(Icons.restore, color: Colors.green, size: 18),
                                    tooltip: 'Khôi phục',
                                    onPressed: () => restoreUser(user['id']),
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_forever, color: Colors.red, size: 18),
                                    tooltip: 'Xoá vĩnh viễn',
                                    onPressed: () => hardDeleteUser(user['id']),
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                ]
                              : [
                                  IconButton(
                                    icon: Icon(
                                      isActive ? Icons.block : Icons.check_circle,
                                      color: isActive ? Colors.red : Colors.green,
                                      size: 18,
                                    ),
                                    tooltip: isActive ? 'Khoá' : 'Mở khoá',
                                    onPressed: () => toggleBlock(user['id']),
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                    tooltip: 'Xoá',
                                    onPressed: () => deleteUser(user['id']),
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.manage_accounts, color: Colors.blue, size: 18),
                                    tooltip: 'Cập nhật vai trò',
                                    onPressed: () => showRoleDialog(user),
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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
    return CommonLayout(
      title: 'Quản lý người dùng',
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/user/create'),
        tooltip: 'Tạo người dùng mới',
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
      child: Container(
        decoration: BoxDecoration(color: Colors.grey[50]),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  buildFilterSection(),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 900) {
                          return ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, index) => buildMobileCard(users[index]),
                          );
                        } else {
                          return buildDesktopTable();
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
