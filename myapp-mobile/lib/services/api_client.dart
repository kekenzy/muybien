import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../navigation.dart';
import '../screens/login_screen.dart';

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

  /// パスワード再設定メールを送信する（未認証）。登録の有無に関わらず同じメッセージが返る。
  /// メールのリンクは Web の再設定画面（/lab/reset-password）を開く。
  Future<String> requestPasswordReset(String email) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/auth/password-reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    String? detail;
    try {
      detail = (jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>)['detail'] as String?;
    } catch (_) {}
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, detail ?? '送信に失敗しました');
    }
    return detail ?? 'パスワード再設定用のリンクを送信しました。';
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
    if (res.statusCode == 401) {
      if (await _refreshAccessToken()) {
        res = await send();
      } else {
        await _forceLogout();
      }
    }
    return res;
  }

  // アクセス・リフレッシュ両方のトークンが無効な場合、強制ログアウトしてログイン画面に戻す
  Future<void> _forceLogout() async {
    await logout();
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
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

  Future<Map<String, dynamic>> uploadDiaryPhoto(int diaryId, List<int> bytes, String filename) async {
    Future<http.Response> send() async {
      final access = await _storage.read(key: _accessKey);
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBaseUrl/lab/diaries/$diaryId/photos'),
      );
      if (access != null) request.headers['Authorization'] = 'Bearer $access';
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
      final streamed = await request.send();
      return http.Response.fromStream(streamed);
    }

    var res = await send();
    if (res.statusCode == 401 && await _refreshAccessToken()) {
      res = await send();
    }
    if (res.statusCode != 201) {
      throw ApiException(res.statusCode, _errorMessage(res, '写真のアップロードに失敗しました'));
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> deleteDiaryPhoto(int diaryId, int photoId) async {
    final res = await _authedRequest('DELETE', '/lab/diaries/$diaryId/photos/$photoId');
    if (res.statusCode != 204) {
      throw ApiException(res.statusCode, _errorMessage(res, '写真の削除に失敗しました'));
    }
  }

  Future<Map<String, dynamic>> uploadMemoPhoto(int memoId, List<int> bytes, String filename) async {
    Future<http.Response> send() async {
      final access = await _storage.read(key: _accessKey);
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBaseUrl/lab/memos/$memoId/photos'),
      );
      if (access != null) request.headers['Authorization'] = 'Bearer $access';
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
      final streamed = await request.send();
      return http.Response.fromStream(streamed);
    }

    var res = await send();
    if (res.statusCode == 401 && await _refreshAccessToken()) {
      res = await send();
    }
    if (res.statusCode != 201) {
      throw ApiException(res.statusCode, _errorMessage(res, '写真のアップロードに失敗しました'));
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> deleteMemoPhoto(int memoId, int photoId) async {
    final res = await _authedRequest('DELETE', '/lab/memos/$memoId/photos/$photoId');
    if (res.statusCode != 204) {
      throw ApiException(res.statusCode, _errorMessage(res, '写真の削除に失敗しました'));
    }
  }

  Future<List<Map<String, dynamic>>> listTasks() async {
    final res = await _authedRequest('GET', '/lab/tasks');
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, _errorMessage(res, 'タスクの取得に失敗しました'));
    }
    return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getTask(int id) async {
    final res = await _authedRequest('GET', '/lab/tasks/$id');
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, _errorMessage(res, 'タスクの取得に失敗しました'));
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// [fields] は API のフィールド名そのまま（日付は [ymd] で文字列、未設定は null）
  Future<Map<String, dynamic>> createTask(Map<String, dynamic> fields) async {
    final res = await _authedRequest('POST', '/lab/tasks', body: fields);
    if (res.statusCode != 201) {
      throw ApiException(res.statusCode, _errorMessage(res, 'タスクの作成に失敗しました'));
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// 渡したフィールドだけを更新する（PATCH）
  Future<Map<String, dynamic>> updateTask(int id, Map<String, dynamic> fields) async {
    final res = await _authedRequest('PATCH', '/lab/tasks/$id', body: fields);
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

  Future<List<Map<String, dynamic>>> listDailyItems() async {
    final res = await _authedRequest('GET', '/lab/daily-items');
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, _errorMessage(res, 'Daily項目の取得に失敗しました'));
    }
    return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
  }

  /// [fields] は API のフィールド名そのまま（title / color / mark / order / is_active）
  Future<Map<String, dynamic>> createDailyItem(Map<String, dynamic> fields) async {
    final res = await _authedRequest('POST', '/lab/daily-items', body: fields);
    if (res.statusCode != 201) {
      throw ApiException(res.statusCode, _errorMessage(res, 'Daily項目の作成に失敗しました'));
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateDailyItem(int id, Map<String, dynamic> fields) async {
    final res = await _authedRequest('PATCH', '/lab/daily-items/$id', body: fields);
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, _errorMessage(res, 'Daily項目の更新に失敗しました'));
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> deleteDailyItem(int id) async {
    final res = await _authedRequest('DELETE', '/lab/daily-items/$id');
    if (res.statusCode != 204) {
      throw ApiException(res.statusCode, _errorMessage(res, 'Daily項目の削除に失敗しました'));
    }
  }

  Future<List<Map<String, dynamic>>> listDailyChecks(int year, int month) async {
    final res = await _authedRequest('GET', '/lab/daily-checks?year=$year&month=$month');
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, _errorMessage(res, 'Dailyチェックの取得に失敗しました'));
    }
    return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
  }

  /// チェックを反転し、反転後の状態（true=チェック済み）を返す
  Future<bool> toggleDailyCheck(int itemId, DateTime date) async {
    final res = await _authedRequest('POST', '/lab/daily-checks/toggle', body: {
      'item': itemId,
      'date': _ymd(date),
    });
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, _errorMessage(res, 'チェックの更新に失敗しました'));
    }
    return (jsonDecode(res.body) as Map<String, dynamic>)['checked'] as bool;
  }

  /// API に渡す日付文字列（YYYY-MM-DD）
  String ymd(DateTime d) => _ymd(d);

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
