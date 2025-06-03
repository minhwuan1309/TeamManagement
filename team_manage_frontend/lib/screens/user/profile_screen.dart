import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/api_service.dart';
import 'package:team_manage_frontend/layouts/common_layout.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController(); // Readonly field for display
  bool isLoading = true;
  int? userRole;
  String? avatarUrl;
  File? _selectedAvatar;
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  String getRoleName(int? role) {
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

  Future<void> fetchProfile() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getInt('role');

    setState(() {
      userRole = role;
    });

    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        nameCtrl.text = data['fullName'] ?? '';
        phoneCtrl.text = data['phone'] ?? '';
        emailCtrl.text = data['email'] ?? '';
        avatarUrl = data['avatar'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/user/update-profile'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['fullName'] = nameCtrl.text;
    request.fields['phone'] = phoneCtrl.text;

    if (kIsWeb && _avatarBytes != null && _selectedAvatar != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _avatarBytes!,
          filename: _selectedAvatar!.path, // dùng tên file
        ),
      );
    } else if (_selectedAvatar != null && !kIsWeb) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _selectedAvatar!.path,
          filename: path.basename(_selectedAvatar!.path),
        ),
      );
    }

    final response = await request.send();
    final res = await http.Response.fromStream(response);

    setState(() => isLoading = false);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['avatar'] != null) {
        setState(() {
          avatarUrl = data['avatar'];
          _avatarBytes = null;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi: ${res.body}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> pickAvatarImage() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _avatarBytes = result.files.single.bytes;
          _selectedAvatar = File(
            result.files.single.name,
          ); // dùng tên để upload
          avatarUrl = null;
        });
      }
    } else {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _selectedAvatar = File(picked.path);
          _avatarBytes = null;
          avatarUrl = null;
        });
      }
    }
  }

  Future<void> changePassword(String current, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/user/change-password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'currentPassword': current,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context); // đóng popup
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đổi mật khẩu thành công"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Thất bại: ${response.body}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, bool isReadOnly) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.grey[700],
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(
        icon,
        color: Colors.blue.shade700,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.blue.shade700,
          width: 2,
        ),
      ),
      filled: true,
      fillColor: isReadOnly ? Colors.grey.shade100 : Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 16,
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, bool isDesktop) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.lock_rounded,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              const Text('Đổi mật khẩu'),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 500 : 400,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: oldPassCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu hiện tại',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (val) => val == null || val.isEmpty
                        ? 'Nhập mật khẩu hiện tại'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPassCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (val) => val == null || val.length < 6
                        ? 'Tối thiểu 6 ký tự'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPassCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Xác nhận mật khẩu mới';
                      }
                      if (val != newPassCtrl.text) {
                        return 'Mật khẩu không khớp';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  changePassword(oldPassCtrl.text, newPassCtrl.text);
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;
    
    return CommonLayout(
      title: "Hồ sơ cá nhân",
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 800 : (isTablet ? 700 : double.infinity),
                  ),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        // Profile Header with Avatar
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade700,
                                Colors.blue.shade400,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          padding: EdgeInsets.all(isDesktop ? 32 : 24),
                          child: Column(
                            children: [
                              // Avatar with edit button
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: isDesktop ? 70 : (isTablet ? 65 : 60),
                                      backgroundColor: Colors.white.withOpacity(0.3),
                                      backgroundImage: _avatarBytes != null
                                          ? MemoryImage(_avatarBytes!)
                                          : (_selectedAvatar != null
                                              ? FileImage(_selectedAvatar!)
                                              : (avatarUrl != null && avatarUrl!.isNotEmpty
                                                  ? NetworkImage(avatarUrl!)
                                                  : null)),
                                      child: avatarUrl == null || avatarUrl!.isEmpty
                                          ? Text(
                                            nameCtrl.text.isNotEmpty
                                                ? nameCtrl.text[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              fontSize: isDesktop ? 56 : (isTablet ? 52 : 48),
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          )
                                          : null,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: pickAvatarImage,
                                    child: Container(
                                      width: isDesktop ? 45 : 40,
                                      height: isDesktop ? 45 : 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.camera_alt_rounded,
                                        size: isDesktop ? 26 : 22,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isDesktop ? 20 : 16),

                              // User name in header
                              Text(
                                nameCtrl.text,
                                style: TextStyle(
                                  fontSize: isDesktop ? 28 : (isTablet ? 26 : 24),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              // User role badge
                              if (userRole != null)
                                Container(
                                  margin: EdgeInsets.only(top: isDesktop ? 12 : 8),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isDesktop ? 20 : 16,
                                    vertical: isDesktop ? 8 : 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    getRoleName(userRole),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isDesktop ? 16 : 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Form Content
                        Padding(
                          padding: EdgeInsets.all(isDesktop ? 32 : 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Thông tin cá nhân",
                                  style: TextStyle(
                                    fontSize: isDesktop ? 20 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: isDesktop ? 28 : 24),

                                // Form fields in responsive layout
                                if (isDesktop) ...[
                                  // Desktop: 2 columns
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: emailCtrl,
                                          readOnly: true,
                                          decoration: _buildInputDecoration('Email', Icons.email_rounded, true),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: TextFormField(
                                          controller: nameCtrl,
                                          decoration: _buildInputDecoration('Họ và tên', Icons.person_rounded, false),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Vui lòng nhập họ tên';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextFormField(
                                      controller: phoneCtrl,
                                      keyboardType: TextInputType.phone,
                                      decoration: _buildInputDecoration('Số điện thoại', Icons.phone_rounded, false),
                                    ),
                                  ),
                                ] else ...[
                                  // Mobile/Tablet: Single column
                                  TextFormField(
                                    controller: emailCtrl,
                                    readOnly: true,
                                    decoration: _buildInputDecoration('Email', Icons.email_rounded, true),
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: nameCtrl,
                                    decoration: _buildInputDecoration('Họ và tên', Icons.person_rounded, false),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Vui lòng nhập họ tên';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    decoration: _buildInputDecoration('Số điện thoại', Icons.phone_rounded, false),
                                  ),
                                ],
                                
                                SizedBox(height: isDesktop ? 40 : 36),

                                // Action Buttons
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: updateProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade700,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        vertical: isDesktop ? 18 : 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.save_rounded),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Lưu thay đổi',
                                          style: TextStyle(
                                            fontSize: isDesktop ? 18 : 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Change password option
                                Padding(
                                  padding: EdgeInsets.only(top: isDesktop ? 28 : 24),
                                  child: Divider(color: Colors.grey.shade300),
                                ),

                                // Security Section
                                Padding(
                                  padding: EdgeInsets.only(top: isDesktop ? 20 : 16),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: TextButton.icon(
                                      onPressed: () => _showChangePasswordDialog(context, isDesktop),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: isDesktop ? 16 : 12,
                                          horizontal: 16,
                                        ),
                                        backgroundColor: Colors.blue.shade50,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.lock_outline_rounded,
                                        color: Colors.blue.shade700,
                                      ),
                                      label: Text(
                                        'Đổi mật khẩu',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w600,
                                          fontSize: isDesktop ? 16 : 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }
}
