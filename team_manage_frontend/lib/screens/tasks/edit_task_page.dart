import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/api_service.dart';
import 'package:team_manage_frontend/layouts/common_layout.dart';

class EditTaskPage extends StatefulWidget {
  final int taskId;
  final int moduleId;

  const EditTaskPage({super.key, required this.taskId, required this.moduleId});

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String? _assignedUserId;
  List<dynamic> _members = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchTaskData();
  }

  Future<void> fetchTaskData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final headers = {'Authorization': 'Bearer $token'};

    try {
      final taskRes = await http.get(
        Uri.parse('$baseUrl/task/${widget.taskId}'),
        headers: headers,
      );

      final memberRes = await http.get(
        Uri.parse('$baseUrl/module/members/${widget.moduleId}'),
        headers: headers,
      );

      if (taskRes.statusCode == 200 && memberRes.statusCode == 200) {
        final taskData = jsonDecode(taskRes.body);
        final memberData = jsonDecode(memberRes.body);
        final List memberList = memberData[r'$values'] ?? [];

        setState(() {
          _titleController.text = taskData['title'] ?? '';
          _noteController.text = taskData['note'] ?? '';
          _startDate = DateTime.tryParse(taskData['startDate'] ?? '');
          _endDate = DateTime.tryParse(taskData['endDate'] ?? '');
          _assignedUserId = taskData['assignedUserId'];
          _members = memberList;
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: ${taskRes.statusCode}/${memberRes.statusCode}')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> updateTask() async {
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
      final res = await http.put(
        Uri.parse('$baseUrl/task/update/${widget.taskId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật task'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật thất bại: ${res.statusCode}'), backgroundColor: Colors.red,),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red,),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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
      title: 'Chỉnh sửa Task',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Bắt buộc nhập tiêu đề' : null,
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
                      label: Text(_isSubmitting ? 'Đang cập nhật...' : 'Lưu thay đổi'),
                      onPressed: _isSubmitting ? null : updateTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
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
