import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/screens/modules/edit_module_page.dart';

class ModuleDetailPage extends StatefulWidget {
  final Map? module;
  final int? moduleId;

  const ModuleDetailPage.withModule({super.key, required this.module})
      : moduleId = null;

  const ModuleDetailPage.withId({super.key, required this.moduleId})
      : module = null;

  @override
  State<ModuleDetailPage> createState() => _ModuleDetailPageState();
}


class _ModuleDetailPageState extends State<ModuleDetailPage> {
  bool isUpdating = false;
  final String baseUrl = 'http://localhost:5053/api';
  Map? currentModule;
  bool isLoading = true;

@override
void initState() {
  super.initState();
  if (widget.module != null) {
    currentModule = widget.module!;
    isLoading = false;
  } else if (widget.moduleId != null) {
    fetchModule(widget.moduleId!);
  }
}


Future<void> fetchModule(int moduleId) async {
  setState(() => isLoading = true);
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final res = await http.get(
    Uri.parse('http://localhost:5053/api/module/$moduleId'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (res.statusCode == 200) {
    setState(() {
      currentModule = jsonDecode(res.body);
      isLoading = false;
    });
  } else {
    setState(() => isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: ${res.body}")),
      );
    }
  }
}



  String _getStatusText(dynamic status) {
    if (status is int) {
      switch (status) {
        case 0:
          return 'Chưa bắt đầu';
        case 1:
          return 'Đang tiến hành';
        case 2:
          return 'Hoàn thành';
        default:
          return 'Không xác định';
      }
    } else if (status is String) {
      switch (status.toLowerCase()) {
        case 'none':
          return 'Chưa bắt đầu';
        case 'inprogress':
        case 'in_progress':
          return 'Đang tiến hành';
        case 'done':
          return 'Hoàn thành';
        default:
          return 'Không xác định';
      }
    }
    return 'Không xác định';
  }

  // Lấy giá trị enum ProcessStatus từ chuỗi hiển thị
  int _getStatusValue(String statusText) {
    switch (statusText) {
      case 'Chưa bắt đầu':
        return 0;
      case 'Đang tiến hành':
        return 1;
      case 'Hoàn thành':
        return 2;
      default:
        return 0;
    }
  }

  // Fetch fresh module data
  Future<void> _refreshModuleData() async {
    setState(() => isUpdating = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final moduleId = currentModule?['id'];

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/module/$moduleId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      setState(() => isUpdating = false);

      if (res.statusCode == 200) {
        final updatedData = jsonDecode(res.body);
        setState(() {
          currentModule = updatedData;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải lại dữ liệu: ${res.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => isUpdating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
    }
  }

  Future<void> _updateModuleStatus(int newStatus) async {
    setState(() => isUpdating = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final moduleId = currentModule?['id'];

    try {
      final res = await http.put(
        Uri.parse('$baseUrl/module/update-status/$moduleId?status=$newStatus'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final updatedData = jsonDecode(res.body);
        setState(() {
          currentModule?['status'] = newStatus;
          isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật trạng thái thành công')),
        );
      } else {
        setState(() => isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: ${res.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => isUpdating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
    }
  }

  Future<void> _deleteModule() async {
    final moduleId = currentModule?['id'];
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/module/delete/$moduleId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Xóa module thành công')));
        Navigator.pop(context, true); // Quay lại trang trước và reload
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa module: ${res.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
    }
  }

  List<String> _extractMemberIds(dynamic members) {
    List<dynamic> membersList = [];

    if (members == null) {
      return [];
    } else if (members is List) {
      membersList = members;
    } else if (members is Map && members.containsKey(r'$values')) {
      membersList = members[r'$values'];
    }

    // Extract user IDs
    return membersList
        .map<String>((member) => member['userId'] as String)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (currentModule == null) return const Scaffold(body: Center(child: Text("Không tìm thấy module")));


    List<dynamic> members = [];
    if (currentModule?['members'] != null) {
      if (currentModule?['members'] is List) {
        members = currentModule?['members'];
      } else if (currentModule?['members'] is Map &&
          currentModule?['members'].containsKey(r'$values')) {
        members = currentModule?['members'][r'$values'];
      }
    }

    // Format dates properly
    String createdAt = 'Không rõ';
    if (currentModule?['createdAt'] != null) {
      try {
        final DateTime date = DateTime.parse(
          currentModule!['createdAt'].toString(),
        );
        createdAt =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      } catch (e) {
        print("Error parsing createdAt: $e");
      }
    }

    String updatedAt = 'Không rõ';
    if (currentModule?['updatedAt'] != null) {
      try {
        final DateTime date = DateTime.parse(
          currentModule!['updatedAt'].toString(),
        );
        updatedAt =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      } catch (e) {
        print("Error parsing updatedAt: $e");
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Module'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới dữ liệu',
            onPressed: _refreshModuleData,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Chỉnh sửa Module',
            onPressed: () {
              // Fix here: Safely extract member IDs regardless of the data structure
              final moduleWithMembers = {
                ...currentModule!,
                'memberIds': {
                  r'$values': _extractMemberIds(currentModule?['members']),
                },
              };

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => EditModulePage(module: moduleWithMembers),
                ),
              )..then((result) {
                if (result != null) {
                  if (result is Map) {
                    setState(() {
                      currentModule = result;
                    });
                    Navigator.pop(
                      context,
                      true,
                    ); // ✅ Thêm dòng này để báo về module_page
                  } else if (result == true) {
                    _refreshModuleData();
                  }
                }
              });
            },
          ),

          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Xác nhận xóa'),
                      content: const Text('Bạn có chắc muốn xóa module này?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteModule();
                          },
                          child: const Text(
                            'Xóa',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body:
          isUpdating
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentModule?['name'] ?? 'Không có tên',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cập nhật trạng thái module bằng dropdown
                    Row(
                      children: [
                        const Text(
                          'Trạng thái: ',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value:
                              currentModule?['status'] is int
                                  ? currentModule!['status']
                                  : _getStatusValue(
                                    _getStatusText(currentModule?['status']),
                                  ),
                          items: [
                            DropdownMenuItem(
                              value: 0,
                              child: Text('Chưa bắt đầu'),
                            ),
                            DropdownMenuItem(
                              value: 1,
                              child: Text('Đang tiến hành'),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text('Hoàn thành'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _updateModuleStatus(value);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ngày tạo: $createdAt',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const Divider(height: 32),
                    const Text(
                      'Thành viên:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child:
                          members.isEmpty
                              ? const Text('Không có thành viên nào.')
                              : ListView.builder(
                                itemCount: members.length,
                                itemBuilder: (context, index) {
                                  final member = members[index];
                                  final String fullName =
                                      member['fullName'] ?? 'Không tên';
                                  final String? avatarUrl = member['avatar'];
                                  final String role =
                                      member['roleInProject'] ??
                                      'Không có vai trò';

                                  return ListTile(
                                    leading:
                                        avatarUrl != null &&
                                                avatarUrl.isNotEmpty
                                            ? CircleAvatar(
                                              backgroundImage: NetworkImage(
                                                avatarUrl,
                                              ),
                                              onBackgroundImageError: (_, __) {
                                                // Handle image loading error
                                              },
                                            )
                                            : const CircleAvatar(
                                              backgroundColor: Colors.blue,
                                              child: Icon(
                                                Icons.person,
                                                color: Colors.white,
                                              ),
                                            ),
                                    title: Text(fullName),
                                    subtitle: Text('Vai trò: $role'),
                                  );
                                },
                              ),
                    ),
                    const Divider(height: 32),
                    Text(
                      'Cập nhật lần cuối: $updatedAt',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
    );
  }
}
