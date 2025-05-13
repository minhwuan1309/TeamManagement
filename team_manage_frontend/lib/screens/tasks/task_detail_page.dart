import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/screens/tasks/edit_task_page.dart';
import 'package:team_manage_frontend/layouts/common_layout.dart';
import 'package:team_manage_frontend/api_service.dart';
import 'package:team_manage_frontend/screens/tasks/issue_item_widget.dart';

class TaskDetailPage extends StatefulWidget {
  final int taskId;

  const TaskDetailPage({super.key, required this.taskId});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  Map<String, dynamic>? task;
  List<dynamic> issues = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTask();
  }

  Future<void> fetchTask() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final headers = {'Authorization': 'Bearer $token'};

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/task/${widget.taskId}'),
        headers: headers,
      );
      final resIssue = await http.get(
        Uri.parse('$baseUrl/issue/task/${widget.taskId}'),
        headers: headers,
      );

      if (res.statusCode == 200 && resIssue.statusCode == 200) {
        setState(() {
          task = jsonDecode(res.body);
          final decodeIssue = jsonDecode(resIssue.body);
          issues = decodeIssue[r'$values'] ?? [];
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi tải dữ liệu task hoặc issue')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
    }
  }

  String formatDate(String? iso) {
    if (iso == null) return '--';
    final dt = DateTime.tryParse(iso);
    return dt != null ? '${dt.day}/${dt.month}/${dt.year}' : '--';
  }

  String statusText(String status) {
    switch (status) {
      case 'none':
        return 'Chưa bắt đầu';
      case 'inProgress':
        return 'Đang thực hiện';
      case 'done':
        return 'Hoàn thành';
      default:
        return 'Không xác định';
    }
  }

  Future<void> deleteTask() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final headers = {'Authorization': 'Bearer $token'};

    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/task/delete/${widget.taskId}'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xoá task'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // trở về trang trước
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xoá task: ${res.statusCode}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showCreateIssueDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return CreateIssueDialog(
          taskId: widget.taskId,
          onIssueCreated: () {
            fetchTask();
          },
        );
      },
    );
  }

  Future<void> updateTaskStatus(int taskId, String statusString) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final headers = {'Authorization': 'Bearer $token'};

  int statusValue;
  switch (statusString.toLowerCase()) {
    case 'none':
      statusValue = 0;
      break;
    case 'inprogress':
      statusValue = 1;
      break;
    case 'done':
      statusValue = 2;
      break;
    default:
      statusValue = 0;
  }

  try {
    final res = await http.put(
      Uri.parse('$baseUrl/task/update-status/$taskId?status=$statusValue'),
      headers: headers,
    );

    if (res.statusCode == 200) {
      await fetchTask(); // cập nhật lại UI
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật trạng thái thành công')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật trạng thái: ${res.statusCode}')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi kết nối: $e')),
    );
  }
}

void _showTaskStatusUpdateDialog(String currentStatus) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cập nhật trạng thái Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption('none', 'Chưa bắt đầu', currentStatus),
            _buildStatusOption('inProgress', 'Đang thực hiện', currentStatus),
            _buildStatusOption('done', 'Hoàn thành', currentStatus),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
        ],
      );
    },
  );
}

Widget _buildStatusOption(String status, String label, String currentStatus) {
  final bool isSelected = currentStatus == status;
  final Color statusColor = status == 'done'
      ? Colors.green
      : status == 'inProgress'
          ? Colors.orange
          : Colors.grey;

  return InkWell(
    onTap: () {
      Navigator.pop(context);
      if (currentStatus != status) {
        updateTaskStatus(task!['id'], status);
      }
    },
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected ? statusColor.withOpacity(0.2) : Colors.transparent,
        border: Border.all(
          color: isSelected ? statusColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: isSelected ? statusColor : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? statusColor : Colors.black87,
            ),
          ),
        ],
      ),
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return CommonLayout(
      title: 'Chi tiết Task',
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          tooltip: 'Chỉnh sửa Task',
          onPressed: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditTaskPage(
                  taskId: task!['id'],
                  moduleId: task!['moduleId'],
                ),
              ),
            );
            if (updated == true) fetchTask();
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          tooltip: 'Xoá Task',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text('Xác nhận xoá'),
                content: const Text('Bạn có chắc muốn xoá task này không?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Huỷ', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await deleteTask();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Xoá'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateIssueDialog,
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text('Thêm Issue'),
      ),
      child: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchTask,
              color: Colors.blue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task info card
                    Card(
                      elevation: 4,
                      shadowColor: Colors.blue.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.blue.shade100, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.assignment_outlined,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    task!['title'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (task!['note']?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Text(
                                  task!['note'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                            const Divider(height: 24, thickness: 1),
                            _buildTaskInfoRow(
                              icon: Icons.person_outline,
                              title: 'Người được giao:',
                              value: task!['assignedUserName'] ?? 'Chưa có',
                              iconColor: Colors.orange,
                            ),
                            const SizedBox(height: 12),
                            _buildTaskInfoRow(
                              icon: Icons.calendar_today_outlined,
                              title: 'Thời gian:',
                              value: '${formatDate(task!['startDate'])} → ${formatDate(task!['endDate'])}',
                              iconColor: Colors.green,
                            ),
                            const SizedBox(height: 12),
                            _buildTaskInfoWithStatus(
                              status: task!['status'] ?? '',
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Issues header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bug_report, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'Danh sách Issues',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Tổng số: ${issues.length}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Issues list
                    if (issues.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.note_alt_outlined,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có issue nào được tạo',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _showCreateIssueDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Tạo Issue mới'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...issues.map((issue) {
                        return IssueItemWidget(
                          issue: issue,
                          onStatusChanged: () async {
                            await fetchTask();
                          },
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper widget for task info row
  Widget _buildTaskInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // Helper widget for task status
  Widget _buildTaskInfoWithStatus({required String status}) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel = statusText(status);
    
    switch (status) {
      case 'done':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'inProgress':
        statusColor = Colors.orange;
        statusIcon = Icons.timelapse;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.circle_outlined;
    }
    
    return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.flag, size: 16, color: statusColor),
      ),
      const SizedBox(width: 12),
      const Text(
        'Trạng thái:',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: GestureDetector(
          onTap: () => _showTaskStatusUpdateDialog(status),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
  }
}