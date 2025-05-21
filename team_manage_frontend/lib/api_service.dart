import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/env.dart';

final String baseUrl = 
  kIsWeb
    ?'http://localhost:5053/api'
    : Platform.isAndroid
        ?'http://10.0.2.2:5053/api'
        :'http://192.168.1.8:5053/api';

class ApiService {
  static Future<String?> login(String email, String password) async{
    final url = Uri.parse('$baseUrl/auth/login');

    
      final response = await http.post(
        url,
        headers: {'Content-Type' : 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        })
      );

      if(response.statusCode == 200){
        final data = jsonDecode(response.body);
        final token = data['token'];
        final role = data['role'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setInt('role', role);

        return token;
      } else if (response.statusCode == 401) {
      final message = response.body.toLowerCase();
      if (message.contains("sai mật khẩu")) {
        throw Exception("Sai tài khoản hoặc mật khẩu");
      } else if (message.contains("email không tồn tại") || message.contains("tài khoản bị khoá")) {
        throw Exception("Không tìm thấy tài khoản");
      } else {
        throw Exception("Đăng nhập thất bại");
      }
    } else {
      throw Exception("Lỗi hệ thống. Vui lòng thử lại sau.");
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

  static Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

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

  static Future<bool> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/auth/forgot-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) {
      print('OTP đã gửi đến email');
      return true;
    } else {
      print('Lỗi gửi mã: ${response.body}');
      return false;
    }  
  }

  static Future<bool> resetPassword(String email, String code, String newPassword) async {
    final url = Uri.parse('$baseUrl/auth/reset-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'code': code,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      print('Đặt lại mật khẩu thành công');
      return true;
    } else {
      print('Lỗi reset mật khẩu: ${response.body}');
      return false;
    }
  }
  
}
