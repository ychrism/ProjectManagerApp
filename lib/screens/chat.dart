import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_client/web_socket_client.dart';
import '../services/api.dart';
import 'messages_screen.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger();

class MessageHome extends StatefulWidget {
  const MessageHome({Key? key}) : super(key: key);

  @override
  State<MessageHome> createState() => _MessageHomeState();
}

class _MessageHomeState extends State<MessageHome> {
  final Api _api = Api();
  List<Map<String, dynamic>> latestMessages = [];
  bool isLoading = true;
  Map<String, dynamic> _userProfile = {};
  final String baseHost = defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2': '127.0.0.1' ;
  WebSocket? _socket;
  late String _userUuid;
  final _timeout = const Duration(seconds: 10);
  final _backoff = LinearBackoff(
    initial: const Duration(seconds: 0),
    increment: const Duration(seconds: 1),
    maximum: const Duration(seconds: 5),
  );

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchLatestMessages();
    _fetchChannelUuid();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await _api.fetchCurrentUser();
      setState(() {
        _userProfile = response;
        //logger.i('User infos: $_userProfile');
      });
    } catch (e) {
      _showSnackBar('Failed to fetch user profile: $e');
    }
  }

  Future<void> _fetchLatestMessages() async {
    try {
      final fetchedMessagesData = await _api.fetchLatestMessages();
      setState(() {
        latestMessages = fetchedMessagesData;
        logger.i(latestMessages.toString());
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Failed to fetch latest messages: ${e.toString()}');
    }
  }

  Future<void> _fetchChannelUuid() async {
    try {
      final response = await _api.getChannelUuid();
      if (response['success']) {
        setState(() {
          _userUuid = response['uuid'];
          //logger.i(_userUuid.toString());
        });
        _initWebSocket();
      } else {
        _showSnackBar('An error occurred: ${response['error']}');
      }
    } catch (e) {
      _showSnackBar('Failed to fetch user channel authentication uuid: $e');
    }
  }

  Future<void> _initWebSocket() async {
    _socket = WebSocket(
      Uri.parse('ws://$baseHost:8000/ws/latest_message_update/?uuid=$_userUuid'),
      timeout: _timeout,
      backoff: _backoff,
    );

    _socket!.connection.listen((state) {
      logger.i('WebSocket connection state: $state');
    });

    try {
      await _socket!.connection
          .firstWhere((state) => state is Connected)
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
        throw TimeoutException('WebSocket connection timeout'),
      );
      logger.i('WebSocket connected successfully');
      _listenForNewMessages();
    } catch (error) {
      logger.e('WebSocket connection error: $error');
      _showSnackBar('Failed to connect to chat. Please try again later.');
    }
  }

  void _listenForNewMessages() {
    _socket?.messages.listen((message) {
      final newMessage = jsonDecode(message.toString());
      logger.i(newMessage.toString());
      _updateLatestMessage(newMessage);
    });
  }

  void _updateLatestMessage(Map<String, dynamic> newMessage) {
    setState(() {
      int index = latestMessages.indexWhere((msg) => msg['board']['id'] == newMessage['board']['id']);
      newMessage['board']['pic'] = 'http://$baseHost:8000${newMessage['board']['pic']}';
      if (index != -1) {
        latestMessages[index] = newMessage;
      } else {
        latestMessages.insert(0, newMessage);
      }
      latestMessages.sort((a, b) => DateTime.parse(b['date_sent']).compareTo(DateTime.parse(a['date_sent'])));
    });


  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: latestMessages.length,
        itemBuilder: (BuildContext context, int index) {
          var message = latestMessages[index];
          var board = message['board'];
          var isCurrentUser = _userProfile.isNotEmpty &&
              message['sent_by']['id'] == _userProfile['id'];
          return ListTile(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => BoardChatScreen(
                    board: board,
                  ),
                ),
              );
              _fetchLatestMessages();
              _fetchChannelUuid();
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
                  isCurrentUser ? 'You' : message['sent_by']['first_name'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: Text(DateFormat('yy-MM-dd HH:mm').format(DateTime.parse(message['date_sent']))),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _socket?.close();
    super.dispose();
  }
}