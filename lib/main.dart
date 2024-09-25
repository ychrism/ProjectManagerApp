import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/sign_up.dart';
import 'screens/sign_in.dart';
import 'screens/dashboard.dart';
import 'screens/board.dart';
import 'screens/confirm_email.dart';
import 'services/navigation.dart';

void main() {
  runApp(ProjectManagerApp());
}

class ProjectManagerApp extends StatelessWidget {
  const ProjectManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigationService.navigatorKey,
      title: 'Project Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const WelcomeScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/sign-up': (context) => const SignUpScreen(),
        '/sign-in': (context) => SignInScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/board': (context) => const BoardScreen(),
        '/confirm-email': (context) => const ConfirmEmailScreen(),
      },
    );
  }
}
