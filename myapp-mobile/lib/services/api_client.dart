import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final _storage = const FlutterSecureStorage();
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<void> _saveTokens({String? access, String? refresh}) async {
    if (access != null) await _storage.write(key: _accessKey, value: access);
    if (refresh != null) await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<bool> get isLoggedIn async => await _storage.read(key: _refreshKey) != null;

  Future<void> logout() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  Future<void> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, 'ログインに失敗しました');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await _saveTokens(access: data['access'] as String, refresh: data['refresh'] as String);
  }

  Future<bool> _refreshAccessToken() async {
    final refresh = await _storage.read(key: _refreshKey);
    if (refresh == null) return false;
    final res = await http.post(
      Uri.parse('$apiBaseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refresh}),
    );
    if (res.statusCode != 200) return false;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await _saveTokens(access: data['access'] as String);
    return true;
  }

  Future<http.Response> _authedRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    Future<http.Response> send() async {
      final access = await _storage.read(key: _accessKey);
      final uri = Uri.parse('$apiBaseUrl$path');
      final headers = {
        'Content-Type': 'application/json',
        if (access != null) 'Authorization': 'Bearer $access',
      };
      switch (method) {
        case 'GET':
          return http.get(uri, headers: headers);
        case 'POST':
          return http.post(uri, headers: headers, body: jsonEncode(body));
        case 'PATCH':
          return http.patch(uri, headers: headers, body: jsonEncode(body));
        case 'DELETE':
          return http.delete(uri, headers: headers);
        default:
          throw ArgumentError('unsupported method: $method');
      }
    }

    var res = await send();
    if (res.statusCode == 401 && await _refreshAccessToken()) {
      res = await send();
    }
    return res;
  }

  Future<List<Map<String, dynamic>>> listMemos() async {
    final res = await _authedRequest('GET', '/lab/memos');
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, 'メモの取得に失敗しました');
    }
    return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createMemo(String title, String content) async {
    final res = await _authedRequest('POST', '/lab/memos', body: {'title': title, 'content': content});
    if (res.statusCode != 201) {
      throw ApiException(res.statusCode, 'メモの作成に失敗しました');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMemo(int id, String title, String content) async {
    final res = await _authedRequest('PATCH', '/lab/memos/$id', body: {'title': title, 'content': content});
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, 'メモの更新に失敗しました');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> deleteMemo(int id) async {
    final res = await _authedRequest('DELETE', '/lab/memos/$id');
    if (res.statusCode != 204) {
      throw ApiException(res.statusCode, 'メモの削除に失敗しました');
    }
  }
}
