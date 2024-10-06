import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger();

// Use a secure WebSocket connection
const String baseWebSocketUrl = "ws://10.0.2.2:8000/ws/chat";

class NotificationController {
  static final Map<int, NotificationController> _instances = {};

  StreamController streamController = StreamController.broadcast(sync: true);
  IOWebSocketChannel? channel;
  late var channelStream = channel?.stream.asBroadcastStream();
  final int boardId;

  factory NotificationController(int boardId) {
    if (!_instances.containsKey(boardId)) {
      _instances[boardId] = NotificationController._internal(boardId);
    }
    return _instances[boardId]!;
  }

  NotificationController._internal(this.boardId) {
    initWebSocketConnection();
  }

  void _onDisconnected() {
    logger.w("WebSocket disconnected. Attempting to reconnect...");
    initWebSocketConnection();
  }

  Future<void> initWebSocketConnection() async {
    logger.i("Connecting to WebSocket...");

    try {
      final uri = Uri.parse('$baseWebSocketUrl/$boardId/');
      final socket = await WebSocket.connect(uri.toString());

      channel = IOWebSocketChannel(socket);


      // Listen for connection established
      /*channelStream = channel!.stream.asBroadcastStream();
      channelStream?.listen(
            (data) {
          logger.i("Received data: $data");
          // Handle incoming messages
        },
        onError: (error) {
          logger.e("WebSocket error: $error");
          _onDisconnected();
        },
        onDone: () {
          logger.w("WebSocket connection closed");
          _onDisconnected();
        },
      );*/

      logger.i("WebSocket connection initialized");
    } catch (e) {
      logger.e("Failed to connect to WebSocket: $e");
      // Implement exponential backoff for reconnection
      await Future.delayed(Duration(seconds: 5));
      return initWebSocketConnection();
    }
  }

  void sendMessage(Map<String, dynamic> messageObject) {
    try {
      if (channel != null && channel!.sink != null) {
        channel!.sink.add(json.encode(messageObject));
        logger.i("Message sent: $messageObject");
      } else {
        logger.w("Cannot send message: WebSocket not connected");
      }
    } catch (e) {
      logger.e("Error sending message: $e");
    }
  }


  void dispose() {
    logger.i("Disposing WebSocket connection");
    channel?.sink.close();
    _instances.remove(boardId);
  }
}