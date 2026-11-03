import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:donbug/main.dart';
import 'package:donbug/screens/employee/employee_shell.dart';
import 'package:donbug/screens/employer/employer_shell.dart';
import 'package:donbug/screens/web/web_shell.dart';
import 'package:donbug/theme.dart';

Future<void> pumpAt(WidgetTester tester, Widget home, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: appTheme, home: home));
  await tester.pumpAndSettle();
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
    await tester.pumpWidget(const MyApp());
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

  testWidgets('웹 셸', (tester) async {
    await pumpAt(tester, const WebShell(), const Size(1440, 1024));
    expect(tester.takeException(), isNull);
  });
}
