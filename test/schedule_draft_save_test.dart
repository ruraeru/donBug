import 'dart:async';
import 'dart:convert';

import 'package:donbug/data/api_client.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/data/seed.dart';
import 'package:donbug/data/app_scope.dart';
import 'package:donbug/screens/web/web_schedule_screen.dart';
import 'package:donbug/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 5, 14, 14, 30);

/// 서버처럼 숫자 id 를 쓰고, PUT /schedules/{month}/shifts 를 그 달 근무로 반영하는 가짜 서버.
/// [hold] 가 있으면 /me/state 응답을 그 future 가 끝날 때까지 늦춘다(느린 새로고침).
Future<(AppStore, List<Object?>)> _setup({Future<void>? Function()? hold}) async {
  SharedPreferences.setMockInitialValues({'donbug.access': 't', 'donbug.refresh': 'r'});
  final prefs = await SharedPreferences.getInstance();
  final seed = buildSeed(_now);
  var next = 1000;
  final server = jsonDecode(jsonEncode(seed.toJson())) as Map<String, dynamic>;
  for (final s in server['shifts'] as List) {
    s['id'] = '${next++}';
  }
  final storeId = seed.stores.first.id;
  (server['schedules'] as List).add({'id': '1', 'storeId': storeId, 'month': '2026-05', 'status': 'draft', 'source': 'manual'});
  final puts = <Object?>[];
  final mock = MockClient((req) async {
    final p = req.url.path;
    if (p == '/api/v1/me/state') {
      final snapshot = jsonEncode(server);
      await hold?.call();
      return http.Response.bytes(utf8.encode(snapshot), 200, headers: {'content-type': 'application/json'});
    }
    if (p == '/unused') {
      return http.Response.bytes(utf8.encode(jsonEncode(server)), 200, headers: {'content-type': 'application/json'});
    }
    final m = RegExp(r'/schedules/(\d{4}-\d{2})/shifts$').firstMatch(p);
    if (req.method == 'PUT' && m != null) {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      puts.add(body);
      final month = m.group(1)!;
      final shifts = server['shifts'] as List;
      shifts.removeWhere((s) => s['storeId'] == storeId && (s['date'] as String).startsWith(month));
      for (final it in body['shifts'] as List) {
        shifts.add({...it as Map, 'id': '${it['id'] ?? next++}', 'storeId': storeId, 'staffId': '${it['staffId']}'});
      }
      return http.Response('{"skipped":[]}', 200, headers: {'content-type': 'application/json'});
    }
    return http.Response('', 204);
  });
  final api = ApiClient(prefs: prefs, baseUrl: 'http://x', client: mock);
  final store = AppStore(buildSeed(_now), now: () => _now, api: api);
  store.login(Role.employer);
  server['session'] = store.state.session.toJson();
  await store.reload();
  return (store, puts);
}

void main() {
  test('초안 편집·삭제 → 저장하면 PUT 에 반영되고 저장 뒤에도 남는다', () async {
    final (s, puts) = await _setup();
    s.setScheduleDraft(true);
    const month = '2026-05';
    final mine = s.state.shifts.where((x) => x.storeId == s.store.id && x.date.startsWith(month) && x.isWork).toList();
    final edit = mine[0], gone = mine[1];
    s.updateShift(edit.id, startMin: 7 * 60, endMin: 11 * 60);
    expect(s.deleteShift(gone.id), isTrue);
    expect(s.scheduleDirty, isTrue);
    await s.saveSchedule(month);

    final body = puts.single as Map;
    final sent = {for (final x in body['shifts'] as List) x['id']: x};
    expect(sent[int.parse(edit.id)]?['startMin'], 420);
    expect(sent[int.parse(edit.id)]?['endMin'], 660);
    expect(sent.containsKey(int.parse(gone.id)), isFalse);

    expect(s.scheduleDirty, isFalse);
    expect(s.shiftById(edit.id)?.startMin, 420);
    expect(s.shiftById(gone.id), isNull);
  });

  // 60초 주기·변경 신호 새로고침(GET /me/state)이 편집 전에 출발해 늦게 도착하는 경우.
  for (final landsAfterSave in [false, true]) {
    test('편집 전에 시작한 새로고침이 늦게 와도 편집을 덮지 않는다 (저장 ${landsAfterSave ? '뒤' : '전'} 도착)', () async {
      Completer<void>? gate;
      final (s, puts) = await _setup(hold: () {
        final g = gate;
        gate = null; // 첫 GET 만 붙잡는다
        return g?.future;
      });
      const month = '2026-05';
      final slow = Completer<void>();
      gate = slow;
      final refresh = s.refreshNow(quiet: true);
      await Future<void>.delayed(Duration.zero);
      s.setScheduleDraft(true);
      final mine = s.state.shifts.where((x) => x.storeId == s.store.id && x.date.startsWith(month) && x.isWork).toList();
      final edit = mine[0], gone = mine[1];
      s.updateShift(edit.id, startMin: 7 * 60, endMin: 11 * 60);
      s.deleteShift(gone.id);
      if (!landsAfterSave) {
        slow.complete();
        await refresh;
        expect(s.shiftById(edit.id)?.startMin, 420);
        expect(s.shiftById(gone.id), isNull);
      }
      await s.saveSchedule(month);
      if (landsAfterSave) {
        slow.complete();
        await refresh;
      }
      final sent = {for (final x in (puts.single as Map)['shifts'] as List) x['id']: x};
      expect(sent[int.parse(edit.id)]?['startMin'], 420);
      expect(sent.containsKey(int.parse(gone.id)), isFalse);
      expect(s.shiftById(edit.id)?.startMin, 420);
      expect(s.shiftById(gone.id), isNull);
    });
  }

  testWidgets('서버 모드 편집기: 편집·삭제 후 저장 버튼 → PUT 반영, 저장 뒤 유지', (t) async {
    final (s, puts) = await _setup();
    t.view.physicalSize = const Size(1440, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(AppScope(
        store: s,
        child: MaterialApp(theme: appTheme, home: const Scaffold(body: WebScheduleScreen(month: '2026-05')))));
    await t.pumpAndSettle();
    final mine = s.state.shifts.where((x) => x.storeId == s.store.id && x.date.startsWith('2026-05') && x.isWork).toList();
    final edit = mine[0], gone = mine[1];
    s.updateShift(edit.id, startMin: 7 * 60, endMin: 11 * 60);
    s.deleteShift(gone.id);
    await t.pumpAndSettle();
    expect(find.text('저장 안 됨'), findsOneWidget);
    await t.tap(find.text('저장').first);
    await t.pumpAndSettle();
    final sent = {for (final x in (puts.single as Map)['shifts'] as List) x['id']: x};
    expect(sent[int.parse(edit.id)]?['startMin'], 420);
    expect(sent.containsKey(int.parse(gone.id)), isFalse);
    expect(s.shiftById(edit.id)?.startMin, 420);
    expect(s.shiftById(gone.id), isNull);
  });
}
