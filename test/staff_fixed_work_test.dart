import 'dart:convert';

import 'package:donbug/data/api_client.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/data/seed.dart';
import 'package:donbug/screens/web/web_staff_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widget_test.dart' show employerStore, pumpAt, testNow;

/// 직원 상세의 고정 근무(직원 파트가 있는 매장).
void main() {
  void addFlexParts(AppStore s) => s.store.parts
    ..add(PartTemplate('얼리', 300, 960, 1, flex: true, breakMin: 60))
    ..add(PartTemplate('늦은', 840, 1380, 1, flex: true, breakMin: 60));

  Widget editor(String id) => Scaffold(body: SizedBox(width: 520, child: FixedWorkEditor(staffId: id)));
  bool checked(WidgetTester t) => t.widget<Checkbox>(find.byType(Checkbox)).value!;

  testWidgets('직원 파트 없는 매장: 예전 요일별 출퇴근 그대로', (tester) async {
    final store = employerStore();
    await pumpAt(tester, editor(store.flexStaff.single.id), const Size(1440, 900), store: store);
    expect(find.text('고정 근무 요일·시간'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('직원 파트 있는 매장: 고정 근무 없으면 꺼짐, 저장된 시간 있으면 켜짐', (tester) async {
    final store = employerStore();
    addFlexParts(store);
    final jihun = store.flexStaff.single; // 시드: 요일별 출퇴근 있음
    await pumpAt(tester, editor(jihun.id), const Size(1440, 900), store: store);
    expect(find.text('고정 근무 요일·시간'), findsNothing);
    expect(checked(tester), isTrue);
    expect(find.byKey(const ValueKey('fixedDay6')), findsOneWidget);
    expect(find.text('시간 직접 입력'), findsWidgets);

    jihun.workHours = List.filled(7, null);
    await pumpAt(tester, editor(jihun.id), const Size(1440, 900), store: store);
    expect(checked(tester), isFalse);
    expect(find.text('꺼 두면 직원 파트를 돌아가며 맡아요'), findsOneWidget);
    expect(find.byKey(const ValueKey('fixedDay0')), findsNothing);
  });

  testWidgets('켜기 · 월 파트 · 화 시간 → PATCH, 끄기 → 모두 비움', (tester) async {
    final (store, patches) = await tester.runAsync(_remoteStore) as (AppStore, List<Map>);
    addFlexParts(store);
    final jihun = store.flexStaff.single..workHours = List.filled(7, null);
    await pumpAt(tester, editor(jihun.id), const Size(1440, 1200), store: store);

    Future<void> act(Future<void> Function() f) async {
      await tester.runAsync(() async {
        await f();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
    }

    Future<void> pick(int day, String text) async {
      await tester.tap(find.byKey(ValueKey('fixedDay$day')));
      await tester.pumpAndSettle();
      await act(() => tester.tap(find.textContaining(text).last));
    }

    await tester.tap(find.text('고정 근무'));
    await tester.pumpAndSettle();
    expect(checked(tester), isTrue);
    expect(patches, isEmpty); // 켜기만 해서는 바뀐 게 없다

    await pick(0, '얼리');
    await pick(1, '시간 직접 입력');
    final on = patches.last;
    expect(on['fixedParts'], [['얼리'], [], [], [], [], [], []]);
    expect(on['workHours'], [null, {'startMin': 540, 'endMin': 1080}, null, null, null, null, null]);
    final local = store.staffById(jihun.id)!;
    expect([local.fixedParts[0], local.workHours[1]?.startMin], [['얼리'], 540]);

    await act(() => tester.tap(find.text('고정 근무')));
    expect(checked(tester), isFalse);
    final off = patches.last;
    expect(off['fixedParts'], List.filled(7, []));
    expect(off['workHours'], List.filled(7, null));
  });

  testWidgets('고용 형태를 바꾸면 고정 파트를 비워 보낸다', (tester) async {
    final (store, patches) = await tester.runAsync(_remoteStore) as (AppStore, List<Map>);
    final kid = store.activeStaff.firstWhere((s) => !s.kind.flex && s.fixedParts.any((l) => l.isNotEmpty));
    await pumpAt(tester, _launcher(kid.id), const Size(1440, 1200), store: store);
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('직원'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(patches.last, {'kind': 'fulltime', 'fixedParts': List.filled(7, [])});
  });

  for (final w in [1440.0, 1280.0, 1024.0, 800.0]) {
    testWidgets('직원 상세 · 고정 근무 켜짐 넘침 없음 @${w.toInt()}', (tester) async {
      final store = employerStore();
      addFlexParts(store);
      final jihun = store.flexStaff.single
        ..workHours[0] = null
        ..fixedParts[0] = ['얼리'];
      await pumpAt(tester, _launcher(jihun.id), Size(w, 900), store: store);
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('얼리 05:00'), findsOneWidget);
    });
  }
}

Widget _launcher(String staffId) => Scaffold(
    body: Builder(builder: (c) => TextButton(onPressed: () => showStaffSheet(c, staffId), child: const Text('열기'))));

/// 서버 모드 store. /me/state 는 지금 로컬 상태를 돌려주고, PATCH …/staff/… 본문을 모은다.
Future<(AppStore, List<Map>)> _remoteStore() async {
  SharedPreferences.setMockInitialValues({'donbug.access': 't', 'donbug.refresh': 'r'});
  final prefs = await SharedPreferences.getInstance();
  final patches = <Map>[];
  late final AppStore store;
  final mock = MockClient((req) async {
    if (req.url.path == '/api/v1/me/state') {
      return http.Response.bytes(utf8.encode(jsonEncode(store.state.toJson())), 200,
          headers: {'content-type': 'application/json'});
    }
    if (req.method == 'PATCH' && req.url.path.contains('/staff/')) patches.add(jsonDecode(req.body) as Map);
    return http.Response('', 204);
  });
  store = AppStore(buildSeed(testNow), now: () => testNow, api: ApiClient(prefs: prefs, baseUrl: 'http://x', client: mock))
    ..login(Role.employer);
  return (store, patches);
}
