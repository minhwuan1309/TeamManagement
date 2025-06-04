import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/api_service.dart';
import 'package:team_manage_frontend/layouts/common_layout.dart';
import 'package:team_manage_frontend/screens/modules/edit_module_page.dart';
import 'package:team_manage_frontend/screens/modules/task_list_card.dart';
import 'package:team_manage_frontend/screens/tasks/create_task_page.dart';
import 'package:team_manage_frontend/screens/workflow/create_workflow_page.dart';
import 'package:team_manage_frontend/screens/workflow/workflow_widget.dart';

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
  bool isLoading = true;
  Map? currentModule;
  Map? currentWorkflow;
  String? errorMessage;
  int currentUserRole = -1;

  @override
  void initState() {
    super.initState();
    _loadUserRole();

    // 1. Ưu tiên truyền trực tiếp module từ widget
    if (widget.module != null) {
      currentModule = widget.module!;

      final m = currentModule?['members'];

      if (m is Map && m.containsKey(r'$values')) {
        currentModule!['members'] = m[r'$values'];
      }
      isLoading = false;
    } 
    // 2. Nếu có moduleId từ constructor
    else if (widget.moduleId != null) {
      fetchModule(widget.moduleId!);
      fetchWorkflow(widget.moduleId!);
    } 
    // 3. Trường hợp F5: lấy moduleId từ URL query
    else {
      final idParam = Uri.base.queryParameters['id'];
      final parsedId = int.tryParse(idParam ?? '');
      if (parsedId != null) {
        fetchModule(parsedId);
        fetchWorkflow(parsedId);
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Lỗi: moduleId không hợp lệ";
        });
      }
    }
  }
    Future<void> _loadUserRole() async {
      final profile = await ApiService.getProfile();
      setState(() {
        currentUserRole = profile?['role'] == 'admin' ? 0 : 1;
      });
    }

Future<void> fetchModule(int moduleId) async {
  setState(() => isLoading = true);
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final res = await http.get(
    Uri.parse('$baseUrl/module/$moduleId'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);

    // ✅ Normalize members
    final rawMembers = data['members'];
    if (rawMembers is Map && rawMembers.containsKey(r'$values')) {
      data['members'] = rawMembers[r'$values'];
    }

    setState(() {
      currentModule = data;
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


  Future<void> fetchWorkflow(int moduleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final res = await http.get(
        Uri.parse('$baseUrl/workflow/module/$moduleId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final workflowData = jsonDecode(res.body);
        setState(() {
          currentWorkflow = workflowData;
        });
      } else {
        setState(() {
          currentWorkflow = null;
        });
      }
    } catch (e) {
      setState(() {
        currentWorkflow = null;
      });
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

  // Trả về màu tương ứng với trạng thái
  Color _getStatusColor(dynamic status) {
    int statusValue =
        status is int ? status : _getStatusValue(_getStatusText(status));
    switch (statusValue) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Format ngày tháng
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Không có';
    try {
      final DateTime date = DateTime.parse(dateString);
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return 'Không hợp lệ';
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
          SnackBar(
            content: Text('Cập nhật trạng thái thành công'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            ),
        );
      } else {
        setState(() => isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: ${res.statusCode}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            ),
        );
      }
    } catch (e) {
      setState(() => isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kết nối: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            ),
        );
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

  Future<void> _toggleDeleteModule() async {
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
        Navigator.pop(context, true);
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

  Future<void> _hardDeleteModule() async {
    final moduleId = currentModule?['id'];
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/module/hard-delete/$moduleId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã xoá vĩnh viễn module')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xoá vĩnh viễn: ${res.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }
    if (currentModule == null) {
      return const Scaffold(
        body: Center(
          child: Text("Không tìm thấy module", style: TextStyle(fontSize: 16)),
        ),
      );
    }

    List<dynamic> members = [];
    if (currentModule?['members'] != null) {
      if (currentModule?['members'] is List) {
        members = currentModule?['members'];
      } else if (currentModule?['members'] is Map &&
          currentModule?['members'].containsKey(r'$values')) {
        members = currentModule?['members'][r'$values'];
      }
    }

    // Xử lý danh sách task
    List<dynamic> tasks = [];
    if (currentModule?['tasks'] != null) {
      if (currentModule?['tasks'] is List) {
        tasks = currentModule?['tasks'];
      } else if (currentModule?['tasks'] is Map &&
          currentModule?['tasks'].containsKey(r'$values')) {
        tasks = currentModule?['tasks'][r'$values'];
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
          icon: const Icon(Icons.group, color: Colors.blue),
          tooltip: 'Thành viên',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Danh sách thành viên'),
                  content: members.isEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.group_off,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Không có thành viên nào.',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          width: MediaQuery.of(context).size.width * 0.6,
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: members.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final member = members[index];
                              final String fullName = member['fullName'] ?? 'Không tên';
                              final String? avatarUrl = member['avatar'];
                              final String role = member['roleInProject'] ?? 'Không có vai trò';

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                leading: Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue.withOpacity(0.1),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.3),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: avatarUrl != null && avatarUrl.isNotEmpty
                                        ? Image.network(
                                            avatarUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const Icon(
                                              Icons.person,
                                              color: Colors.blue,
                                              size: 28,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person,
                                            color: Colors.blue,
                                            size: 28,
                                          ),
                                  ),
                                ),
                                title: Text(
                                  fullName,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        role,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Đóng'),
                    ),
                  ],
                );
              },
            );
          },
        ),

        IconButton(
          icon: const Icon(Icons.edit, color: Colors.orange),
          tooltip: 'Chỉnh sửa Module',
          onPressed: () {
            final moduleWithMembers = {
              ...currentModule!,
              'memberIds': {
                r'$values': _extractMemberIds(currentModule?['members']),
              },
            };

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditModulePage(module: moduleWithMembers),
              ),
            ).then((result) {
              if (result != null) {
                if (result is Map) {
                  setState(() {
                    currentModule = result;
                  });
                } else if (result == true) {
                  _refreshModuleData();
                }
              }
            });
          },
        ),
        IconButton(
          icon: Icon(
            currentModule?['isDeleted'] == true ? Icons.restore : Icons.delete,
            color:
                currentModule?['isDeleted'] == true ? Colors.green : Colors.red,
          ),
          tooltip:
              currentModule?['isDeleted'] == true
                  ? 'Khôi phục Module'
                  : 'Xoá Module',
          onPressed: () {
            final confirmText =
                currentModule?['isDeleted'] == true
                    ? 'Bạn có muốn khôi phục module này?'
                    : 'Bạn có chắc muốn xoá module này?';
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    title: Text(
                      'Xác nhận',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(confirmText),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _toggleDeleteModule();
                        },
                        child: Text(
                          currentModule?['isDeleted'] == true
                              ? 'Khôi phục'
                              : 'Xoá',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
            );
          },
        ),
        if (currentModule?['isDeleted'] == true)
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: 'Xoá vĩnh viễn Module',
            onPressed: () {
              final confirmHardDeleteText =
                  'Bạn có chắc muốn xoá vĩnh viễn module này?';
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      title: Text(
                        'Xác nhận',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: Text(confirmHardDeleteText),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _hardDeleteModule();
                          },
                          child: const Text(
                            'Xoá vĩnh viễn',
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

      floatingActionButton: SpeedDial(
        icon: Icons.keyboard_arrow_up, // mũi tên ^
        activeIcon: Icons.close,
        backgroundColor: Colors.blue,
        overlayOpacity: 0,
        overlayColor: Colors.transparent,
        children: [
          SpeedDialChild(
            child: Icon(Icons.add_task),
            label: 'Thêm task',
            onTap: () async {
              if (mounted) setState(() {}); // đảm bảo cập nhật layout trước
              await Future.delayed(Duration(milliseconds: 100));

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateTaskPage(moduleId: currentModule!['id']),
                ),
              ).then((shouldReload) {
                if (shouldReload == true) _refreshModuleData();
              });
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.account_tree),
            label: 'Thêm workflow',
            onTap: () async{
              if (mounted) setState(() {});
              await Future.delayed(Duration(milliseconds: 100));

              Navigator.push(context, MaterialPageRoute(
                builder: (_) => CreateWorkflowPage(moduleId: currentModule!['id']),
              ),
              ).then((shouldReload) {
                if (shouldReload == true) _refreshModuleData();
              });
            } 
          ),
        ],
      ),
      body:
          isUpdating
              ? const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              )
              : RefreshIndicator(
                onRefresh: _refreshModuleData,
                color: Colors.blue,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 12.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header với thông tin cơ bản
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.dashboard_rounded, color: Colors.blue, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      currentModule?['name'] ?? 'Không có tên',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, thickness: 1),
                              Row(
                                children: [
                                  const Text(
                                    'Trạng thái: ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(currentModule?['status']).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: _getStatusColor(currentModule?['status']),
                                      ),
                                    ),
                                    child: DropdownButton<int>(
                                      value: currentModule?['status'] is int
                                          ? currentModule!['status']
                                          : _getStatusValue(
                                              _getStatusText(currentModule?['status']),
                                            ),
                                      items: [
                                        DropdownMenuItem(
                                          value: 0,
                                          child: Text(
                                            'Chưa bắt đầu',
                                            style: TextStyle(color: Colors.grey[700]),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 1,
                                          child: Text(
                                            'Đang tiến hành',
                                            style: TextStyle(color: Colors.blue[700]),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 2,
                                          child: Text(
                                            'Hoàn thành',
                                            style: TextStyle(color: Colors.green[700]),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          _updateModuleStatus(value);
                                        }
                                      },
                                      underline: Container(height: 0),
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: _getStatusColor(currentModule?['status']),
                                      ),
                                      dropdownColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 18,
                                            color: Colors.blue[600],
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Ngày tạo',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                Text(
                                                  createdAt,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.update,
                                            size: 18,
                                            color: Colors.orange[600],
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Cập nhật',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                Text(
                                                  updatedAt,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      //Workflow
                      const SizedBox(height: 10),
                      WorkflowWidget(moduleId: currentModule!['id']),

                      const SizedBox(height: 16),
                      
                      TaskListCard(
                        tasks: tasks,
                        currentModule: currentModule?.cast<String, dynamic>(),
                        refreshModuleData: _refreshModuleData,
                        formatDate: _formatDate,
                        getStatusColor: _getStatusColor,
                        getStatusText: _getStatusText,
                        currentUserRole: currentUserRole,
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
