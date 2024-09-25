import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text('Detail Screen'),
      ),
      body: Center(
        child: Text('This is the detail screen'),
      ),
    );
  }
}