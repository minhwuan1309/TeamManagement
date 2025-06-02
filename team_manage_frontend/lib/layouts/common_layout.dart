import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:team_manage_frontend/api_service.dart';
import 'package:team_manage_frontend/screens/modules/module_detail_page.dart';
import 'package:team_manage_frontend/screens/searchBar.dart';
import 'package:team_manage_frontend/layouts/sidebar.dart'; 

class CommonLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final bool showAppBar;
  final List<Widget>? appBarActions;
  final Widget? floatingActionButton;

  const CommonLayout({
    Key? key,
    required this.child,
    required this.title,
    this.showAppBar = true,
    this.appBarActions,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  State<CommonLayout> createState() => _CommonLayoutState();
}

class _CommonLayoutState extends State<CommonLayout> {
  bool isLoading = false;
  bool _refreshInProgress = false;
  bool showDeletedOnly = false;
  static bool _isSidebarVisible = true;

  List<dynamic> projects = [];
  int? selectedProjectId;
  List<Map<String, dynamic>> projectMembers = [];
  final Map<int, Map<String, dynamic>> moduleCache = {};
  int currentPageIndex = 0;
  Map<String, dynamic>? selectedModule;

  Map<String, dynamic>? treeModulesData;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchProjects();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
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
      if(!mounted) return; 

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List<dynamic> projectList =
            decoded is Map && decoded.containsKey(r'$values')
                ? decoded[r'$values']
                : (decoded is List ? decoded : []);
        if (!mounted) return;

        setState(() {
          projects = projectList.where((p) => p['isDeleted'] == false).toList();
          if (projects.isNotEmpty) {
            selectedProjectId = projects[0]['id'];
            fetchTreeModules(selectedProjectId!);
            fetchProjectMembers(selectedProjectId!);
          }
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: ${res.statusCode}'),
          backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e'),
        backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> fetchProjectMembers(int projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.get(
      Uri.parse('$baseUrl/project/$projectId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);

      // ✅ Kiểm tra members chính xác và xử lý kiểu Map
      final membersRaw = decoded['members'];
      List<Map<String, dynamic>> normalizedMembers = [];

      if (membersRaw is Map && membersRaw.containsKey(r'$values')) {
        final values = membersRaw[r'$values'];
        if (values is List) {
          normalizedMembers = values.map<Map<String, dynamic>>(
            (e) => Map<String, dynamic>.from(e),
          ).toList();
        }
      }

      setState(() {
        projectMembers = normalizedMembers;
      });
    }
  }


  Future<void> fetchTreeModules(int projectId, {bool showLoadingIndicator = true}) async {
    if (_refreshInProgress) return;
    _refreshInProgress = true;
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/module/tree?projectId=$projectId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        var decoded = jsonDecode(res.body);
        List modulesList = [];
        setState(() {
          treeModulesData = decoded;
          moduleCache[projectId] = decoded;
          isLoading = false;
        });

        if (decoded is Map && decoded.containsKey(r'$values')) {
          modulesList = decoded[r'$values'];
        } else if (decoded is List) {
          modulesList = decoded;
        }

        // Sắp xếp module theo code để đảm bảo hiển thị đúng thứ tự cây
        modulesList.sort((a, b) {
          String codeA = a['code'] ?? '';
          String codeB = b['code'] ?? '';
          return codeA.compareTo(codeB);
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải module: ${res.statusCode}'),
            backgroundColor: Colors.red,
            ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _refreshInProgress = false;
    }
  }

  void setDataFromCache(int projectId) {
    if (moduleCache.containsKey(projectId)) {
      treeModulesData = moduleCache[projectId]; 
    }
  }

  List<Map<String, dynamic>> buildModuleTreeFromFlatList(List<dynamic> flatModules) {
    final Map<int, Map<String, dynamic>> mapById = {};
    final List<Map<String, dynamic>> tree = [];

    for (var m in flatModules) {
      m['children'] = [];
      mapById[m['id']] = m;
    }

    for (var m in flatModules) {
      final parentId = m['parentModuleId'];
      if (parentId == null) {
        tree.add(m);
      } else {
        final parent = mapById[parentId];
        parent?['children']?.add(m);
      }
    }

    return tree;
  }

  void _onProjectChanged(int newProjectId) {
    setState(() {
      selectedProjectId = newProjectId;
      isLoading = true;
    });
    fetchTreeModules(newProjectId);
    fetchProjectMembers(newProjectId);
  }

  void _onModuleSelected(Map<String, dynamic> module) {
    setState(() {
      selectedModule = module;
      currentPageIndex = 1; // Chuyển sang trang chi tiết module
    });
  }

  String get dynamicTitle {
    switch (currentPageIndex) {
      case 1:
        return selectedModule != null 
          ? 'Chi tiết Module: ${selectedModule!['name'] ?? 'Không rõ tên'}'
          : 'Chi tiết Module';
      default:
        return widget.title;
    }
  }

  void _onRefreshModules() {
    if (selectedProjectId != null) {
      fetchTreeModules(selectedProjectId!);
    }
  }

  Widget _buildContentHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isSidebarVisible ? Icons.menu_open : Icons.menu),
            onPressed: () {
              setState(() {
                _isSidebarVisible = !_isSidebarVisible;
              });
            },
            tooltip: _isSidebarVisible ? 'Ẩn sidebar' : 'Hiện sidebar',
          ),
          SizedBox(width: 12),
          
          // Hiển thị nút back khi đang ở trang chi tiết module
          if (currentPageIndex == 1)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Quay lại danh sách',
              onPressed: () {
                setState(() {
                  currentPageIndex = 0;
                  selectedModule = null;
                });
              },
            ),
          
          Expanded(
            child: Text(
              dynamicTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Thêm nút reload ở đây
          IconButton(
            onPressed: _onRefreshModules,
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới dữ liệu',
          ),
          
          if (widget.appBarActions != null) ...widget.appBarActions!,
          
          if (Navigator.of(context).canPop())
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Quay lại',
              onPressed: () {
                Navigator.pop(context);
              },
            )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      drawer: _isSidebarVisible ? null : Sidebar(
        projects: projects,
        selectedProjectId: selectedProjectId,
        projectMembers: projectMembers,
        treeModulesData: treeModulesData,
        onProjectChanged: _onProjectChanged,
        onModuleSelected: _onModuleSelected,
        onRefresh: _onRefreshModules,
      ),
      body: Row(
        children: [
          if (_isSidebarVisible)
            Sidebar(
              projects: projects,
              selectedProjectId: selectedProjectId,
              projectMembers: projectMembers,
              treeModulesData: treeModulesData,
              onProjectChanged: _onProjectChanged,
              onModuleSelected: _onModuleSelected,
              onRefresh: _onRefreshModules,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContentHeader(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    height: 48,
                    child: GlobalSearchBar(),
                  ),
                ),

                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : IndexedStack(
                          index: currentPageIndex,
                          children: [
                            widget.child,
                            selectedModule != null
                                ? ModuleDetailPage.withId(
                                    key: ValueKey(selectedModule?['id']),
                                    moduleId: selectedModule?['id'],
                                  )
                                : const SizedBox(),
                          ],
                        ),
                )
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }
}