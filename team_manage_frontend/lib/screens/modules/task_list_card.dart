import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/api_service.dart';

import 'package:team_manage_frontend/screens/tasks/create_task_page.dart';
import 'package:team_manage_frontend/screens/tasks/task_detail_page.dart';
import 'package:team_manage_frontend/utils/env.dart';

class TaskListCard extends StatefulWidget {
  final List<dynamic> tasks;
  final Map<String, dynamic>? currentModule;
  final Function _refreshModuleData;
  final String Function(String?) formatDate;
  final Color Function(dynamic status) getStatusColor;
  final String Function(dynamic status) getStatusText;
  final int currentUserRole;

  const TaskListCard({
    super.key,
    required this.tasks,
    required this.currentModule,
    required Function refreshModuleData,
    required this.formatDate,
    required this.getStatusColor,
    required this.getStatusText,
    required this.currentUserRole,
  }) : _refreshModuleData = refreshModuleData;

  @override
  State<TaskListCard> createState() => _TaskListCardState();
}

class _TaskListCardState extends State<TaskListCard> {
  final Set<int> expandedTaskIds = {};
  final Map<int, List<Map<String, dynamic>>> taskComments = {};
  final Map<int, bool> loadingComments = {};
  final Map<int, TextEditingController> commentControllers = {};
  final Map<int, bool> submittingComments = {};
  late final int currentUserRole = widget.currentUserRole;

  @override
  void dispose() {
    for (var controller in commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  Future<void> _submitComment(int taskId) async {
    final controller = commentControllers[taskId];
    if (controller == null || controller.text.trim().isEmpty) return;

    setState(() {
      submittingComments[taskId] = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$baseUrl/task/comment/$taskId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': controller.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final newComment = responseData['comment'];
        
        setState(() {
          if (taskComments[taskId] != null) {
            taskComments[taskId]!.insert(0, newComment);
          } else {
            taskComments[taskId] = [newComment];
          }
          controller.clear();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã lưu bình luận'),
            backgroundColor: Colors.green[600],
            
          ),
        );
      } else {
        _showErrorSnackBar('Không thể thêm bình luận');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi kết nối mạng');
    } finally {
      setState(() {
        submittingComments[taskId] = false;
      });
    }
  }

  Future<void> _loadComments(int taskId) async {
    if (loadingComments[taskId] == true) return;
    
    setState(() {
      loadingComments[taskId] = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/task/comment/$taskId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final rawData = jsonDecode(response.body);
        final List<dynamic> values = rawData[r'$values'] ?? [];

        setState(() {
          taskComments[taskId] = values
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      } else {
        _showErrorSnackBar('Không thể tải bình luận');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi kết nối mạng');
    } finally {
      setState(() {
        loadingComments[taskId] = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            widget.tasks.isEmpty
                ? _buildEmptyState(context)
                : _buildTaskList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.task_alt, color: Colors.blue, size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Danh sách công việc',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        if (widget.tasks.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widget.tasks.length}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTaskList(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.tasks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = widget.tasks[index];
        final int taskId = task['id'];
        final String title = task['title'] ?? 'Không có tiêu đề';
        final dynamic status = task['status'];
        final String startDate = widget.formatDate(task['startDate']);
        final String endDate = widget.formatDate(task['endDate']);
        final String assignedUserName = task['assignedUserName'] ?? 'Chưa gán';
        final String? currentStepName = task['currentStepName'];

        return _buildTaskCard(context, taskId, title, status, startDate, 
                            endDate, assignedUserName, currentStepName);
      },
    );
  }

  Widget _buildTaskCard(BuildContext context, int taskId, String title, 
                       dynamic status, String startDate, String endDate, 
                       String assignedUserName, String? currentStepName) {
    final bool isExpanded = expandedTaskIds.contains(taskId);
    final bool hasComments = taskComments[taskId]?.isNotEmpty ?? false;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded ? Colors.blue[200]! : Colors.grey[200]!,
          width: isExpanded ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onTap: () {
              final statusStr = status.toString().toLowerCase();
              final normalizedStatus = statusStr == 'done' ? 2 : statusStr == 'inprogress' ? 1 : 0;

              if (normalizedStatus == 2 && currentUserRole != 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chỉ admin mới được xem task đã hoàn thành.'),
                    backgroundColor: Colors.red,
                    
                  ),
                );
                return;
              }
              _navigateToTaskDetail(taskId);
            },
            
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTaskHeader(title, status),
                    if (currentStepName != null && currentStepName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildCurrentStep(currentStepName),
                    ],
                    const SizedBox(height: 12),
                    _buildTaskMetadata(status, startDate, endDate, assignedUserName),
                  ],
                ),
              ),
            ),
          ),
          _buildCommentSection(taskId, isExpanded),
          if (isExpanded) _buildCommentList(taskId),
          if (isExpanded) _buildCommentInput(taskId),
        ],
      ),
    );
  }

  Widget _buildTaskHeader(String title, dynamic status) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: widget.getStatusColor(status).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getStatusIcon(status),
            color: widget.getStatusColor(status),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
      ],
    );
  }

  IconData _getStatusIcon(dynamic status) {
    switch (status) {
      case 2:
        return Icons.check_circle;
      case 1:
        return Icons.schedule;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  Widget _buildCurrentStep(String currentStepName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.alt_route, size: 16, color: Colors.purple[600]),
          const SizedBox(width: 6),
          Text(
            'Bước hiện tại: $currentStepName',
            style: TextStyle(
              fontSize: 13,
              color: Colors.purple[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskMetadata(dynamic status, String startDate, 
                           String endDate, String assignedUserName) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildMetadataBadge(
          widget.getStatusText(status),
          widget.getStatusColor(status).withOpacity(0.1),
          widget.getStatusColor(status),
          icon: _getStatusIcon(status),
        ),
        _buildMetadataBadge(
          '$startDate - $endDate',
          Colors.orange[50],
          Colors.orange[700],
          icon: Icons.schedule,
        ),
        _buildMetadataBadge(
          assignedUserName,
          Colors.green[50],
          Colors.green[700],
          icon: Icons.person,
        ),
      ],
    );
  }

  Widget _buildMetadataBadge(String text, Color? bgColor, Color? textColor,
      {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentSection(int taskId, bool isExpanded) {
    final commentCount = taskComments[taskId]?.length ?? 0;
    final isLoading = loadingComments[taskId] ?? false;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Material(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        child: InkWell(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
          onTap: () => _toggleComments(taskId),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.comment_outlined,
                  size: 18,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  commentCount > 0 
                      ? 'Bình luận ($commentCount)'
                      : 'Bình luận',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.grey[400]),
                    ),
                  )
                else
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentList(int taskId) {
    final comments = taskComments[taskId] ?? [];
    
    if (comments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.grey[400], size: 20),
            const SizedBox(width: 8),
            Text(
              'Chưa có bình luận nào',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[25],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Column(
        children: comments.map((comment) => _buildCommentItem(comment)).toList(),
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue[100],
            child: Text(
              (comment['userName'] ?? '?')[0].toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment['userName'] ?? 'Ẩn danh',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.formatDate(comment['createdAt']),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment['content'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleComments(int taskId) async {
    setState(() {
      if (expandedTaskIds.contains(taskId)) {
        expandedTaskIds.remove(taskId);
      } else {
        expandedTaskIds.add(taskId);
        // Initialize controller if not exists
        if (!commentControllers.containsKey(taskId)) {
          commentControllers[taskId] = TextEditingController();
        }
      }
    });

    if (expandedTaskIds.contains(taskId) && !taskComments.containsKey(taskId)) {
      await _loadComments(taskId);
    }
  }

  Widget _buildCommentInput(int taskId) {
    final controller = commentControllers[taskId];
    final isSubmitting = submittingComments[taskId] ?? false;
    
    if (controller == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue[100],
                child: Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Thêm bình luận',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: controller,
              maxLines: 3,
              minLines: 1,
              enabled: !isSubmitting,
              decoration: InputDecoration(
                hintText: 'Nhập bình luận của bạn...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: isSubmitting ? null : () {
                  controller.clear();
                },
                child: Text(
                  'Hủy',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isSubmitting ? null : () => _submitComment(taskId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 1,
                ),
                child: isSubmitting
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Đang gửi...',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      )
                    : const Text(
                        'Gửi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToTaskDetail(int taskId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailPage(taskId: taskId)),
    ).then((result) {
      if (result == true) widget._refreshModuleData();
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Chưa có công việc nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tạo công việc đầu tiên để bắt đầu quản lý dự án',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'Tạo công việc mới',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateTaskPage(
                    moduleId: widget.currentModule!['id'],
                  ),
                ),
              ).then((shouldReload) {
                if (shouldReload == true) widget._refreshModuleData();
              });
            },
          ),
        ],
      ),
    );
  }
}