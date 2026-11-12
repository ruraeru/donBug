import 'package:donbug/data/app_scope.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/screens/web/web_shell.dart';
import 'package:donbug/screens/web/web_shift_dialog.dart';
import 'package:donbug/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 5, 14, 14, 30);

Future<AppStore> _pump(WidgetTester tester, Size size, Widget home) async {
  final store = AppStore.seeded(now: _now)..switchRole(Role.employer);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AppScope(
      store: store, child: MaterialApp(theme: appTheme, home: home)));
  await tester.pumpAndSettle();
  return store;
}

void main() {
  testWidgets('파트 칸 빈 칸: 그 파트 알바가 기본 구성원, 파트 유지', (tester) async {
    late BuildContext ctx;
    final store = await _pump(tester, const Size(1440, 900),
        Scaffold(body: Builder(builder: (c) { ctx = c; return const SizedBox(); })));
    final day = DateTime(2026, 5, 16);
    showShiftDialog(ctx, date: day, part: '오픈');
    await tester.pumpAndSettle();
    expect(find.textContaining('(매니저)'), findsNothing);
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    final added = store.scheduleOn(day).where((s) => s.part == '오픈');
    expect(added.any((s) => !store.staffById(s.staffId)!.kind.flex), isTrue);
    expect(store.scheduleOn(day).where((s) => s.part == '직원' && s.startMin == 540 && s.endMin == 1080),
        isEmpty);
  });

  testWidgets('일간 보기: 현재 월 밖 날짜 탭은 눌러도 월이 안 바뀐다', (tester) async {
    await _pump(tester, const Size(1440, 900), const WebShell());
    await tester.tap(find.text('근무표').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('일간'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('1주차'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('목 4/30'));
    await tester.pumpAndSettle();
    expect(find.text('근무표 · 2026년 5월'), findsOneWidget);
  });

  testWidgets('폭이 800 경계를 넘어도 근무표 보기 상태가 유지된다', (tester) async {
    await _pump(tester, const Size(1440, 900), const WebShell());
    await tester.tap(find.text('근무표').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('일간'));
    await tester.pumpAndSettle();
    expect(find.textContaining('휴게'), findsWidgets);
    tester.view.physicalSize = const Size(799, 900);
    await tester.pumpAndSettle();
    expect(find.text('월 5/11'), findsOneWidget); // 일간 요일 탭이 남아 있음
    expect(find.text('근무표 · 2026년 5월'), findsOneWidget);
  });

  testWidgets('아이콘 레일에도 데모 초기화 진입이 있다', (tester) async {
    await _pump(tester, const Size(1024, 768), const WebShell());
    expect(find.byTooltip('데모 데이터 초기화'), findsOneWidget);
  });
}
