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

/// 보낸 요청을 `calls` 에 쌓고 /me/state 는 [served] 를 돌려주는 가짜 서버.
Future<(AppStore, List<String>, List<Object?>)> _setup({AppState? served}) async {
  SharedPreferences.setMockInitialValues({'donbug.access': 't', 'donbug.refresh': 'r'});
  final prefs = await SharedPreferences.getInstance();
  final calls = <String>[];
  final bodies = <Object?>[];
  final stateJson = jsonEncode((served ?? buildSeed(_now)).toJson());
  final mock = MockClient((req) async {
    calls.add('${req.method} ${req.url.path}${req.url.hasQuery ? '?${req.url.query}' : ''}');
    bodies.add(req.body.isEmpty ? null : jsonDecode(req.body));
    if (req.url.path == '/api/v1/me/state') {
      return http.Response.bytes(utf8.encode(stateJson), 200,
          headers: {'content-type': 'application/json'});
    }
    if (req.url.path.endsWith('/schedule-plans')) {
      return http.Response('{"planId":"p1"}', 200);
    }
    return http.Response('', 204);
  });
  final api = ApiClient(prefs: prefs, baseUrl: 'http://x', client: mock);
  final store = AppStore(buildSeed(_now), now: () => _now, api: api);
  store.login(Role.employer);
  calls.clear();
  bodies.clear();
  return (store, calls, bodies);
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  test('updateStaff → PATCH wage/deduction 만, 이어서 state 다시 읽음', () async {
    final (s, calls, bodies) = await _setup();
    final staff = s.activeStaff.first;
    s.updateStaff(staff.id, wage: 12000, deduction: Deduction.insurance);
    await _settle();
    expect(calls.first, 'PATCH /api/v1/stores/${staff.storeId}/staff/${staff.id}');
    expect(bodies.first, {'wage': 12000, 'deduction': 'insurance'});
    expect(calls.last, 'GET /api/v1/me/state');
  });

  test('addShift → POST /shifts, 로컬 임시 id 는 reload 로 사라짐', () async {
    final (s, calls, bodies) = await _setup();
    final staff = s.partStaff.first;
    final created = s.addShift(
        date: DateTime(2026, 6, 1),
        startMin: 600,
        endMin: 960,
        part: '오픈',
        staffIds: [staff.id],
        repeatWeeks: 2);
    final tempId = created.first.id;
    await _settle();
    expect(calls.first, 'POST /api/v1/stores/${s.store.id}/shifts');
    final b = bodies.first as Map;
    expect(b['date'], '2026-06-01');
    expect(b['kind'], 'work');
    expect(b['repeatWeeks'], 2);
    expect(s.shiftById(tempId), isNull);
  });

  test('applySchedulePlan → plan 올린 뒤 apply', () async {
    final (s, calls, bodies) = await _setup();
    final plan = s.planSchedule(from: DateTime(2026, 5, 18), to: DateTime(2026, 5, 20), needs: [3, 3, 3]);
    expect(plan.shifts, isNotEmpty);
    s.applySchedulePlan(plan, needs: [3, 3, 3]);
    await _settle();
    final id = s.store.id;
    expect(calls[0], 'POST /api/v1/stores/$id/schedule-plans');
    expect((bodies[0] as Map)['from'], '2026-05-18');
    expect(calls[1], 'POST /api/v1/stores/$id/schedule-plans/p1/apply');
    expect(bodies[1], {'needs': [3, 3, 3]});
  });

  test('publishNotice · markNotificationRead 경로', () async {
    final (s, calls, bodies) = await _setup();
    s.publishNotice(title: 't', body: 'b', category: '중요');
    s.markNotificationRead('7');
    await _settle();
    expect(calls, contains('POST /api/v1/stores/${s.store.id}/notices'));
    expect(bodies.firstWhere((b) => b is Map && b['title'] == 't'),
        {'title': 't', 'body': 'b', 'category': '중요'});
    expect(calls, contains('POST /api/v1/me/notifications/7/read'));
  });

  test('서버 모드에서 데모 전용 동작은 무시', () async {
    final (s, calls, _) = await _setup();
    s.resetDemo();
    s.switchRole(Role.employee);
    expect(s.session.role, Role.employer);
    expect(s.canUndo, isFalse);
    expect(s.simulatePeerAccept('x'), isFalse);
    s.uploadHealthCert(expiry: DateTime(2027), alertDays: [7]);
    expect(s.remoteError.value, '추후 지원 예정이에요');
    await _settle();
    expect(calls, isEmpty);
  });

  test('서버 오류는 remoteError 에 메시지', () async {
    SharedPreferences.setMockInitialValues({'donbug.access': 't'});
    final prefs = await SharedPreferences.getInstance();
    final mock = MockClient((req) async => req.url.path == '/api/v1/me/state'
        ? http.Response(jsonEncode(buildSeed(_now).toJson()), 200)
        : http.Response.bytes(utf8.encode('{"code":"X","message":"안 돼요"}'), 400));
    final s = AppStore(buildSeed(_now),
        now: () => _now, api: ApiClient(prefs: prefs, baseUrl: 'http://x', client: mock));
    s.updateStore(substitutePush: false);
    await _settle();
    expect(s.remoteError.value, '안 돼요');
  });
}
