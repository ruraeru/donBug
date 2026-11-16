import 'dart:convert';

import 'package:donbug/data/api_client.dart';
import 'package:donbug/data/app_scope.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/data/seed.dart';
import 'package:donbug/screens/employee/join_pending_screen.dart';
import 'package:donbug/screens/employee/login_screen.dart';
import 'package:donbug/screens/employee/role_select_screen.dart';
import 'package:donbug/screens/mobile_boot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 5, 14, 14, 30);

/// 서버가 [served] 를 /me/state 로 주는 상태에서 [MobileBoot] 를 띄운다.
Future<void> _boot(WidgetTester t, {AppState? served, bool token = true}) async {
  SharedPreferences.setMockInitialValues(
      token ? {'donbug.access': 'a', 'donbug.refresh': 'r'} : {});
  final prefs = await SharedPreferences.getInstance();
  final body = utf8.encode(jsonEncode((served ?? buildSeed(_now)).toJson()));
  final api = ApiClient(
      prefs: prefs,
      baseUrl: 'http://x',
      client: MockClient((_) async => http.Response.bytes(body, 200)));
  final store = AppStore(buildSeed(_now), now: () => _now, api: api);
  await t.pumpWidget(AppScope(store: store, child: const MaterialApp(home: MobileBoot())));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('토큰 없음 → 로그인', (t) async {
    await _boot(t, token: false);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('매장 없음 → 역할 선택', (t) async {
    final s = buildSeed(_now);
    s.session
      ..employeeStoreId = ''
      ..ownerStoreId = '';
    await _boot(t, served: s);
    expect(find.byType(RoleSelectScreen), findsOneWidget);
  });

  testWidgets('가입 대기 알바생 → 승인 대기 화면', (t) async {
    final s = buildSeed(_now);
    s.session.role = Role.employee;
    s.staff
        .firstWhere((m) => m.personId == s.session.employeeId && m.storeId == s.session.employeeStoreId)
        .status = StaffStatus.pending;
    await _boot(t, served: s);
    expect(find.byType(JoinPendingScreen), findsOneWidget);
    expect(find.text('사장님이 승인한 것으로 (데모)'), findsNothing);
  });
}
