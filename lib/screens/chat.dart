import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import '../services/api.dart';
import 'messages_screen.dart';
import '../services/websocket.dart';

// Initialize a logger for debugging
final Logger logger = Logger();

/// MessageHome widget represents the main screen for displaying chat messages
class MessageHome extends StatefulWidget {
  final Map<String, dynamic>? userProfile;

  const MessageHome({super.key, required this.userProfile});

  @override
  State<MessageHome> createState() => _MessageHomeState();
}

class _MessageHomeState extends State<MessageHome> {
  final Api _api = Api();
  List<Map<String, dynamic>> latestMessages = [];
  bool isLoading = true;
  List<Map<String, dynamic>> boards = [];

  late WebSocketService _webSocketService;

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
    _fetchBoardsAndLatestMessages();
  }

  Future<void> _initializeWebSocket() async {
    _webSocketService = WebSocketService(
        channelPath: '/ws/latest_message_update/'
    );

    try {
      await _webSocketService.initWebSocket();
      _listenForNewMessages();
    } catch (e) {
      _showSnackBar('Failed to connect to chat. Please try again later.');
    }
  }

  /// Fetch boards and latest messages from the API
  Future<void> _fetchBoardsAndLatestMessages() async {
    try {
      final fetchedMessagesData = await _api.fetchLatestMessages();
      final fetchedBoards = await _api.fetchBoards();
      setState(() {
        latestMessages = fetchedMessagesData;
        boards = fetchedBoards;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar(
          'Failed to fetch board or latest messages: ${e.toString()}');
    }
  }

  /// Listen for new messages from the WebSocket
  void _listenForNewMessages() {
    _webSocketService.listenForNewMessages().listen((newMessage) {
      if (newMessage['type'] == 'latest_message_update') {
        _updateLatestMessage(newMessage['message']);
      }
    }, onError: (error) {
      logger.e('Error in WebSocket stream: $error');
      _showSnackBar('Error receiving messages. Please try again later.');
    });
  }

  /// Update the latest message in the state
  void _updateLatestMessage(Map<String, dynamic> newMessage) {
    setState(() {
      int index = latestMessages
          .indexWhere((msg) => msg['board']['id'] == newMessage['board']['id']);
      newMessage['board']['pic'] =
      'http://${_webSocketService.baseHost}:8000${newMessage['board']['pic']}';
      if (index != -1) {
        latestMessages[index] = newMessage;
      } else {
        latestMessages.insert(0, newMessage);
      }
      latestMessages.sort((a, b) => DateTime.parse(b['date_sent'])
          .compareTo(DateTime.parse(a['date_sent'])));
    });
  }

  /// Show a snackbar with the given message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Show a dialog to create a new chat
  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[800],
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('New chat', style: TextStyle(color: Colors.white)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: boards.length,
              itemBuilder: (BuildContext context, int index) {
                var board = boards[index];
                return ListTile(
                  onTap: () async {
                    Navigator.of(context).pop(); // Close the dialog
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) => BoardChatScreen(
                            board: board,
                            userProfile: widget.userProfile!
                        ),
                      ),
                    );
                    _fetchBoardsAndLatestMessages();
                  },
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(board['pic']),
                    radius: 30.0,
                  ),
                  title: Text(
                    board['name'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          toolbarHeight: 75.0,
          title: const Text('Chats'),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Iconsax.more),
            ),
          ],
        ),
        body: Stack(
          children: [
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: latestMessages.length,
              itemBuilder: (BuildContext context, int index) {
                var message = latestMessages[index];
                var board = message['board'];
                var isCurrentUser = widget.userProfile!.isNotEmpty &&
                    message['sent_by']['id'] == widget.userProfile!['id'];
                return ListTile(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) =>
                            BoardChatScreen(
                              board: board,
                              userProfile: widget.userProfile!,
                            ),
                      ),
                    );
                    _fetchBoardsAndLatestMessages();
                    _initializeWebSocket();
                  },
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(board['pic']),
                    radius: 30.0,
                  ),
                  title: Text(
                    board['name'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message['content'] ?? "No messages",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isCurrentUser
                            ? 'You'
                            : message['sent_by']['first_name'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(DateFormat('yy-MM-dd HH:mm')
                      .format(DateTime.parse(message['date_sent']))),
                );
              },
            ),
            Positioned(
              bottom: 16.0,
              right: 16.0,
              child: FloatingActionButton(
                onPressed: () {
                  _showDialog(context);
                },
                backgroundColor: Colors.lightBlue,
                heroTag: null,
                child: Icon(Icons.message, color: Colors.white),
              ),
            ),
          ],
        ));
  }

  @override
  void dispose() {
    _webSocketService.close();
    super.dispose();
  }
}