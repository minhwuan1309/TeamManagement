import 'package:flutter/material.dart';

class ModuleDropdownWidget extends StatefulWidget {
  final int projectId;
  final Map<String, dynamic> modules;
  final List<Map<String, dynamic>>? projectMembers;
  final Function(Map<String, dynamic> module)? onModuleSelected;
  final VoidCallback? onRefresh;

  const ModuleDropdownWidget({
    super.key,
    required this.projectId,
    required this.modules,
    this.projectMembers,
    this.onModuleSelected,
    this.onRefresh,
  });

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isMobile = screenWidth < 600;
    
    final List<dynamic> rawModules = widget.modules[r'$values'] ?? [];

    List<Map<String, dynamic>> modules = rawModules
        .map((m) => _normalizeModule(Map<String, dynamic>.from(m)))
        .toList();

    modules.sort((a, b) => a['code'].compareTo(b['code']));

    final filteredModules = _searchQuery.isEmpty
        ? modules
        : _filterModules(modules, _searchQuery);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSearchBar(constraints.maxWidth),
            SizedBox(height: isMobile ? 4 : 8),
            _buildActionButtons(constraints.maxWidth, isMobile),
            SizedBox(height: isMobile ? 4 : 8),
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: filteredModules.map((m) => _buildModuleItem(m, 0, constraints.maxWidth)).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons(double screenWidth, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
          ),
          SizedBox(width: isMobile ? 4 : 8),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/module/create',
                      arguments: {
                        'projectId': widget.projectId,
                        'projectMembers': widget.projectMembers ?? [],
                        'parentModuleId': null,
                      },
                    );
                    if (result == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tạo module thành công!'))
                      );
                      widget.onRefresh?.call();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 6 : 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.green, size: isMobile ? 16 : 20),
                        SizedBox(width: isMobile ? 2 : 4),
                        if (!isMobile || screenWidth > 360)
                          Text(
                            'Thêm Module',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: isMobile ? 10 : 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(double screenWidth) {
    final isMobile = screenWidth < 600;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
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
          hintStyle: TextStyle(fontSize: isMobile ? 14 : 16),
          prefixIcon: Icon(Icons.search, color: Colors.grey, size: isMobile ? 20 : 24),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey, size: isMobile ? 20 : 24),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 12),
        ),
        style: TextStyle(fontSize: isMobile ? 14 : 16),
      ),
    );
  }

  Map<String, dynamic> _normalizeModule(Map<String, dynamic> raw) {
    final projectId = raw['projectId'] ?? widget.projectId;

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

  List<Map<String, dynamic>> normalizeList(dynamic rawList, int parentProjectId) {
    if (rawList is Map && rawList.containsKey(r'$values')) {
      return List<Map<String, dynamic>>.from(
        rawList[r'$values'].map((child) {
          final normalized = _normalizeModule(Map<String, dynamic>.from(child));
          normalized['projectId'] = parentProjectId;
          return normalized;
        }),
      );
    }
    return [];
  }

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
          _expanded[module['id']] = true;
        }
        
        results.add(filteredModule);
      }
    }
    
    return results;
  }

  Widget _buildModuleItem(Map<String, dynamic> module, int depth, double screenWidth) {
    final hasChildren = module['children'].isNotEmpty;
    final isExpanded = _expanded[module['id']] ?? false;
    final String status = module['status'] ?? 'none';
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 360;

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

    final leftMargin = isMobile 
        ? (depth * 8.0 + 4) 
        : (depth * 16.0 + 8);

    return Card(
      margin: EdgeInsets.only(
        left: leftMargin,
        right: isMobile ? 4 : 8,
        bottom: isMobile ? 2 : 4,
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
                      width: isMobile ? 24 : 28,
                      height: isMobile ? 24 : 28,
                      alignment: Alignment.center,
                      child: Icon(
                        isExpanded ? Icons.expand_more : Icons.chevron_right,
                        size: isMobile ? 16 : 20,
                        color: Colors.grey[700],
                      ),
                    ),
                  )
                else
                  SizedBox(width: isMobile ? 24 : 28),
                Container(
                  width: isMobile ? 8 : 10,
                  height: isMobile ? 8 : 10,
                  margin: EdgeInsets.only(right: isMobile ? 4 : 8),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (widget.onModuleSelected != null) {
                        widget.onModuleSelected!(module);
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 12),
                      child: isSmallMobile 
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '(${module['code']})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  module['name'] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Text(
                                  '(${module['code']}) ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    module['name'] ?? '',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: isMobile ? 12 : 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Thêm module con',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/module/create',
                          arguments: {
                            'projectId': module['projectId'],
                            'parentModuleId': module['id'],
                            'projectMembers': widget.projectMembers,
                          },
                        );
                        if (result == true) {
                          widget.onRefresh?.call();
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(isMobile ? 6 : 8),
                        child: Icon(
                          Icons.add_circle_outline, 
                          color: Colors.green,
                          size: isMobile ? 16 : 20,
                        ),
                      ),
                    ),
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
                  (child) => _buildModuleItem(child, depth + 1, screenWidth),
                ).toList(),
              ),
            ),
        ],
      ),
    );
  }
}