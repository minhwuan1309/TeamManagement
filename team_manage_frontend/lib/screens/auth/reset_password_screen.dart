import 'package:flutter/material.dart';
import 'package:team_manage_frontend/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final codeController = TextEditingController();
  final newPassController = TextEditingController();
  String errorMessage = '';
  bool isLoading = false;
  late String email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    email = ModalRoute.of(context)!.settings.arguments as String;
  }

  Future<void> handleResetPassword() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final success = await ApiService.resetPassword(
      email,
      codeController.text.trim(),
      newPassController.text,
    );

    setState(() => isLoading = false);

    if (success) {
      Navigator.pushReplacementNamed(context, '/');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đặt lại mật khẩu thành công")),
      );
    } else {
      setState(() {
        errorMessage = 'Mã xác thực sai hoặc đã hết hạn.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đặt lại mật khẩu")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text("Nhập mã xác thực đã được gửi qua email và mật khẩu mới."),
            const SizedBox(height: 20),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Mã xác thực',
                prefixIcon: Icon(Icons.pin),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPassController,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : handleResetPassword,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Đặt lại mật khẩu'),
            ),
            if (errorMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(errorMessage, style: const TextStyle(color: Colors.red)),
            ]
          ],
        ),
      ),
    );
  }
}
