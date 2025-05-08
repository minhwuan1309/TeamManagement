import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/api_service.dart';
import 'package:team_manage_frontend/layouts/common_layout.dart';

class EditProjectPage extends StatefulWidget {
  final int projectId;
  const EditProjectPage({super.key, required this.projectId});

  @override
  State<EditProjectPage> createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  DateTime? startDate;

  List<dynamic> allUsers = [];
  List<Map<String, dynamic>> members = [];
  String? selectedUserId;
  String selectedRole = 'dev';

  final dateFormat = DateFormat('dd/MM/yyyy');
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAll();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchAll() async {
    await Future.wait([fetchUsers(), fetchProject()]);
    setState(() => isLoading = false);
  }

  Future<void> fetchUsers() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      allUsers = jsonDecode(res.body);
    }
  }

  Future<void> fetchProject() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/project/${widget.projectId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      nameCtrl.text = data['name'] ?? '';
      descCtrl.text = data['description'] ?? '';
      startDate = DateTime.tryParse(data['startDate'] ?? '');
      final rawMembers = data['members']?['\$values'] ?? [];
      members = List<Map<String, dynamic>>.from(
        rawMembers.map(
          (m) => {'userId': m['userId'], 'roleInProject': m['roleInProject']},
        ),
      );
    }
  }

  Future<void> updateProject() async {
    final token = await getToken();

    final res = await http.put(
      Uri.parse('$baseUrl/project/update/${widget.projectId}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': nameCtrl.text,
        'description': descCtrl.text,
        'startDate': startDate?.toIso8601String(),
        'members': members,
        'modules': [],
      }),
    );

    if (res.statusCode == 200) {
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cập nhật thành công"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi: ${res.body}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void addMember() {
    if (selectedUserId == null) return;
    final exists = members.any((m) => m['userId'] == selectedUserId);
    if (!exists) {
      setState(() {
        members.add({'userId': selectedUserId, 'roleInProject': selectedRole});
      });
    }
  }

  void removeMember(String userId) {
    setState(() {
      members.removeWhere((m) => m['userId'] == userId);
    });
  }

  String getUserName(String userId) {
    final user = allUsers.firstWhere(
      (u) => u['id'] == userId,
      orElse: () => null,
    );
    return user != null ? user['fullName'] : 'Không rõ';
  }

  Widget _buildProjectInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.folder, color: Colors.blue, size: 26),
                ),
                const SizedBox(width: 14),
                const Text(
                  "Thông tin dự án",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Project name
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextFormField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Tên dự án',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.edit),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              ),
              validator: (val) => val!.isEmpty ? 'Không để trống' : null,
            ),
          ),

          // Project description
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextFormField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: 'Mô tả chi tiết',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              ),
              maxLines: 3,
            ),
          ),

          // Start date
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => startDate = picked);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text(
                      startDate == null
                          ? 'Chọn ngày bắt đầu'
                          : 'Ngày bắt đầu: ${dateFormat.format(startDate!)}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.people, color: Colors.blue, size: 26),
                ),
                const SizedBox(width: 14),
                const Text(
                  "Thành viên dự án",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // User selection
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: DropdownButtonFormField<String>(
              value: selectedUserId,
              items: allUsers.map<DropdownMenuItem<String>>((user) {
                return DropdownMenuItem(
                  value: user['id'],
                  child: Text(user['fullName']),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedUserId = val),
              decoration: InputDecoration(
                labelText: 'Chọn thành viên',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              ),
              isExpanded: true,
            ),
          ),

          // Role selection
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: DropdownButtonFormField<String>(
              value: selectedRole,
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'dev', child: Text('Dev')),
                DropdownMenuItem(value: 'tester', child: Text('Tester')),
                DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
              ],
              onChanged: (val) => setState(() => selectedRole = val!),
              decoration: InputDecoration(
                labelText: 'Vai trò trong dự án',
                prefixIcon: const Icon(Icons.work),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              ),
              isExpanded: true,
            ),
          ),

          // Add member button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: ElevatedButton.icon(
              onPressed: addMember,
              icon: const Icon(Icons.person_add),
              label: const Text("Thêm thành viên"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),

          // Members list
          if (members.isNotEmpty) ...[
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Danh sách thành viên hiện tại:",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  ...members.map(
                    (m) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(Icons.person, color: Colors.blue.shade700),
                        ),
                        title: Text(getUserName(m['userId'])),
                        subtitle: Text("Vai trò: ${m['roleInProject']}", style: const TextStyle(fontSize: 13)),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => removeMember(m['userId']),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 16, 12, 24),
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            updateProject();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
        child: const Text(
          'Lưu thay đổi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      title: 'Chỉnh sửa dự án',
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.grey.shade100,
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildProjectInfoSection(),
                    _buildMembersSection(),
                    _buildUpdateButton(),
                    
                    // Error message area
                    if (allUsers.isEmpty)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.error, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Không thể tải danh sách người dùng",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}