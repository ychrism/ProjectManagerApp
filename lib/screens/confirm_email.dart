import 'package:flutter/material.dart';

class ConfirmEmailScreen extends StatefulWidget {
  const ConfirmEmailScreen({super.key});

  @override
  ConfirmEmailScreenState createState() => ConfirmEmailScreenState();
}


class ConfirmEmailScreenState extends State<ConfirmEmailScreen> {
  final _otpController = TextEditingController();

  void _confirmEmail() {
    // Add logic to confirm the OTP received via email
    final otp = _otpController.text;

    // After successful confirmation, navigate to sign-in
    Navigator.pushNamed(context, '/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm Your Email'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email_outlined, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'A confirmation link has been sent to your email.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to login after confirmation
                Navigator.pushNamed(context, '/sign-in');
              },
              child: Text('Go to Login'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

