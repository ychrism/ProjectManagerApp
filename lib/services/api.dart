import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'navigation.dart';
import 'package:logger/logger.dart';

var baseApiUrl =  defaultTargetPlatform == TargetPlatform.android ? 'http://10.0.2.2:8000/api' : 'http://127.0.0.1:8000/api';
final Logger logger = Logger();

class Api {
  final String baseUrl = baseApiUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final http.Client _client = http.Client();

  Api();

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

    //  String? accessToken = await _storage.read(key: 'access');
    //  String? refreshToken = await _storage.read(key: 'refresh');

    //  logger.i(accessToken);
    //  logger.i(refreshToken);

      return {'success': true};
    } catch (e) {
      if (e is ApiException) {
        return {'success': false, 'error': e.message};
      }
      return {'success': false, 'error': 'An unexpected error occurred'};
    }

  }

  Future<Map<String, dynamic>> getChannelUuid() async {
    try {
      final response = await get('/ws_auth_uuid/');

      return {'success': true, 'uuid': response['uuid']};
    } catch (e) {
      if (e is ApiException) {
        return {'success': false, 'error': e.message};
      }
      return {'success': false, 'error': 'An unexpected error occurred'};
    }

  }

  Future<Map<String, dynamic>> fetchCurrentUser() async {
    try {
      return await get('/users/me/');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to fetch current user');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access');
    await _storage.delete(key: 'refresh');
    await navigationService.replaceTo('/sign-in');
  }

  // Board operations
  Future<List<Map<String, dynamic>>> fetchBoards() async {
    try {
      final response = await get('/boards/');
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      } else {
        throw ApiException('Unexpected response format');
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to fetch boards');
    }
  }

  Future<Map<String, dynamic>> fetchBoardDetails({required int boardId}) async {
    try {
      return await get('/boards/$boardId/');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to fetch board details');
    }
  }

  Future<Map<String, dynamic>> createBoard({required String name, required String startDate, required String dueDate,  required String description, required Map<String, dynamic>? imageData,}) async {
    try {
      var data = {
        'name': name,
        'start_date': startDate,
        'due_date': dueDate,
        'description': description,
        'progress': 0,
      };
      if (imageData != null) {
        if (imageData.containsKey('file')) {
          data['pic'] = imageData['file'];
        }
      }

      final response = await post('/boards/', data);
      return {'success': true};
    } catch (e) {
      if (e is ApiException) {
        return {'success': false, 'error': e.message};
      }
      return {'success': false, 'error': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> updateBoard({required int boardId, required Map<String, dynamic> updates}) async {
    try {
      var data = Map<String, dynamic>.from(updates);

      if (data.containsKey('pic') && data['pic'] is Map<String, dynamic>) {
        var imageData = data['pic'];
        if (imageData.containsKey('file')) {
          // new upload
          data['pic'] = imageData['file'];
        } else {
          // If no new file, remove the 'pic' field
          data.remove('pic');
        }
      }

      final response = await patch('/boards/$boardId/', data);
      return {'success': true};
    } catch (e) {
      if (e is ApiException) {
        return {'success': false, 'error': e.message};
      }
      return {'success': false, 'error': 'An unexpected error occurred'};
    }

  }

  Future<Map<String, dynamic>> deleteBoard({required int boardId}) async {
    try {
      final response = await delete('/boards/$boardId/');
      return {'success': true};
    } catch (e) {
      if (e is ApiException) {
        return {'success': false, 'error': e.message};
      }
      return {'success': false, 'error': 'An unexpected error occurred'};
    }
  }

  // Card operations
  Future<List<Map<String, dynamic>>> fetchCards({required int boardId}) async {
    try {
      final response = await get('/cards/?board=$boardId');
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      } else {
        throw ApiException('Unexpected response format');
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException("Failed to fetch the board's cards");
    }
  }



  Future<Map<String, dynamic>> createCard({required int boardId, required Map<String, dynamic> cardData}) async {
    try {

      var data = Map<String, dynamic>.from(cardData);
      data['board'] = boardId;
      final response = await post('/cards/', data);
      return {'success': true};
    } catch (e) {
      if (e is ApiException) {
        return {'success': false, 'error': e.message};
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateCard({required int cardId, required Map<String, dynamic> updates}) async {
    try {
      var data = Map<String, dynamic>.from(updates);
      //logger.i(data.toString());
      final response = await patch('/cards/$cardId/', data);
      // logger.i(response.toString());
      return {'success': true};
    } catch (e) {
      if (e is ApiException) {
        return {'success': false, 'error': e.message};
      }
      return {'success': false, 'error': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> updateCardStatus({required int cardId, required String newStatus}) async {
    try {
      final response = await patch('/cards/$cardId/', {'status': newStatus});
      return {'success': true};
    } catch (e) {
      if (e is ApiException) {
        return {'success': false, 'error': e.message};
      }
      return {'success': false, 'error': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> deleteCard({required int cardId}) async {
    try {
      final response = await delete('/cards/$cardId/');
      return {'success': true};
    } catch (e) {
      if (e is ApiException) {
        return {'success': false, 'error': e.message};
      }
      return {'success': false, 'error': 'An unexpected error occurred'};
    }
  }


  // Message operations
  Future<List<Map<String, dynamic>>> fetchBoardMessages({required int boardId}) async {
    try {
      final response = await get('/messages/?board=$boardId');
      //logger.i(response);
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      } else {
        throw ApiException('Unexpected response format');
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException("Failed to fetch messages");
    }
  }

  Future<List<Map<String, dynamic>>> fetchLatestMessages() async {
    try {
      final response = await get('/messages/latest_messages/');
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      } else {
        throw ApiException('Unexpected response format');
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException("Failed to fetch latest messages");
    }
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
      'Content-Type': 'application/json; charset=utf-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    var url = Uri.parse('$baseUrl$endpoint');

    try {
      http.Response response;
      if (method != 'GET' && body != null && body.values.any((v) => v is File)) {
        // Handle multipart request for methods with file upload
        var request = http.MultipartRequest(method, url);
        request.headers.addAll(headers);

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
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Handle regular requests
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
      }

      if (response.statusCode == 401) {
        if (endpoint == '/signin/') {
          // For login attempts, just throw the error without logging out
          throw ApiException('Invalid email or password');
        } else {
          // Token might be expired, try to refresh
          bool refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the original request
            return await _sendRequest(method, endpoint, body: body);
          } else {
            await logout();
          }
        }

      } else if (response.statusCode >= 200 && response.statusCode < 300) {
        // Try to parse the response as JSON
        try {
            return json.decode(utf8.decode(response.bodyBytes));
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
      throw ApiException(e.toString());
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
      throw ApiException('Error refreshing token: $e');
    }

    return false;
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
}