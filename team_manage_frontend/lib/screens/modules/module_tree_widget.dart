import 'package:flutter/material.dart';

class ModuleDropdownWidget extends StatefulWidget {
  final Map<String, dynamic> modules;
  final List<Map<String, dynamic>>? projectMembers;

  const ModuleDropdownWidget({super.key, required this.modules, this.projectMembers});

  @override
  State<ModuleDropdownWidget> createState() => _ModuleDropdownWidgetState();
}

class _ModuleDropdownWidgetState extends State<ModuleDropdownWidget> {
  final Map<int, bool> _expanded = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> rawModules = widget.modules[r'$values'] ?? [];

    List<Map<String, dynamic>> modules = rawModules
        .map((m) => _normalizeModule(Map<String, dynamic>.from(m)))
        .toList();

    modules.sort((a, b) => a['code'].compareTo(b['code']));

    // Filter modules based on search query
    final filteredModules = _searchQuery.isEmpty
        ? modules
        : _filterModules(modules, _searchQuery);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSearchBar(),
        const SizedBox(height: 8),
        ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: filteredModules.map((m) => _buildModuleItem(m, 0)).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm module',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }


  /// Hàm normalize một module (cha + đệ quy children)
  Map<String, dynamic> _normalizeModule(Map<String, dynamic> raw) {
    final projectId = raw['projectId'] ?? 0;

    return {
      'id': raw['id'],
      'name': raw['name'],
      'code': raw['code'],
      'status': raw['status'],
      'projectId': projectId,
      'parentModuleId': raw['parentModuleId'],
      'children': normalizeList(raw['children'], projectId),
    };
  }

  /// Đảm bảo children kế thừa projectId từ module cha
  List<Map<String, dynamic>> normalizeList(dynamic rawList, int parentProjectId) {
    if (rawList is Map && rawList.containsKey(r'$values')) {
      return List<Map<String, dynamic>>.from(
        rawList[r'$values'].map((child) {
          final normalized = _normalizeModule(Map<String, dynamic>.from(child));
          normalized['projectId'] = parentProjectId; // gán lại projectId
          return normalized;
        }),
      );
    }
    return [];
  }

  // Filter modules recursively
  List<Map<String, dynamic>> _filterModules(List<Map<String, dynamic>> modules, String query) {
    List<Map<String, dynamic>> results = [];
    
    for (var module in modules) {
      final bool matchesQuery = 
          module['code'].toString().toLowerCase().contains(query) ||
          (module['name'] ?? '').toString().toLowerCase().contains(query);
      
      final List<Map<String, dynamic>> matchingChildren = 
          _filterModules(List<Map<String, dynamic>>.from(module['children']), query);
      
      if (matchesQuery || matchingChildren.isNotEmpty) {
        final Map<String, dynamic> filteredModule = {...module};
        
        if (matchingChildren.isNotEmpty) {
          filteredModule['children'] = matchingChildren;
          // Auto-expand parent if children match the search
          _expanded[module['id']] = true;
        }
        
        results.add(filteredModule);
      }
    }
    
    return results;
  }

  Widget _buildModuleItem(Map<String, dynamic> module, int depth) {
    final hasChildren = module['children'].isNotEmpty;
    final isExpanded = _expanded[module['id']] ?? false;
    final String status = module['status'] ?? 'none';

    Color statusColor;
    switch (status) {
      case 'done':
        statusColor = Colors.green;
        break;
      case 'inProgress':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.only(
        left: depth * 16.0,
        right: 0,
        bottom: 4,
      ),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (hasChildren)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _expanded[module['id']] = !isExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      child: Icon(
                        isExpanded ? Icons.expand_more : Icons.chevron_right,
                        size: 20,
                        color: Colors.grey[700],
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 28),
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/module-detail',
                        arguments: module['id'],
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Text(
                            '(${module['code']}) ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              module['name'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Thêm module con',
                  child: IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/module/create',
                        arguments: {
                          'parentModuleId': module['id'],
                          'projectId': module['projectId'],
                          'projectMembers': widget.projectMembers,
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (hasChildren && isExpanded)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Column(
                children: module['children'].map<Widget>(
                  (child) => _buildModuleItem(child, depth + 1),
                ).toList(),
              ),
            ),
        ],
      ),
    );
  }
}