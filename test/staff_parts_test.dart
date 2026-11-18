import 'dart:convert';

import 'package:donbug/data/api_client.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/autoschedule.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/data/seed.dart';
import 'package:donbug/screens/web/web_common.dart';
import 'package:donbug/screens/web/web_schedule_views.dart';
import 'package:donbug/screens/web/web_settings_screen.dart';
import 'package:donbug/screens/web/web_staff_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widget_test.dart' show employerStore, pumpAt, testNow;

/// 직원 파트(flex)·요일(days) 기능.
void main() {
  test('PartTemplate JSON: 새 키 없으면 기본값, 있으면 읽고 왕복', () {
    final old = PartTemplate.fromJson({'id': 1, 'name': '오픈', 'startMin': 600, 'endMin': 960, 'need': 1});
    expect([old.flex, old.days], [false, PartDays.all]);
    final j = {'id': '7', 'name': '얼리', 'startMin': 420, 'endMin': 960, 'need': 2, 'flex': true, 'days': 'weekend'};
    final p = PartTemplate.fromJson(j);
    expect([p.flex, p.days], [true, PartDays.weekend]);
    final back = PartTemplate.fromJson(p.toJson());
    expect([back.id, back.name, back.flex, back.days, back.startMin], ['7', '얼리', true, PartDays.weekend, 420]);
    expect(PartTemplate.fromJson({...j, 'days': '???'}).days, PartDays.all);
    final c = p.copy();
    expect([c.flex, c.days], [true, PartDays.weekend]);
  });

  test('appliesOn: 평일 · 토요일 · 공휴일', () {
    PartTemplate part(PartDays d) => PartTemplate('x', 600, 900, 1, days: d);
    final wed = DateTime(2026, 5, 20), sat = DateTime(2026, 5, 23), holiday = DateTime(2026, 5, 5); // 어린이날(화)
    expect([wed, sat, holiday].map(part(PartDays.weekday).appliesOn), [true, false, false]);
    expect([wed, sat, holiday].map(part(PartDays.weekend).appliesOn), [false, true, true]);
    expect([wed, sat, holiday].map(part(PartDays.all).appliesOn), [true, true, true]);
  });

  test('settingsError: 알바생·직원 파트 이름이 겹치면 막는다', () {
    String? err(List<PartRow> parts) =>
        settingsError(openMin: 480, closeMin: 1320, weekendOpenMin: 480, weekendCloseMin: 1320, parts: parts);
    final a = PartRow(1, '', '오픈', PartTone.open, 600, 960, 30, 1);
    final b = PartRow(2, '', '오픈 ', PartTone.open, 300, 960, 30, 1, flex: true);
    expect(err([a, b]), contains('파트 이름이 겹쳐요: 오픈'));
    // 직원 파트는 영업 시작(08:00) 전에 시작해도 된다.
    expect(err([a, PartRow(2, '', '얼리', PartTone.open, 300, 960, 30, 1, flex: true)]), isNull);
  });

  test('flexPartShifts: 직원 파트를 직원으로, 파트 이름·자르지 않은 시각·요일대로', () {
    final s = AppStore.seeded(now: testNow)..login(Role.employer);
    s.store.parts.add(PartTemplate('얼리', 300, 960, 1, flex: true, days: PartDays.weekend, breakMin: 60));
    final jihun = s.flexStaff.single;
    final dates = [for (var d = 18; d <= 24; d++) DateTime(2026, 5, d)]; // 월~일
    final out = flexPartShifts(s.store, s.activeStaff, dates, const []);
    expect(out.map((x) => x.date), ['2026-05-23', '2026-05-24']);
    expect(out.map((x) => (x.staffId, x.part, x.startMin, x.endMin, x.breakMin)).toSet(),
        {(jihun.id, '얼리', 300, 960, 60)});
    // 그날 이미 근무가 있는 직원은 빼고, 같은 파트 근무는 필요 인원에 센다.
    final busy = Shift(id: '1', storeId: '', staffId: jihun.id, date: '2026-05-23', startMin: 0, endMin: 0, part: '직원', kind: ShiftKind.off);
    final have = Shift(id: '2', storeId: '', staffId: 'x', date: '2026-05-24', startMin: 300, endMin: 960, part: '얼리');
    expect(flexPartShifts(s.store, s.activeStaff, dates, [busy, have]), isEmpty);
  });

  test('데모 자동 생성: 직원 파트는 직원으로 채우고, 그날 직원 고정 근무는 건너뛴다', () async {
    final s = AppStore.seeded(now: testNow)..login(Role.employer);
    s.store.parts.add(PartTemplate('얼리', 300, 960, 1, flex: true, days: PartDays.weekend));
    final jihun = s.flexStaff.single;
    final p = await s.previewGenerate('2026-05',
        weeklyHolidayPay: HolidayPolicy.allow, priority: SchedulePriority.fairness);
    final early = p.shifts.where((x) => x.part == '얼리').toList();
    expect(early, isNotEmpty);
    expect(early.every((x) => x.staffId == jihun.id && x.startMin == 300 && x.endMin == 960), isTrue);
    final days = early.map((x) => x.date).toSet();
    expect(days.contains('2026-05-16') && days.contains('2026-05-17') && !days.contains('2026-05-18'), isTrue);
    expect(p.shifts.where((x) => x.staffId == jihun.id && x.part == '직원' && days.contains(x.date)), isEmpty);
  });

  test('autoFill(예전 API): 주말 전용 파트는 평일에 안 채우고, 직원 파트는 건너뛴다(서버와 같음)', () {
    final s = AppStore.seeded(now: testNow)..login(Role.employer);
    s.store.parts.add(PartTemplate('주말', 600, 900, 1, days: PartDays.weekend));
    s.store.parts.add(PartTemplate('얼리', 300, 540, 1, flex: true));
    s.autoFill(DateTime(2026, 5, 18));
    final weekend = s.state.shifts.where((x) => x.part == '주말').map((x) => x.date).toSet();
    expect(weekend.difference({'2026-05-23', '2026-05-24'}), isEmpty);
    expect(weekend, isNotEmpty);
    expect(s.state.shifts.where((x) => x.part == '얼리'), isEmpty);
  });

  testWidgets('주말 전용 파트는 평일에 인원 부족이 없고, 직원 파트 이름의 직원 근무는 그 파트에 센다', (tester) async {
    final store = employerStore();
    store.store.parts.add(PartTemplate('주말', 600, 900, 2, days: PartDays.weekend));
    final monday = DateTime(2026, 5, 18);
    await pumpAt(tester, Scaffold(body: SingleChildScrollView(child: PartWeekView(monday: monday, month: DateTime(2026, 5)))),
        const Size(1440, 2400), store: store);
    expect(find.text('인원 부족 0/2'), findsNWidgets(2)); // 토·일만

    store.store.parts.removeLast();
    store.store.parts.add(PartTemplate('얼리', 300, 960, 2, flex: true));
    final jihun = store.flexStaff.single;
    store.state.shifts.removeWhere((x) => x.staffId == jihun.id && x.date == '2026-05-19');
    store.addShift(date: DateTime(2026, 5, 19), startMin: 300, endMin: 960, part: '얼리', staffIds: [jihun.id], breakMin: 60);
    await pumpAt(tester, Scaffold(body: SingleChildScrollView(child: PartWeekView(monday: monday, month: DateTime(2026, 5)))),
        const Size(1440, 2400), store: store);
    expect(find.text('인원 부족 1/2'), findsOneWidget);
    expect(find.text('인원 부족 0/2'), findsNWidgets(6));
    expect(isFlexShift(store, store.scheduleOn(DateTime(2026, 5, 19)).firstWhere((x) => x.part == '얼리')), isFalse);
  });

  testWidgets('알바생 고정 파트 격자에 직원 파트가 없다', (tester) async {
    final store = employerStore();
    store.store.parts.add(PartTemplate('얼리', 300, 960, 1, flex: true));
    final kid = store.activeStaff.firstWhere((s) => !s.kind.flex).id;
    await pumpAt(tester, Scaffold(body: SizedBox(width: 480, child: FixedWorkEditor(staffId: kid))),
        const Size(1440, 900), store: store);
    expect(find.text('오픈'), findsWidgets);
    expect(find.text('얼리'), findsNothing);
  });

  for (final w in [1440.0, 1280.0, 1024.0, 800.0]) {
    testWidgets('매장 설정 · 직원 파트 카드 넘침 없음 @${w.toInt()}', (tester) async {
      final store = employerStore();
      store.store.parts.add(PartTemplate('얼리', 300, 960, 1, flex: true, days: PartDays.weekend));
      await pumpAt(tester, const WebSettingsScreen(), Size(w, 900), store: store);
      expect(tester.takeException(), isNull);
      expect(find.text('직원 근무 파트'), findsOneWidget);
      expect(find.text('주말·공휴일'), findsOneWidget);
    });
  }

  testWidgets('설정: 이름이 다른 카드와 겹치면 저장 못 함', (tester) async {
    await pumpAt(tester, const WebSettingsScreen(), const Size(1440, 1400), store: employerStore());
    await tester.tap(find.byKey(const ValueKey('addFlexPart')));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '새 직원 파트'), '오픈');
    await tester.pumpAndSettle();
    expect(find.textContaining('파트 이름이 겹쳐요: 오픈'), findsOneWidget);
    expect(tester.widget<WebButton>(find.widgetWithText(WebButton, '저장')).onPressed, isNull);
  });

  testWidgets('설정: 직원 파트 추가 · 요일 변경 · 되돌리기 · 저장 → PUT 에 flex/days', (tester) async {
    final (store, puts) = await tester.runAsync(_remoteStore) as (AppStore, List<Map>);
    await pumpAt(tester, const Scaffold(body: WebSettingsScreen()), const Size(1440, 1400), store: store);

    Future<void> addAndPick(String day) async {
      await tester.tap(find.byKey(const ValueKey('addFlexPart')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<PartDays>).last); // 직원 카드는 맨 아래, 줄 하나
      await tester.pumpAndSettle();
      await tester.tap(find.text(day).last);
      await tester.pumpAndSettle();
    }

    await addAndPick('평일');
    expect(find.text('평일'), findsOneWidget);
    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '새 직원 파트'), findsNothing);

    await addAndPick('주말·공휴일');
    await tester.runAsync(() async {
      await tester.tap(find.text('저장'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    final sent = (puts.single['parts'] as List).cast<Map>();
    expect(sent.where((p) => p['flex'] == false && p['days'] == 'all').length, 3);
    final flex = sent.singleWhere((p) => p['flex'] == true);
    expect([flex['name'], flex['days'], flex.containsKey('id')], ['새 직원 파트', 'weekend', false]);
  });
}

/// 서버 모드 store. PUT …/parts 본문을 모은다.
Future<(AppStore, List<Map>)> _remoteStore() async {
  SharedPreferences.setMockInitialValues({'donbug.access': 't', 'donbug.refresh': 'r'});
  final prefs = await SharedPreferences.getInstance();
  final seed = buildSeed(testNow);
  final puts = <Map>[];
  late final AppStore store;
  final mock = MockClient((req) async {
    if (req.url.path == '/api/v1/me/state') {
      final j = seed.toJson()..['session'] = store.state.session.toJson();
      return http.Response.bytes(utf8.encode(jsonEncode(j)), 200, headers: {'content-type': 'application/json'});
    }
    if (req.method == 'PUT' && req.url.path.endsWith('/parts')) puts.add(jsonDecode(req.body) as Map);
    return http.Response('', 204);
  });
  store = AppStore(buildSeed(testNow), now: () => testNow, api: ApiClient(prefs: prefs, baseUrl: 'http://x', client: mock));
  store.login(Role.employer);
  return (store, puts);
}
