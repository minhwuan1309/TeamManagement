import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/api_service.dart';

class WorkflowWidget extends StatefulWidget {
  final int? moduleId;

  const WorkflowWidget({Key? key, required this.moduleId}) : super(key: key);

  @override
  State<WorkflowWidget> createState() => _WorkflowWidgetState();
}

class _WorkflowWidgetState extends State<WorkflowWidget> {
  bool _isLoading = true;
  Map<String, dynamic>? _workflowData;
  String? _errorMessage;
  String? _currentUserId;

  final List<Map<String, String>> _statusOptions = [
    {'value': 'inprogress', 'label': 'Đang tiến hành'},
    {'value': 'testing', 'label': 'Đang kiểm thử'},
    {'value': 'approving', 'label': 'Chờ duyệt'},
    {'value': 'approved', 'label': 'Hoàn thành'},
    {'value': 'rejected', 'label': 'Từ chối'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchWorkflowData();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/auth/me');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final user = jsonDecode(response.body);
      setState(() {
        _currentUserId = user['id'];
      });
    }
  }

  Future<void> _fetchWorkflowData() async {
    try {
      if (widget.moduleId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ModuleId không hợp lệ';
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Phiên đăng nhập hết hạn';
        });
        return;
      }

      final url = Uri.parse('$baseUrl/workflow/module/${widget.moduleId}');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _workflowData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Đã xảy ra lỗi: $e';
      });
    }
  }

  Future<void> _approveStep(int stepId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/workflow/update-step-status/$stepId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'newStatus': 'approved'}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Duyệt bước thành công!')));
        _fetchWorkflowData(); // reload lại bước
      } else {
        final msg = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${msg['message'] ?? response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
    }
  }

  Future<void> _updateStatus(int stepId, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/workflow/update-step-status/$stepId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'newStatus': newStatus}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật trạng thái thành công')),
        );
        _fetchWorkflowData();
      } else {
        final msg = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${msg['message'] ?? response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
    }
  }

  void _showStatusDialog(BuildContext context, int stepId) {
    String? selectedStatus = _statusOptions.first['value'];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Chọn trạng thái mới'),
            content: DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(labelText: 'Trạng thái'),
              items:
                  _statusOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option['value'],
                      child: Text(option['label']!),
                    );
                  }).toList(),
              onChanged: (value) {
                selectedStatus = value;
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  if (selectedStatus != null) {
                    await _updateStatus(stepId, selectedStatus!);
                  }
                },
                child: const Text('Cập nhật'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_workflowData == null) {
      return const Center(child: Text('Module này không có workflow'));
    }

    // Hiển thị workflow
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_workflowData!['name']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildWorkflowSteps(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflowSteps() {
    final stepsRaw = _workflowData?['steps'];
    final List<Map<String, dynamic>> steps =
        (stepsRaw is Map && stepsRaw.containsKey(r'$values'))
            ? List<Map<String, dynamic>>.from(stepsRaw[r'$values'])
            : [];

    if (steps.isEmpty) {
      return const Text('Module này không có workflow');
    }

    return Column(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _buildStepItem(steps[i], i, steps.length),
          if (i < steps.length - 1) _buildConnector(),
        ],
      ],
    );
  }

  Widget _buildStepItem(Map<String, dynamic> step, int index, int totalSteps) {
    final String status = step['status'] as String? ?? 'none';
    final Color statusColor = _getStatusColor(status);
    final rawApprovals = step['approvals'];
    final List<Map<String, dynamic>> approvals =
        (rawApprovals is Map && rawApprovals.containsKey(r'$values'))
            ? List<Map<String, dynamic>>.from(rawApprovals[r'$values'])
            : [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Bước ${index + 1}: ${step['stepName']}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Người phê duyệt:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                approvals.map((approval) {
                  return _buildApproverChip(approval);
                }).toList(),
          ),
          if (_currentUserId != null &&
              approvals.any((a) => a['approverId'] == _currentUserId) &&
              status != 'approved')
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: ElevatedButton.icon(
                onPressed: () => _showStatusDialog(context, step['id']),
                icon: const Icon(Icons.edit_calendar),
                label: const Text('Cập nhật trạng thái'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildApproverChip(Map<String, dynamic> approval) {
    final String fullName = approval['fullName'] as String? ?? 'Unknown';
    final String role = approval['role'] as String? ?? 'user';
    final String avatar = approval['avatar'] as String? ?? '';

    return Chip(
      avatar: CircleAvatar(
        backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
        child: avatar.isEmpty ? Text(fullName[0].toUpperCase()) : null,
      ),
      label: Text(fullName, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey[100],
    );
  }

  Widget _buildStatusBadge(String status) {
    String label;
    Color color;

    switch (status.toLowerCase()) {
      case 'none':
        label = 'Chưa bắt đầu';
        color = Colors.grey;
        break;
      case 'pending':
        label = 'Chờ xử lý';
        color = Colors.orange;
        break;
      case 'inprogress':
        label = 'Đang tiến hành';
        color = Colors.blue;
        break;
      case 'testing':
        label = 'Đang kiểm thử';
        color = Colors.indigo;
        break;
      case 'approving':
        label = 'Chờ duyệt';
        color = Colors.deepPurple;
        break;
      case 'approved':
        label = 'Đã duyệt';
        color = Colors.green;
        break;
      case 'done':
        label = 'Hoàn thành';
        color = Colors.green.shade700;
        break;
      case 'rejected':
        label = 'Đã từ chối';
        color = Colors.red;
        break;
      default:
        label = 'Không xác định';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildConnector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      height: 20,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return CustomPaint(
              size: Size(10, constraints.maxHeight),
              painter: _ArrowPainter(),
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return Colors.green;
      case 'inprogress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    final dashWidth = 4.0;
    final dashSpace = 3.0;
    final startX = size.width / 2;

    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }

    // Draw arrow head
    final path = Path();
    path.moveTo(startX - 5, size.height - 6);
    path.lineTo(startX, size.height);
    path.lineTo(startX + 5, size.height - 6);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
