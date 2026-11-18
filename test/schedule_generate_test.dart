import 'dart:convert';

import 'package:donbug/data/api_client.dart';
import 'package:donbug/data/app_scope.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/data/seed.dart';
import 'package:donbug/screens/web/web_schedule_generate.dart';
import 'package:donbug/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 5, 14, 14, 30);

/// generate/preview·apply 를 흉내 내는 가짜 서버. [applyStatus] 로 apply 응답 코드를 바꾼다.
Future<(AppStore, List<String>, List<Object?>)> _setup({int applyStatus = 204}) async {
  SharedPreferences.setMockInitialValues({'donbug.access': 't', 'donbug.refresh': 'r'});
  final prefs = await SharedPreferences.getInstance();
  final seed = buildSeed(_now);
  final staffId = seed.staff.firstWhere((x) => x.storeId == seed.stores.first.id && x.active).id;
  final calls = <String>[], bodies = <Object?>[];
  final stateJson = jsonEncode(seed.toJson());
  final mock = MockClient((req) async {
    calls.add('${req.method} ${req.url.path}');
    bodies.add(req.body.isEmpty ? null : jsonDecode(req.body));
    final p = req.url.path;
    if (p == '/api/v1/me/state') {
      return http.Response.bytes(utf8.encode(stateJson), 200, headers: {'content-type': 'application/json'});
    }
    if (p.endsWith('/generate/preview')) {
      return http.Response.bytes(
          utf8.encode(jsonEncode({
            'planId': 'plan-1',
            'month': '2026-06',
            'shifts': [
              {'staffId': staffId, 'date': '2026-06-01', 'startMin': 540, 'endMin': 900, 'part': '오픈', 'breakMin': 30},
              {'staffId': staffId, 'date': '2026-06-02', 'startMin': 540, 'endMin': 900, 'part': null, 'breakMin': 30},
            ],
            'lines': ['예상 인건비 약 100,000원'],
            'laborCost': 100000,
            'unfilled': [
              {'date': '2026-06-03', 'part': '마감', 'startMin': 1080, 'endMin': 1320, 'missing': 2}
            ],
            'replacing': 37,
          })),
          200,
          headers: {'content-type': 'application/json'});
    }
    if (p.endsWith('/generate/apply') && applyStatus != 204) {
      return http.Response.bytes(
          utf8.encode(jsonEncode({'code': 'PLAN_EXPIRED', 'message': '미리보기가 만료됐어요. 다시 만들어 주세요'})),
          applyStatus,
          headers: {'content-type': 'application/json'});
    }
    return http.Response('', 204);
  });
  final api = ApiClient(prefs: prefs, baseUrl: 'http://x', client: mock);
  final store = AppStore(seed, now: () => _now, api: api)..login(Role.employer);
  return (store, calls, bodies);
}

Future<void> _open(WidgetTester tester, AppStore s, ValueNotifier<String?> result) async {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AppScope(
      store: s,
      child: MaterialApp(
          theme: appTheme,
          home: Scaffold(
              body: Builder(
                  builder: (c) => TextButton(
                      onPressed: () async => result.value = await showGenerateScheduleDialog(c),
                      child: const Text('open')))))));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  test('availHours: JSON 왕복, updateStaff 가 PATCH 에 실어 보낸다', () async {
    final (s, calls, bodies) = await _setup();
    final st = s.partStaff.first;
    final av = [WorkHours(540, 1080), null, null, null, null, null, null];
    s.updateStaff(st.id, availHours: av);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final i = calls.indexOf('PATCH /api/v1/stores/${st.storeId}/staff/${st.id}');
    expect((bodies[i] as Map)['availHours'], [
      {'startMin': 540, 'endMin': 1080},
      null, null, null, null, null, null
    ]);
    final back = Staff.fromJson(jsonDecode(jsonEncode((Staff.fromJson(st.toJson())..availHours = av).toJson())));
    expect(back.availHours.first?.endMin, 1080);
    expect(Staff.fromJson({...st.toJson()}..remove('availHours')).availHours, List.filled(7, null));
  });

  testWidgets('생성 창: 미리보기 → 덮어쓰기 경고 → 적용하면 그 달을 돌려준다', (tester) async {
    final (s, calls, bodies) = await tester.runAsync(_setup) as (AppStore, List<String>, List<Object?>);
    final result = ValueNotifier<String?>(null);
    await _open(tester, s, result);

    await tester.tap(find.text('미리보기'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.byType(GeneratePreviewView), findsOneWidget);
    expect(find.text('새 근무 2건'), findsOneWidget);
    expect(find.text('못 채운 칸 2'), findsOneWidget);
    expect(find.textContaining('6월 작성 중 근무 37건'), findsOneWidget);
    expect(find.textContaining('6/3(수) · 마감 · 18:00 – 22:00 · 2명 부족'), findsOneWidget);
    expect(find.text('· 예상 인건비 약 100,000원'), findsOneWidget);
    final body = bodies[calls.indexWhere((c) => c.endsWith('/generate/preview'))] as Map;
    expect(body, {'month': '2026-06', 'weeklyHolidayPay': 'minimize', 'priority': 'fairness'});

    await tester.tap(find.text('덮어쓰고 적용'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(bodies[calls.indexWhere((c) => c.endsWith('/generate/apply'))], {'planId': 'plan-1'});
    expect(result.value, '2026-06');
    expect(find.byType(GeneratePreviewView), findsNothing);
  });

  testWidgets('생성 창: 적용이 410 이면 메시지와 함께 설정 화면으로', (tester) async {
    final (s, _, _) =
        await tester.runAsync(() => _setup(applyStatus: 410)) as (AppStore, List<String>, List<Object?>);
    final result = ValueNotifier<String?>(null);
    await _open(tester, s, result);
    await tester.tap(find.text('미리보기'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('덮어쓰고 적용'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.byType(GeneratePreviewView), findsNothing);
    expect(find.text('적용 실패: 미리보기가 만료됐어요. 다시 만들어 주세요'), findsOneWidget);
    expect(result.value, isNull);
  });
}
