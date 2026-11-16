import 'dart:convert';

import 'package:donbug/data/api_client.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/autoschedule.dart';
import 'package:donbug/data/holidays.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/data/seed.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 5, 14, 14, 30); // 목

AppStore _demo() => AppStore.seeded(now: _now)..login(Role.employer);

void main() {
  test('법정 휴게', () {
    expect(requiredBreak(239), 0);
    expect(requiredBreak(240), 30);
    expect(requiredBreak(480), 60);
    expect(minBreakFor(240), 30);
    expect(minBreakFor(270), 30);
    expect(minBreakFor(540), 60);
    expect(partBreakFor(300), 30);
    expect(partBreakFor(480), 60);
  });

  test('공휴일·영업시간', () {
    expect(isHoliday(DateTime(2026, 5, 5)), isTrue);
    expect(isHoliday(DateTime(2026, 5, 6)), isFalse);
    final st = Store(
        id: 's', name: 'n', address: '', code: '', parts: [], openMin: 480, closeMin: 1320, weekendOpenMin: 600, weekendCloseMin: 1200);
    expect(hoursOn(st, DateTime(2026, 5, 6)), (open: 480, close: 1320)); // 수
    expect(hoursOn(st, DateTime(2026, 5, 9)), (open: 600, close: 1200)); // 토
    expect(hoursOn(st, DateTime(2026, 5, 5)), (open: 600, close: 1200)); // 어린이날(화)
  });

  test('fixedShifts: 알바생은 고른 파트, 직원은 요일별 시간(영업시간 밖 제외)', () {
    final s = _demo();
    final mon = DateTime(2026, 5, 18), wed = DateTime(2026, 5, 20), fri = DateTime(2026, 5, 22);
    final jimin = s.partStaff.firstWhere((m) => s.nameOf(m.id) == '지민');
    final jihun = s.flexStaff.single;
    final out = fixedShifts(s.store, [jimin, jihun], [mon, wed, fri]);
    final byDay = {for (final x in out) '${x.date}/${x.staffId}': x};
    final jm = byDay['2026-05-18/${jimin.id}']!;
    expect([jm.part, jm.startMin, jm.endMin, jm.breakMin], ['오픈', 600, 960, 30]);
    expect(byDay['2026-05-22/${jimin.id}'], isNull); // 금 지민 쉼
    expect(byDay['2026-05-20/${jihun.id}'], isNull); // 수 지훈 쉼
    final jh = byDay['2026-05-18/${jihun.id}']!;
    expect([jh.part, jh.startMin, jh.endMin, jh.breakMin], ['직원', 540, 1080, 60]);
    // 영업시간 밖이면 뺀다
    s.store.closeMin = 1000;
    expect(fixedShifts(s.store, [jihun], [mon]), isEmpty);
    // 날짜·시작 순
    expect(out.map((x) => x.date).toList(), [...out.map((x) => x.date)]..sort());
  });

  test('autofill: 빠진 것만, 연차 날은 안 넣음', () {
    final s = _demo();
    final jimin = s.partStaff.firstWhere((m) => s.nameOf(m.id) == '지민');
    final jihun = s.flexStaff.single;
    final dates = [DateTime(2026, 5, 18), DateTime(2026, 5, 19)];
    final fixed = fixedShifts(s.store, [jimin, jihun], dates);
    expect(fixed.length, 4);
    final existing = [
      Shift(id: '1', storeId: 'x', staffId: jimin.id, date: '2026-05-18', startMin: 600, endMin: 960, part: '오픈'),
      Shift(id: '2', storeId: 'x', staffId: jihun.id, date: '2026-05-19', startMin: 0, endMin: 0, part: '직원', kind: ShiftKind.leave),
    ];
    final add = autofill(existing, fixed);
    expect(add.length, 2);
    expect(add.any((x) => x.staffId == jimin.id && x.date == '2026-05-18'), isFalse);
    expect(add.any((x) => x.staffId == jihun.id && x.date == '2026-05-19'), isFalse);
  });

  test('toPattern/fillMonth: 첫 완전한 주 → 그 달 같은 요일, from 이전은 안 만듦', () {
    // 2026-06: 1일이 월요일 → 첫 완전한 주는 1~7일
    Shift sh(String d, String staff) =>
        Shift(id: d, storeId: 'x', staffId: staff, date: d, startMin: 600, endMin: 960, part: '오픈');
    final shifts = [sh('2026-06-01', 'a'), sh('2026-06-03', 'b'), sh('2026-06-08', 'c')];
    final p = toPattern(shifts, '2026-06');
    expect(p.map((t) => (t.dayIndex, t.staffId)), [(0, 'a'), (2, 'b')]);
    final filled = fillMonth(p, '2026-06', DateTime(2026, 6, 10));
    expect(filled.every((x) => x.date.compareTo('2026-06-10') >= 0), isTrue);
    expect(filled.where((x) => x.staffId == 'a').map((x) => x.date), ['2026-06-15', '2026-06-22', '2026-06-29']);
    expect(filled.where((x) => x.staffId == 'b').length, 3); // 6/10, 17, 24
    // 완전한 주 없음(2026-05: 1일 금 → 첫 월요일 4일, 4~10 완전) / 짧은 달은 없다고 가정 불가 → 빈 입력
    expect(toPattern([], '2026-06'), isEmpty);
  });

  test('데모: generateSchedule 은 고정 근무로 채우고 AI 코멘트, confirm 은 미정이면 409', () async {
    final s = _demo();
    await s.generateSchedule('2026-06', weeklyHolidayPay: HolidayPolicy.minimize, priority: SchedulePriority.cost);
    final m = s.monthSchedule('2026-06')!;
    expect([m.source, m.status, m.aiComment], [ScheduleSource.ai, ScheduleStatus.draft, '데모: AI 없이 고정 근무로 채웠어요']);
    expect(m.priority, SchedulePriority.cost);
    expect(s.state.shifts.where((x) => x.date.startsWith('2026-06')).isNotEmpty, isTrue);
    final tbd = s.state.shifts.firstWhere((x) => x.date.startsWith('2026-06'));
    tbd.timeTbd = true;
    await expectLater(s.confirmMonth('2026-06'), throwsA(isA<ApiException>().having((e) => e.status, 'status', 409)));
    tbd.timeTbd = false;
    await s.confirmMonth('2026-06');
    expect(s.monthSchedule('2026-06')!.status, ScheduleStatus.confirmed);
  });

  test('데모: 템플릿 저장 → 적용 → 삭제, 근무표 삭제', () async {
    final s = _demo();
    await s.createMonthSchedule('2026-06');
    final n = s.state.shifts.where((x) => x.date.startsWith('2026-06')).length;
    expect(n, greaterThan(0));
    await s.saveScheduleTemplate('기본', '2026-06');
    final t = s.templates.single;
    expect(t.shifts, isNotEmpty);
    await s.deleteMonthSchedule('2026-06');
    expect(s.monthSchedule('2026-06'), isNull);
    expect(s.state.shifts.where((x) => x.date.startsWith('2026-06')), isEmpty);
    await s.applyScheduleTemplate(t.id, '2026-06');
    expect(s.monthSchedule('2026-06')!.source, ScheduleSource.template);
    expect(s.state.shifts.where((x) => x.date.startsWith('2026-06')).length, n);
    await s.deleteScheduleTemplate(t.id);
    expect(s.templates, isEmpty);
  });

  test('설정 검증 문구 · 파트 저장(이름 변경 전파)', () async {
    final s = _demo();
    await expectLater(s.updateStoreSettings(openMin: 600, closeMin: 600),
        throwsA(isA<ApiException>().having((e) => e.message, 'm', '평일 영업 종료 시각은 시작 시각보다 늦어야 합니다.')));
    await expectLater(s.updateStoreSettings(weekendOpenMin: 600, weekendCloseMin: 500),
        throwsA(isA<ApiException>().having((e) => e.message, 'm', '주말·공휴일 영업 종료 시각은 시작 시각보다 늦어야 합니다.')));
    await expectLater(s.updateStoreSettings(openMin: 0, closeMin: 1500),
        throwsA(isA<ApiException>().having((e) => e.message, 'm', '영업시간은 24시간을 넘을 수 없습니다.')));
    await s.updateStoreSettings(openMin: 540, sizeMode: SizeMode.under5);
    expect([s.store.openMin, s.store.isSmall, s.store.sizeMode], [540, true, SizeMode.under5]);

    final parts = [for (final p in s.store.parts) p.copy()];
    parts[0].name = '얼리';
    await s.saveParts(parts);
    expect(s.store.parts.first.name, '얼리');
    expect(s.state.shifts.where((x) => x.storeId == s.store.id && x.part == '오픈'), isEmpty);
    expect(s.partStaff.any((m) => m.fixedParts.any((l) => l.contains('얼리'))), isTrue);
    parts[1].name = ' ';
    await expectLater(s.saveParts(parts), throwsA(isA<ApiException>().having((e) => e.message, 'm', '파트 이름을 입력하세요.')));
    parts[1]
      ..name = '미들'
      ..endMin = parts[1].startMin;
    await expectLater(s.saveParts(parts), throwsA(isA<ApiException>().having((e) => e.message, 'm', '미들 종료 시각은 시작 시각보다 늦어야 합니다.')));
    final added = [...s.store.parts.map((p) => p.copy()), PartTemplate('새', 300, 400, 1)];
    await s.saveParts(added);
    expect(s.store.parts.last.id, isNotEmpty);
  });

  test('JSON 왕복: v4 새 필드', () {
    final s = _demo();
    final j = jsonDecode(s.toJson()) as Map<String, dynamic>;
    expect(j['v'], 4);
    final back = AppState.fromJson(j)!;
    final jihun = back.staff.firstWhere((m) => m.kind == StaffKind.manager);
    expect(jihun.workHours[0]!.startMin, 540);
    expect(jihun.workHours[2], isNull);
    expect(back.stores.first.parts.first.id, 'part-open');
    expect(back.stores.first.openMin, 480);
  });

  group('서버 초안 모드', () {
    Future<(AppStore, List<String>, List<Object?>)> setup() async {
      SharedPreferences.setMockInitialValues({'donbug.access': 't', 'donbug.refresh': 'r'});
      final prefs = await SharedPreferences.getInstance();
      final calls = <String>[], bodies = <Object?>[];
      final stateJson = jsonEncode(buildSeed(_now).toJson());
      final mock = MockClient((req) async {
        calls.add('${req.method} ${req.url.path}');
        bodies.add(req.body.isEmpty ? null : jsonDecode(req.body));
        if (req.url.path == '/api/v1/me/state') {
          return http.Response.bytes(utf8.encode(stateJson), 200, headers: {'content-type': 'application/json'});
        }
        if (req.method == 'PUT' && req.url.path.endsWith('/shifts')) {
          return http.Response('{"skipped":[]}', 200);
        }
        return http.Response('', 204);
      });
      final store = AppStore(buildSeed(_now), now: () => _now, api: ApiClient(prefs: prefs, baseUrl: 'http://x', client: mock));
      store.login(Role.employer);
      calls.clear();
      bodies.clear();
      return (store, calls, bodies);
    }

    test('편집은 서버로 안 가고 되돌리기 되며 save 가 PUT 한다', () async {
      final (s, calls, bodies) = await setup();
      s.setScheduleDraft(true);
      final staff = s.partStaff.first;
      s.addShift(date: DateTime(2026, 6, 2), startMin: 600, endMin: 960, part: '오픈', staffIds: [staff.id]);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(calls, isEmpty);
      expect(s.scheduleDirty, isTrue);
      expect(s.canUndo, isTrue);
      s.undo();
      expect(s.state.shifts.where((x) => x.date == '2026-06-02'), isEmpty);
      expect(s.canRedo, isTrue);
      s.redo();
      expect(s.state.shifts.where((x) => x.date == '2026-06-02').length, 1);
      // 서버 id(숫자)가 있는 근무 하나 + 새 근무
      final old = Shift(id: '77', storeId: s.store.id, staffId: staff.id, date: '2026-06-03', startMin: 600, endMin: 960, part: '오픈');
      s.state.shifts.add(old);
      s.updateShift('77', startMin: 660);
      await saveAndCheck(s, calls, bodies);
    });
  });
}

Future<void> saveAndCheck(AppStore s, List<String> calls, List<Object?> bodies) async {
  await s.saveSchedule('2026-06');
  expect(calls.first, 'PUT /api/v1/stores/${s.store.id}/schedules/2026-06/shifts');
  final shifts = ((bodies.first as Map)['shifts'] as List).cast<Map>();
  expect(shifts.length, 2);
  final withId = shifts.firstWhere((x) => x.containsKey('id'));
  expect([withId['id'], withId['startMin']], [77, 660]);
  expect(shifts.firstWhere((x) => !x.containsKey('id'))['date'], '2026-06-02');
  expect(calls.last, 'GET /api/v1/me/state');
  expect(s.scheduleDirty, isFalse);
}
