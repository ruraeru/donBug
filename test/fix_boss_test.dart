import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/format.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/data/seed.dart';
import 'package:donbug/screens/employer/shift_add_screen.dart';

import 'widget_test.dart';

AppStore make() {
  final t = DateTime(2026, 5, 14, 14, 30);
  return AppStore(buildSeed(t), now: () => t)..switchRole(Role.employer);
}

String sid(AppStore s, String name) =>
    s.activeStaff.firstWhere((x) => s.personOf(x).name == name).id;

int notes(AppStore s, String title) =>
    s.state.notifications.where((n) => n.title == title).length;

void main() {
  test('removeStaff: 오늘 근무 삭제 · 수락자 퇴사 시 대타 요청 open 복귀', () {
    final s = make();
    final jimin = sid(s, '지민');
    final req = s.pendingSubs.firstWhere((r) => r.acceptedId == jimin);
    s.removeStaff(jimin);
    expect(
        s.state.shifts.where((x) =>
            x.staffId == jimin &&
            !parseYmd(x.date).isBefore(s.today) &&
            s.attendanceFor(x.id) == null),
        isEmpty);
    expect(req.acceptedId, isNull);
    expect(req.status, SubStatus.open);
    expect(req.applicantIds, isNot(contains(jimin)));
  });

  test('removeStaff: 이미 출근한 오늘 근무는 남긴다', () {
    final s = make();
    final me = s.myStaff!;
    final shift = s.myTodayShift!;
    s.switchRole(Role.employee);
    s.clockIn(shift.id);
    s.switchRole(Role.employer);
    s.removeStaff(me.id);
    expect(s.shiftById(shift.id), isNotNull);
  });

  test('deleteShift: 출근 기록 있으면 막고, 없으면 지우고 알바생에게 알림', () {
    final s = make();
    final shift = s.myTodayShift!;
    s.switchRole(Role.employee);
    s.clockIn(shift.id);
    s.switchRole(Role.employer);
    expect(s.deleteShift(shift.id), isFalse);
    expect(s.shiftById(shift.id), isNotNull);

    final other = s.state.shifts.firstWhere(
        (x) => x.id != shift.id && x.isWork && s.attendanceFor(x.id) == null);
    expect(s.deleteShift(other.id), isTrue);
    expect(s.shiftById(other.id), isNull);
    expect(notes(s, '근무가 삭제됐어요'), 1);
  });

  test('updateShift: 시간 바꾸면 알바생에게 알림', () {
    final s = make();
    final shift = s.state.shifts.firstWhere((x) => x.isWork && x.date == '2026-05-15');
    s.updateShift(shift.id, startMin: shift.startMin + 30);
    expect(notes(s, '근무가 수정됐어요'), 1);
  });

  test('대타 알림 푸시 끄면 동료 알림만 빠지고 사장님 알림은 유지', () {
    final s = make();
    s.updateStore(substitutePush: false);
    final before = s.state.notifications.length;
    final shift = s.state.shifts.firstWhere((x) => x.isWork && x.date == '2026-05-16');
    s.requestSubstitute(shift.id, reason: '개인 사정');
    final added = s.state.notifications.skip(before).toList();
    expect(added.length, 1);
    expect(added.single.title, contains('휴무·대타'));
  });

  testWidgets('근무 수정 모드: 수정 · 삭제 버튼', (tester) async {
    final s = employerStore();
    final shift = s.state.shifts.firstWhere((x) => x.isWork && x.date == '2026-05-16');
    await pumpAt(tester, ShiftAddScreen(date: parseYmd(shift.date), shift: shift),
        const Size(390, 844), store: s);
    expect(find.text('근무 수정'), findsOneWidget);
    expect(find.text('근무 삭제'), findsOneWidget);
    await tester.tap(find.text('수정 저장'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('근무 추가: 같은 시간 겹치면 등록 안 됨', (tester) async {
    final s = employerStore();
    final n = s.state.shifts.length;
    await pumpAt(tester, ShiftAddScreen(date: s.today), const Size(390, 844), store: s);
    final today = s.state.shifts.firstWhere((x) => x.isWork && x.date == ymd(s.today));
    await tester.tap(find.text(s.nameOf(today.staffId)).first);
    await tester.pump();
    await tester.tap(find.text('근무 등록'));
    await tester.pump();
    expect(s.state.shifts.length, n);
  });
}
