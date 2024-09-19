import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/sign_up.dart';
import 'screens/sign_in.dart';
import 'screens/dashboard.dart';

void main() {
  runApp(const ProjectManagerApp());
}

class ProjectManagerApp extends StatelessWidget {
  const ProjectManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WelcomeScreen(),
      routes: {
        '/welcome': (context) => WelcomeScreen(),
        '/sign-up': (context) => SignUpScreen(),
        '/sign-in': (context) => SignInScreen(),
        '/dashboard': (context) => BoardScreen(),
      },
    );
  }
}
