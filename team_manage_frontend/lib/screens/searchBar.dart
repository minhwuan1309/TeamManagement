import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:team_manage_frontend/api_service.dart';

class GlobalSearchBar extends StatelessWidget {
  const GlobalSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox( 
      height: 50,
      child: TypeAheadField<Map<String, dynamic>>(
        suggestionsCallback: (pattern) async {
          if (pattern.trim().isEmpty) return [];
          if (pattern.trim().length < 2) return []; // Chỉ tìm kiếm khi có ít nhất 2 ký tự
          return await _search(pattern.trim());
        },
        itemBuilder: (context, suggestion) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  _getIcon(suggestion['type']),
                  size: 20,
                  color: _getIconColor(suggestion['type']),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        suggestion['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (suggestion['description']?.isNotEmpty == true)
                        Text(
                          suggestion['description'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTypeColor(suggestion['type']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getTypeLabel(suggestion['type']),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        onSuggestionSelected: (suggestion) {
          _navigateToDetail(context, suggestion);
        },
        textFieldConfiguration: TextFieldConfiguration(
          decoration: InputDecoration(
            hintText: 'Tìm kiếm dự án, module, task...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        suggestionsBoxDecoration: SuggestionsBoxDecoration(
          constraints: const BoxConstraints(
            maxHeight: 300, // Giới hạn chiều cao tối đa
          ),
          borderRadius: BorderRadius.circular(12),
          elevation: 8,
          color: Colors.white,
          shadowColor: Colors.black26,
        ),
        noItemsFoundBuilder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.search_off, color: Colors.grey[400]),
              const SizedBox(width: 12),
              Text(
                'Không tìm thấy kết quả',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        loadingBuilder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Đang tìm kiếm...',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        errorBuilder: (context, error) => Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[400]),
              const SizedBox(width: 12),
              Text(
                'Lỗi khi tìm kiếm',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<List<Map<String, dynamic>>> _search(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/search?query=${Uri.encodeComponent(query)}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10)); // Thêm timeout

      if (response.statusCode == 200) {
        final Map<String, dynamic> raw = jsonDecode(response.body);
        final List<dynamic> values = raw[r'$values'] ?? [];

        // Giới hạn số lượng kết quả trả về
        final limitedValues = values.take(8).toList();

        return limitedValues.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id'],
            'title': item['title'] ?? '',
            'description': item['description'] ?? '',
            'type': item['type'] ?? '',
          };
        }).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Search failed with status: ${response.statusCode}');
      }
    } catch (e) {
      // Log error nhưng không throw để tránh crash app
      print('Search error: $e');
      return [];
    }
  }

  IconData _getIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'project':
        return Icons.folder;
      case 'module':
        return Icons.view_module;
      case 'task':
        return Icons.task;
      case 'issue':
        return Icons.bug_report;
      case 'workflow':
        return Icons.timeline;
      default:
        return Icons.search;
    }
  }

  Color _getIconColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'project':
        return Colors.blue;
      case 'module':
        return Colors.green;
      case 'task':
        return Colors.orange;
      case 'issue':
        return Colors.red;
      case 'workflow':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'project':
        return Colors.blue;
      case 'module':
        return Colors.green;
      case 'task':
        return Colors.orange;
      case 'issue':
        return Colors.red;
      case 'workflow':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String? type) {
    switch (type?.toLowerCase()) {
      case 'project':
        return 'Dự án';
      case 'module':
        return 'Module';
      case 'task':
        return 'Task';
      case 'issue':
        return 'Issue';
      case 'workflow':
        return 'Workflow';
      default:
        return 'Khác';
    }
  }

  void _navigateToDetail(BuildContext context, Map<String, dynamic> suggestion) {
    final type = suggestion['type']?.toString().toLowerCase();
    final id = suggestion['id'];
    
    if (type != null && id != null) {
      // Đóng bàn phím trước khi navigate
      FocusScope.of(context).unfocus();
      Navigator.pushNamed(context, '/$type/$id');
    }
  }
}