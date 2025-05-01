import 'package:flutter/material.dart';
import '../api_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final codeController = TextEditingController();
  String errorMessage = '';
  bool isLoading = false;
  late String email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    email = ModalRoute.of(context)!.settings.arguments as String;
  }

  Future<void> handleVerify() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final success = await ApiService.verifyEmail(email, codeController.text.trim());

    setState(() {
      isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xác minh thành công')));
      Navigator.pushReplacementNamed(context, '/');
    } else {
      setState(() {
        errorMessage = 'Mã xác thực không đúng hoặc đã hết hạn.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác minh Email')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Mã xác minh đã được gửi đến: $email'),
            TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Nhập mã 6 số')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : handleVerify,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Xác minh'),
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
