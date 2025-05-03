import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/screens/modules/module_detail_page.dart';
import 'package:team_manage_frontend/screens/modules/create_module_page.dart';

class ModulePage extends StatefulWidget {
  const ModulePage({super.key});

  @override
  State<ModulePage> createState() => _ModulePageState();
}

class _ModulePageState extends State<ModulePage> {
  List modules = [];
  List projects = [];
  int? selectedProjectId;
  bool isLoading = false;
  bool _refreshInProgress = false;
  final String baseUrl = 'http://localhost:5053/api';

  @override
  void initState() {
    super.initState();
    fetchProjects();
  }

  Future<void> fetchProjects() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/project'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        final List<dynamic> projectList =
            decoded is Map && decoded.containsKey(r'$values')
                ? decoded[r'$values']
                : (decoded is List ? decoded : []);

        setState(() {
          projects = projectList;
          isLoading = false;
          if (projectList.isNotEmpty) {
            selectedProjectId = projectList[0]['id'];
            fetchModules(selectedProjectId!);
          }
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải project: ${res.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
    }
  }

  Future<void> fetchModules(
    int projectId, {
    bool showLoadingIndicator = true,
  }) async {
    // Avoid multiple simultaneous refresh operations
    if (_refreshInProgress) return;
    _refreshInProgress = true;

    if (showLoadingIndicator) {
      setState(() {
        isLoading = true;
        modules = [];
      });
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/module?projectId=$projectId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        var decoded = jsonDecode(res.body);
        List modulesList = [];

        // Handle different response formats
        if (decoded is Map && decoded.containsKey(r'$values')) {
          modulesList = decoded[r'$values'];
        } else if (decoded is List) {
          modulesList = decoded;
        }

        setState(() {
          modules = modulesList;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tải module: ${res.statusCode}')),
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
      }
    } finally {
      _refreshInProgress = false;
    }
  }

  // Periodic data refresh setup with a timer
  void setupPeriodicRefresh() {
    // Refresh data every 30 seconds if the page is active
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && selectedProjectId != null) {
        fetchModules(selectedProjectId!, showLoadingIndicator: false);
      }
      // Setup the next refresh cycle
      if (mounted) setupPeriodicRefresh();
    });
  }

  // Chuyển đổi enum ProcessStatus từ backend (0, 1, 2) sang chuỗi hiển thị
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

  // Get status color for visual indication
  Color _getStatusColor(dynamic status) {
    if (status is int) {
      switch (status) {
        case 0:
          return Colors.grey;
        case 1:
          return Colors.blue;
        case 2:
          return Colors.green;
        default:
          return Colors.grey;
      }
    } else if (status is String) {
      switch (status.toLowerCase()) {
        case 'none':
          return Colors.grey;
        case 'inprogress':
        case 'in_progress':
          return Colors.blue;
        case 'done':
          return Colors.green;
        default:
          return Colors.grey;
      }
    }
    return Colors.grey;
  }

  Widget buildModuleCard(dynamic module) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          Icons.view_module,
          color: _getStatusColor(module['status']),
        ),
        title: Text(module['name'] ?? 'Không có tên'),
        subtitle: Text("Trạng thái: ${_getStatusText(module['status'])}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Thành viên: ${module['memberCount'] ?? 0}"),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () => _viewModuleDetails(module['id']),
            ),
          ],
        ),
      ),
    );
  }

  void _viewModuleDetails(int moduleId) async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/module/$moduleId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      setState(() => isLoading = false);

      if (res.statusCode == 200) {
        final moduleData = jsonDecode(res.body);

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ModuleDetailPage.withModule(module: moduleData),
          ),
        );

        // Refresh module list after returning from detail page
        if (result == true && selectedProjectId != null) {
          await fetchModules(selectedProjectId!);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải chi tiết module: ${res.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
    }
  }

  void _createNewModule() {
    if (selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn project trước')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateModulePage(projectId: selectedProjectId!),
      ),
    ).then((_) {
      // Always refresh data when returning from create module page
      if (selectedProjectId != null) {
        fetchModules(selectedProjectId!);
      }
    });
  }

  Future<void> _onRefresh() async {
    if (selectedProjectId != null) {
      await fetchModules(selectedProjectId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Module'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (selectedProjectId != null) {
                fetchModules(selectedProjectId!);
              }
            },
            tooltip: 'Làm mới dữ liệu',
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Chọn Project',
                border: OutlineInputBorder(),
              ),
              value: selectedProjectId,
              items:
                  projects.map<DropdownMenuItem<int>>((project) {
                    return DropdownMenuItem<int>(
                      value: project['id'],
                      child: Text(project['name'] ?? '---'),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedProjectId = value;
                });
                if (value != null) fetchModules(value);
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : modules.isEmpty
                      ? ListView(
                        children: const [
                          SizedBox(height: 100),
                          Center(child: Text('Không có module nào.')),
                        ],
                      )
                      : ListView(
                        children:
                            modules
                                .map<Widget>(
                                  (module) => buildModuleCard(module),
                                )
                                .toList(),
                      ),
            ),
          ),
        ],
      ),
      floatingActionButton:
          selectedProjectId != null
              ? FloatingActionButton(
                onPressed: _createNewModule,
                child: const Icon(Icons.add),
                tooltip: 'Tạo module mới',
                backgroundColor: Colors.blue.shade700,
              )
              : null,
    );
  }

  @override
  void dispose() {
    _refreshInProgress = false;
    super.dispose();
  }
}
