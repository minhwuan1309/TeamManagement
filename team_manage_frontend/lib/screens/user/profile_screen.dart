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

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      title: "Hồ sơ cá nhân",
      child:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
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
                              padding: const EdgeInsets.all(24),
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
                                              color: Colors.black.withOpacity(
                                                0.2,
                                              ),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 60,
                                          backgroundColor: Colors.white
                                              .withOpacity(0.3),
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
                                                    style: const TextStyle(
                                                      fontSize: 48,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                  : null,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: pickAvatarImage,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.camera_alt_rounded,
                                            size: 22,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // User name in header
                                  Text(
                                    nameCtrl.text,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),

                                  // User role badge
                                  if (userRole != null)
                                    Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
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
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Form Content
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Thông tin cá nhân",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Email field (readonly)
                                    TextFormField(
                                      controller: emailCtrl,
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        labelStyle: TextStyle(
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.email_rounded,
                                          color: Colors.blue.shade700,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.blue.shade700,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.shade100,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 16,
                                              horizontal: 16,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Full name field
                                    TextFormField(
                                      controller: nameCtrl,
                                      decoration: InputDecoration(
                                        labelText: 'Họ và tên',
                                        labelStyle: TextStyle(
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.person_rounded,
                                          color: Colors.blue.shade700,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.blue.shade700,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 16,
                                              horizontal: 16,
                                            ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Vui lòng nhập họ tên';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Phone field
                                    TextFormField(
                                      controller: phoneCtrl,
                                      keyboardType: TextInputType.phone,
                                      decoration: InputDecoration(
                                        labelText: 'Số điện thoại',
                                        labelStyle: TextStyle(
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.phone_rounded,
                                          color: Colors.blue.shade700,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.blue.shade700,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 16,
                                              horizontal: 16,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 36),

                                    // Action Buttons
                                    Row(
                                      children: [
                                        // Save button
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: updateProfile,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.blue.shade700,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              elevation: 2,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.save_rounded),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'Lưu thay đổi',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Change password option
                                    Padding(
                                      padding: const EdgeInsets.only(top: 24),
                                      child: Divider(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),

                                    // Security Section
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: TextButton.icon(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              final oldPassCtrl =
                                                  TextEditingController();
                                              final newPassCtrl =
                                                  TextEditingController();
                                              final confirmPassCtrl =
                                                  TextEditingController();
                                              final formKey =
                                                  GlobalKey<FormState>();

                                              return AlertDialog(
                                                title: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.lock_rounded,
                                                      color:
                                                          Colors.blue.shade700,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text('Đổi mật khẩu'),
                                                  ],
                                                ),
                                                content: Form(
                                                  key: formKey,
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      TextFormField(
                                                        controller: oldPassCtrl,
                                                        obscureText: true,
                                                        decoration: InputDecoration(
                                                          labelText:
                                                              'Mật khẩu hiện tại',
                                                          prefixIcon: const Icon(
                                                            Icons.lock_outline,
                                                          ),
                                                          border: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                          ),
                                                        ),
                                                        validator:
                                                            (val) =>
                                                                val == null ||
                                                                        val.isEmpty
                                                                    ? 'Nhập mật khẩu hiện tại'
                                                                    : null,
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      TextFormField(
                                                        controller: newPassCtrl,
                                                        obscureText: true,
                                                        decoration: InputDecoration(
                                                          labelText:
                                                              'Mật khẩu mới',
                                                          prefixIcon:
                                                              const Icon(
                                                                Icons.lock,
                                                              ),
                                                          border: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                          ),
                                                        ),
                                                        validator:
                                                            (val) =>
                                                                val == null ||
                                                                        val.length <
                                                                            6
                                                                    ? 'Tối thiểu 6 ký tự'
                                                                    : null,
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      TextFormField(
                                                        controller:
                                                            confirmPassCtrl,
                                                        obscureText: true,
                                                        decoration: InputDecoration(
                                                          labelText:
                                                              'Xác nhận mật khẩu mới',
                                                          prefixIcon:
                                                              const Icon(
                                                                Icons.lock,
                                                              ),
                                                          border: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                          ),
                                                        ),
                                                        validator: (val) {
                                                          if (val == null ||
                                                              val.isEmpty) {
                                                            return 'Xác nhận mật khẩu mới';
                                                          }
                                                          if (val !=
                                                              newPassCtrl
                                                                  .text) {
                                                            return 'Mật khẩu không khớp';
                                                          }
                                                          return null;
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                        ),
                                                    child: const Text('Huỷ'),
                                                  ),
                                                  ElevatedButton(
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors
                                                                  .blue
                                                                  .shade700,
                                                          foregroundColor:
                                                              Colors.white,
                                                        ),
                                                    onPressed: () {
                                                      if (formKey.currentState!
                                                          .validate()) {
                                                        changePassword(
                                                          oldPassCtrl.text,
                                                          newPassCtrl.text,
                                                        );
                                                      }
                                                    },
                                                    child: const Text(
                                                      'Xác nhận',
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 16,
                                          ),
                                          backgroundColor: Colors.blue.shade50,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
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
