import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  final String baseUrl = 'http://localhost:5053/api';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Module'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên Module',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 20),
              const Text(
                'Thành viên Module:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              projectMembers.isEmpty
                  ? const Center(child: Text('Đang tải danh sách thành viên...'))
                  : Expanded(
                      child: ListView.builder(
                        itemCount: projectMembers.length,
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
                  onPressed: isSubmitting ? null : _createModule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Tạo Module',
                          style: TextStyle(color: Colors.white, fontSize: 16),
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