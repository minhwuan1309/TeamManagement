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

  bool get isMobile => MediaQuery.of(context).size.width < 768;
  bool get isTablet => MediaQuery.of(context).size.width >= 768 && MediaQuery.of(context).size.width < 1024;
  bool get isDesktop => MediaQuery.of(context).size.width >= 1024;

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

  Widget _buildModuleInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.view_module, color: Colors.blue.shade700),
                SizedBox(width: isMobile ? 6 : 8),
                Text(
                  'Thông tin Module',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Tên Module',
                hintText: 'Nhập tên module',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: Icon(Icons.title, color: Colors.blue.shade700),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 12 : 16,
                ),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Không được để trống' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.blue.shade700),
                SizedBox(width: isMobile ? 6 : 8),
                Expanded(
                  child: Text(
                    'Chọn thành viên tham gia vào Module',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 6 : 8),
            Padding(
              padding: EdgeInsets.only(left: isMobile ? 8 : 12),
              child: Text(
                '(Các thành viên đã tham gia project này)',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w500
                ),
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            if (selectedMembers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Chip(
                  backgroundColor: Colors.blue.shade100,
                  label: Text(
                    'Đã chọn ${selectedMembers.length} thành viên',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: isMobile ? 13 : 14,
                    ),
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
                    title: Text(
                      fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                    secondary: CircleAvatar(
                      radius: isMobile ? 16 : 20,
                      backgroundColor: isSelected ? Colors.blue.shade100 : Colors.grey.shade200,
                      backgroundImage: avatar != null && avatar.isNotEmpty
                          ? NetworkImage(avatar)
                          : null,
                      child: avatar == null || avatar.isEmpty
                          ? Icon(
                              Icons.person,
                              size: isMobile ? 16 : 20,
                              color: isSelected ? Colors.blue.shade700 : Colors.grey,
                            )
                          : null,
                    ),
                    activeColor: Colors.blue.shade700,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 8 : 16,
                      vertical: isMobile ? 4 : 8,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      title: 'Tạo Module',
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModuleInfoCard(),
                    SizedBox(height: isMobile ? 12 : 16),
                    Expanded(child: _buildMembersCard()),
                    SizedBox(height: isMobile ? 12 : 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSubmitting ? null : _createModule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 12 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        icon: isSubmitting
                            ? SizedBox(
                                width: isMobile ? 20 : 24,
                                height: isMobile ? 20 : 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                Icons.add_circle,
                                size: isMobile ? 20 : 24,
                              ),
                        label: Text(
                          'Tạo Module',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
