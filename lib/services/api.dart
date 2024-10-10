// ignore_for_file: unused_local_variable

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'navigation.dart';
import 'package:logger/logger.dart';

// Define base API URL based on platform
final String baseApiUrl = defaultTargetPlatform == TargetPlatform.android
    ? 'http://10.0.2.2:8000/api'
    : 'http://127.0.0.1:8000/api';

final Logger logger = Logger();

class Api {
  final String baseUrl = baseApiUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final http.Client _client = http.Client();

  Api();

  // Authentication methods

  /// Sign up a new user
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await post('/signup/', {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      });
      return {'success': true, 'message': response['msg']};
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Log in a user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await post('/signin/', {
        'email': email,
        'password': password,
      });
      await _storage.write(key: 'access', value: response['access']);
      await _storage.write(key: 'refresh', value: response['refresh']);
      return {'success': true};
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Get a channel UUID for WebSocket authentication
  Future<Map<String, dynamic>> getChannelUuid() async {
    try {
      final response = await get('/ws_auth_uuid/');
      return {'success': true, 'uuid': response['uuid']};
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Fetch current user details
  Future<Map<String, dynamic>> fetchCurrentUser() async {
    try {
      return await get('/users/me/');
    } catch (e) {
      throw _handleApiException(e, 'Failed to fetch current user');
    }
  }

  /// Log out the current user
  Future<void> logout() async {
    await _storage.delete(key: 'access');
    await _storage.delete(key: 'refresh');
    await navigationService.replaceTo('/sign-in');
  }

  // Board operations

  /// Fetch all boards
  Future<List<Map<String, dynamic>>> fetchBoards() async {
    try {
      final response = await get('/boards/');
      return _convertToList(response);
    } catch (e) {
      throw _handleApiException(e, 'Failed to fetch boards');
    }
  }

  /// Fetch details of a specific board
  Future<Map<String, dynamic>> fetchBoardDetails({required int boardId}) async {
    try {
      return await get('/boards/$boardId/');
    } catch (e) {
      throw _handleApiException(e, 'Failed to fetch board details');
    }
  }

  /// Create a new board
  Future<Map<String, dynamic>> createBoard({
    required String name,
    required String startDate,
    required String dueDate,
    required String description,
    required Map<String, dynamic>? imageData,
  }) async {
    try {
      var data = {
        'name': name,
        'start_date': startDate,
        'due_date': dueDate,
        'description': description,
        'progress': 0,
      };
      if (imageData != null && imageData.containsKey('file')) {
        data['pic'] = imageData['file'];
      }
      await post('/boards/', data);
      return {'success': true};
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Update an existing board
  Future<Map<String, dynamic>> updateBoard({
    required int boardId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      var data = Map<String, dynamic>.from(updates);
      if (data.containsKey('pic') && data['pic'] is Map<String, dynamic>) {
        var imageData = data['pic'];
        data['pic'] = imageData.containsKey('file') ? imageData['file'] : null;
      }
      await patch('/boards/$boardId/', data);
      return {'success': true};
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Delete a board
  Future<Map<String, dynamic>> deleteBoard({required int boardId}) async {
    try {
      await delete('/boards/$boardId/');
      return {'success': true};
    } catch (e) {
      return _handleError(e);
    }
  }

  // Card operations

  /// Fetch cards for a specific board
  Future<List<Map<String, dynamic>>> fetchCards({required int boardId}) async {
    try {
      final response = await get('/cards/?board=$boardId');
      return _convertToList(response);
    } catch (e) {
      throw _handleApiException(e, "Failed to fetch the board's cards");
    }
  }

  /// Create a new card
  Future<Map<String, dynamic>> createCard({
    required int boardId,
    required Map<String, dynamic> cardData,
  }) async {
    try {
      var data = Map<String, dynamic>.from(cardData)..['board'] = boardId;
      await post('/cards/', data);
      return {'success': true};
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Update an existing card
  Future<Map<String, dynamic>> updateCard({
    required int cardId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await patch('/cards/$cardId/', updates);
      return {'success': true};
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Update the status of a card
  Future<Map<String, dynamic>> updateCardStatus({
    required int cardId,
    required String newStatus,
  }) async {
    try {
      await patch('/cards/$cardId/', {'status': newStatus});
      return {'success': true};
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Delete a card
  Future<Map<String, dynamic>> deleteCard({required int cardId}) async {
    try {
      await delete('/cards/$cardId/');
      return {'success': true};
    } catch (e) {
      return _handleError(e);
    }
  }

  // Message operations

  /// Fetch messages for a specific board
  Future<List<Map<String, dynamic>>> fetchBoardMessages({required int boardId}) async {
    try {
      final response = await get('/messages/?board=$boardId');
      return _convertToList(response);
    } catch (e) {
      throw _handleApiException(e, "Failed to fetch messages");
    }
  }

  /// Fetch latest messages across all boards
  Future<List<Map<String, dynamic>>> fetchLatestMessages() async {
    try {
      final response = await get('/messages/latest_messages/');
      return _convertToList(response);
    } catch (e) {
      throw _handleApiException(e, "Failed to fetch latest messages");
    }
  }

  // HTTP methods
  Future<dynamic> get(String endpoint) async => _sendRequest('GET', endpoint);
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async => _sendRequest('POST', endpoint, body: data);
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async => _sendRequest('PUT', endpoint, body: data);
  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async => _sendRequest('PATCH', endpoint, body: data);
  Future<dynamic> delete(String endpoint) async => _sendRequest('DELETE', endpoint);

  /// Send an HTTP request with proper error handling and token refresh
  Future<dynamic> _sendRequest(String method, String endpoint, {Map<String, dynamic>? body}) async {
    String? token = await _storage.read(key: 'access');
    var headers = {
      'Content-Type': 'application/json; charset=utf-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    var url = Uri.parse('$baseUrl$endpoint');

    try {
      http.Response response;
      if (method != 'GET' && body != null && body.values.any((v) => v is File)) {
        response = await _handleMultipartRequest(method, url, headers, body);
      } else {
        response = await _handleRegularRequest(method, url, headers, body);
      }

      if (response.statusCode == 401) {
        if (endpoint == '/signin/') {
          throw ApiException('Invalid email or password');
        } else {
          bool refreshed = await _refreshToken();
          return refreshed ? _sendRequest(method, endpoint, body: body) : await logout();
        }
      } else if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseResponse(response);
      } else {
        throw ApiException(_parseErrorResponse(response));
      }
    } catch (e) {
      throw _handleApiException(e, 'Request failed');
    }
  }

  /// Handle multipart request for file uploads
  Future<http.Response> _handleMultipartRequest(
      String method,
      Uri url,
      Map<String, String> headers,
      Map<String, dynamic> body,
      ) async {
    var request = http.MultipartRequest(method, url)..headers.addAll(headers);
    body.forEach((key, value) {
      if (value is File) {
        request.files.add(http.MultipartFile(
          key,
          value.readAsBytes().asStream(),
          value.lengthSync(),
          filename: value.path.split('/').last,
        ));
      } else {
        request.fields[key] = value.toString();
      }
    });
    var streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  /// Handle regular HTTP requests
  Future<http.Response> _handleRegularRequest(
      String method,
      Uri url,
      Map<String, String> headers,
      Map<String, dynamic>? body,
      ) async {
    switch (method) {
      case 'GET':
        return await _client.get(url, headers: headers);
      case 'POST':
        return await _client.post(url, headers: headers, body: json.encode(body));
      case 'PUT':
        return await _client.put(url, headers: headers, body: json.encode(body));
      case 'PATCH':
        return await _client.patch(url, headers: headers, body: json.encode(body));
      case 'DELETE':
        return await _client.delete(url, headers: headers);
      default:
        throw ApiException('Unsupported HTTP method');
    }
  }

  /// Refresh the access token
  Future<bool> _refreshToken() async {
    final refreshToken = await _storage.read(key: 'refresh');
    if (refreshToken == null) return false;

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/signin/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['access'] != null && data['refresh'] != null) {
          await _storage.write(key: 'access', value: data['access']);
          await _storage.write(key: 'refresh', value: data['refresh']);
          return true;
        }
      }
    } catch (e) {
      throw ApiException('Error refreshing token: $e');
    }
    return false;
  }

  // Helper methods

  /// Parse the response body
  dynamic _parseResponse(http.Response response) {
    try {
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return response.body;
    }
  }

  /// Parse error response
  String _parseErrorResponse(http.Response response) {
    try {
      var errorResponse = json.decode(response.body);
      return errorResponse['err'] ?? 'Request failed';
    } catch (e) {
      return 'Request failed';
    }
  }

  /// Convert response to list
  List<Map<String, dynamic>> _convertToList(dynamic response) {
    if (response is List) {
      return response.cast<Map<String, dynamic>>();
    } else {
      return [response as Map<String, dynamic>];
    }
  }

  /// Handle API exceptions
  ApiException _handleApiException(dynamic e, String defaultMessage) {
    return e is ApiException ? e : ApiException(defaultMessage);
  }

  /// Handle errors and return a standardized error response
  Map<String, dynamic> _handleError(dynamic e) {
    if (e is ApiException) {
      return {'success': false, 'error': e.message};
    }
    return {'success': false, 'error': 'An unexpected error occurred'};
  }
}

/// Custom exception class for API errors
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
}