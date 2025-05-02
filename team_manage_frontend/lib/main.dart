import 'package:flutter/material.dart';
import 'package:team_manage_frontend/screens/auth/forgot_password_screen.dart';
import 'package:team_manage_frontend/screens/auth/login_screen.dart';
import 'package:team_manage_frontend/screens/auth/register_screen.dart';
import 'package:team_manage_frontend/screens/auth/reset_password_screen.dart';
import 'package:team_manage_frontend/screens/auth/verify_email_screen.dart';
import 'package:team_manage_frontend/screens/project/create_project_page.dart';
import 'package:team_manage_frontend/screens/project/project_page.dart';
import 'screens/home_screen.dart';
import 'screens/user/create_user_page.dart';
import 'screens/user/profile_screen.dart';
import 'screens/user/user_page.dart';

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
        //Auth - User
        '/': (context) => const LoginScreen(),
        '/verify-email': (context) => const VerifyEmailScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/user': (context) => const UserPage(),
        '/user/create': (context) => const CreateUserPage(),
        '/profile': (context) => const ProfileScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),

        //Project
        '/project': (context) => const ProjectPage(),
        '/project/create': (context) => const CreateProjectPage(),
      },
    );
  }
}
