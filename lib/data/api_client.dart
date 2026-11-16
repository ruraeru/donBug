import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 서버 연동 모드가 기본. `--dart-define=DEMO=true` 로 빌드하면 기기 안 데모 데이터로 돈다.
const bool useApi = !bool.fromEnvironment('DEMO');

/// API 주소. 비우면 웹은 페이지와 같은 origin (배포: Caddy 가 /api 를 백엔드로 넘김), 앱은 운영 서버.
const String apiBase = String.fromEnvironment('API_BASE');
const String _appDefaultBase = 'https://donbug.ruraeru.xyz';

/// 서버 에러 응답 `{code, message, details}`.
class ApiException implements Exception {
  ApiException(this.status, this.code, this.message);

  final int status;
  final String code;
  final String message;

  @override
  String toString() => message;
}

/// 백엔드 HTTP 클라이언트. 토큰은 SharedPreferences 에 둔다.
/// 401 이면 refresh 토큰으로 한 번 갱신하고 다시 보낸다. 갱신도 실패하면 토큰을 지우고 [onUnauthorized].
class ApiClient {
  ApiClient({required this.prefs, String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? (apiBase.isNotEmpty ? apiBase : kIsWeb ? Uri.base.origin : _appDefaultBase),
        _http = client ?? http.Client();

  static const _accessKey = 'donbug.access';
  static const _refreshKey = 'donbug.refresh';

  final SharedPreferences prefs;
  final String baseUrl;
  final http.Client _http;

  /// 로그인이 풀렸을 때 (갱신 실패). 화면을 로그인으로 돌린다.
  void Function()? onUnauthorized;

  String? get _access => prefs.getString(_accessKey);
  String? get _refresh => prefs.getString(_refreshKey);
  bool get hasToken => _access != null;

  Future<void> setTokens(String access, String refresh) async {
    await prefs.setString(_accessKey, access);
    await prefs.setString(_refreshKey, refresh);
  }

  Future<void> clearTokens() async {
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }

  /// 웹 카카오 로그인 시작 주소 (브라우저를 이 주소로 보낸다).
  String get kakaoLoginUrl => '$baseUrl/api/auth/kakao/login';

  /// 앱 카카오 로그인 시작 주소. 콜백이 `donbug://auth?access=..&refresh=..` 로 돌아온다.
  String get kakaoAppLoginUrl => '$baseUrl/api/auth/kakao/login?app=true';

  /// 서버 refresh 토큰 폐기 후 로컬 토큰 삭제.
  Future<void> logout() async {
    final r = _refresh;
    // 먼저 지운다: 서버 응답을 기다리는 사이 새로 로그인한 토큰을 지우지 않게.
    await clearTokens();
    if (r != null) {
      try {
        await _send('POST', '/api/auth/logout', {'refreshToken': r}, auth: false);
      } catch (_) {}
    }
  }

  Future<dynamic> get(String path) => _call('GET', path);
  Future<dynamic> post(String path, [Object? body]) => _call('POST', path, body);
  Future<dynamic> put(String path, [Object? body]) => _call('PUT', path, body);
  Future<dynamic> patch(String path, [Object? body]) => _call('PATCH', path, body);
  Future<dynamic> delete(String path) => _call('DELETE', path);

  /// Image.network 처럼 직접 요청할 때 붙이는 인증 헤더.
  Map<String, String> get authHeaders => {if (_access != null) 'Authorization': 'Bearer $_access'};

  /// multipart 업로드 (파일 1개 + 문자열 필드). 401 이면 토큰 갱신 후 한 번 더.
  Future<dynamic> multipart(String method, String path,
      {Map<String, String> fields = const {},
      required String fileField,
      required List<int> bytes,
      required String filename}) async {
    Future<http.Response> send() {
      final req = http.MultipartRequest(method, Uri.parse('$baseUrl$path'))
        ..headers['Accept'] = 'application/json'
        ..fields.addAll(fields)
        ..files.add(http.MultipartFile.fromBytes(fileField, bytes, filename: filename));
      final token = _access;
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      return _http.send(req).then(http.Response.fromStream);
    }

    var res = await send();
    if (res.statusCode == 401 && await _tryRefresh()) res = await send();
    if (res.statusCode == 401) {
      await clearTokens();
      onUnauthorized?.call();
    }
    if (res.statusCode >= 400) throw _error(res);
    if (res.body.isEmpty) return null;
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  Future<dynamic> _call(String method, String path, [Object? body]) async {
    var res = await _send(method, path, body);
    if (res.statusCode == 401 && await _tryRefresh()) {
      res = await _send(method, path, body);
    }
    if (res.statusCode == 401) {
      await clearTokens();
      onUnauthorized?.call();
    }
    if (res.statusCode >= 400) throw _error(res);
    if (res.body.isEmpty) return null;
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  Future<http.Response> _send(String method, String path, Object? body, {bool auth = true}) {
    final req = http.Request(method, Uri.parse('$baseUrl$path'));
    req.headers['Accept'] = 'application/json';
    final token = _access;
    if (auth && token != null) req.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      req.headers['Content-Type'] = 'application/json; charset=utf-8';
      req.body = jsonEncode(body);
    }
    return _http.send(req).then(http.Response.fromStream);
  }

  Future<bool> _tryRefresh() async {
    final r = _refresh;
    if (r == null) return false;
    final res = await _send('POST', '/api/auth/refresh', {'refreshToken': r}, auth: false);
    if (res.statusCode != 200) return false;
    final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    await setTokens(j['accessToken'] as String, j['refreshToken'] as String);
    return true;
  }

  static ApiException _error(http.Response res) {
    try {
      final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return ApiException(res.statusCode, '${j['code'] ?? res.statusCode}',
          '${j['message'] ?? '요청을 처리하지 못했어요'}');
    } catch (_) {
      return ApiException(res.statusCode, '${res.statusCode}',
          res.statusCode == 401 ? '다시 로그인해 주세요' : '서버와 통신하지 못했어요 (${res.statusCode})');
    }
  }
}
