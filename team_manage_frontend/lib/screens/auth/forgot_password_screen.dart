import 'package:flutter/material.dart';
import 'package:team_manage_frontend/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  String errorMessage = '';
  bool isLoading = false;

  Future<void> handleSendOtp() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final success = await ApiService.forgotPassword(emailController.text.trim());

    setState(() => isLoading = false);

    if (success) {
      Navigator.pushReplacementNamed(context, '/reset-password', arguments: emailController.text.trim());
    } else {
      setState(() {
        errorMessage = 'Không thể gửi mã xác thực. Hãy kiểm tra lại email.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quên mật khẩu")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text("Nhập email để nhận mã xác nhận đặt lại mật khẩu."),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : handleSendOtp,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Gửi mã xác thực'),
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
