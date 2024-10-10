import 'package:flutter/material.dart';

// This class defines the welcome screen of the app
class WelcomeScreen extends StatelessWidget {
  // This is the constructor for the WelcomeScreen class
  const WelcomeScreen({super.key});

  // This method builds the user interface for the welcome screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The main container for the screen
      body: Container(
        // This creates a gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.blueGrey],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        // This centers the content vertically and horizontally
        child: Center(
          // This creates a column to arrange widgets vertically
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // This is the welcome text
              const Text(
                'Welcome to TaskFlow',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              // This adds some space between the text and the button
              SizedBox(height: 20),
              // This is the "Get Started" button
              ElevatedButton(
                // This defines what happens when the button is pressed
                onPressed: () {
                  // This navigates to the sign-up screen
                  Navigator.pushReplacementNamed(context, '/sign-up');
                },
                // This styles the button
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // This sets the background color
                  foregroundColor: Colors.white, // This sets the text color
                ),
                // This is the text displayed on the button
                child: Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}