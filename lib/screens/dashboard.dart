import 'package:flutter/material.dart';
import 'package:project_manager_app/screens/workspace.dart';
import 'board.dart';
import 'chat.dart';
import 'settings.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack( // Use IndexedStack to switch between screens
        index: _selectedIndex,
        children: [
          WorkspaceScreen(),
          BoardScreen(),
          ChatScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.workspaces_sharp), label: 'Workspaces'),
          BottomNavigationBarItem(icon: Icon(Icons.view_kanban), label: 'Boards'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}