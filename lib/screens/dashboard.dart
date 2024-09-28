import 'package:flutter/material.dart';
import 'workspace.dart';
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
  int? _selectedBoardId;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void updateSelectedBoard(int boardId) {
    setState(() {
      _selectedBoardId = boardId;
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          WorkspaceScreen(onBoardSelected: updateSelectedBoard),
          _selectedBoardId != null
              ? BoardScreen(
            boardId: _selectedBoardId!,
            key: ValueKey(_selectedBoardId),
          )
              : Center(child: Text('No board selected')),
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
          BottomNavigationBarItem(icon: Icon(Icons.person_2), label: 'Profil'),
        ],
      ),
    );
  }
}