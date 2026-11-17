import 'dart:convert';

import 'package:donbug/data/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ApiClient> _client(MockClientHandler h) async {
  SharedPreferences.setMockInitialValues({'donbug.access': 'old', 'donbug.refresh': 'r1'});
  return ApiClient(prefs: await SharedPreferences.getInstance(), baseUrl: 'http://x', client: MockClient(h));
}

http.Response _json(int s, Object b) => http.Response(jsonEncode(b), s, headers: {'content-type': 'application/json'});

void main() {
  test('동시 401 은 refresh 를 한 번만 부르고 둘 다 성공한다', () async {
    var refreshes = 0;
    final api = await _client((req) async {
      if (req.url.path == '/api/auth/refresh') {
        refreshes++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return refreshes == 1
            ? _json(200, {'accessToken': 'new', 'refreshToken': 'r2'})
            : _json(401, {'code': 'x', 'message': 'used'});
      }
      return req.headers['Authorization'] == 'Bearer new' ? _json(200, {'ok': true}) : _json(401, {});
    });
    var out = 0;
    api.onUnauthorized = () => out++;
    final r = await Future.wait([api.get('/a'), api.get('/b'), api.get('/c')]);
    expect(r.length, 3);
    expect(refreshes, 1);
    expect(out, 0);
    expect(api.hasToken, true);
  });

  test('refresh 가 502 면 토큰을 지우지 않는다', () async {
    final api = await _client((req) async =>
        req.url.path == '/api/auth/refresh' ? http.Response('bad gateway', 502) : _json(401, {}));
    var out = 0;
    api.onUnauthorized = () => out++;
    await expectLater(api.get('/a'), throwsA(isA<ApiException>()));
    expect(api.hasToken, true);
    expect(out, 0);
  });

  test('refresh 가 401 이면 토큰을 지우고 onUnauthorized', () async {
    final api = await _client((req) async => _json(401, {'code': 'x', 'message': 'no'}));
    var out = 0;
    api.onUnauthorized = () => out++;
    await expectLater(api.get('/a'), throwsA(isA<ApiException>()));
    expect(api.hasToken, false);
    expect(out, 1);
  });

  test('/api/auth/* 의 401 은 세션 만료로 보지 않는다', () async {
    final api = await _client((req) async => _json(401, {'code': 'AUTH', 'message': '로그인 실패'}));
    var out = 0;
    api.onUnauthorized = () => out++;
    await expectLater(api.post('/api/auth/kakao/token', {'accessToken': 'bad'}),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', '로그인 실패')));
    expect(api.hasToken, true);
    expect(out, 0);
  });
}
