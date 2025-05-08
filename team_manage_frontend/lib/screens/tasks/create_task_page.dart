import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/api_service.dart';
import 'package:team_manage_frontend/layouts/common_layout.dart';


class CreateTaskPage extends StatefulWidget {
  final int moduleId;
  const CreateTaskPage({super.key, required this.moduleId});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String? _assignedUserId;
  List<dynamic> _members = [];
  bool _isSubmitting = false;


  @override
  void initState() {
    super.initState();
    fetchModuleMembers();
  }

  Future<void> fetchModuleMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/module/members/${widget.moduleId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        setState(() {
          _members = decoded is Map && decoded.containsKey(r'$values')
              ? decoded[r'$values']
              : (decoded is List ? decoded : []);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thành viên: ${res.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e')),
      );
    }
  }

  Future<void> submitTask() async {
    if (!_formKey.currentState!.validate() ||
        _startDate == null ||
        _endDate == null) return;

    setState(() => _isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final body = {
      'title': _titleController.text.trim(),
      'note': _noteController.text.trim(),
      'assignedUserId': _assignedUserId,
      'startDate': _startDate!.toIso8601String(),
      'endDate': _endDate!.toIso8601String(),
    };

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/task/create/${widget.moduleId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo task thành công'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tạo task thất bại: ${res.statusCode}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e'),backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> pickDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      title: 'Tạo Task mới',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Bắt buộc nhập tiêu đề' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Người thực hiện',
                  border: OutlineInputBorder(),
                ),
                value: _assignedUserId,
                items: _members.map<DropdownMenuItem<String>>((member) {
                  return DropdownMenuItem<String>(
                    value: member['userId'],
                    child: Text(member['fullName'] ?? '---'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _assignedUserId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => pickDate(context, true),
                      child: Text(_startDate == null
                          ? 'Chọn ngày bắt đầu'
                          : 'Bắt đầu: ${_startDate!.toLocal().toString().split(' ')[0]}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => pickDate(context, false),
                      child: Text(_endDate == null
                          ? 'Chọn ngày kết thúc'
                          : 'Kết thúc: ${_endDate!.toLocal().toString().split(' ')[0]}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(_isSubmitting ? 'Đang gửi...' : 'Tạo task'),
                onPressed: _isSubmitting ? null : submitTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
