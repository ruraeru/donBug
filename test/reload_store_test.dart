import 'dart:convert';

import 'package:donbug/data/api_client.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/data/seed.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 5, 14, 14, 30);

void main() {
  test('reload 는 지금 매장을 유지하고, 403 이면 매장 지정 없이 다시 읽는다', () async {
    SharedPreferences.setMockInitialValues({'donbug.access': 'a', 'donbug.refresh': 'r'});
    final prefs = await SharedPreferences.getInstance();
    final calls = <String>[];
    final j = buildSeed(_now).toJson();
    // 깨진 행 하나(subs)가 있어도 나머지는 읽힌다.
    (j['subs'] as List).add({'id': 'x'});
    final body = utf8.encode(jsonEncode(j));
    final api = ApiClient(
        prefs: prefs,
        baseUrl: 'http://x',
        client: MockClient((req) async {
          calls.add(req.url.toString());
          if (req.url.queryParameters['storeId'] == 'gone') {
            return http.Response('{"code":"forbidden","message":"no"}', 403);
          }
          return http.Response.bytes(body, 200);
        }));
    final s = AppStore(buildSeed(_now), now: () => _now, api: api)..login(Role.employee);
    await s.reload(); // 서버 상태를 한 번 읽은 뒤부터 session 매장 id 를 보낸다
    s.session.employeeStoreId = 'st-moa';
    calls.clear();
    await s.reload();
    expect(calls.single, 'http://x/api/v1/me/state?storeId=st-moa');
    s.session.employeeStoreId = 'gone';
    calls.clear();
    await s.reload();
    expect(calls, ['http://x/api/v1/me/state?storeId=gone', 'http://x/api/v1/me/state']);
  });

  test('로그인 직후 첫 reload 는 시드 매장 id(st-cafe)를 보내지 않는다', () async {
    SharedPreferences.setMockInitialValues({'donbug.access': 'a', 'donbug.refresh': 'r'});
    final prefs = await SharedPreferences.getInstance();
    final calls = <String>[];
    final body = utf8.encode(jsonEncode(buildSeed(_now).toJson()));
    final api = ApiClient(
        prefs: prefs,
        baseUrl: 'http://x',
        client: MockClient((req) async {
          calls.add(req.url.toString());
          if (req.url.queryParameters.containsKey('storeId')) {
            return http.Response('{"code":"bad_request","message":"bad storeId"}', 400);
          }
          return http.Response.bytes(body, 200);
        }));
    final s = AppStore(buildSeed(_now), now: () => _now, api: api);
    await s.reload();
    expect(calls, ['http://x/api/v1/me/state']);
    // 명시한 매장은 첫 reload 에도 보낸다(매장 만들기·가입 직후).
    final s2 = AppStore(buildSeed(_now), now: () => _now, api: api);
    calls.clear();
    await s2.reload(storeId: '7');
    expect(calls, ['http://x/api/v1/me/state?storeId=7', 'http://x/api/v1/me/state']);
  });
}
