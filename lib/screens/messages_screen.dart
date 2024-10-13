import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:logger/logger.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;

import '../services/api.dart';
import '../services/websocket.dart';

final Logger logger = Logger();

class BoardChatScreen extends StatefulWidget {
  final Map<String, dynamic> board;
  final Map<String, dynamic>? userProfile;

  const BoardChatScreen({
    super.key,
    required this.board,
    required this.userProfile,
  });

  @override
  State<BoardChatScreen> createState() => _BoardChatScreenState();
}

class _BoardChatScreenState extends State<BoardChatScreen> {
  final TextEditingController _sendMessageController = TextEditingController();
  bool isLoading = true;
  final Api _api = Api();
  late final int _boardId;
  late WebSocketService _webSocketService; // Use WebSocketService instead of direct WebSocket
  List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _showEmoji = false;

  @override
  void initState() {
    super.initState();
    _boardId = widget.board['id'];
    _fetchMessages();
    _initWebSocket();
  }

  // Fetch initial messages
  Future<void> _fetchMessages() async {
    try {
      final fetchedMessages = await _api.fetchBoardMessages(boardId: _boardId);
      setState(() {
        _messages = fetchedMessages;
        isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Failed to fetch messages');
    }
  }

  // Initialize WebSocket connection
  Future<void> _initWebSocket() async {
    _webSocketService = WebSocketService(channelPath: '/ws/chat/$_boardId/');
    try {
      await _webSocketService.initWebSocket();
      _listenForNewMessages();
    } catch (e) {
      _showSnackBar('Failed to connect to chat. Please try again later.');
    }
  }

  // Listen for new messages from WebSocket
  void _listenForNewMessages() {
    _webSocketService.listenForNewMessages().listen((newMessage) {
      setState(() {
        _messages.add(newMessage);
      });
      _scrollToBottom();
    });
  }

  // Show a snack bar with an error message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Scroll to the bottom of the chat
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.board['pic']),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    widget.board['name'] as String,
                    style: const TextStyle(color: Colors.black87, fontSize: 18.0),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            PopupMenuButton(
              itemBuilder: (context) => <PopupMenuEntry>[
                const PopupMenuItem(child: Text('Block')),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/default_chat_background.png'),
                  fit: BoxFit.cover
              )
          ),
          child: Column(
            children: [
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final boardMessage = _messages[index];
                    return _buildMessageTile(boardMessage);
                  },
                ),
              ),
              _buildMessageInput(),
              Offstage(
                offstage: !_showEmoji,
                child: SizedBox(
                  height: 250,
                  child: EmojiPicker(
                    onEmojiSelected: (Category? category, Emoji emoji) {
                      _onEmojiSelected(emoji);
                    },
                    onBackspacePressed: _onBackspacePressed,
                    config: Config(
                      emojiViewConfig: EmojiViewConfig(
                        columns: 7,
                        emojiSizeMax: 32 * (foundation.defaultTargetPlatform == foundation.TargetPlatform.iOS ? 1.30 : 1.0),
                        verticalSpacing: 0,
                        horizontalSpacing: 0,
                        gridPadding: EdgeInsets.zero,
                        replaceEmojiOnLimitExceed: false,
                        noRecents: const Text(
                          'No Recents',
                          style: TextStyle(fontSize: 20, color: Colors.black26),
                          textAlign: TextAlign.center,
                        ),
                        loadingIndicator: const SizedBox.shrink(),
                        buttonMode: ButtonMode.MATERIAL,
                        recentsLimit: 28,
                        backgroundColor: const Color(0xFFF2F2F2),
                      ),
                      skinToneConfig: const SkinToneConfig(
                        enabled: true,
                        dialogBackgroundColor: Colors.white,
                        indicatorColor: Colors.grey,
                      ),
                      categoryViewConfig: const CategoryViewConfig(
                        tabIndicatorAnimDuration: kTabScrollDuration,
                        categoryIcons: CategoryIcons(),
                        initCategory: Category.RECENT,
                        iconColor: Colors.grey,
                        iconColorSelected: Colors.blue,
                        backspaceColor: Colors.blue,
                      ),
                      checkPlatformCompatibility: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
    );
  }

  // Build individual message tile
  Widget _buildMessageTile(Map<String, dynamic> boardMessage) {
    final isCurrentUser = widget.userProfile!.isNotEmpty &&
        boardMessage['sent_by']['id'] == widget.userProfile!['id'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser)
            CircleAvatar(
              foregroundImage: AssetImage('assets/default_photo_profile.jpg'),
              radius: 16,
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrentUser ? Colors.blue[900] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Text(
                    boardMessage['content'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      color: isCurrentUser ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    isCurrentUser ? 'You' : boardMessage['sent_by']['first_name'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isCurrentUser)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                foregroundImage: AssetImage('assets/default_photo_profile.jpg'),
                radius: 16,
              ),
            ),
        ],
      ),
    );
  }

  // Build message input field
  Widget _buildMessageInput() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_showEmoji ? Icons.keyboard : Icons.emoji_emotions),
            onPressed: _toggleEmojiKeyboard,
          ),
          Expanded(
            child: TextField(
              controller: _sendMessageController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.send_14),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  // Toggle emoji keyboard visibility
  void _toggleEmojiKeyboard() {
    setState(() {
      _showEmoji = !_showEmoji;
    });
  }

  // Handle emoji selection
  void _onEmojiSelected(Emoji emoji) {
    _sendMessageController
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: _sendMessageController.text.length));
  }

  // Handle backspace in emoji keyboard
  void _onBackspacePressed() {
    _sendMessageController
      ..text = _sendMessageController.text.characters.skipLast(1).toString()
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: _sendMessageController.text.length));
  }

  // Send a message
  void _sendMessage() {
    if (_sendMessageController.text.isNotEmpty) {
      final message = {
        'board': _boardId,
        'sent_by': widget.userProfile!['id'],
        'content': _sendMessageController.text
      };
      _webSocketService.sendMessage(message);
      _sendMessageController.clear();
    }
  }

  @override
  void dispose() {
    _webSocketService.close();
    _sendMessageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}