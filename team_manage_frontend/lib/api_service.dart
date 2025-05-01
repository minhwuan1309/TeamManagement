import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/env.dart';

// URL API backend
final String baseUrl =
    kIsWeb
        ? 'http://localhost:5053/api'
        : (Platform.isAndroid
            ? 'http://192.168.1.8:5053/api' // g22
            : 'http://10.0.2.2:5053/api'); // emulator

class ApiService {
  static Future<String?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final role = data['role'];

        // Lưu token vào local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setInt('role', role);

        return token;
      } else {
        print('Login thất bại: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Lỗi login: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return null;

    final url = Uri.parse('${getBaseUrl()}/auth/me');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Lỗi lấy profile: ${response.body}');
      return null;
    }
  }

  static Future<bool> register(
    String fullName,
    String phone,
    String email,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      print('Lỗi đăng ký: ${response.body}');
    }

    return response.statusCode == 200;
  }

  static Future<bool> verifyEmail(String email, String code) async {
    final url = Uri.parse('$baseUrl/auth/verify-email');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    return response.statusCode == 200;
  }

  // Thêm phương thức này vào file api_service.dart
  static Future<bool> updateUserRole(String userId, int newRole) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.put(
        Uri.parse('$baseUrl/user/update-role/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'role': newRole}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating user role: $e');
      return false;
    }
  }
}
