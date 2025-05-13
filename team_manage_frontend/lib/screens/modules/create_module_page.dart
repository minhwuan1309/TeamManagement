import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/api_service.dart';
import 'package:team_manage_frontend/layouts/common_layout.dart';


class CreateModulePage extends StatefulWidget {
  final int projectId;
  const CreateModulePage({super.key, required this.projectId});

  @override
  State<CreateModulePage> createState() => _CreateModulePageState();
}

class _CreateModulePageState extends State<CreateModulePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  List<dynamic> projectMembers = [];
  List<Map<String, dynamic>> selectedMembers = [];
  bool isSubmitting = false;


  @override
  void initState() {
    super.initState();
    fetchProjectMembers();
  }

  Future<void> fetchProjectMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.get(
      Uri.parse('$baseUrl/project/${widget.projectId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final members = decoded['members']?[r'$values'] ?? [];
      setState(() {
        projectMembers = members;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải thành viên project')),
      );
    }
  }

  Future<void> _createModule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Tạo danh sách thành viên theo định dạng API
    final members = selectedMembers.map((member) => {
      'userId': member['userId'],
      'fullName': member['fullName'],
      'avatar': member['avatar'],
    }).toList();

    final body = jsonEncode({
      'projectId': widget.projectId,
      'name': _nameController.text,
      'status': 0, // Mặc định là none (0)
      'members': members,
    });

    final res = await http.post(
      Uri.parse('$baseUrl/module/create'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    setState(() => isSubmitting = false);

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo module thành công')),
      );
      Navigator.pop(context, true); // reload lại danh sách
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tạo module thất bại: ${res.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      title: 'Tạo Module',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card cho form thông tin chính
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
                          Icon(Icons.view_module, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Thông tin Module',
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
                        validator: (value) => value == null || value.isEmpty ? 'Không được để trống' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Card cho danh sách thành viên
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
                          children: [
                            Icon(Icons.people, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'Thành viên Module',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Badge hiển thị số lượng thành viên đã chọn
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
                        
                        // Danh sách thành viên
                        projectMembers.isEmpty
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
                            : Expanded(
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
              
              // Button tạo module
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSubmitting ? null : _createModule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  icon: isSubmitting 
                      ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(Icons.add_circle),
                  label: Text(
                    'Tạo Module',
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