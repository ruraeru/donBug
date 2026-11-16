import 'dart:convert';

import 'package:donbug/data/api_client.dart';
import 'package:donbug/data/app_scope.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/data/seed.dart';
import 'package:donbug/screens/employee/employee_shell.dart';
import 'package:donbug/screens/employee/role_select_screen.dart';
import 'package:donbug/screens/employer/employer_shell.dart';
import 'package:donbug/screens/web/web_boot.dart';
import 'package:donbug/screens/web/web_shell.dart';
import 'package:donbug/screens/web/web_view_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 5, 14, 14, 30);

/// 폭 [width] 화면에서 서버가 [served] 를 줄 때 [WebBoot] 를 띄운다.
Future<void> _boot(WidgetTester t, double width,
    {AppState? served, String? view}) async {
  t.view.physicalSize = Size(width, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  webMobileFrame.value = false;
  SharedPreferences.setMockInitialValues({
    'donbug.access': 'a',
    'donbug.refresh': 'r',
    'donbug.webView': ?view,
  });
  final prefs = await SharedPreferences.getInstance();
  final body = utf8.encode(jsonEncode((served ?? buildSeed(_now)).toJson()));
  final api = ApiClient(
      prefs: prefs,
      baseUrl: 'http://x',
      client: MockClient((_) async => http.Response.bytes(body, 200)));
  final store = AppStore(buildSeed(_now), now: () => _now, api: api);
  await t.pumpWidget(AppScope(store: store, child: MaterialApp(home: WebBoot(store: store))));
  for (var i = 0; i < 5; i++) {
    await t.pump(const Duration(milliseconds: 300));
  }
}

AppState _employeeOnly() {
  final s = buildSeed(_now);
  s.session
    ..role = Role.employee
    ..ownerStoreId = '';
  return s;
}

void main() {
  testWidgets('폰 폭 사장님 → 모바일 사장님 화면', (t) async {
    await _boot(t, 390, served: buildSeed(_now)..session.role = Role.employer);
    expect(find.byType(EmployerShell), findsOneWidget);
    expect(webMobileFrame.value, isTrue);
  });

  testWidgets('PC 폭 사장님 → 웹 대시보드', (t) async {
    await _boot(t, 1280);
    expect(find.byType(WebShell), findsOneWidget);
  });

  testWidgets('PC 폭 알바생만 → 모바일 알바생 화면', (t) async {
    await _boot(t, 1280, served: _employeeOnly());
    expect(find.byType(EmployeeShell), findsOneWidget);
  });

  testWidgets('폰 폭 매장 없음 → 역할 선택', (t) async {
    final s = buildSeed(_now);
    s.session
      ..ownerStoreId = ''
      ..employeeStoreId = '';
    await _boot(t, 390, served: s);
    expect(find.byType(RoleSelectScreen), findsOneWidget);
  });

  testWidgets('저장값 pc 면 폰 폭이어도 웹 대시보드', (t) async {
    await _boot(t, 390, view: 'pc');
    expect(find.byType(WebShell), findsOneWidget);
  });
}
