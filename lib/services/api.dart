import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const baseApiUrl =  'http://10.0.2.2:8000/api';

class Api {
  final String baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final http.Client _client = http.Client();

  Api({this.baseUrl = baseApiUrl});

  // Authentication methods
  Future<Map<String, dynamic>> signUp({required String email, required String password, required String firstName, required String lastName}) async {
    try {
      final response = await post('/signup/', {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      });

      return {'success': true, 'message': response['msg']};
    } catch (e){
      if (e is ApiException) {
        return {'success': false, 'error': e.message};
      }
      return {'success': false, 'error': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    try {
      final response = await post('/signin/', {
        'email': email,
        'password': password,
      });

      await _storage.write(key: 'access', value: response['access']);
      await _storage.write(key: 'refresh', value: response['refresh']);
      return {'success': true};
    } catch (e) {
      if (e is ApiException) {
        return {'success': false, 'error': e.message};
      }
      return {'success': false, 'error': 'An unexpected error occurred'};
    }

  }

  Future<void> logout() async {
    await _storage.delete(key: 'access');
    await _storage.delete(key: 'refresh');
  }

  // Board operations
  Future<Map<String, dynamic>> fetchBoard({required String boardId}) async {
    return await get('/boards/$boardId');
  }

  Future<Map<String, dynamic>> createBoard({required String name, required DateTime startDate, required DateTime dueDate,  required String description, required String progress, required FileImage pic}) async {
    return await post('/boards/', {
      'name': name,
      'start_date': startDate,
      'due_date': dueDate,
      'description': description,
      'progress': progress,
      'pic': pic,
    });
  }

  Future<Map<String, dynamic>> updateBoard({required String boardId, required Map<String, dynamic> updates}) async {
    return await patch('/boards/$boardId', updates);
  }

  Future<void> deleteBoard({required String boardId}) async {
    final response = await delete('/boards/$boardId');
  }

  // Card operations
  Future<Map<String, dynamic>> fetchCard({required String cardId}) async {
    return await get('/cards/$cardId');
  }

  Future<Map<String, dynamic>> createCard({required String title, required String priority, required DateTime startDate, required DateTime dueDate, required String description, required String board_id, required String status, required List<String> emails}) async {
    return await post('/cards/', {
      'title': title,
      'priority': priority,
      'start_date': startDate,
      'due_date': dueDate,
      'description': description,
      'board': board_id,
      'status': status,
      'emails': emails,
    });
  }

  Future<Map<String, dynamic>> updateCard({required String cardId, required Map<String, dynamic> updates}) async {
    return await put('/cards/$cardId', updates);
  }

  Future<Map<String, dynamic>> updateCardStatus({required String cardId, required String newStatus}) async {
    return await patch('/cards/$cardId', {
      'status': newStatus,
    });
  }

  Future<void> deleteCard({required String cardId}) async {
    final response = await delete('/cards/$cardId');
  }

  // HTTP methods
  Future<dynamic> get(String endpoint) async {
    return await _sendRequest('GET', endpoint);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    return await _sendRequest('POST', endpoint, body: data);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    return await _sendRequest('PUT', endpoint, body: data);
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    return await _sendRequest('PATCH', endpoint, body: data);
  }

  Future<dynamic> delete(String endpoint) async {
    return await _sendRequest('DELETE', endpoint);
  }

  Future<dynamic> _sendRequest(String method, String endpoint, {Map<String, dynamic>? body}) async {
    String? token = await _storage.read(key: 'access');
    var headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    http.Response response;
    var url = Uri.parse('$baseUrl$endpoint');

    try {
      switch (method) {
        case 'GET':
          response = await _client.get(url, headers: headers);
          break;
        case 'POST':
          response = await _client.post(url, headers: headers, body: json.encode(body));
          break;
        case 'PUT':
          response = await _client.put(url, headers: headers, body: json.encode(body));
          break;
        case 'PATCH':
          response = await _client.patch(url, headers: headers, body: json.encode(body));
          break;
        case 'DELETE':
          response = await _client.delete(url, headers: headers);
          break;
        default:
          throw ApiException('Unsupported HTTP method');
      }

      if (response.statusCode == 401) {
        // Token might be expired, try to refresh
        bool refreshed = await _refreshToken();
        if (refreshed) {
          // Retry the original request
          return await _sendRequest(method, endpoint, body: body);
        } else {
          // If refresh failed, clear tokens and throw exception
          await logout();
          throw ApiException('Invalid email or password');
        }
      } else if (response.statusCode >= 200 && response.statusCode < 300) {
        // Try to parse the response as JSON
        try {
          return json.decode(response.body);
        } catch (e) {
          // If parsing fails, return the raw body
          return response.body;
        }
      } else {
        var errorResponse = json.decode(response.body);
        throw ApiException(errorResponse['err'] ?? 'Request failed');
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('An error occurred: $e');
    }
  }

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
      print('Error refreshing token: $e');
    }

    return false;
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
}