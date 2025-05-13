import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:team_manage_frontend/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/layouts/common_layout.dart';

class EditModulePage extends StatefulWidget {
  final Map module;

  const EditModulePage({super.key, required this.module});

  @override
  State<EditModulePage> createState() => _EditModulePageState();
}

class _EditModulePageState extends State<EditModulePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  List<dynamic> projectMembers = [];
  List<String> selectedUserIds = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.module['name'] ?? '';
    selectedUserIds = List<String>.from(widget.module['memberIds'][r'$values'] ?? []);
    fetchProjectMembers();
  }

  Future<void> fetchProjectMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final projectId = widget.module['projectId'];

    final res = await http.get(
      Uri.parse('$baseUrl/project/$projectId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      setState(() {
        projectMembers = decoded['members'][r'$values'] ?? [];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải thành viên dự án')),
      );
    }
  }

  Future<void> _updateModule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final body = jsonEncode({
      'id': widget.module['id'],
      'projectId': widget.module['projectId'],
      'name': _nameController.text,
      'status': widget.module['status'],
      'members': selectedUserIds.map((id) => { 'userId': id }).toList(),
    });


    final res = await http.put(
      Uri.parse('$baseUrl/module/update/${widget.module['id']}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    setState(() => isLoading = false);

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thành công')),
      );
      
      // Fetch updated module data to return to detail page
      final updatedModuleRes = await http.get(
        Uri.parse('$baseUrl/module/${widget.module['id']}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (updatedModuleRes.statusCode == 200) {
        final updatedModuleData = jsonDecode(updatedModuleRes.body);
        Navigator.pop(context, updatedModuleData); // Return updated data
      } else {
        Navigator.pop(context, true); // At least indicate update happened
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật: ${res.statusCode}')),
      );
    }
  }

@override
Widget build(BuildContext context) {
  return CommonLayout(
    title: 'Chỉnh sửa Module',
    child: isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card thông tin module
                  Card(
                    elevation: 2,
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
                              Icon(Icons.edit_note, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Cập nhật thông tin Module',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Tên Module',
                              hintText: 'Nhập tên module',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.title, color: Colors.blue.shade700),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Không được để trống'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Card danh sách thành viên
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.people, color: Colors.blue.shade700),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Thành viên:',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                // Hiển thị số lượng thành viên đã chọn
                                Chip(
                                  backgroundColor: Colors.blue.shade100,
                                  label: Text(
                                    'Đã chọn ${selectedUserIds.length} thành viên',
                                    style: TextStyle(color: Colors.blue.shade700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: projectMembers.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const CircularProgressIndicator(),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Đang tải danh sách thành viên...',
                                            style: TextStyle(color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: projectMembers.length,
                                      separatorBuilder: (context, index) => const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final member = projectMembers[index];
                                        final userId = member['userId'];
                                        final fullName = member['fullName'] ?? 'Không tên';
                                        final avatar = member['avatar'];
                                        final isSelected = selectedUserIds.contains(userId);

                                        return CheckboxListTile(
                                          value: isSelected,
                                          onChanged: (bool? checked) {
                                            setState(() {
                                              if (checked == true) {
                                                selectedUserIds.add(userId);
                                              } else {
                                                selectedUserIds.remove(userId);
                                              }
                                            });
                                          },
                                          title: Text(
                                            fullName,
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                          secondary: CircleAvatar(
                                            backgroundColor: isSelected ? Colors.blue.shade100 : Colors.grey.shade200,
                                            backgroundImage: avatar != null && avatar.isNotEmpty
                                                ? NetworkImage(avatar)
                                                : null,
                                            child: avatar == null || avatar.isEmpty
                                                ? Icon(Icons.person, color: isSelected ? Colors.blue.shade700 : Colors.grey)
                                                : null,
                                          ),
                                          activeColor: Colors.blue.shade700,
                                          dense: false,
                                          controlAffinity: ListTileControlAffinity.trailing,
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Button cập nhật
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _updateModule,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      icon: isLoading
                          ? Container(
                              width: 24,
                              height: 24,
                              padding: const EdgeInsets.all(2.0),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        'Lưu thay đổi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
  );
}
}