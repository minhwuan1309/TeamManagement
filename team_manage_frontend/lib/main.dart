import 'package:flutter/material.dart';
import 'package:team_manage_frontend/screens/register_screen.dart';
import 'package:team_manage_frontend/screens/verify_email_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/user_page.dart';
import 'screens/create_user_page.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TeamManage',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/verify-email': (context) => const VerifyEmailScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/user': (context) => const UserPage(),
        '/user/create': (context) => const CreateUserPage(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
