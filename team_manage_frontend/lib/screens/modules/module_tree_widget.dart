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

  @override
  Widget build(BuildContext context) {
    final List<dynamic> rawModules = widget.modules[r'$values'] ?? [];

    List<Map<String, dynamic>> modules = rawModules
        .map((m) => _normalizeModule(Map<String, dynamic>.from(m)))
        .toList();

    modules.sort((a, b) => a['code'].compareTo(b['code']));

    return Column(
      children: modules.map((m) => _buildModuleItem(m, 0)).toList(),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(width: depth * 16.0),
            SizedBox(
              width: 16,
              child: hasChildren
                ? InkWell(
                    onTap: () {
                      setState(() {
                        _expanded[module['id']] = !isExpanded;
                      });
                    },
                    child: Text(
                      isExpanded ? '▾' : '▸',
                      style: const TextStyle(fontSize: 16),
                    ),
                  )
                : const SizedBox(),
            ),
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
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
                child: Row(
                  children: [
                    Text(
                      '(${module['code']}) ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(
                        module['name'] ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 18, color: Colors.green),
              tooltip: 'Thêm module con',
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
          ],
        ),
        if (hasChildren && isExpanded)
          ...List<Widget>.from(
            module['children'].map<Widget>(
              (child) => _buildModuleItem(child, depth + 1),
            ),
          )
      ],
    );
  }
}