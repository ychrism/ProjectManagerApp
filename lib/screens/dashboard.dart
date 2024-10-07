import 'package:flutter/material.dart';
import 'workspace.dart';
import 'chat.dart';
import '../services/api.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
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
    if (index == 2) {  // Profile index
      _scaffoldKey.currentState?.openEndDrawer();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }


  Future<void> _handleLogout() async {
    await _api.logout();
  }


  @override
  Widget build(BuildContext context) {
    return _userProfile == null
    ? Center(child: CircularProgressIndicator())
    : Scaffold(
      key: _scaffoldKey,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          WorkspaceScreen(userProfile: _userProfile!),
          const MessageHome(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: [
          //BottomNavigationBarItem(icon: Icon(Icons.workspaces_sharp), label: 'Workspaces'),
          BottomNavigationBarItem(icon: Icon(Icons.view_kanban), label: 'Boards'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.person_2), label: 'Profil'),
        ],
      ),
      endDrawer: Drawer(
        child:  ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
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
              leading: Icon(Icons.logout, color: Colors.white,),
              title: Text('Logout', style: TextStyle(color: Colors.white),),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
    );
  }
}