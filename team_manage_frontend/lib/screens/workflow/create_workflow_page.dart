import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_manage_frontend/api_service.dart';
import 'package:team_manage_frontend/layouts/common_layout.dart';


class CreateWorkflowPage extends StatefulWidget {
  final int moduleId;
  const CreateWorkflowPage({required this.moduleId, super.key});

  @override
  State<CreateWorkflowPage> createState() => _CreateWorkflowPageState();
}

class _CreateWorkflowPageState extends State<CreateWorkflowPage> {
  final TextEditingController nameController = TextEditingController();
  List<StepFormData> steps = [StepFormData()];
  List<dynamic> users = [];
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      setState(() {
        users = jsonDecode(res.body);
      });
    }
  }

  void addStep() {
    setState(() {
      steps.add(StepFormData());
    });
  }

  void removeStep(int index) {
    setState(() {
      steps.removeAt(index);
    });
  }

  Future<void> submitWorkflow() async {
    if (nameController.text.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final stepData = steps.asMap().entries.map((entry) {
      final index = entry.key;
      final step = entry.value;
      return {
        "stepName": step.stepName,
        "order": index + 1,
        "approvers": [
          {"approverId": step.approverId}
        ]
      };
    }).toList();

    final body = jsonEncode({
      "name": nameController.text,
      "moduleId": widget.moduleId,
      "steps": stepData
    });

    setState(() => isSubmitting = true);

    final res = await http.post(
      Uri.parse('$baseUrl/workflow/create'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    setState(() => isSubmitting = false);

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo workflow thành công')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${res.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      title: "Tạo Workflow mới",
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Tên Workflow",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              itemCount: steps.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (_, index) {
                return StepInputCard(
                  step: steps[index],
                  users: users,
                  index: index,
                  onRemove: () => removeStep(index),
                );
              },
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: addStep,
              icon: const Icon(Icons.add),
              label: const Text("Thêm bước"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isSubmitting ? null : submitWorkflow,
              child: isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text("Tạo Workflow"),
            ),
          ],
        ),
      ),
    );
  }
}

class StepFormData {
  String stepName = '';
  String? approverId;
}

class StepInputCard extends StatelessWidget {
  final StepFormData step;
  final List users;
  final int index;
  final VoidCallback onRemove;

  const StepInputCard({
    required this.step,
    required this.users,
    required this.index,
    required this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: "Tên bước",
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => step.stepName = val,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: "Người duyệt",
                border: OutlineInputBorder(),
              ),
              value: step.approverId,
              items: users.map((u) {
                return DropdownMenuItem<String>(
                  value: u['id'],
                  child: Text(u['fullName'] ?? u['email']),
                );
              }).toList(),
              onChanged: (val) => step.approverId = val,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text('Xoá bước', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
