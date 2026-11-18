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

/// [respond] 가 null 을 주면 204. /me/state 는 시드.
Future<(AppStore, List<String>, List<Object?>)> _setup(
    http.Response? Function(http.Request req) respond, {Role role = Role.employer}) async {
  SharedPreferences.setMockInitialValues({'donbug.access': 't', 'donbug.refresh': 'r'});
  final prefs = await SharedPreferences.getInstance();
  final calls = <String>[];
  final bodies = <Object?>[];
  final stateJson = jsonEncode(buildSeed(_now).toJson());
  final mock = MockClient((req) async {
    calls.add('${req.method} ${req.url.path}');
    bodies.add(req.headers['content-type']?.startsWith('application/json') == true ? jsonDecode(req.body) : null);
    if (req.url.path == '/api/v1/me/state') {
      return http.Response.bytes(utf8.encode(stateJson), 200, headers: {'content-type': 'application/json'});
    }
    return respond(req) ?? http.Response('', 204);
  });
  final store = AppStore(buildSeed(_now), now: () => _now, api: ApiClient(prefs: prefs, baseUrl: 'http://x', client: mock));
  store.login(role);
  return (store, calls, bodies);
}

http.Response _json(Object body, int status) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status, headers: {'content-type': 'application/json'});

void main() {
  test('가입 신청: 새 서버 200 result, 예전 서버 404/409 본문 둘 다 읽는다', () async {
    for (final (status, result) in [(200, 'notFound'), (404, 'notFound'), (409, 'alreadyPending')]) {
      final (s, _, _) = await _setup((_) => _json({'result': result, 'store': null}, status), role: Role.employee);
      final (r, _) = await s.requestJoinRemote('ZZZZ-ZZZZ');
      expect(r.name, result);
    }
    final (s, _, _) = await _setup((_) => _json({'code': 'X', 'message': '안 돼요'}, 409), role: Role.employee);
    expect(() => s.requestJoinRemote('ZZZZ-ZZZZ'), throwsA(isA<ApiException>()));
  });

  test('재알림: 1시간 안이면 서버에 안 보내고 막는다, 아니면 서버 sent 를 돌려준다', () async {
    final (s, calls, _) = await _setup((r) => r.url.path.endsWith('/remind') ? _json({'sent': 3}, 200) : null);
    final n = s.storeNotices.first;
    n.remindedAt = _now.subtract(const Duration(minutes: 10)).toIso8601String();
    expect(s.remindWait(n), isNotNull);
    await expectLater(s.remindUnreadRemote(n.id), throwsA(isA<ApiException>()));
    expect(s.remindUnread(n.id), 0);
    expect(calls.where((c) => c.endsWith('/remind')), isEmpty);
    n.remindedAt = _now.subtract(const Duration(hours: 2)).toIso8601String();
    expect(await s.remindUnreadRemote(n.id), 3);
  });

  test('계약서 서명: 본 계약서 id 를 보내고, 409 면 바뀌었다고 알린다', () async {
    final (s, calls, bodies) = await _setup((r) {
      if (r.url.path.endsWith('/me/signatures')) return _json({'signatureUrl': 'u'}, 200);
      if (r.url.path.endsWith('/contract/sign')) return _json({'code': 'CONTRACT_CHANGED', 'message': 'x'}, 409);
      return null;
    }, role: Role.employee);
    final me = s.myStaff!;
    me.contract = Contract(start: '2026-05-01', end: '2027-04-30', wage: 10320, weeklyHours: 20, workDays: '월', id: '6');
    await expectLater(
        s.signContractRemote([1, 2, 3]),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('바뀌었어요'))));
    final i = calls.indexWhere((c) => c.endsWith('/contract/sign'));
    expect((bodies[i] as Map)['contractId'], 6);
  });

  test('파트 이름 중복: 대소문자·전각 무시', () {
    expect(AppStore.partNameKey('Night'), AppStore.partNameKey('night'));
    expect(AppStore.partNameKey('A'), AppStore.partNameKey('Ａ'));
    expect(AppStore.partNameKey('오픈'), isNot(AppStore.partNameKey('마감')));
  });

  test('대타: 시작 지난 요청은 진행 중에서 빠지고, 겹치는 요청은 지원 가능에서 빠진다', () {
    final s = AppStore.seeded(now: _now)..login(Role.employer);
    final r = s.pendingSubs.first;
    final sh = s.shiftById(r.shiftId)!;
    final later = s.shiftStart(sh).add(const Duration(minutes: 1));
    final s2 = AppStore(buildSeed(_now), now: () => later)..login(Role.employer);
    expect(s2.pendingSubs.any((x) => x.id == r.id), isFalse);

    final e = AppStore.seeded(now: _now)..login(Role.employee);
    final open = e.subsAvailableToMe;
    if (open.isNotEmpty) {
      final t = e.shiftById(open.first.shiftId)!;
      e.state.shifts.add(Shift(
          id: 'x-overlap', storeId: t.storeId, staffId: e.myStaff!.id, date: t.date,
          startMin: t.startMin, endMin: t.endMin, part: t.part));
      expect(e.subsAvailableToMe.any((x) => x.id == open.first.id), isFalse);
    }
  });

  test('다른 매장의 열린 출근을 찾고 그 매장으로 퇴근한다', () async {
    final (s, calls, _) = await _setup((_) => null, role: Role.employee);
    final other = s.state.staff.firstWhere(
        (m) => m.personId == s.session.employeeId && m.storeId != s.session.employeeStoreId && m.active);
    final a = Attendance(id: 'a-x', storeId: other.storeId, shiftId: 'none', staffId: other.id, clockIn: _now.toIso8601String());
    s.state.attendance.add(a);
    expect(s.myOpenAttendanceElsewhere?.id, 'a-x');
    s.clockOut(s.myOpenAttendanceElsewhere);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(calls, contains('POST /api/v1/stores/${other.storeId}/attendance/clock-out'));
  });

  test('떠난 매장 알림도 내 알림에 보인다', () {
    final s = AppStore.seeded(now: _now)..login(Role.employee);
    s.state.notifications.add(AppNotification(
        id: 'n-gone', storeId: 'st-gone', toPersonId: s.session.employeeId, type: 'staff',
        title: '퇴사 처리됐어요', createdAt: _now.toIso8601String()));
    expect(s.myNotifications.any((x) => x.id == 'n-gone'), isTrue);
  });
}
