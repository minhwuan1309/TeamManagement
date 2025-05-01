import 'package:flutter/material.dart';
import '../api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String errorMessage = '';
  bool isLoading = false;

  Future<void> handleRegister() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final success = await ApiService.register(
      fullNameController.text.trim(),
      phoneController.text.trim(),
      emailController.text.trim(),
      passwordController.text,
    );

    setState(() {
      isLoading = false;
    });

    if (success) {
      Navigator.pushReplacementNamed(context, '/verify-email',
          arguments: emailController.text.trim());
    } else {
      setState(() {
        errorMessage = 'Đăng ký thất bại. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký tài khoản')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(controller: fullNameController, decoration: const InputDecoration(labelText: 'Họ tên')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Số điện thoại')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Mật khẩu'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : handleRegister,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Đăng ký'),
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
