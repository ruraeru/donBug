import 'dart:convert';

import 'package:donbug/data/api_client.dart';
import 'package:donbug/data/app_scope.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/data/seed.dart';
import 'package:donbug/screens/employee/employee_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 5, 14, 14, 30);

Future<(AppStore, List<String>)> _store({int version = AppState.version}) async {
  SharedPreferences.setMockInitialValues({'donbug.access': 'a', 'donbug.refresh': 'r'});
  final prefs = await SharedPreferences.getInstance();
  final calls = <String>[];
  final j = buildSeed(_now).toJson()..['v'] = version;
  final body = utf8.encode(jsonEncode(j));
  final api = ApiClient(
      prefs: prefs,
      baseUrl: 'http://x',
      client: MockClient((req) async {
        calls.add(req.url.path);
        return http.Response.bytes(body, 200);
      }));
  final store = AppStore(buildSeed(_now), now: () => _now, api: api)..login(Role.employee);
  calls.clear();
  return (store, calls);
}

void main() {
  test('앱 버전이 서버와 다르면 한 번만 알린다', () async {
    final (s, _) = await _store(version: AppState.version + 1);
    await s.refreshNow(quiet: true);
    expect(s.remoteError.value, contains('업데이트'));
    s.remoteError.value = null;
    await s.refreshNow(quiet: true);
    expect(s.remoteError.value, isNull);
  });

  testWidgets('알바생 홈을 아래로 당기면 서버에서 다시 읽는다', (t) async {
    final (s, calls) = await _store();
    await t.pumpWidget(AppScope(store: s, child: const MaterialApp(home: EmployeeShell())));
    await t.pump();
    await t.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(calls, contains('/api/v1/me/state'));
  });
}
