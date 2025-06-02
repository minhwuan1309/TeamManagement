import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/api_service.dart';
import 'package:team_manage_frontend/layouts/common_layout.dart';


class CreateModulePage extends StatefulWidget {
  final int projectId;
  final int? parentModuleId;
  final List<Map<String, dynamic>> projectMembers;

  const CreateModulePage({
    super.key,
    required this.projectId,
    this.parentModuleId,
    required this.projectMembers,
  });

  @override
  State<CreateModulePage> createState() => _CreateModulePageState();
}

class _CreateModulePageState extends State<CreateModulePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  int? parentModuleId;
  int projectId = 0;
  List<Map<String, dynamic>> projectMembers = [];
  List<Map<String, dynamic>> selectedMembers = [];

  bool isSubmitting = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    projectId = widget.projectId;
    parentModuleId = widget.parentModuleId;
    projectMembers = widget.projectMembers;
    isLoading = false;
  }


  Future<void> _createModule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final members = selectedMembers.map((member) => {
      'userId': member['userId'],
      'fullName': member['fullName'],
      'avatar': member['avatar'],
    }).toList();

    final body = jsonEncode({
      'projectId': projectId,
      'name': _nameController.text,
      'status': 0,
      'members': members,
      'parentModuleId': parentModuleId,
    });

    final res = await http.post(
      Uri.parse('$baseUrl/module/create'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (!mounted) return;
    setState(() => isSubmitting = false);

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo module thành công'),
          backgroundColor: Colors.green,
          ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tạo module thất bại: ${res.statusCode}'),
          backgroundColor: Colors.red,
          ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      title: 'Tạo Module',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.view_module, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                const Text('Thông tin Module', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Tên Module',
                                hintText: 'Nhập tên module',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                prefixIcon: Icon(Icons.title, color: Colors.blue.shade700),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Không được để trống' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.people, color: Colors.blue.shade700),
                                  const SizedBox(width: 8),
                                  const Text('Chọn thành viên tham gia vào Module', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),                             
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const SizedBox(width: 12),
                                  const Text('(Các thành viên đã tham gia project này)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),                                   
                              ]),
                              const SizedBox(height: 16),
                              if (selectedMembers.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Chip(
                                    backgroundColor: Colors.blue.shade100,
                                    label: Text(
                                      'Đã chọn ${selectedMembers.length} thành viên',
                                      style: TextStyle(color: Colors.blue.shade700),
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: projectMembers.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final member = projectMembers[index];
                                    final userId = member['userId'];
                                    final fullName = member['fullName'] ?? 'Không tên';
                                    final avatar = member['avatar'];
                                    final isSelected = selectedMembers.any((selected) => selected['userId'] == userId);

                                    return CheckboxListTile(
                                      value: isSelected,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            selectedMembers.add({
                                              'userId': userId,
                                              'fullName': fullName,
                                              'avatar': avatar,
                                            });
                                          } else {
                                            selectedMembers.removeWhere((selected) => selected['userId'] == userId);
                                          }
                                        });
                                      },
                                      title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.w500)),
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSubmitting ? null : _createModule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 2,
                        ),
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                              )
                            : const Icon(Icons.add_circle),
                        label: const Text('Tạo Module', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
