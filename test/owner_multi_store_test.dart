import 'dart:convert';

import 'package:donbug/data/api_client.dart';
import 'package:donbug/data/app_scope.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/data/seed.dart';
import 'package:donbug/screens/web/web_shell.dart';
import 'package:donbug/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 5, 14, 14, 30);

/// 시드에 사장님 소유 매장 하나(`st-two`)를 더 붙인다: 직원 1명·근무 1건·월 근무표·템플릿·공지·대타.
AppState _twoStores() {
  final j = buildSeed(_now).toJson();
  Map<String, dynamic> copy(Map m) => jsonDecode(jsonEncode(m)) as Map<String, dynamic>;
  final cafe = (j['stores'] as List).cast<Map>().firstWhere((s) => s['id'] == 'st-cafe');
  (j['stores'] as List).add(copy(cafe)
    ..['id'] = 'st-two'
    ..['name'] = '두번째 매장'
    ..['code'] = 'TWOO-0002'
    ..['monthlyTotals'] = <String, int>{});
  final staff = (j['staff'] as List).cast<Map>().firstWhere((s) => s['storeId'] == 'st-cafe' && s['status'] == 'active');
  (j['staff'] as List).add(copy(staff)
    ..['id'] = 'm-two'
    ..['storeId'] = 'st-two');
  final shift = (j['shifts'] as List).cast<Map>().firstWhere((s) => s['staffId'] == staff['id']);
  (j['shifts'] as List).add(copy(shift)
    ..['id'] = 's-two'
    ..['storeId'] = 'st-two'
    ..['staffId'] = 'm-two'
    ..['date'] = '2026-05-14');
  for (final k in ['schedules', 'templates', 'notices', 'subs']) {
    final list = j[k] as List;
    if (list.isNotEmpty) list.add(copy(list.first as Map)..['id'] = '$k-two'..['storeId'] = 'st-two');
  }
  return AppState.fromJson(j)!;
}

void main() {
  test('소유 매장 게터는 다른 매장 데이터를 빼고, ownedStores 는 둘 다', () {
    final s = AppStore(_twoStores(), now: () => _now)..switchRole(Role.employer);
    expect(s.ownedStores.map((x) => x.id), containsAll(['st-cafe', 'st-two']));
    bool cafeOnly(Iterable<String> ids) => ids.every((id) => id == 'st-cafe');
    expect(cafeOnly(s.activeStaff.map((x) => x.storeId)), isTrue);
    expect(cafeOnly(s.scheduleOn(_now).map((x) => x.storeId)), isTrue);
    expect(cafeOnly(s.schedules.map((x) => x.storeId)), isTrue);
    expect(cafeOnly(s.templates.map((x) => x.storeId)), isTrue);
    expect(cafeOnly(s.storeNotices.map((x) => x.storeId)), isTrue);
    expect(cafeOnly(s.storeSubs.map((x) => x.storeId)), isTrue);
    final cafeLabor = s.laborTotal(2026, 5);

    expect(s.switchOwnerStore('st-two'), isTrue);
    expect(s.store.id, 'st-two');
    expect(s.activeStaff.map((x) => x.id), ['m-two']);
    expect(s.scheduleOn(_now).map((x) => x.id), ['s-two']);
    expect(s.laborTotal(2026, 5), isNot(cafeLabor));
  });

  test('서버 모드 switchOwnerStore → ?storeId= 로 reload, 다음 실행은 기억한 매장, 로그아웃이면 잊음', () async {
    SharedPreferences.setMockInitialValues({'donbug.access': 't', 'donbug.refresh': 'r'});
    final prefs = await SharedPreferences.getInstance();
    final calls = <String>[];
    final mock = MockClient((req) async {
      calls.add('${req.method} ${req.url.path}${req.url.hasQuery ? '?${req.url.query}' : ''}');
      if (req.url.path == '/api/v1/me/state') {
        final st = _twoStores()..session.role = Role.employer;
        st.session.ownerStoreId = req.url.queryParameters['storeId'] ?? 'st-cafe';
        return http.Response.bytes(utf8.encode(jsonEncode(st.toJson())), 200,
            headers: {'content-type': 'application/json'});
      }
      return http.Response('', 204);
    });
    final api = ApiClient(prefs: prefs, baseUrl: 'http://x', client: mock);
    final s = AppStore(buildSeed(_now), now: () => _now, api: api);
    await s.reload();
    expect(calls.last, 'GET /api/v1/me/state');
    expect(s.store.id, 'st-cafe');

    expect(s.switchOwnerStore('st-two'), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(calls.last, 'GET /api/v1/me/state?storeId=st-two');
    expect(s.store.id, 'st-two');
    expect(prefs.getString(ownerStoreKey), 'st-two');

    // 새로고침·재시작: 첫 reload 가 기억한 매장을 고른다.
    final s2 = AppStore(buildSeed(_now), now: () => _now, api: api);
    await s2.reload();
    expect(calls.last, 'GET /api/v1/me/state?storeId=st-two');
    expect(s2.store.id, 'st-two');

    s2.logout();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(prefs.getString(ownerStoreKey), isNull);
  });

  testWidgets('웹 셸 매장 이름 → 매장 전환 메뉴 → 다른 매장, 대시보드·토스트', (tester) async {
    final store = AppStore(_twoStores(), now: () => _now)..switchRole(Role.employer);
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppScope(
        store: store,
        child: MaterialApp(theme: appTheme, home: const WebShell())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('근무표').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('카페 커푸치노').first);
    await tester.pumpAndSettle();
    expect(find.text('매장 전환'), findsOneWidget);
    expect(find.text('현재'), findsOneWidget);
    expect(find.text('+ 새 매장 추가'), findsNothing); // 데모 모드

    await tester.tap(find.text('두번째 매장'));
    await tester.pumpAndSettle();
    expect(store.store.id, 'st-two');
    expect(find.text('두번째 매장 매장으로 전환했어요'), findsOneWidget);
    expect(find.text('대시보드'), findsWidgets);
    await tester.pump(const Duration(seconds: 5));
  });
}
