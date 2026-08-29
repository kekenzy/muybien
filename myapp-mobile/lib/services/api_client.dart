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
      throw ApiException(res.statusCode, _errorMessage(res, 'メモの取得に失敗しました'));
    }
    return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createMemo(String title, String content, {DateTime? date}) async {
    final body = <String, dynamic>{
      'title': title,
      'content': content,
      if (date != null) 'date': _ymd(date),
    };
    final res = await _authedRequest('POST', '/lab/memos', body: body);
    if (res.statusCode != 201) {
      throw ApiException(res.statusCode, _errorMessage(res, 'メモの作成に失敗しました'));
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMemo(
    int id,
    String title,
    String content, {
    DateTime? date,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'content': content,
      if (date != null) 'date': _ymd(date),
    };
    final res = await _authedRequest('PATCH', '/lab/memos/$id', body: body);
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, _errorMessage(res, 'メモの更新に失敗しました'));
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> deleteMemo(int id) async {
    final res = await _authedRequest('DELETE', '/lab/memos/$id');
    if (res.statusCode != 204) {
      throw ApiException(res.statusCode, _errorMessage(res, 'メモの削除に失敗しました'));
    }
  }

  Future<List<Map<String, dynamic>>> listDiaries() async {
    final res = await _authedRequest('GET', '/lab/diaries');
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, _errorMessage(res, '日記の取得に失敗しました'));
    }
    return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createDiary(String title, String content, DateTime date) async {
    final res = await _authedRequest('POST', '/lab/diaries', body: {
      'date': _ymd(date),
      'title': title,
      'content': content,
    });
    if (res.statusCode != 201) {
      throw ApiException(res.statusCode, _errorMessage(res, '日記の作成に失敗しました'));
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateDiary(
    int id,
    String title,
    String content,
    DateTime date,
  ) async {
    final res = await _authedRequest('PATCH', '/lab/diaries/$id', body: {
      'date': _ymd(date),
      'title': title,
      'content': content,
    });
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, _errorMessage(res, '日記の更新に失敗しました'));
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> deleteDiary(int id) async {
    final res = await _authedRequest('DELETE', '/lab/diaries/$id');
    if (res.statusCode != 204) {
      throw ApiException(res.statusCode, _errorMessage(res, '日記の削除に失敗しました'));
    }
  }

  Future<List<Map<String, dynamic>>> listTasks() async {
    final res = await _authedRequest('GET', '/lab/tasks');
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, _errorMessage(res, 'タスクの取得に失敗しました'));
    }
    return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createTask(
    String title,
    String description,
    String status, {
    DateTime? dueDate,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'description': description,
      'status': status,
      'due_date': dueDate != null ? _ymd(dueDate) : null,
    };
    final res = await _authedRequest('POST', '/lab/tasks', body: body);
    if (res.statusCode != 201) {
      throw ApiException(res.statusCode, _errorMessage(res, 'タスクの作成に失敗しました'));
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTask(
    int id,
    String title,
    String description,
    String status, {
    DateTime? dueDate,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'description': description,
      'status': status,
      'due_date': dueDate != null ? _ymd(dueDate) : null,
    };
    final res = await _authedRequest('PATCH', '/lab/tasks/$id', body: body);
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, _errorMessage(res, 'タスクの更新に失敗しました'));
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> deleteTask(int id) async {
    final res = await _authedRequest('DELETE', '/lab/tasks/$id');
    if (res.statusCode != 204) {
      throw ApiException(res.statusCode, _errorMessage(res, 'タスクの削除に失敗しました'));
    }
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _errorMessage(http.Response res, String fallback) {
    try {
      final data = jsonDecode(res.body);
      if (data is Map && data['detail'] != null) return '${data['detail']} (${res.statusCode})';
    } catch (_) {}
    return '$fallback (${res.statusCode})';
  }
}
