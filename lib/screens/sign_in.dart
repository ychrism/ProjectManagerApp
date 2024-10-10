// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../services/api.dart';

// This class defines the sign-in screen of the app
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  // Controllers for text input fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // State variable to toggle password visibility
  bool _obscurePassword = true;
  // Instance of API service
  final Api _apiService = Api();

  // Method to handle sign in
  void _signIn() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      final result = await _apiService.login(
        email: email,
        password: password,
      );

      if (result['success']) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'An unexpected error occurred. Please contact administrator.')),
      );
    }
  }

  // Method to navigate to sign up screen
  void _signUp() {
    Navigator.pushReplacementNamed(context, '/sign-up');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 600, // Maximum width of the form
              maxHeight: 400, // Maximum height of the form
            ),
            padding: const EdgeInsets.all(24.0),
            // Form container decoration
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.blue.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 4,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sign In title
                Text(
                  'Sign In',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    prefixIcon: Icon(Icons.email),
                    labelStyle: TextStyle(color: Colors.black),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blue, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.black),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blue, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    prefixIcon: Icon(Icons.lock),
                    // Toggle password visibility
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.blueAccent,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Sign In button
                // Sign In button
                ElevatedButton(
                  onPressed: _signIn,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.blueAccent,
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Sign In'),
                ),
                // Sign Up link
                ListTile(
                  title: const Text(
                    'Sign up',
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  onTap: () {
                    _signUp();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}