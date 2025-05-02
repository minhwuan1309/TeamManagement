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

  final baseUrl = 'http://localhost:5053/api';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hồ sơ cá nhân"),
        backgroundColor: Colors.blue.shade700,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.grey[50]),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Avatar section
                                  Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      CircleAvatar(
                                        radius: 50,
                                        backgroundColor: Colors.blue.shade700
                                            .withOpacity(0.2),
                                        backgroundImage:
                                            _avatarBytes != null
                                                ? MemoryImage(_avatarBytes!)
                                                : (_selectedAvatar != null
                                                    ? FileImage(
                                                      _selectedAvatar!,
                                                    )
                                                    : (avatarUrl != null &&
                                                            avatarUrl!
                                                                .isNotEmpty
                                                        ? NetworkImage(
                                                          avatarUrl!,
                                                        )
                                                        : null)),

                                        child:
                                            avatarUrl == null ||
                                                    avatarUrl!.isEmpty
                                                ? Text(
                                                  nameCtrl.text.isNotEmpty
                                                      ? nameCtrl.text[0]
                                                          .toUpperCase()
                                                      : '?',
                                                  style: TextStyle(
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).primaryColor,
                                                  ),
                                                )
                                                : null,
                                      ),
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade700,
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.camera_alt,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          onPressed: () async {
                                            await pickAvatarImage();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // User role badge
                                  if (userRole != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade700.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        getRoleName(userRole),
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 24),

                                  // Email field (readonly)
                                  TextFormField(
                                    controller: emailCtrl,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(
                                        Icons.email,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      labelStyle: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Full name field
                                  TextFormField(
                                    controller: nameCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Họ và tên',
                                      prefixIcon: Icon(
                                        Icons.person,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Vui lòng nhập họ tên';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Phone field
                                  TextFormField(
                                    controller: phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: 'Số điện thoại',
                                      prefixIcon: Icon(
                                        Icons.phone,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Save button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: updateProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade700,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: const Text(
                                        'Lưu thay đổi',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Change password option
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          final oldPassCtrl =
                                              TextEditingController();
                                          final newPassCtrl =
                                              TextEditingController();
                                          final formKey =
                                              GlobalKey<FormState>();

                                          return AlertDialog(
                                            title: const Text('Đổi mật khẩu'),
                                            content: Form(
                                              key: formKey,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  TextFormField(
                                                    controller: oldPassCtrl,
                                                    obscureText: true,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText:
                                                              'Mật khẩu hiện tại',
                                                        ),
                                                    validator:
                                                        (val) =>
                                                            val == null ||
                                                                    val.isEmpty
                                                                ? 'Nhập mật khẩu hiện tại'
                                                                : null,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  TextFormField(
                                                    controller: newPassCtrl,
                                                    obscureText: true,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText:
                                                              'Mật khẩu mới',
                                                        ),
                                                    validator:
                                                        (val) =>
                                                            val == null ||
                                                                    val.length <
                                                                        6
                                                                ? 'Tối thiểu 6 ký tự'
                                                                : null,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: const Text('Huỷ'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  if (formKey.currentState!
                                                      .validate()) {
                                                    changePassword(
                                                      oldPassCtrl.text,
                                                      newPassCtrl.text,
                                                    );
                                                  }
                                                },
                                                child: const Text('Xác nhận'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },

                                    child: const Text('Đổi mật khẩu'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}
