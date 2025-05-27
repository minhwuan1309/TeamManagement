import 'package:flutter/material.dart';
import 'package:team_manage_frontend/screens/auth/forgot_password_screen.dart';
import 'package:team_manage_frontend/screens/auth/login_screen.dart';
import 'package:team_manage_frontend/screens/auth/register_screen.dart';
import 'package:team_manage_frontend/screens/auth/reset_password_screen.dart';
import 'package:team_manage_frontend/screens/auth/verify_email_screen.dart';
import 'package:team_manage_frontend/screens/modules/create_module_page.dart';
import 'package:team_manage_frontend/screens/modules/module_detail_page.dart';
import 'package:team_manage_frontend/screens/project/create_project_page.dart';
import 'package:team_manage_frontend/screens/tasks/task_detail_page.dart';
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

      initialRoute: '/home',
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '');
        final pathSegments = uri.pathSegments;

        // Basic routes
        if (uri.path == '/home') return MaterialPageRoute(builder: (context) => const HomeScreen());
        if (uri.path == '/login') return MaterialPageRoute(builder: (context) => const LoginScreen());
        if (uri.path == '/verify-email') return MaterialPageRoute(builder: (context) => const VerifyEmailScreen());
        if (uri.path == '/register') return MaterialPageRoute(builder: (context) => const RegisterScreen());
        if (uri.path == '/forgot-password') return MaterialPageRoute(builder: (context) => const ForgotPasswordScreen());
        if (uri.path == '/reset-password') return MaterialPageRoute(builder: (context) => const ResetPasswordScreen());
        if (uri.path == '/profile') return MaterialPageRoute(builder: (context) => const ProfileScreen());

        // User routes - RESTful style
        if (uri.path == '/user') return MaterialPageRoute(builder: (context) => const UserPage());
        if (uri.path == '/user/create') return MaterialPageRoute(builder: (context) => const CreateUserPage());
        

        // Project routes - RESTful style
        if (uri.path == '/projects/create') {
          return MaterialPageRoute(builder: (context) => const CreateProjectPage());
        }


        if (uri.path == '/module/create') {
          final args = settings.arguments;
          if (args is Map && args['projectId'] is int) {
            return MaterialPageRoute(
              builder: (_) => CreateModulePage(
                projectId: args['projectId'],
                parentModuleId: args['parentModuleId'] as int?,
                projectMembers: List<Map<String, dynamic>>.from(args['projectMembers'] ?? []),
              ),
            );
          }
        }

        if (uri.path == '/module-detail') {
          final idParam = uri.queryParameters['id'];
          final moduleId = int.tryParse(idParam ?? '');
          if (moduleId != null) {
            return MaterialPageRoute(
              builder: (_) => ModuleDetailPage.withId(moduleId: moduleId),
            );
          } 
        }

        //Task
        if (uri.path == '/task-detail') {
          final id = int.tryParse(uri.queryParameters['id'] ?? '');
          if (id != null) {
            return MaterialPageRoute(
              builder: (_) => TaskDetailPage(taskId: id),
            );
          }
        }


        if (pathSegments.length == 4 && 
            pathSegments[0] == 'projects' && 
            pathSegments[2] == 'modules' && 
            pathSegments[3] == 'create') {
          final projectId = int.tryParse(pathSegments[1]);
          if (projectId != null) {
            final args = settings.arguments;
            return MaterialPageRoute(
              builder: (_) => CreateModulePage(
                projectId: projectId,
                parentModuleId: args is Map ? args['parentModuleId'] as int? : null,
                projectMembers: args is Map ? List<Map<String, dynamic>>.from(args['projectMembers'] ?? []) : [],
              ),
            );
          }
        }

        // Fallback to home if no route matches
        return MaterialPageRoute(builder: (context) => const HomeScreen());
      },
    );
  }
}