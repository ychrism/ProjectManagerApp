import 'package:flutter/material.dart';
import 'package:project_manager_app/screens/dashboard.dart';
import 'screens/welcome_screen.dart';
import 'screens/sign_up.dart';
import 'screens/sign_in.dart';
import 'screens/confirm_email.dart';
import 'services/navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ProjectManagerApp());
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
        scaffoldBackgroundColor: Colors.white.withOpacity(0.9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
        ),
        drawerTheme: DrawerThemeData(
          backgroundColor: Colors.grey[900],
          surfaceTintColor: Colors.blue,
        ),
        datePickerTheme: DatePickerThemeData(
          headerBackgroundColor: Colors.lightBlueAccent,
          dayBackgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.blue : null
          ),
          todayBackgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.blue : null
          ),
          todayForegroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.white : Colors.blue
          ),
          yearBackgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.blue : null
          ),
          todayBorder: const BorderSide(color: Colors.blue, width: 2),
          cancelButtonStyle: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected) ? null : Colors.blue
              ),
          ),
          confirmButtonStyle: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? null : Colors.blue // Text color for non-selected dates
            ),
          ),
        ),
        timePickerTheme: TimePickerThemeData(
          dialHandColor: Colors.blue,
            cancelButtonStyle: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? null : Colors.blue
              ),
            ),
            confirmButtonStyle: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? null : Colors.blue // Text color for non-selected dates
              ),
            ),
          hourMinuteColor: WidgetStateColor.resolveWith((Set<WidgetState> states) =>
          states.contains(WidgetState.selected) ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1)
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: WidgetStateColor.resolveWith((Set<WidgetState> states) =>
              states.contains(WidgetState.focused) ? Colors.blue.withOpacity(0.3) : Colors.grey.withOpacity(0.1)
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,

            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            hintStyle: TextStyle(color: Colors.blue.withOpacity(0.5)),
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.blue,
          selectionColor: Colors.blue,
          selectionHandleColor: Colors.blue,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.blue
        )
      ),
      home: const StartupController(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/sign-up': (context) => const SignUpScreen(),
        '/sign-in': (context) => SignInScreen(),
        '/confirm-email': (context) => ConfirmEmailScreen(),
        '/dashboard': (context) => DashboardScreen(),
      },
    );
  }
}


class StartupController extends StatefulWidget {
  const StartupController({super.key});

  @override
  StartupControllerState createState() => StartupControllerState();
}

class StartupControllerState extends State<StartupController> {
  bool _isFirstTime = true;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;

    setState(() {
      _isFirstTime = isFirstTime;
    });

    if (isFirstTime) {
      await prefs.setBool('isFirstTime', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstTime) {
      return const WelcomeScreen();
    } else {
      return SignInScreen();
    }
  }
}
