import 'package:flutter/material.dart';
import 'workspace.dart';
import 'board.dart';
import 'chat.dart';
import 'settings.dart';
import '../services/api.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  int? _selectedBoardId;
  final Api _api = Api();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await _api.fetchCurrentUser();
      setState(() {
        _userProfile = response;
      });
    } catch (e) {
      _showSnackBar('Failed to fetch user profile: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onItemTapped(int index) {
    if (index == 3) {  // Profile index
      _scaffoldKey.currentState?.openEndDrawer();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void updateSelectedBoard(int boardId) {
    setState(() {
      _selectedBoardId = boardId;
      _selectedIndex = 1;
    });
  }

  Future<void> _handleLogout() async {
    await _api.logout();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.workspaces_sharp), label: 'Workspaces'),
          BottomNavigationBarItem(icon: Icon(Icons.view_kanban), label: 'Boards'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.person_2), label: 'Profil'),
        ],
      ),
      endDrawer: Drawer(
        child: _userProfile == null
            ? Center(child: CircularProgressIndicator())
            : ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text('${_userProfile!['first_name']} ${_userProfile!['last_name']}'),
              accountEmail: Text(_userProfile!['email']),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  '${_userProfile!['first_name'][0]}${_userProfile!['last_name'][0]}',
                  style: TextStyle(fontSize: 24.0),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
    );
  }
}