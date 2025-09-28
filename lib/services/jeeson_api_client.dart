import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

/// A lightweight client that talks to the jeeson.iptime.org REST API.
class JeesonApiClient {
  JeesonApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  static const String _baseUrl = 'http://jeeson.iptime.org';
  static const Map<String, String> _defaultHeaders = <String, String>{
    'Content-Type': 'application/json; charset=utf-8',
  };

  final http.Client _httpClient;

  Uri _buildUri(String path) {
    return Uri.parse('$_baseUrl$path');
  }

  /// Loads the list of friends from the remote API.
  Future<List<Friend>> fetchFriends() async {
    final http.Response response = await _httpClient.get(_buildUri('/api/friends'));
    _throwIfNotSuccess(response);

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List<dynamic>) {
      throw const FormatException('친구 목록 응답이 올바르지 않습니다.');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Friend.fromJson)
        .toList(growable: false);
  }

  /// Creates a new friend entry on the server and returns the saved entity.
  Future<Friend> addFriend({
    required String code,
    required String name,
    String statusMessage = '',
  }) async {
    final http.Response response = await _httpClient.post(
      _buildUri('/api/friends'),
      headers: _defaultHeaders,
      body: jsonEncode(<String, String>{
        'code': code,
        'name': name,
        'statusMessage': statusMessage,
      }),
    );

    _throwIfNotSuccess(response);
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('친구 추가 응답이 올바르지 않습니다.');
    }

    return Friend.fromJson(decoded);
  }

  /// Loads the list of chat rooms from the remote API.
  Future<List<ChatRoom>> fetchChatRooms() async {
    final http.Response response = await _httpClient.get(_buildUri('/api/chatrooms'));
    _throwIfNotSuccess(response);

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List<dynamic>) {
      throw const FormatException('채팅방 목록 응답이 올바르지 않습니다.');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ChatRoom.fromJson)
        .toList(growable: false);
  }

  /// Creates a new chat room through the API and returns the created room.
  Future<ChatRoom> createChatRoom({
    required String name,
    required String endpoint,
  }) async {
    final http.Response response = await _httpClient.post(
      _buildUri('/api/chatrooms'),
      headers: _defaultHeaders,
      body: jsonEncode(<String, String>{
        'name': name,
        'endpoint': endpoint,
      }),
    );

    _throwIfNotSuccess(response);
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('채팅방 생성 응답이 올바르지 않습니다.');
    }

    return ChatRoom.fromJson(decoded);
  }

  void dispose() {
    _httpClient.close();
  }

  void _throwIfNotSuccess(http.Response response) {
    final int statusCode = response.statusCode;
    if (statusCode < 200 || statusCode >= 300) {
      throw http.ClientException(
        'API 호출이 실패했습니다. (HTTP $statusCode)',
        response.request?.url,
      );
    }
  }
}
