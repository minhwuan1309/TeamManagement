import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/api_service.dart';
import 'package:team_manage_frontend/layouts/common_layout.dart';
import 'package:team_manage_frontend/screens/modules/create_module_page.dart';
import 'package:team_manage_frontend/screens/modules/edit_module_page.dart';
import 'package:team_manage_frontend/screens/tasks/create_task_page.dart';
import 'package:team_manage_frontend/screens/tasks/task_detail_page.dart';
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
  Map? currentModule;
  bool isLoading = true;
  Map? currentWorkflow;

  @override
  void initState() {
    super.initState();
    if (widget.module != null) {
      currentModule = widget.module!;
      isLoading = false;
    } else if (widget.moduleId != null) {
      fetchModule(widget.moduleId!);
      fetchWorkflow(widget.moduleId!);
    }
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
      setState(() {
        currentModule = jsonDecode(res.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: ${res.body}")));
      }
    }
  }

  // Hàm debug để kiểm tra dữ liệu workflow trong fetchWorkflow
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

    return CommonLayout(
      title: 'Chi tiết Module',
      appBarActions: [
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
                  Navigator.pop(context, true);
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
      floatingActionButton: SpeedDial(
        icon: Icons.keyboard_arrow_up, // mũi tên ^
        activeIcon: Icons.close,
        backgroundColor: Colors.blue,
        children: [
          SpeedDialChild(
            child: Icon(Icons.add_task),
            label: 'Thêm task',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          CreateTaskPage(moduleId: currentModule!['id']),
                ),
              ).then((shouldReload) {
                if (shouldReload == true) _refreshModuleData();
              });
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.account_tree),
            label: 'Thêm workflow',
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => CreateWorkflowPage(moduleId: currentModule!['id']),
            ))
          ),
        ],
      ),
      child:
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
                                  Icon(
                                    Icons.dashboard_rounded,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
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
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        currentModule?['status'],
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: _getStatusColor(
                                          currentModule?['status'],
                                        ),
                                      ),
                                    ),
                                    child: DropdownButton<int>(
                                      value:
                                          currentModule?['status'] is int
                                              ? currentModule!['status']
                                              : _getStatusValue(
                                                _getStatusText(
                                                  currentModule?['status'],
                                                ),
                                              ),
                                      items: [
                                        DropdownMenuItem(
                                          value: 0,
                                          child: Text(
                                            'Chưa bắt đầu',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 1,
                                          child: Text(
                                            'Đang tiến hành',
                                            style: TextStyle(
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 2,
                                          child: Text(
                                            'Hoàn thành',
                                            style: TextStyle(
                                              color: Colors.green[700],
                                            ),
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
                                        color: _getStatusColor(
                                          currentModule?['status'],
                                        ),
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

                      const SizedBox(height: 16),

                      // Phần Thành viên
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
                                  const Icon(Icons.people, color: Colors.blue),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Danh sách thành viên',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, thickness: 1),

                              members.isEmpty
                                  ? Container(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    alignment: Alignment.center,
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.group_off,
                                          size: 48,
                                          color: Colors.grey[300],
                                        ),
                                        SizedBox(height: 12),
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
                                    constraints: BoxConstraints(maxHeight: 200),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics: AlwaysScrollableScrollPhysics(),
                                      itemCount: members.length,
                                      separatorBuilder:
                                          (context, index) =>
                                              Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final member = members[index];
                                        final String fullName =
                                            member['fullName'] ?? 'Không tên';
                                        final String? avatarUrl =
                                            member['avatar'];
                                        final String role =
                                            member['roleInProject'] ??
                                            'Không có vai trò';

                                        return ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 4,
                                            horizontal: 8,
                                          ),
                                          leading: Container(
                                            width: 45,
                                            height: 45,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.blue.withOpacity(
                                                0.1,
                                              ),
                                              border: Border.all(
                                                color: Colors.blue.withOpacity(
                                                  0.3,
                                                ),
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                              child:
                                                  avatarUrl != null &&
                                                          avatarUrl.isNotEmpty
                                                      ? Image.network(
                                                        avatarUrl,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) => Icon(
                                                              Icons.person,
                                                              color:
                                                                  Colors.blue,
                                                              size: 28,
                                                            ),
                                                      )
                                                      : Icon(
                                                        Icons.person,
                                                        color: Colors.blue,
                                                        size: 28,
                                                      ),
                                            ),
                                          ),
                                          title: Text(
                                            fullName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          subtitle: Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
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
                            ],
                          ),
                        ),
                      ),

                      //Workflow
                      const SizedBox(height: 10),
                      WorkflowWidget(moduleId: currentModule!['id']),

                      const SizedBox(height: 16),
                      // Phần Công việc
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
                                  const Icon(
                                    Icons.task_alt,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Danh sách công việc',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, thickness: 1),

                              tasks.isEmpty
                                  ? Container(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    alignment: Alignment.center,
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.assignment_outlined,
                                          size: 48,
                                          color: Colors.grey[300],
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Không có công việc nào.',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                        SizedBox(height: 8),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          icon: Icon(Icons.add),
                                          label: Text('Thêm công việc mới'),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => CreateTaskPage(
                                                      moduleId:
                                                          currentModule!['id'],
                                                    ),
                                              ),
                                            ).then((shouldReload) {
                                              if (shouldReload == true)
                                                _refreshModuleData();
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  )
                                  : Container(
                                    constraints: BoxConstraints(maxHeight: 500),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics: AlwaysScrollableScrollPhysics(),
                                      itemCount: tasks.length,
                                      itemBuilder: (context, index) {
                                        final task = tasks[index];
                                        final String title = task['title'] ?? 'Không có tiêu đề';
                                        final String? currentStepName = task['currentStepName'];
                                        final dynamic status = task['status'];
                                        final String startDate = _formatDate(
                                          task['startDate'],
                                        );
                                        final String endDate = _formatDate(
                                          task['endDate'],
                                        );
                                        final String assignedUserName =
                                            task['assignedUserName'] ??
                                            'Chưa gán';

                                        return Card(
                                          margin: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            side: BorderSide(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => TaskDetailPage(
                                                        taskId: task['id'],
                                                      ),
                                                ),
                                              ).then(
                                                (result) => {
                                                  if (result == true)
                                                    _refreshModuleData(),
                                                },
                                              );
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                12.0,
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(
                                                        status,
                                                      ).withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Icon(
                                                        status == 2
                                                            ? Icons.check_circle
                                                            : status == 1
                                                            ? Icons.pending
                                                            : Icons
                                                                .circle_outlined,
                                                        color: _getStatusColor(
                                                          status,
                                                        ),
                                                        size: 24,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          title,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16
                                                            ),
                                                        ),
                                                        if (task['currentStepName'] !=
                                                                null &&
                                                            (task['currentStepName']
                                                                    as String)
                                                                .isNotEmpty)
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  top: 4.0,
                                                                ),
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .alt_route,
                                                                  size: 16,
                                                                  color:
                                                                      Colors
                                                                          .purple,
                                                                ),
                                                                const SizedBox(
                                                                  width: 4,
                                                                ),
                                                                Text(
                                                                  'Bước hiện tại: ${task['currentStepName']}',
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    color:
                                                                        Colors
                                                                            .purple,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),

                                                        SizedBox(height: 8),
                                                        Wrap(
                                                          spacing: 8,
                                                          runSpacing: 8,
                                                          children: [
                                                            Container(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical: 3,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    _getStatusColor(
                                                                      status,
                                                                    ).withOpacity(
                                                                      0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                                border: Border.all(
                                                                  color: _getStatusColor(
                                                                    status,
                                                                  ).withOpacity(
                                                                    0.5,
                                                                  ),
                                                                  width: 1,
                                                                ),
                                                              ),
                                                              child: Text(
                                                                _getStatusText(
                                                                  status,
                                                                ),
                                                                style: TextStyle(
                                                                  color:
                                                                      _getStatusColor(
                                                                        status,
                                                                      ),
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ),
                                                            Container(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical: 3,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    Colors
                                                                        .grey[100],
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .calendar_today,
                                                                    size: 12,
                                                                    color:
                                                                        Colors
                                                                            .grey[600],
                                                                  ),
                                                                  SizedBox(
                                                                    width: 4,
                                                                  ),
                                                                  Text(
                                                                    '$startDate - $endDate',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color:
                                                                          Colors
                                                                              .grey[600],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            Container(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical: 3,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    Colors
                                                                        .blue[50],
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .person_outline,
                                                                    size: 12,
                                                                    color:
                                                                        Colors
                                                                            .blue[600],
                                                                  ),
                                                                  SizedBox(
                                                                    width: 4,
                                                                  ),
                                                                  Text(
                                                                    assignedUserName,
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color:
                                                                          Colors
                                                                              .blue[600],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                                                    child: Icon(
                                                      Icons.chevron_right,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
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
    );
  }
}
