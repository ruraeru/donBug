import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/screens/employee/employee_shell.dart';
import 'package:donbug/screens/employee/substitute_status_screen.dart';
import 'widget_test.dart';

/// 오늘이 아닌 다가오는 내 근무.
List<Shift> laterShifts(AppStore s) =>
    s.myUpcomingShifts.where((x) => x.date != '2026-05-14').toList();

void main() {
  testWidgets('홈: 내 요청이 없으면 내 대타 요청 카드가 없다', (tester) async {
    await pumpAt(tester, const EmployeeShell(), const Size(390, 1400));
    expect(find.textContaining('내 대타 요청'), findsNothing);
    expect(find.textContaining('건 더 보기'), findsNothing);
  });

  testWidgets('홈: 내 요청 상태가 지원 대기 → 승인 대기 → 승인 완료로 바뀌고, 누르면 현황', (tester) async {
    final store = testStore();
    final r = store.requestSubstitute(laterShifts(store).first.id, reason: '치과 진료');
    await pumpAt(tester, const EmployeeShell(), const Size(390, 1400), store: store);
    expect(find.text('지원 대기'), findsOneWidget);
    expect(find.text('내 대타 요청 · 동료 지원을 기다리고 있어요'), findsOneWidget);

    expect(store.simulatePeerAccept(r.id), isTrue);
    await tester.pumpAndSettle();
    final who = store.nameOf(r.acceptedId);
    expect(find.text('사장님 승인 대기'), findsOneWidget);
    expect(find.text('내 대타 요청 · $who님이 수락했어요'), findsOneWidget);

    // 역할을 바꿨다 돌려 놓는 사이에 그리지 않는다.
    store.switchRole(Role.employer);
    store.approveSubstitute(r.id);
    store.switchRole(Role.employee);
    await tester.pumpAndSettle();
    expect(find.text('승인 완료'), findsOneWidget);
    expect(find.text('내 대타 요청 · $who님 근무로 바뀌었어요'), findsOneWidget);

    await tester.tap(find.text('승인 완료'));
    await tester.pumpAndSettle();
    expect(find.byType(SubstituteStatusScreen), findsOneWidget);
    expect(find.text('사유: 치과 진료'), findsOneWidget); // 내 요청 탭
  });

  testWidgets('홈: 지난 근무·취소한 요청은 안 보이고, 3건 이상이면 더 보기', (tester) async {
    final store = testStore();
    final past = store.myShifts.firstWhere((x) => store.shiftEnd(x).isBefore(store.now));
    store.requestSubstitute(past.id, reason: '지난 근무');
    final later = laterShifts(store);
    expect(later.length, greaterThanOrEqualTo(4));
    final cancelled = store.requestSubstitute(later[3].id, reason: '취소함');
    store.cancelSubstitute(cancelled.id);
    for (final s in later.take(3)) {
      store.requestSubstitute(s.id, reason: '개인 사정');
    }
    await pumpAt(tester, const EmployeeShell(), const Size(390, 1400), store: store);
    expect(find.textContaining('내 대타 요청 ·'), findsNWidgets(2));
    expect(find.text('내 요청 1건 더 보기'), findsOneWidget);

    await tester.tap(find.text('내 요청 1건 더 보기'));
    await tester.pumpAndSettle();
    expect(find.byType(SubstituteStatusScreen), findsOneWidget);
  });

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    testWidgets('홈: 내 요청 카드 넘침 없음 ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      final store = testStore();
      final later = laterShifts(store);
      final a = store.requestSubstitute(later[0].id, reason: '개인 사정');
      store.simulatePeerAccept(a.id);
      store.requestSubstitute(later[1].id, reason: '개인 사정');
      store.requestSubstitute(later[2].id, reason: '개인 사정');
      await pumpAt(tester, const EmployeeShell(), size, store: store);
      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pumpAndSettle();
      }
      expect(find.text('내 요청 1건 더 보기'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
