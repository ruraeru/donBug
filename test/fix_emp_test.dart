import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/seed.dart';
import 'package:donbug/screens/employee/employee_shell.dart';
import 'package:donbug/screens/employee/store_code_screen.dart';
import 'package:donbug/screens/employee/employee_schedule_screen.dart';
import 'widget_test.dart';

({AppStore store, void Function(DateTime) setNow}) make(DateTime start) {
  var t = start;
  return (store: AppStore(buildSeed(t), now: () => t), setNow: (v) => t = v);
}

void main() {
  _overflowMain();
  test('끝난 미출근 근무는 오늘 근무가 아니고 출근도 막는다', () {
    final m = make(DateTime(2026, 5, 14, 21, 0));
    final s = m.store;
    expect(s.myTodayShift, isNull);
    final past = s.myShifts.firstWhere((x) => x.date == '2026-05-14');
    expect(s.clockInBlock(past), isNotNull);
  });

  test('출근은 시작 30분 전부터', () {
    final m = make(DateTime(2026, 5, 14, 8, 0));
    final s = m.store;
    final shift = s.myTodayShift!;
    expect(s.clockInBlock(shift), isNotNull);
    m.setNow(DateTime(2026, 5, 14, 13, 30));
    expect(s.clockInBlock(shift), isNull);
  });

  test('급여 실근무는 소정 시작부터 (5분 일찍 출근해도 같다)', () {
    final m = make(DateTime(2026, 5, 14, 13, 30));
    final s = m.store;
    final shift = s.myTodayShift!;
    s.clockIn(shift.id);
    m.setNow(DateTime(2026, 5, 14, 20, 0));
    final a = s.clockOut()!;
    expect(s.workedMinutes(a), 330); // 14–20시 360분 - 휴게 30분
  });

  test('근무 중에는 매장 전환 불가', () {
    final m = make(DateTime(2026, 5, 14, 14, 30));
    final s = m.store;
    s.clockIn(s.myTodayShift!.id);
    expect(s.switchStore(moaId), isFalse);
    expect(s.session.employeeStoreId, isNot(moaId));
    s.clockOut();
    expect(s.switchStore(moaId), isTrue);
  });

  test('가입 대기 데모 매장: 미가입 코드로 신청 → 대기', () {
    final s = make(DateTime(2026, 5, 14, 14, 30)).store;
    expect(s.requestJoin('BAKE-5TQ1').$1, JoinResult.requested);
    expect(s.requestJoin('bake5tq1').$1, JoinResult.alreadyPending);
  });

  testWidgets('매장 코드 8칸 입력 · 이미 가입한 코드는 안내', (tester) async {
    await pumpAt(tester, const StoreCodeScreen(addMode: true), const Size(390, 800));
    await tester.enterText(find.byType(TextField), 'cafe-8k2d');
    await tester.pump();
    for (final c in 'CAFE8K2D'.split('')) {
      expect(find.text(c), findsWidgets);
    }
    await tester.tap(find.text('가입 신청하기'));
    await tester.pump();
    expect(find.text('이미 가입한 매장이에요'), findsOneWidget);
  });

  testWidgets('로그인 직후 이미 가입한 코드를 넣으면 그 매장 홈으로', (tester) async {
    // 근무 중이면 매장 전환이 막힌다. 시연 영상과 같은 출근 전 시각으로.
    final s = AppStore.seeded(now: DateTime(2026, 5, 14, 13, 55));
    expect(s.isWorking, isFalse);
    await pumpAt(tester, const StoreCodeScreen(), const Size(390, 800), store: s);
    await tester.enterText(find.byType(TextField), 'CAFE-8K2D');
    await tester.pump();
    await tester.tap(find.text('가입 신청하기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(EmployeeShell), findsOneWidget);
  });
}

void _overflowMain() {
  testWidgets('근무표 주 이동 줄: 320 폭 · 글자 1.3배에서도 넘치지 않는다', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpAt(tester, const EmployeeScheduleScreen(), const Size(320, 568));
    expect(tester.takeException(), isNull);
  });
}
