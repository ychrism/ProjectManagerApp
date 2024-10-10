import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_client/web_socket_client.dart';
import 'package:logger/logger.dart';

import 'api.dart';

class WebSocketService {
  // Determine the base host based on the platform
  final String baseHost = defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'   //change websocket IP here
      : '127.0.0.1';
  final String channelPath;
  late String userUuid;
  WebSocket? _socket;
  final Api _api = Api();
  final _timeout = const Duration(seconds: 10);
  final _backoff = LinearBackoff(
    initial: const Duration(seconds: 0),
    increment: const Duration(seconds: 1),
    maximum: const Duration(seconds: 5),
  );
  final Logger logger = Logger();

  WebSocketService({required this.channelPath});

  /// Fetch the user's channel UUID for WebSocket connection
  Future<void> fetchUserUuid() async {
    try {
      final response = await _api.getChannelUuid();
      if (response['success']) {
        userUuid = response['uuid'];
      } else {
        throw Exception('Failed to fetch UUID: ${response['error']}');
      }
    } catch (e) {
      logger.e('Failed to fetch user channel authentication uuid: $e');
      rethrow;
    }
  }


  /// Initialize WebSocket connection
  Future<void> initWebSocket() async {
    await fetchUserUuid();

    _socket = WebSocket(
      Uri.parse('ws://$baseHost:8000$channelPath?uuid=$userUuid'),
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
    } catch (error) {
      logger.e('WebSocket connection error: $error');
      rethrow;
    }
  }

  /// Listen for new messages from the WebSocket
  Stream<Map<String, dynamic>> listenForNewMessages() {
    if (_socket == null) {
      throw StateError('WebSocket not initialized. Call initWebSocket() first.');
    }
    return _socket!.messages.map((message) {
      final newMessage = jsonDecode(message.toString());
      logger.i(newMessage.toString());
      return newMessage;
    });
  }

  /// Send a message through the WebSocket
  void sendMessage(Map<String, dynamic> message) {
    if (_socket == null) {
      throw StateError('WebSocket not initialized. Call initWebSocket() first.');
    }
    _socket!.send(jsonEncode(message));
    logger.i('Sent message: $message');
  }

  /// Close the WebSocket connection
  void close() {
    _socket?.close();
  }
}