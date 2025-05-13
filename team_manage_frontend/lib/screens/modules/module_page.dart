import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/api_service.dart';
import 'package:team_manage_frontend/layouts/common_layout.dart';
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
  bool showDeletedOnly = false;
  List<dynamic> allModules = [];

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
          projects = projectList.where((p) => p['isDeleted'] == false).toList();
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
          allModules = modulesList;
          applyFilter();
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

  void applyFilter() {
    setState(() {
      if (showDeletedOnly) {
        modules = allModules.where((m) => m['isDeleted'] == true).toList();
      } else {
        modules = allModules.where((m) => m['isDeleted'] == false).toList();
      }
    });
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
    final bool isDeleted = module['isDeleted'] ?? false;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          Icons.view_module,
          color: isDeleted ? Colors.red : _getStatusColor(module['status']),
        ),
        title: Text(module['name'] ?? 'Không có tên'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Trạng thái: ${_getStatusText(module['status'])}"),
            Text(
              isDeleted ? "Đã xoá" : "Đang hoạt động",
              style: TextStyle(
                color: isDeleted ? Colors.red : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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

  Widget buildFilterToggle() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              "Hiển thị module đã xoá",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Switch(
              value: showDeletedOnly,
              activeColor: Theme.of(context).primaryColor,
              onChanged: (val) {
                setState(() {
                  showDeletedOnly = val;
                  applyFilter();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

@override
Widget build(BuildContext context) {
  final bool isTabletOrDesktop = MediaQuery.of(context).size.width > 600;
  
  return CommonLayout(
    title: 'Quản lý module',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        // Project selection card
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn Project',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  value: selectedProjectId,
                  icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  items: projects.map<DropdownMenuItem<int>>((project) {
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
              ],
            ),
          ),
        ),
        
        // Filter toggle with improved design
        Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Bộ lọc",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      "Hiển thị module đã xoá",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Switch(
                      value: showDeletedOnly,
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (val) {
                        setState(() {
                          showDeletedOnly = val;
                          applyFilter();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Module list with improved styling
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: Theme.of(context).primaryColor,
            child: isLoading 
              ? const Center(child: CircularProgressIndicator())
              : modules.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 100),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Không có module nào',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (selectedProjectId != null) ...[
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _createNewModule,
                              icon: const Icon(Icons.add),
                              label: const Text('Tạo module mới'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  )
                : isTabletOrDesktop 
                  ? _buildDesktopModuleList()
                  : _buildMobileModuleList(),
          ),
        ),
      ],
    ),
    floatingActionButton: selectedProjectId != null && modules.isNotEmpty
      ? FloatingActionButton(
          onPressed: _createNewModule,
          child: const Icon(Icons.add),
          tooltip: 'Tạo module mới',
          backgroundColor: Colors.blue.shade700,
        )
      : null,
  );
}

// Desktop/tablet view for module list
Widget _buildDesktopModuleList() {
  return ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    itemCount: modules.length,
    itemBuilder: (context, index) {
      final module = modules[index];
      final bool isDeleted = module['isDeleted'] ?? false;
      
      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _viewModuleDetails(module['id']),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status indicator and icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDeleted 
                      ? Colors.red.shade50
                      : _getStatusColor(module['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.view_module,
                      color: isDeleted 
                        ? Colors.red 
                        : _getStatusColor(module['status']),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Module details (expanded to take available space)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module['name'] ?? 'Không có tên',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatusChip(module['status'], isDeleted),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.people_outline,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Thành viên: ${module['memberCount'] ?? 0}",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Actions
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _viewModuleDetails(module['id']),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Chi tiết'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// Mobile view for module list
Widget _buildMobileModuleList() {
  return ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    itemCount: modules.length,
    itemBuilder: (context, index) {
      final module = modules[index];
      final bool isDeleted = module['isDeleted'] ?? false;
      
      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _viewModuleDetails(module['id']),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Status icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDeleted 
                          ? Colors.red.shade50
                          : _getStatusColor(module['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.view_module,
                          color: isDeleted 
                            ? Colors.red 
                            : _getStatusColor(module['status']),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Module name and member count
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            module['name'] ?? 'Không có tên',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Thành viên: ${module['memberCount'] ?? 0}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Arrow icon
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                _buildStatusChip(module['status'], isDeleted),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// Helper widget for status display
Widget _buildStatusChip(dynamic status, bool isDeleted) {
  Color bgColor;
  Color textColor;
  String statusText;
  
  if (isDeleted) {
    bgColor = Colors.red.shade50;
    textColor = Colors.red.shade700;
    statusText = "Đã xoá";
  } else {
    final statusValue = status is int ? status : (status is String ? status.toLowerCase() : null);
    
    if (statusValue == 0 || statusValue == 'none') {
      bgColor = Colors.grey.shade100;
      textColor = Colors.grey.shade700;
      statusText = "Chưa bắt đầu";
    } else if (statusValue == 1 || statusValue == 'inprogress' || statusValue == 'in_progress') {
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
      statusText = "Đang tiến hành";
    } else if (statusValue == 2 || statusValue == 'done') {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      statusText = "Hoàn thành";
    } else {
      bgColor = Colors.grey.shade100;
      textColor = Colors.grey.shade700;
      statusText = "Không xác định";
    }
  }
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: textColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          statusText,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

  @override
  void dispose() {
    _refreshInProgress = false;
    super.dispose();
  }
}
