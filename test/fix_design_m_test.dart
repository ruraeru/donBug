import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:donbug/screens/employee/employee_shell.dart';
import 'package:donbug/screens/employee/shift_detail_screen.dart';
import 'package:donbug/screens/employer/attendance_screen.dart';
import 'package:donbug/screens/employer/employer_shell.dart';
import 'package:donbug/widgets/common.dart';

import 'widget_test.dart';

void main() {
  testWidgets('근무표 · 근태 · 급여 · 인건비가 같은 PeriodNav 를 쓴다', (tester) async {
    await pumpAt(tester, const EmployerShell(), const Size(390, 844), store: employerStore());
    await tester.tap(find.text('근무표').last);
    await tester.pumpAndSettle();
    expect(find.byType(PeriodNav), findsOneWidget);
    await tester.tap(find.text('인건비').last);
    await tester.pumpAndSettle();
    expect(find.byType(PeriodNav), findsOneWidget);
    await openPage(tester, const AttendanceScreen(), store: employerStore());
    expect(find.byType(PeriodNav), findsOneWidget);
    await pumpAt(tester, const EmployeeShell(), const Size(390, 844));
    await tester.tap(find.text('근무표').last);
    await tester.pumpAndSettle();
    expect(find.byType(PeriodNav), findsOneWidget);
    await tester.tap(find.text('급여').last);
    await tester.pumpAndSettle();
    expect(find.byType(PeriodNav), findsOneWidget);
  });

  testWidgets('큰 글자에서 인건비 막대 차트가 넘치지 않는다', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpAt(tester, const EmployerShell(), const Size(390, 1600), store: employerStore());
    await tester.tap(find.text('인건비').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('급여 내역은 지급 · 공제 카드로 나뉘고 공제는 빨강이 아니다', (tester) async {
    await pumpAt(tester, const EmployeeShell(), const Size(390, 1400));
    await tester.tap(find.text('급여').last);
    await tester.pumpAndSettle();
    expect(find.text('지급 내역'), findsOneWidget);
    expect(find.text('공제 내역'), findsOneWidget);
    expect(find.text('세전 합계'), findsOneWidget);
    expect(find.textContaining('원천징수'), findsOneWidget);
  });

  testWidgets('끝난 근무 상세에는 신청 안내가 없다', (tester) async {
    final store = testStore();
    final past = store.myShifts.firstWhere((s) => store.shiftEnd(s).isBefore(store.now));
    await openPage(tester, ShiftDetailScreen(shiftId: past.id), store: store);
    expect(find.textContaining('근무 2일 전까지'), findsNothing);
  });
}
