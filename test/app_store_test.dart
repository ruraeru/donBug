import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/format.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/data/seed.dart';

/// 시계를 움직일 수 있는 store. 기준: 2026-05-14(수) 14:30.
({AppStore store, void Function(DateTime) setNow}) makeStore() {
  var t = DateTime(2026, 5, 14, 14, 30);
  final store = AppStore(buildSeed(t), now: () => t);
  return (store: store, setNow: (v) => t = v);
}

void main() {
  test('시드: 오늘 내 근무 · 대기 중 대타 2건 · 가입 대기 1명', () {
    final s = makeStore().store;
    expect(s.store.name, '카페 커푸치노');
    expect(s.myStaff, isNotNull);
    expect(s.myTodayShift?.date, '2026-05-14');
    expect(s.pendingSubs.length, 2);
    expect(s.pendingStaff.single.personId, 'p-dohyun');
    expect(s.payslip(s.myStaff!.id, 2026, 5).gross, greaterThan(0));
  });

  test('시드는 어느 날짜·시각에도 만들어진다', () {
    for (var d = 0; d < 35; d++) {
      for (final h in [0, 9, 15, 23]) {
        final t = DateTime(2026, 12, 20 + d, h, 10);
        final s = AppStore(buildSeed(t), now: () => t);
        expect(s.myTodayShift?.date, ymd(s.today), reason: '$t');
        expect(s.laborTotal(t.year, t.month, projected: true), greaterThan(0), reason: '$t');
      }
    }
  });

  test('저장 JSON 왕복', () {
    final s = makeStore().store;
    final json = s.toJson();
    expect(AppStore.load(json).toJson(), json);
    expect(AppStore.load('{broken').state.stores, isNotEmpty);
    // 버전이 다르면 저장본을 버리고 시드로 시작한다.
    final old = (jsonDecode(json) as Map<String, dynamic>)
      ..['v'] = 0
      ..['stores'] = [];
    expect(AppStore.load(jsonEncode(old)).state.stores, isNotEmpty);
  });

  test('출근 → 퇴근', () {
    final m = makeStore();
    final s = m.store;
    final shift = s.myTodayShift!;
    s.clockIn(shift.id);
    expect(s.isWorking, isTrue);
    expect(s.attendanceStatus(shift), AttStatus.working);
    m.setNow(DateTime(2026, 5, 14, 20, 5));
    s.clockOut();
    expect(s.isWorking, isFalse);
    expect(s.attendanceStatus(shift), AttStatus.late); // 14:00 근무에 14:30 출근
    expect(s.lateMinutes(shift), 30);
  });

  test('대타: 신청 → 동료 수락(데모) → 사장님 승인', () {
    final s = makeStore().store;
    final shift = s.myUpcomingShifts.firstWhere((x) => x.date != ymd(s.today));
    final me = s.myStaff!.id;
    final r = s.requestSubstitute(shift.id, reason: '치과 진료');
    expect(s.state.notifications.where((x) => x.toPersonId == ownerPersonId && x.refId == r.id),
        isNotEmpty);

    expect(s.simulatePeerAccept(r.id), isTrue);
    expect(r.status, SubStatus.accepted);
    final substitute = r.acceptedId!;

    s.switchRole(Role.employer);
    s.approveSubstitute(r.id);
    expect(r.status, SubStatus.approved);
    expect(shift.staffId, substitute);
    expect(shift.originalStaffId, me);
    expect(shift.isSubstitute, isTrue);

    s.switchRole(Role.employee);
    expect(s.myShifts.contains(shift), isFalse);
    expect(s.myNotifications.first.title, '대타 요청이 승인됐어요');
  });

  test('대타 거절은 근무자를 바꾸지 않는다', () {
    final s = makeStore().store;
    final r = s.pendingSubs.firstWhere((x) => x.status == SubStatus.accepted);
    final shift = s.shiftById(r.shiftId)!;
    final owner = shift.staffId;
    s.switchRole(Role.employer);
    s.rejectSubstitute(r.id);
    expect(r.status, SubStatus.rejected);
    expect(shift.staffId, owner);
    expect(shift.isSubstitute, isFalse);
  });

  test('매장 코드 가입 신청', () {
    final s = makeStore().store;
    expect(s.requestJoin('cafe-8k2d').$1, JoinResult.alreadyMember);
    expect(s.requestJoin('NOPE1234').$1, JoinResult.notFound);
    s.removeStaff(s.membership(meEmployeePersonId, moaId)!.id);
    final (result, store) = s.requestJoin('MOA27QX');
    expect(result, JoinResult.requested);
    expect(store!.id, moaId);
    expect(s.requestJoin('MOA-27QX').$1, JoinResult.alreadyPending);
  });

  test('공지 발행 → 알바생 확인 → 읽음 수 반영', () {
    final s = makeStore().store;
    s.switchRole(Role.employer);
    final n = s.publishNotice(title: '새 공지', body: '내용');
    expect(n.required, isTrue); // 매장 기본값
    expect(s.unreadStaffOf(n).length, 5);
    s.switchRole(Role.employee);
    s.markNoticeRead(n.id);
    s.switchRole(Role.employer);
    expect(s.unreadStaffOf(n).length, 4);
    expect(s.remindUnread(n.id), 4);
  });

  test('직원 승인 · 내보내기', () {
    final s = makeStore().store;
    s.switchRole(Role.employer);
    final d = s.pendingStaff.single;
    s.approveJoin(d.id, wage: 10500);
    expect(d.active, isTrue);
    expect(s.activeStaff.length, 6);

    final subin = s.activeStaff.firstWhere((x) => s.personOf(x).name == '수빈');
    s.removeStaff(subin.id);
    expect(subin.status, StaffStatus.left);
    expect(s.shiftsOfStaff(subin.id).where((x) => parseYmd(x.date).isAfter(s.today)), isEmpty);
  });

  test('계약서 서명 · 데모 초기화', () {
    final s = makeStore().store;
    expect(s.myStaff!.contract!.signed, isFalse);
    s.signContract();
    expect(s.myStaff!.contract!.signed, isTrue);
    s.login(Role.employee);
    s.resetDemo();
    expect(s.myStaff!.contract!.signed, isFalse);
    expect(s.session.loggedIn, isTrue);
  });
}
