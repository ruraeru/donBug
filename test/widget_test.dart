import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:donbug/data/app_scope.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/main.dart';
import 'package:donbug/screens/employee/employee_shell.dart';
import 'package:donbug/screens/employer/employer_shell.dart';
import 'package:donbug/screens/employer/staff_detail_screen.dart';
import 'package:donbug/screens/web/web_shell.dart';
import 'package:donbug/theme.dart';

/// 테스트 기준 시각: 2026-05-14(수) 14:30 (Figma 화면과 같은 날).
final testNow = DateTime(2026, 5, 14, 14, 30);

AppStore testStore() => AppStore.seeded(now: testNow);

Future<AppStore> pumpAt(WidgetTester tester, Widget home, Size size,
    {AppStore? store}) async {
  final s = store ?? testStore();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
      AppScope(store: s, child: MaterialApp(theme: appTheme, home: home)));
  await tester.pumpAndSettle();
  return s;
}

/// 하단 탭을 하나씩 눌러 모든 탭 루트 화면이 오류·넘침 없이 그려지는지 본다.
Future<void> visitTabs(WidgetTester tester, List<String> labels) async {
  for (final label in labels) {
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: '탭: $label');
  }
}

void main() {
  testWidgets('앱이 로그인 화면으로 시작한다', (tester) async {
    await tester.pumpWidget(MyApp(store: testStore()));
    expect(find.text('카카오로 시작하기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('알바생 탭 화면', (tester) async {
    await pumpAt(tester, const EmployeeShell(), const Size(390, 844));
    await visitTabs(tester, ['근무표', '급여', '공지', 'MY', '홈']);
  });

  testWidgets('사장님 탭 화면', (tester) async {
    await pumpAt(tester, const EmployerShell(), const Size(390, 844));
    await visitTabs(tester, ['근무표', '인건비', '서류', '공지', '홈']);
  });

  testWidgets('대시보드 매장 이름 → 매장 설정', (tester) async {
    await pumpAt(tester, const EmployerShell(), const Size(390, 844));
    await tester.tap(find.text('카페 커푸치노'));
    await tester.pumpAndSettle();
    expect(find.text('매장 설정'), findsOneWidget);
  });

  testWidgets('대타 거절: 취소하면 남고, 확인하면 닫히고 스낵바', (tester) async {
    await pumpAt(tester, const EmployerShell(), const Size(390, 844));
    await tester.tap(find.text('지원자 확인하고 확정'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('거절'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('대타 승인'), findsOneWidget);

    await tester.tap(find.text('거절'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('거절하기'));
    await tester.pumpAndSettle();
    expect(find.text('대타 승인'), findsNothing);
    expect(find.text('대타 요청을 거절했어요'), findsOneWidget);
  });

  testWidgets('직원 상세 내보내기 → 확인 후 닫힘', (tester) async {
    await pumpAt(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const StaffDetailScreen())),
              child: const Text('open'),
            ),
          ),
        ),
        const Size(390, 844));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('매장에서 내보내기'));
    await tester.pumpAndSettle();
    expect(find.text('수빈님을 매장에서 내보낼까요?'), findsOneWidget);
    await tester.tap(find.text('내보내기'));
    await tester.pumpAndSettle();
    expect(find.text('수빈님을 매장에서 내보냈어요'), findsOneWidget);
  });

  testWidgets('웹 셸', (tester) async {
    await pumpAt(tester, const WebShell(), const Size(1440, 1024));
    expect(tester.takeException(), isNull);
  });
}
