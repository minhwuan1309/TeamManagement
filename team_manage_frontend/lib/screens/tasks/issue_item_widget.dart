import 'dart:io' as io;
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_saver/file_saver.dart';
import 'package:team_manage_frontend/api_service.dart';

class IssueItemWidget extends StatefulWidget {
  final Map<String, dynamic> issue;
  final VoidCallback onStatusChanged;

  const IssueItemWidget({
    super.key,
    required this.issue,
    required this.onStatusChanged,
  });

  @override
  State<IssueItemWidget> createState() => _IssueItemWidgetState();
}

class _IssueItemWidgetState extends State<IssueItemWidget> {
  bool isExpanded = false;

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

  Future<void> downloadFile(BuildContext context, String url, String filename) async {
    try {
      if (kIsWeb) {
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", filename)
          ..click();
      } else {
        final response = await Dio().get(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        final bytes = response.data is List<int>
            ? Uint8List.fromList(response.data)
            : response.data as Uint8List;

        final res = await FileSaver.instance.saveFile(
          name: filename,
          bytes: bytes,
          ext: filename.split('.').last, 
          mimeType: MimeType.other,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã lưu vào: $res')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi tải: $e')));
    }
  }

  Future<void> updateIssueStatus(int issueId, String statusString) async {
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
        Uri.parse('$baseUrl/issue/update-status/$issueId?status=$statusValue'),
        headers: headers,
      );

      if (res.statusCode == 200) {
        widget.onStatusChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật trạng thái thành công')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật trạng thái: ${res.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật trạng thái: $e')),
      );
    }
  }

  void _showStatusUpdateDialog(int issueId, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Cập nhật trạng thái'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusOptions(
                  issueId,
                  currentStatus,
                  'none',
                  'Chưa bắt đầu',
                ),
                _buildStatusOptions(
                  issueId,
                  currentStatus,
                  'inprogress',
                  'Đang thực hiện',
                ),
                _buildStatusOptions(
                  issueId,
                  currentStatus,
                  'done',
                  'Hoàn thành',
                ),
              ],
            ),
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

  Widget _buildStatusOptions(
    int issueId,
    String currentStatus,
    String status,
    String label,
  ) {
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
          updateIssueStatus(issueId, status);
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? statusColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? statusColor : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic>? extractFiles(dynamic issue) {
    if (issue['files'] == null) {
      return null;
    }
    if (issue['files'][r'$values'] != null) {
      return issue['files'][r'$values'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;
    final id = issue['id'];
    final statusValue = issue['status'] ?? 'none';
    final statusColor = statusValue == 'done'
        ? Colors.green
        : statusValue == 'inProgress'
            ? Colors.orange
            : Colors.grey;
    final issueFiles = extractFiles(issue);
    final hasFiles = issueFiles != null && issueFiles.isNotEmpty;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isExpanded ? Colors.blue.shade300 : Colors.transparent,
          width: isExpanded ? 1 : 0,
        ),
      ),
      child: Column(
        children: [
          // Issue header
          InkWell(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: isExpanded ? Colors.blue.shade50 : Colors.white,
                border: Border(
                  left: BorderSide(
                    color: statusColor,
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue['title'] ?? 'Không tiêu đề',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            InkWell(
                              onTap: () => _showStatusUpdateDialog(
                                id,
                                statusValue,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      statusValue == 'done'
                                          ? Icons.check_circle
                                          : statusValue == 'inProgress'
                                              ? Icons.timelapse
                                              : Icons.circle_outlined,
                                      size: 14,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusText(statusValue),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (hasFiles) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.attach_file,
                                      size: 14,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${issueFiles.length} tệp',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isExpanded ? Colors.blue.shade100 : Colors.grey.shade100,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: isExpanded ? Colors.blue : Colors.grey.shade700,
                      ),
                      onPressed: () {
                        setState(() {
                          isExpanded = !isExpanded;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),// Issue content when expanded
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Issue details
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.person_outline, size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Người tạo:',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              issue['CreatedByName'] ?? issue['createdByName'] ?? 'Không xác định',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            
                          ],
                        ),
                      ),
                      Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ngày tạo:',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatDate(issue['createdAt']),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Issue description
                  if (issue['description']?.isNotEmpty ?? false) ...[
                    const Text(
                      'Mô tả:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        issue['description'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Files section
                  if (hasFiles) ...[
                    Row(
                      children: [
                        const Icon(Icons.attach_file, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Tệp đính kèm:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...issueFiles.map((fileItem) {
                      final fileName = fileItem['name'] ?? 'Không rõ tên';
                      final fileUrl = '$baseUrl${fileItem['url']}';
                      
                      // Determine icon based on file extension
                      IconData fileIcon;
                      final extension = fileName.split('.').last.toLowerCase();
                      
                      if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension)) {
                        fileIcon = Icons.image;
                      } else if (['pdf'].contains(extension)) {
                        fileIcon = Icons.picture_as_pdf;
                      } else if (['doc', 'docx'].contains(extension)) {
                        fileIcon = Icons.description;
                      } else if (['xls', 'xlsx'].contains(extension)) {
                        fileIcon = Icons.table_chart;
                      } else if (['zip', 'rar', '7z'].contains(extension)) {
                        fileIcon = Icons.folder_zip;
                      } else {
                        fileIcon = Icons.insert_drive_file;
                      }
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: InkWell(
                          onTap: () => downloadFile(
                            context,
                            fileUrl,
                            fileName,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    fileIcon,
                                    size: 18,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fileName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (fileItem['fileSize'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatFileSize(fileItem['fileSize']),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.download,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                  
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _uploadFile(issue['id']),
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Upload tệp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.blue.shade200),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  String _formatFileSize(int? bytes) {
    if (bytes == null) return 'Unknown size';
    
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = bytes.toDouble();
    
    while (size > 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }
  
  // Upload file function
  Future<void> _uploadFile(int issueId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );
    
    if (result == null || result.files.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    for (var file in result.files) {
      String fileName = file.name;
      
      try {
        // Prepare FormData
        final formData = FormData();
        
        if (kIsWeb) {
          // Web platform
          final bytes = file.bytes;
          if (bytes != null) {
            formData.files.add(MapEntry(
              'files',
              MultipartFile.fromBytes(
                bytes,
                filename: fileName,
              ),
            ));
          }
        } else {
          final filePath = file.path;
          if (filePath != null) {
            formData.files.add(MapEntry(
              'files',
              await MultipartFile.fromFile(
                filePath,
                filename: fileName,
              ),
            ));
          }
        }
        
        formData.fields.add(MapEntry('IssueId', issueId.toString()));
        
        final dio = Dio();
        final response = await dio.post(
          '$baseUrl/issue/add-file',
          data: formData,
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
        
        if (response.statusCode == 200) {
          widget.onStatusChanged();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã upload thành công: $fileName'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi upload file $fileName: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi upload file $fileName: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class CreateIssueDialog extends StatefulWidget {
  final int taskId;
  final VoidCallback onIssueCreated;

  const CreateIssueDialog({
    super.key,
    required this.taskId,
    required this.onIssueCreated,
  });

  @override
  State<CreateIssueDialog> createState() => _CreateIssueDialogState();
}

class _CreateIssueDialogState extends State<CreateIssueDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  final List<PlatformFile> _selectedFiles = [];

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(result.files);
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submitIssue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final dio = Dio();
      final formData = FormData();

      // Add text fields
      formData.fields.add(MapEntry('Title', _titleController.text));
      formData.fields.add(MapEntry('Description', _descriptionController.text));
      formData.fields.add(MapEntry('TaskId', widget.taskId.toString()));

      // Add files
      for (var i = 0; i < _selectedFiles.length; i++) {
        final file = _selectedFiles[i];
        
        if (kIsWeb) {
          if (file.bytes != null) {
            formData.files.add(MapEntry(
              'Files',
              MultipartFile.fromBytes(
                file.bytes!,
                filename: file.name,
              ),
            ));
          }
        } else {
          if (file.path != null) {
            formData.files.add(MapEntry(
              'Files',
              await MultipartFile.fromFile(
                file.path!,
                filename: file.name,
              ),
            ));
          }
        }
      }

      // Submit request
      final response = await dio.post(
        '$baseUrl/issue/task/create/${widget.taskId}',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        widget.onIssueCreated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo Issue thành công'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tạo Issue: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tạo Issue: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_task,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Tạo Issue mới',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Title field
                  const Text(
                    'Tiêu đề *',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tiêu đề issue',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tiêu đề';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Mô tả',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Nhập mô tả chi tiết (không bắt buộc)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 20),
                  
                  // File upload section
                  Row(
                    children: [
                      const Text(
                        'Tệp đính kèm',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _pickFiles,
                        icon: const Icon(Icons.attach_file, size: 18),
                        label: const Text('Chọn tệp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (_selectedFiles.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ..._selectedFiles.asMap().entries.map((entry) {
                            final index = entry.key;
                            final file = entry.value;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.insert_drive_file,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      file.name,
                                      style: const TextStyle(fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => _removeFile(index),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey,
                        ),
                        child: const Text('Huỷ'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitIssue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Tạo Issue'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}