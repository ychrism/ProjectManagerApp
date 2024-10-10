import 'package:flutter/material.dart';
import 'workspace.dart';
import 'chat.dart';
import '../services/api.dart';

/// DashboardScreen is the main screen of the application, containing
/// the workspace, chat, and profile sections.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  // Index of the currently selected bottom navigation item
  int _selectedIndex = 0;

  // Instance of the API service for making network requests
  final Api _api = Api();

  // Global key for accessing the Scaffold state (used for opening the drawer)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Stores the user's profile information
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  /// Fetches the user's profile from the API
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

  /// Displays a snack bar with the given message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Handles taps on the bottom navigation bar items
  void _onItemTapped(int index) {
    if (index == 2) {  // Profile index
      _scaffoldKey.currentState?.openEndDrawer();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  /// Handles the logout process
  Future<void> _handleLogout() async {
    await _api.logout();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while fetching user profile
    return _userProfile == null
        ? Center(child: CircularProgressIndicator())
        : Scaffold(
      key: _scaffoldKey,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          WorkspaceScreen(userProfile: _userProfile!),
          MessageHome(userProfile: _userProfile!),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.view_kanban, size: 35,), label: 'Boards'),
          BottomNavigationBarItem(icon: Icon(Icons.message, size: 35), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.person_2, size: 35), label: 'Profile'),
        ],
      ),
      endDrawer: Drawer(
        child:  ListView(
          padding: EdgeInsets.zero,
          children: [
            // User profile header in the drawer
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
            // Logout option in the drawer
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