import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:team_manage_frontend/api_service.dart';
import 'package:team_manage_frontend/screens/modules/module_tree_widget.dart';
import 'package:team_manage_frontend/screens/searchBar.dart';

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

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List<dynamic> projectList =
            decoded is Map && decoded.containsKey(r'$values')
                ? decoded[r'$values']
                : (decoded is List ? decoded : []);

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
          behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
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
      final members = decoded['members']?[r'$values'] ?? [];
      setState(() {
        projectMembers = List<Map<String, dynamic>>.from(members);
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
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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


  Future<String?> getCurrentUserName() async {
    final profile = await ApiService.getProfile();
    return profile != null ? profile['fullName'] as String? : null;
  }

  Widget _buildDrawerContent(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width / 4, 
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.dashboard, color: Colors.white, size: 36),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SThink",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Team Management",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                FutureBuilder<String?>(
                  future: getCurrentUserName(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text(
                        'Đang tải tên...',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      );
                    }
                    final name = snapshot.data ?? 'Không rõ tên';
                    return Row(
                      children: [
                        const Icon(
                          Icons.person,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () => ApiService.logout(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text(
                            'Đăng xuất',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
                            
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Trang chủ'),
              onTap: () => Navigator.pushNamed(context, '/home'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Hồ sơ cá nhân'),
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            ListTile(
              leading: const Icon(Icons.supervisor_account),
              title: const Text('Quản lý người dùng'),
              onTap: () => Navigator.pushNamed(context, '/user'),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Chọn Dự án",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: selectedProjectId,
                            isExpanded: true,
                            items: projects.map((p) {
                              return DropdownMenuItem<int>(
                                value: p['id'],
                                child: Text(p['name']),
                              );
                            }).toList(),
                            onChanged: (int? newProjectId) {
                              if (newProjectId == null) return;
                              setState(() {
                                selectedProjectId = newProjectId;
                                isLoading = true;
                              });
                              fetchTreeModules(newProjectId);
                              fetchProjectMembers(newProjectId);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: InkWell(
                            onTap: () => Navigator.pushReplacementNamed(context, '/project/create'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                border: Border.all(color: Colors.green.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add, color: Colors.green),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Danh sách module",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  // Thêm legend cho trạng thái
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        "Xong",
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(width: 8),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        "Đang làm",
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(width: 8),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        "Chưa làm",
                        style: TextStyle(fontSize: 12),
                      )
                    ],
                  ),
                ],
              ),
            ),

            if (selectedProjectId != null && treeModulesData != null)
              ModuleDropdownWidget(modules: treeModulesData!, projectMembers: projectMembers),
          ],
        ),
      ),
    );
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
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          if (widget.appBarActions != null) ...widget.appBarActions!,

          if(ModalRoute.of(context)?.settings.name != '/home')
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Quay lại',
              onPressed: (){
                Navigator.pop(context);
              }
            )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      drawer: _isSidebarVisible ? null : _buildDrawerContent(context),
      body: Row(
        children: [
          if (_isSidebarVisible) _buildDrawerContent(context),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContentHeader(),

                // 🧠 Thêm thanh tìm kiếm ngay dưới header
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
                      : widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
