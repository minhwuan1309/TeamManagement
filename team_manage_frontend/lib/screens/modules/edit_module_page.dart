import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  final String baseUrl = 'http://localhost:5053/api';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa Module'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên Module',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Không được để trống' : null,
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Thành viên:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: projectMembers.length,
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
                            title: Text(fullName),
                            secondary: avatar != null && avatar.isNotEmpty
                                ? CircleAvatar(backgroundImage: NetworkImage(avatar))
                                : const CircleAvatar(child: Icon(Icons.person)),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _updateModule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Lưu thay đổi',
                          style: TextStyle(fontSize: 16, color: Colors.white),
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