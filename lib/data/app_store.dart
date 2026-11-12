import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'format.dart';
import 'models.dart';
import 'payroll.dart';
import 'seed.dart';

/// 출근 상태 (근태 현황용).
enum AttStatus { waiting, working, normal, late, absent }

/// 매장 코드로 가입 신청한 결과.
enum JoinResult { requested, alreadyMember, alreadyPending, notFound }

/// 근무표 만들기 미리보기. [AppStore.planSchedule] 이 만들고 [AppStore.applySchedulePlan] 이 반영한다.
class SchedulePlan {
  SchedulePlan({
    required this.from,
    required this.to,
    required this.shifts,
    required this.unfilled,
    required this.minutesByStaff,
    required this.cost,
  });

  /// 만들 범위(양 끝 포함, 날짜만).
  final DateTime from, to;

  /// 새로 추가할 근무(id 비어 있음). 기존 근무는 건드리지 않는다.
  final List<Shift> shifts;

  /// 사람이 모자라 못 채운 칸 수(파트 × 날짜 × 필요 인원 기준).
  final int unfilled;

  /// 직원 id → 범위 안 총 근무 분(기존 + 새 근무).
  final Map<String, int> minutesByStaff;

  /// 새 근무의 예상 인건비(원, 기본급 기준).
  final int cost;
}

/// 앱 전체 상태 + 액션. 화면은 [AppScope]로 받아 쓴다.
///
/// 액션마다 상태를 바꾸고 [notifyListeners] 후 [onSave]로 JSON 을 넘긴다.
class AppStore extends ChangeNotifier {
  AppStore(this.state, {this.onSave, DateTime Function()? now})
      : _now = now ?? DateTime.now;

  factory AppStore.seeded({DateTime? now, void Function(String)? onSave}) {
    final clock = now == null ? DateTime.now : () => now;
    return AppStore(buildSeed(clock()), onSave: onSave, now: clock);
  }

  /// 저장된 JSON 을 읽는다. 없거나 깨졌거나 버전이 다르면 시드.
  factory AppStore.load(String? json, {void Function(String)? onSave}) {
    AppState? s;
    if (json != null) {
      try {
        s = AppState.fromJson(jsonDecode(json) as Map<String, dynamic>);
      } catch (_) {
        s = null;
      }
    }
    return AppStore(s ?? buildSeed(DateTime.now()), onSave: onSave);
  }

  AppState state;
  final void Function(String json)? onSave;
  final DateTime Function() _now;

  DateTime get now => _now();
  DateTime get today => dayOf(now);

  String toJson() => jsonEncode(state.toJson());

  void _commit() {
    notifyListeners();
    onSave?.call(toJson());
  }

  String _id(String prefix) => '$prefix${state.nextId++}';
  String _iso(DateTime t) => t.toIso8601String();

  // ───────────────────────── 조회 ─────────────────────────

  Session get session => state.session;
  Role get role => session.role;
  Person get me => person(session.meId);
  Store get store => storeById(session.storeId)!;

  Person person(String id) => state.persons.firstWhere((p) => p.id == id);
  Store? storeById(String id) =>
      state.stores.where((s) => s.id == id).firstOrNull;
  Staff? staffById(String? id) =>
      state.staff.where((s) => s.id == id).firstOrNull;
  Shift? shiftById(String? id) =>
      state.shifts.where((s) => s.id == id).firstOrNull;
  SubstituteRequest? subById(String? id) =>
      state.subs.where((s) => s.id == id).firstOrNull;
  Notice? noticeById(String? id) =>
      state.notices.where((n) => n.id == id).firstOrNull;
  Attendance? attendanceById(String? id) =>
      state.attendance.where((a) => a.id == id).firstOrNull;

  /// 직원 이름(짧은 이름).
  String nameOf(String? staffId) {
    final s = staffById(staffId);
    return s == null ? '-' : person(s.personId).name;
  }

  Person personOf(Staff s) => person(s.personId);

  Staff? membership(String personId, String storeId) => state.staff
      .where((s) =>
          s.personId == personId &&
          s.storeId == storeId &&
          s.status != StaffStatus.rejected &&
          s.status != StaffStatus.left)
      .firstOrNull;

  /// 현재 매장에서의 나(알바생 역할일 때).
  Staff? get myStaff => membership(session.employeeId, session.employeeStoreId);

  /// 알바생이 재직 중인 매장들.
  List<Staff> get myMemberships => state.staff
      .where((s) => s.personId == session.employeeId && s.active)
      .toList();

  List<Staff> get activeStaff => state.staff
      .where((s) => s.storeId == store.id && s.active)
      .toList();

  List<Staff> get pendingStaff => state.staff
      .where((s) => s.storeId == store.id && s.status == StaffStatus.pending)
      .toList();

  DateTime shiftStart(Shift s) =>
      parseYmd(s.date).add(Duration(minutes: s.startMin));
  DateTime shiftEnd(Shift s) => parseYmd(s.date).add(Duration(minutes: s.endAbs));

  int _byStart(Shift a, Shift b) => shiftStart(a).compareTo(shiftStart(b));

  /// 그날 실제 근무([Shift.isWork])만. 출근·근태·급여·대타는 모두 이것을 쓴다.
  List<Shift> shiftsOn(DateTime day, {String? storeId}) =>
      scheduleOn(day, storeId: storeId).where((s) => s.isWork).toList();

  /// [staffId]의 실제 근무만.
  List<Shift> shiftsOfStaff(String staffId) =>
      scheduleOfStaff(staffId).where((s) => s.isWork).toList();

  /// 근무표 표시용: 연차·휴무·시간 미정까지 모두.
  List<Shift> scheduleOn(DateTime day, {String? storeId}) => state.shifts
      .where((s) => s.storeId == (storeId ?? store.id) && s.date == ymd(day))
      .toList()
    ..sort(_byStart);

  List<Shift> scheduleOfStaff(String staffId) =>
      state.shifts.where((s) => s.staffId == staffId).toList()..sort(_byStart);

  /// 그 달 시간 미정 근무 수.
  int tbdCount(int year, int month) => state.shifts
      .where((s) =>
          s.storeId == store.id && s.timeTbd && s.date.startsWith(ym(DateTime(year, month))))
      .length;

  /// 유동 근무(매니저·정직원) / 파트 근무(알바·연소자) 재직자.
  List<Staff> get flexStaff => activeStaff.where((s) => s.kind.flex).toList();
  List<Staff> get partStaff => activeStaff.where((s) => !s.kind.flex).toList();

  List<Shift> get myShifts {
    final m = myStaff;
    return m == null ? [] : shiftsOfStaff(m.id);
  }

  /// 오늘 내 근무 (끝나지 않은 것 우선).
  Shift? get myTodayShift {
    // 종료 시각이 지났는데 출근 기록이 없는 근무는 오늘 근무로 치지 않는다.
    final list = myShifts
        .where((s) =>
            s.date == ymd(today) &&
            (attendanceFor(s.id) != null || !shiftEnd(s).isBefore(now)))
        .toList();
    return list.where((s) => attendanceFor(s.id)?.clockOut == null).firstOrNull ??
        list.firstOrNull;
  }

  /// 출근은 시작 30분 전부터. 막힐 때 안내 문구, 가능하면 null.
  String? clockInBlock(Shift s) {
    if (shiftEnd(s).isBefore(now)) return '근무 시간이 지나 출근할 수 없어요';
    if (now.isBefore(shiftStart(s).subtract(const Duration(minutes: 30)))) {
      return '근무 시작 30분 전부터 출근할 수 있어요';
    }
    return null;
  }

  List<Shift> get myUpcomingShifts => myShifts
      .where((s) => !shiftEnd(s).isBefore(now) && attendanceFor(s.id) == null)
      .toList();

  Attendance? attendanceFor(String shiftId) =>
      state.attendance.where((a) => a.shiftId == shiftId).firstOrNull;

  /// 지금 근무 중인 내 출근 기록.
  Attendance? get myOpenAttendance {
    final m = myStaff;
    if (m == null) return null;
    return state.attendance
        .where((a) => a.staffId == m.id && a.clockOut == null)
        .firstOrNull;
  }

  bool get isWorking => myOpenAttendance != null;

  AttStatus attendanceStatus(Shift s) {
    final a = attendanceFor(s.id);
    if (a == null) {
      return shiftEnd(s).isBefore(now) ? AttStatus.absent : AttStatus.waiting;
    }
    if (a.clockOut == null) return AttStatus.working;
    return lateMinutes(s) > 0 ? AttStatus.late : AttStatus.normal;
  }

  int lateMinutes(Shift s) {
    final a = attendanceFor(s.id);
    if (a == null) return 0;
    final d = DateTime.parse(a.clockIn).difference(shiftStart(s)).inMinutes;
    return d > 0 ? d : 0;
  }

  /// 급여는 소정 시작과 출근 중 늦은 쪽부터 계산한다(일찍 찍어도 부풀지 않음).
  DateTime _paidStart(Attendance a, Shift? s) {
    final inAt = DateTime.parse(a.clockIn);
    if (s == null) return inAt;
    final start = shiftStart(s);
    return inAt.isBefore(start) ? start : inAt;
  }

  /// 실근무 분(휴게 제외). 근무 중이면 지금까지.
  int workedMinutes(Attendance a) {
    final s = shiftById(a.shiftId);
    final end = a.clockOut == null ? now : DateTime.parse(a.clockOut!);
    return WorkEntry(
      start: _paidStart(a, s),
      end: end,
      breakMin: a.clockOut == null ? 0 : (s?.breakMin ?? 0),
    ).minutes;
  }

  /// 그날 일급(기본급만, 주휴·공제 제외).
  int dayPay(Attendance a) => payFor(workedMinutes(a), staffById(a.staffId)!.wage);

  /// 예정 근무를 다 했을 때의 일급.
  int plannedPay(Shift s) => payFor(s.scheduledMinutes, staffById(s.staffId)!.wage);

  /// 예정 퇴근보다 늦게 퇴근한 분.
  int overtimeMinutes(Attendance a) {
    final s = shiftById(a.shiftId);
    if (s == null || a.clockOut == null) return 0;
    final d = DateTime.parse(a.clockOut!).difference(shiftEnd(s)).inMinutes;
    return d > 0 ? d : 0;
  }

  /// 대타 요청 중인 근무인지 (진행 중 요청).
  SubstituteRequest? pendingSubFor(String shiftId) =>
      state.subs.where((r) => r.shiftId == shiftId && r.pending).firstOrNull;

  List<SubstituteRequest> get storeSubs =>
      state.subs.where((r) => r.storeId == store.id).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<SubstituteRequest> get pendingSubs =>
      storeSubs.where((r) => r.pending).toList();

  /// 내가 지원할 수 있는 동료 요청.
  List<SubstituteRequest> get subsAvailableToMe {
    final m = myStaff;
    if (m == null) return [];
    return storeSubs
        .where((r) =>
            r.status == SubStatus.open &&
            r.requesterId != m.id &&
            !r.applicantIds.contains(m.id) &&
            shiftById(r.shiftId) != null &&
            shiftStart(shiftById(r.shiftId)!).isAfter(now))
        .toList();
  }

  List<SubstituteRequest> get mySubs {
    final m = myStaff;
    if (m == null) return [];
    return storeSubs.where((r) => r.requesterId == m.id).toList();
  }

  /// 같은 시간대에 이미 근무가 있는지.
  Shift? overlappingShift(String staffId, Shift target) {
    final s0 = shiftStart(target), e0 = shiftEnd(target);
    return shiftsOfStaff(staffId)
        .where((s) =>
            s.id != target.id &&
            shiftStart(s).isBefore(e0) &&
            shiftEnd(s).isAfter(s0))
        .firstOrNull;
  }

  List<Notice> get storeNotices =>
      state.notices.where((n) => n.storeId == store.id).toList()
        ..sort((a, b) {
          if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
          return b.createdAt.compareTo(a.createdAt);
        });

  bool isNoticeReadByMe(Notice n) => myStaff != null && n.readBy.containsKey(myStaff!.id);

  int get unreadNoticeCount =>
      storeNotices.where((n) => !isNoticeReadByMe(n)).length;

  /// 최신순. 같은 시각이면 나중에 생긴 것이 먼저.
  List<AppNotification> get myNotifications {
    final all = state.notifications;
    final list = all
        .where((x) => x.toPersonId == session.meId && x.storeId == store.id)
        .toList();
    final order = {for (var i = 0; i < all.length; i++) all[i]: i};
    list.sort((a, b) {
      final c = b.createdAt.compareTo(a.createdAt);
      return c != 0 ? c : order[b]!.compareTo(order[a]!);
    });
    return list;
  }

  int get unreadNotificationCount => myNotifications.where((x) => !x.read).length;

  /// 보건증 만료까지 남은 날 (없으면 null).
  int? certDaysLeft(Person p) => p.certExpiry == null
      ? null
      : parseYmd(p.certExpiry!).difference(today).inDays;

  // ───────────────────────── 급여 ─────────────────────────

  /// [staffId]의 그 달 급여. [projected]면 오늘 이후 예정 근무도 포함(예상 급여).
  Payslip payslip(String staffId, int year, int month, {bool projected = false}) {
    final staff = staffById(staffId)!;
    final first = DateTime(year, month, 1); // month 가 0 이하·13 이상이어도 정규화
    year = first.year;
    month = first.month;
    final from = mondayOf(first);
    final to = mondayOf(DateTime(year, month + 1, 0)).add(const Duration(days: 7));
    final entries = <WorkEntry>[];
    for (final s in scheduleOfStaff(staffId)) {
      final day = parseYmd(s.date);
      if (day.isBefore(from) || !day.isBefore(to)) continue;
      if (s.kind == ShiftKind.leave) {
        // 연차는 소정 시간만큼 유급. 지난 연차는 확정, 앞으로의 연차는 예상에만.
        final past = shiftEnd(s).isBefore(now);
        if (past || projected) {
          entries.add(WorkEntry(
              start: shiftStart(s), end: shiftEnd(s), breakMin: s.breakMin, planned: !past));
        }
        continue;
      }
      if (!s.isWork) continue;
      final a = attendanceFor(s.id);
      if (a?.clockOut != null) {
        entries.add(WorkEntry(
          start: _paidStart(a!, s),
          end: DateTime.parse(a.clockOut!),
          breakMin: s.breakMin,
          isSubstitute: s.isSubstitute,
        ));
      } else if (projected && !shiftEnd(s).isBefore(now)) {
        entries.add(WorkEntry(
          start: shiftStart(s),
          end: shiftEnd(s),
          breakMin: s.breakMin,
          isSubstitute: s.isSubstitute,
          planned: true,
        ));
      }
    }
    final st = storeById(staff.storeId)!;
    return computePayslip(
      entries: entries,
      year: year,
      month: month,
      wage: staff.wage,
      deduction: staff.deduction,
      weeklyHolidayAuto: staff.weeklyHolidayAuto,
      premiumApplies: !st.isSmall && staff.premium,
    );
  }

  /// 매장 인건비(세전 합계). 상수로 둔 지난 달은 그 값을 쓴다.
  int laborTotal(int year, int month, {bool projected = false}) {
    final first = DateTime(year, month);
    year = first.year;
    month = first.month;
    final fixed = store.monthlyTotals[ym(first)];
    if (fixed != null) return fixed;
    return state.staff
        .where((s) => s.storeId == store.id && s.status != StaffStatus.pending)
        .fold(0, (sum, s) => sum + payslip(s.id, year, month, projected: projected).gross);
  }

  // ───────────────────────── 알림 ─────────────────────────

  void _notify(String personId, String type, String title,
      {String body = '', String? refId, String? storeId}) {
    state.notifications.add(AppNotification(
      id: _id('x'),
      storeId: storeId ?? store.id,
      toPersonId: personId,
      type: type,
      title: title,
      body: body,
      createdAt: _iso(now),
      refId: refId,
    ));
  }

  void _notifyStaff(String? staffId, String type, String title,
      {String body = '', String? refId}) {
    final s = staffById(staffId);
    if (s != null) {
      _notify(s.personId, type, title, body: body, refId: refId, storeId: s.storeId);
    }
  }

  void _notifyOwner(String storeId, String type, String title,
      {String body = '', String? refId}) {
    final owner = storeById(storeId)?.ownerPersonId;
    if (owner != null) {
      _notify(owner, type, title, body: body, refId: refId, storeId: storeId);
    }
  }

  String _shiftLabel(Shift s) =>
      '${md(parseYmd(s.date))} ${range(s.startMin, s.endMin)}';

  void markNotificationRead(String id) {
    state.notifications.where((x) => x.id == id).forEach((x) => x.read = true);
    _commit();
  }

  void markAllNotificationsRead() {
    for (final x in myNotifications) {
      x.read = true;
    }
    _commit();
  }

  // ───────────────────────── 세션 ─────────────────────────

  void login(Role role) {
    session
      ..loggedIn = true
      ..role = role;
    _commit();
  }

  void logout() {
    session.loggedIn = false;
    _commit();
  }

  void switchRole(Role role) {
    session.role = role;
    _commit();
  }

  /// 근무 중이면 전환하지 않고 false.
  bool switchStore(String storeId) {
    if (isWorking) return false;
    session.employeeStoreId = storeId;
    _commit();
    return true;
  }

  /// 시드로 되돌린다. 로그인·역할은 유지.
  void resetDemo() {
    final keep = session;
    state = buildSeed(now);
    _undo.clear();
    _redo.clear();
    state.session
      ..loggedIn = keep.loggedIn
      ..role = keep.role;
    _commit();
  }

  // ───────────────────────── 출퇴근 ─────────────────────────

  Attendance clockIn(String shiftId) {
    final existing = attendanceFor(shiftId);
    if (existing != null) return existing;
    final s = shiftById(shiftId)!;
    assert(s.isWork, '연차·휴무·시간 미정 근무에는 출근할 수 없다');
    final a = Attendance(
      id: _id('a'),
      storeId: s.storeId,
      shiftId: s.id,
      staffId: s.staffId,
      clockIn: _iso(now),
    );
    state.attendance.add(a);
    _commit();
    return a;
  }

  Attendance? clockOut() {
    final a = myOpenAttendance;
    if (a == null) return null;
    a.clockOut = _iso(now);
    _commit();
    return a;
  }

  void editAttendance(String attendanceId,
      {required DateTime clockIn, DateTime? clockOut, required String reason}) {
    final a = attendanceById(attendanceId)!;
    a
      ..clockIn = _iso(clockIn)
      ..clockOut = clockOut == null ? null : _iso(clockOut)
      ..editReason = reason;
    _notifyStaff(a.staffId, 'pay', '근태 기록이 수정됐어요', body: reason);
    _commit();
  }

  /// 사장님이 출근 기록을 새로 만든다(미출근 처리용).
  Attendance createAttendance(String shiftId,
      {required DateTime clockIn, DateTime? clockOut, required String reason}) {
    final s = shiftById(shiftId)!;
    final a = Attendance(
      id: _id('a'),
      storeId: s.storeId,
      shiftId: s.id,
      staffId: s.staffId,
      clockIn: _iso(clockIn),
      clockOut: clockOut == null ? null : _iso(clockOut),
      editReason: reason,
    );
    state.attendance.add(a);
    _commit();
    return a;
  }

  // ───────────────────────── 대타 ─────────────────────────

  SubstituteRequest requestSubstitute(String shiftId,
      {required String reason, bool notifyPeers = true}) {
    final s = shiftById(shiftId)!;
    assert(s.isWork, '실제 근무만 대타를 구할 수 있다');
    final r = SubstituteRequest(
      id: _id('r'),
      storeId: s.storeId,
      shiftId: s.id,
      requesterId: s.staffId,
      reason: reason,
      notifyPeers: notifyPeers,
      createdAt: _iso(now),
    );
    state.subs.add(r);
    final who = nameOf(s.staffId);
    _notifyOwner(s.storeId, 'sub', '$who님이 휴무·대타를 신청했어요',
        body: _shiftLabel(s), refId: r.id);
    if (notifyPeers) _notifyPeers(r, '$who님이 대타를 구해요');
    _commit();
    return r;
  }

  void _notifyPeers(SubstituteRequest r, String title) {
    if (!store.substitutePush) return; // 사장님 알림은 호출 쪽에서 따로 보낸다
    final s = shiftById(r.shiftId)!;
    for (final p in state.staff.where(
        (x) => x.storeId == r.storeId && x.active && x.id != r.requesterId)) {
      _notifyStaff(p.id, 'sub', title, body: _shiftLabel(s), refId: r.id);
    }
  }

  /// [staffId](기본: 나)가 대타를 수락한다. 첫 수락자가 대타 후보가 된다.
  void applySubstitute(String requestId, {String? staffId}) {
    final r = subById(requestId)!;
    final who = staffId ?? myStaff!.id;
    if (r.requesterId == who || r.applicantIds.contains(who)) return;
    r.applicantIds.add(who);
    if (r.acceptedId == null) {
      r
        ..acceptedId = who
        ..status = SubStatus.accepted;
    }
    final s = shiftById(r.shiftId)!;
    _notifyStaff(r.requesterId, 'sub', '${nameOf(who)}님이 대타를 수락했어요',
        body: _shiftLabel(s), refId: r.id);
    _notifyOwner(r.storeId, 'sub',
        '${nameOf(who)}님이 ${nameOf(r.requesterId)}님 대타를 수락했어요',
        body: '승인하면 근무표에 반영돼요', refId: r.id);
    _commit();
  }

  /// 데모: 같은 시간에 근무가 없는 동료 한 명이 수락한 것으로 만든다.
  bool simulatePeerAccept(String requestId) {
    final r = subById(requestId)!;
    final s = shiftById(r.shiftId)!;
    final peer = state.staff
        .where((x) =>
            x.storeId == r.storeId &&
            x.active &&
            x.id != r.requesterId &&
            x.personId != session.employeeId &&
            !r.applicantIds.contains(x.id) &&
            overlappingShift(x.id, s) == null)
        .firstOrNull;
    if (peer == null) return false;
    applySubstitute(requestId, staffId: peer.id);
    return true;
  }

  void cancelSubstitute(String requestId) {
    final r = subById(requestId)!;
    r.status = SubStatus.cancelled;
    for (final a in r.applicantIds) {
      _notifyStaff(a, 'sub', '${nameOf(r.requesterId)}님이 대타 요청을 취소했어요', refId: r.id);
    }
    _notifyOwner(r.storeId, 'sub', '${nameOf(r.requesterId)}님이 대타 요청을 취소했어요',
        refId: r.id);
    _commit();
  }

  void approveSubstitute(String requestId) {
    final r = subById(requestId)!;
    final s = shiftById(r.shiftId)!;
    if (r.acceptedId == null) return;
    r.status = SubStatus.approved;
    s
      ..originalStaffId = s.staffId
      ..staffId = r.acceptedId!
      ..isSubstitute = true;
    _notifyStaff(r.requesterId, 'sub', '대타 요청이 승인됐어요',
        body: '${_shiftLabel(s)} · ${nameOf(r.acceptedId)}님이 근무해요', refId: r.id);
    _notifyStaff(r.acceptedId, 'sub', '대타 근무가 확정됐어요',
        body: _shiftLabel(s), refId: r.id);
    _commit();
  }

  void rejectSubstitute(String requestId) {
    final r = subById(requestId)!;
    final s = shiftById(r.shiftId)!;
    r.status = SubStatus.rejected;
    _notifyStaff(r.requesterId, 'sub', '대타 요청이 거절됐어요',
        body: '${_shiftLabel(s)} 근무는 그대로 진행돼요', refId: r.id);
    if (r.acceptedId != null) {
      _notifyStaff(r.acceptedId, 'sub', '대타 요청이 거절됐어요', body: _shiftLabel(s), refId: r.id);
    }
    _commit();
  }

  void resendSubstitute(String requestId) {
    final r = subById(requestId)!;
    r.notifiedAt = _iso(now);
    _notifyPeers(r, '${nameOf(r.requesterId)}님 대타를 다시 구해요');
    _commit();
  }

  /// 사장님이 직접 대타자를 정하고 바로 승인한다.
  void assignSubstitute(String requestId, String staffId) {
    final r = subById(requestId)!;
    if (!r.applicantIds.contains(staffId)) r.applicantIds.add(staffId);
    r.acceptedId = staffId;
    approveSubstitute(requestId);
  }

  // ───────────────────────── 근무표 ─────────────────────────

  // 되돌리기: 근무표를 바꾸기 직전 상태(JSON)를 쌓는다. 메모리에만 둔다.
  final _undo = <String>[];
  final _redo = <String>[];
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void _snapshot() {
    _undo.add(toJson());
    if (_undo.length > 50) _undo.removeAt(0);
    _redo.clear();
  }

  void _restore(List<String> from, List<String> to) {
    if (from.isEmpty) return;
    to.add(toJson());
    state = AppState.fromJson(jsonDecode(from.removeLast()) as Map<String, dynamic>)!;
    _commit();
  }

  void undo() => _restore(_undo, _redo);
  void redo() => _restore(_redo, _undo);

  /// 근무를 만든다. [repeatWeeks] > 1 이면 매주 같은 요일로 반복.
  List<Shift> addShift({
    required DateTime date,
    required int startMin,
    required int endMin,
    required String part,
    required List<String> staffIds,
    int? breakMin,
    int repeatWeeks = 1,
    ShiftKind kind = ShiftKind.work,
    bool timeTbd = false,
  }) {
    _snapshot();
    final created = <Shift>[];
    final span = (endMin <= startMin ? endMin + 1440 : endMin) - startMin;
    for (var w = 0; w < repeatWeeks; w++) {
      final d = dayOf(date).add(Duration(days: 7 * w));
      for (final staffId in staffIds) {
        final s = Shift(
          id: _id('s'),
          storeId: store.id,
          staffId: staffId,
          date: ymd(d),
          startMin: startMin,
          endMin: endMin,
          part: part,
          breakMin: breakMin ?? defaultBreak(span),
          kind: kind,
          timeTbd: timeTbd,
        );
        state.shifts.add(s);
        created.add(s);
        if (w == 0 && kind == ShiftKind.work && !timeTbd) {
          _notifyStaff(staffId, 'sub', '새 근무가 배정됐어요', body: _shiftLabel(s));
        }
      }
    }
    _commit();
    return created;
  }

  /// 근무 시간에 맞는 법정 최소 휴게(4시간 30분, 8시간 60분).
  static int defaultBreak(int span) => span >= 480 ? 60 : span >= 240 ? 30 : 0;

  /// 근무를 지운다. 출근 기록이 있으면 지우지 않고 false. 대기 중 대타 요청은 취소하고 알바생에게 알린다.
  bool deleteShift(String shiftId) {
    final s = shiftById(shiftId);
    if (s == null) return true;
    if (attendanceFor(shiftId) != null) return false;
    _snapshot();
    state.shifts.removeWhere((x) => x.id == shiftId);
    for (final r in state.subs.where((r) => r.shiftId == shiftId && r.pending)) {
      r.status = SubStatus.cancelled;
    }
    if (s.isWork) _notifyStaff(s.staffId, 'sub', '근무가 삭제됐어요', body: _shiftLabel(s));
    _commit();
    return true;
  }

  /// 근무 수정 · 다른 칸으로 옮기기.
  void updateShift(
    String shiftId, {
    String? staffId,
    DateTime? date,
    int? startMin,
    int? endMin,
    String? part,
    int? breakMin,
    ShiftKind? kind,
    bool? timeTbd,
  }) {
    final s = shiftById(shiftId);
    if (s == null) return;
    _snapshot();
    final before = _shiftLabel(s), oldStaff = s.staffId, wasWork = s.isWork;
    if (staffId != null) s.staffId = staffId;
    if (date != null) s.date = ymd(date);
    if (startMin != null) s.startMin = startMin;
    if (endMin != null) s.endMin = endMin;
    if (part != null) s.part = part;
    if (breakMin != null) s.breakMin = breakMin;
    if (kind != null) s.kind = kind;
    if (timeTbd != null) s.timeTbd = timeTbd;
    final after = _shiftLabel(s);
    if (wasWork && (s.staffId != oldStaff || !s.isWork)) {
      _notifyStaff(oldStaff, 'sub', '근무가 삭제됐어요', body: before);
    }
    if (s.isWork && (s.staffId != oldStaff || !wasWork)) {
      _notifyStaff(s.staffId, 'sub', '새 근무가 배정됐어요', body: after);
    } else if (s.isWork && after != before) {
      _notifyStaff(s.staffId, 'sub', '근무가 수정됐어요', body: after);
    }
    _commit();
  }

  /// 그 주 파트별 필요 인원이 모자라는 칸을 채운다. 오늘 이후 날짜만.
  /// 그 시간에 근무가 없는 파트 근무자 중 그 주 근무가 적은 사람부터. 배정한 수를 돌려준다.
  int autoFill(DateTime weekMonday) {
    _snapshot();
    var added = 0;
    final monday = mondayOf(weekMonday);
    int weekMin(Staff s) => shiftsOfStaff(s.id)
        .where((x) {
          final d = parseYmd(x.date);
          return !d.isBefore(monday) && d.isBefore(monday.add(const Duration(days: 7)));
        })
        .fold(0, (sum, x) => sum + x.scheduledMinutes);
    for (var i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      if (day.isBefore(today)) continue;
      for (final p in store.parts) {
        var have = scheduleOn(day).where((x) => x.part == p.name && x.kind == ShiftKind.work).length;
        while (have < p.need) {
          final span = (p.endMin <= p.startMin ? p.endMin + 1440 : p.endMin) - p.startMin;
          final draft = Shift(
              id: '',
              storeId: store.id,
              staffId: '',
              date: ymd(day),
              startMin: p.startMin,
              endMin: p.endMin,
              part: p.name,
              breakMin: defaultBreak(span));
          final free = partStaff
              .where((m) =>
                  scheduleOn(day).every((x) => x.staffId != m.id) &&
                  overlappingShift(m.id, draft) == null)
              .toList()
            ..sort((a, b) => weekMin(a).compareTo(weekMin(b)));
          if (free.isEmpty) break;
          state.shifts.add(Shift(
            id: _id('s'),
            storeId: store.id,
            staffId: free.first.id,
            date: draft.date,
            startMin: p.startMin,
            endMin: p.endMin,
            part: p.name,
            breakMin: draft.breakMin,
          ));
          have++;
          added++;
        }
      }
    }
    if (added == 0) _undo.removeLast();
    _commit();
    return added;
  }

  /// 근무표 확정: 재직 직원 모두에게 알린다.
  void confirmSchedule(int year, int month) {
    store.scheduleConfirmedAt = _iso(now);
    for (final s in activeStaff) {
      _notifyStaff(s.id, 'sub', '$month월 근무표가 확정됐어요', body: '근무표에서 내 근무를 확인해 주세요');
    }
    _commit();
  }

  /// 근무표 만들기(웹): [from]–[to] 의 오늘 이후 날짜에 파트별 [needs](store.parts 순서) 만큼 근무를 짠다.
  /// 상태는 바꾸지 않고 미리보기만 돌려준다.
  /// - [copyLastWeek]: 오늘이 든 주의 바로 전 주 근무(연차·휴무 제외, 재직자만)를 요일마다 반복한 뒤 빈칸을 채운다
  /// - 빈칸은 그 파트가 자기 파트인 근무자 먼저, 그다음 그 주 근무가 적은 사람부터. [excludeStaffIds] 는 빼고,
  ///   그 주 소정 분이 [weeklyMaxMin] 을 넘게 되는 사람은 건너뛴다
  /// - 이미 있는 근무 · 겹치는 시간은 그대로 두고 피한다
  SchedulePlan planSchedule({
    required DateTime from,
    required DateTime to,
    required List<int> needs,
    bool copyLastWeek = false,
    Set<String> excludeStaffIds = const {},
    int weeklyMaxMin = 40 * 60,
  }) {
    final start = dayOf(from).isBefore(today) ? today : dayOf(from), end = dayOf(to);
    final planned = <Shift>[];
    final inRange = !end.isBefore(start);

    bool onDay(String staffId, String date) =>
        scheduleOn(parseYmd(date)).any((x) => x.staffId == staffId) ||
        planned.any((x) => x.staffId == staffId && x.date == date);
    bool overlaps(String staffId, Shift d) =>
        overlappingShift(staffId, d) != null ||
        planned.any((x) =>
            x.staffId == staffId &&
            shiftStart(x).isBefore(shiftEnd(d)) &&
            shiftEnd(x).isAfter(shiftStart(d)));
    int weekMin(String staffId, DateTime day) {
      final mon = mondayOf(day), next = mon.add(const Duration(days: 7));
      return [...shiftsOfStaff(staffId), ...planned.where((x) => x.staffId == staffId)]
          .where((x) {
            final d = parseYmd(x.date);
            return !d.isBefore(mon) && d.isBefore(next);
          })
          .fold(0, (sum, x) => sum + x.scheduledMinutes);
    }

    Shift draft(DateTime day, int startMin, int endMin, String part, int breakMin, [String staffId = '']) =>
        Shift(
            id: '',
            storeId: store.id,
            staffId: staffId,
            date: ymd(day),
            startMin: startMin,
            endMin: endMin,
            part: part,
            breakMin: breakMin);

    if (inRange && copyLastWeek) {
      final lastMon = mondayOf(today).subtract(const Duration(days: 7));
      for (var day = start; !day.isAfter(end); day = day.add(const Duration(days: 1))) {
        for (final s in scheduleOn(lastMon.add(Duration(days: day.weekday - 1)))) {
          final id = s.originalStaffId ?? s.staffId;
          if (!s.isWork || excludeStaffIds.contains(id) || !(staffById(id)?.active ?? false)) continue;
          final d = draft(day, s.startMin, s.endMin, s.part, s.breakMin, id);
          if (onDay(id, d.date) ||
              overlaps(id, d) ||
              weekMin(id, day) + d.scheduledMinutes > weeklyMaxMin) {
            continue;
          }
          planned.add(d);
        }
      }
    }

    var unfilled = 0;
    if (inRange) {
      for (var day = start; !day.isAfter(end); day = day.add(const Duration(days: 1))) {
        for (var i = 0; i < store.parts.length; i++) {
          final p = store.parts[i], need = i < needs.length ? needs[i] : p.need;
          final span = (p.endMin <= p.startMin ? p.endMin + 1440 : p.endMin) - p.startMin;
          var have = scheduleOn(day).where((x) => x.part == p.name && x.kind == ShiftKind.work).length +
              planned.where((x) => x.part == p.name && x.date == ymd(day)).length;
          while (have < need) {
            final d = draft(day, p.startMin, p.endMin, p.name, defaultBreak(span));
            final free = partStaff
                .where((m) =>
                    !excludeStaffIds.contains(m.id) &&
                    !onDay(m.id, d.date) &&
                    !overlaps(m.id, d) &&
                    weekMin(m.id, day) + d.scheduledMinutes <= weeklyMaxMin)
                .toList()
              // 자기 파트 근무자 먼저, 그다음 그 주 근무가 적은 사람.
              ..sort((a, b) {
                final home = (a.part == p.name ? 0 : 1).compareTo(b.part == p.name ? 0 : 1);
                return home != 0 ? home : weekMin(a.id, day).compareTo(weekMin(b.id, day));
              });
            if (free.isEmpty) {
              unfilled += need - have;
              break;
            }
            d.staffId = free.first.id;
            planned.add(d);
            have++;
          }
        }
      }
    }

    final minutes = <String, int>{};
    void add(Shift x) => minutes[x.staffId] = (minutes[x.staffId] ?? 0) + x.scheduledMinutes;
    for (final m in activeStaff) {
      for (final x in shiftsOfStaff(m.id)) {
        final d = parseYmd(x.date);
        if (!d.isBefore(dayOf(from)) && !d.isAfter(end)) add(x);
      }
    }
    planned.forEach(add);
    return SchedulePlan(
      from: dayOf(from),
      to: end,
      shifts: planned,
      unfilled: unfilled,
      minutesByStaff: minutes,
      cost: planned.fold(0, (sum, x) => sum + plannedPay(x)),
    );
  }

  /// [plan] 의 근무를 추가하고 파트별 필요 인원을 [needs] 로 저장한다. 되돌리기 한 번에 묶인다.
  /// 담당 직원들에게 알림. 추가한 수를 돌려준다.
  int applySchedulePlan(SchedulePlan plan, {List<int>? needs}) {
    if (plan.shifts.isEmpty) return 0;
    _snapshot();
    if (needs != null) {
      for (var i = 0; i < needs.length && i < store.parts.length; i++) {
        store.parts[i].need = needs[i];
      }
    }
    final counts = <String, int>{};
    for (final x in plan.shifts) {
      state.shifts.add(Shift(
        id: _id('s'),
        storeId: store.id,
        staffId: x.staffId,
        date: x.date,
        startMin: x.startMin,
        endMin: x.endMin,
        part: x.part,
        breakMin: x.breakMin,
      ));
      counts[x.staffId] = (counts[x.staffId] ?? 0) + 1;
    }
    counts.forEach((id, n) =>
        _notifyStaff(id, 'sub', '${plan.from.month}월 근무가 추가됐어요', body: '$n건 · 근무표에서 확인해 주세요'));
    _commit();
    return plan.shifts.length;
  }

  /// 파트별 필요 인원 저장 + (선택) 지난주 근무를 이번 주로 복사.
  int applyTemplate({required List<int> needs, bool copyLastWeek = false}) {
    _snapshot();
    for (var i = 0; i < needs.length && i < store.parts.length; i++) {
      store.parts[i].need = needs[i];
    }
    var copied = 0;
    if (copyLastWeek) {
      final thisMonday = mondayOf(today);
      for (var d = 0; d < 7; d++) {
        final target = thisMonday.add(Duration(days: d));
        for (final s in scheduleOn(target.subtract(const Duration(days: 7)))) {
          final staffId = s.originalStaffId ?? s.staffId;
          final exists = scheduleOn(target).any((x) =>
              (x.originalStaffId ?? x.staffId) == staffId && x.part == s.part);
          if (exists || !(staffById(staffId)?.active ?? false)) continue;
          state.shifts.add(Shift(
            id: _id('s'),
            storeId: store.id,
            staffId: staffId,
            date: ymd(target),
            startMin: s.startMin,
            endMin: s.endMin,
            part: s.part,
            breakMin: s.breakMin,
            kind: s.kind,
            timeTbd: s.timeTbd,
          ));
          copied++;
        }
      }
    }
    _commit();
    return copied;
  }

  // ───────────────────────── 직원 ─────────────────────────

  static String _normCode(String c) => c.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  /// 알바생(나)이 매장 코드로 가입 신청한다.
  (JoinResult, Store?) requestJoin(String code) {
    final st = state.stores
        .where((s) => _normCode(s.code) == _normCode(code))
        .firstOrNull;
    if (st == null) return (JoinResult.notFound, null);
    final existing = membership(session.employeeId, st.id);
    if (existing != null) {
      return (
        existing.active ? JoinResult.alreadyMember : JoinResult.alreadyPending,
        st
      );
    }
    final s = Staff(
      id: _id('m'),
      storeId: st.id,
      personId: session.employeeId,
      part: st.parts.first.name,
      wage: minimumWage2026,
      joinedAt: ymd(today),
      status: StaffStatus.pending,
      requestedAt: _iso(now),
    );
    state.staff.add(s);
    _notifyOwner(st.id, 'join', '${person(session.employeeId).name}님이 가입을 신청했어요',
        body: '직원 관리에서 승인해 주세요', refId: s.id);
    _commit();
    return (JoinResult.requested, st);
  }

  void approveJoin(String staffId, {required int wage, Deduction? deduction}) {
    final s = staffById(staffId)!;
    s
      ..status = StaffStatus.active
      ..wage = wage
      ..deduction = deduction ?? storeById(s.storeId)!.defaultDeduction
      ..joinedAt = ymd(today);
    _notifyStaff(s.id, 'join', '${storeById(s.storeId)!.name} 가입이 승인됐어요',
        body: '시급 ${wonText(wage)}', refId: s.id);
    _commit();
  }

  void rejectJoin(String staffId) {
    final s = staffById(staffId)!;
    s.status = StaffStatus.rejected;
    _notifyStaff(s.id, 'join', '${storeById(s.storeId)!.name} 가입이 거절됐어요');
    _commit();
  }

  void updateStaff(String staffId,
      {int? wage,
      Deduction? deduction,
      bool? weeklyHolidayAuto,
      bool? premium,
      String? part,
      StaffKind? kind}) {
    final s = staffById(staffId)!;
    if (kind != null) s.kind = kind;
    if (wage != null) s.wage = wage;
    if (deduction != null) s.deduction = deduction;
    if (weeklyHolidayAuto != null) s.weeklyHolidayAuto = weeklyHolidayAuto;
    if (premium != null) s.premium = premium;
    if (part != null) s.part = part;
    _commit();
  }

  /// 매장에서 내보낸다. 오늘 이후(아직 출근 안 한) 근무는 지우고, 대기 대타에서 뺀다.
  void removeStaff(String staffId) {
    final s = staffById(staffId)!;
    s.status = StaffStatus.left;
    state.shifts.removeWhere((x) =>
        x.staffId == staffId &&
        !parseYmd(x.date).isBefore(today) &&
        attendanceFor(x.id) == null);
    for (final r in state.subs.where((r) => r.pending)) {
      if (r.requesterId == staffId) {
        r.status = SubStatus.cancelled;
        continue;
      }
      if (!r.applicantIds.remove(staffId) && r.acceptedId != staffId) continue;
      if (r.acceptedId == staffId) {
        r
          ..acceptedId = null
          ..status = SubStatus.open;
      }
    }
    _notifyStaff(staffId, 'join', '${storeById(s.storeId)!.name}에서 퇴사 처리됐어요');
    _commit();
  }

  // ───────────────────────── 공지 ─────────────────────────

  Notice publishNotice({
    required String title,
    required String body,
    bool? required,
    String category = '일반',
  }) {
    final n = Notice(
      id: _id('n'),
      storeId: store.id,
      title: title,
      body: body,
      category: category,
      required: required ?? store.noticeRequiredDefault,
      createdAt: _iso(now),
    );
    state.notices.add(n);
    for (final s in activeStaff) {
      _notifyStaff(s.id, 'notice', n.required ? '새 필독 공지' : '새 공지', body: title, refId: n.id);
    }
    _commit();
    return n;
  }

  void markNoticeRead(String noticeId) {
    final m = myStaff;
    final n = noticeById(noticeId);
    if (m == null || n == null || n.readBy.containsKey(m.id)) return;
    n.readBy[m.id] = _iso(now);
    _commit();
  }

  void markAllNoticesRead() {
    final m = myStaff;
    if (m == null) return;
    for (final n in storeNotices) {
      n.readBy.putIfAbsent(m.id, () => _iso(now));
    }
    _commit();
  }

  List<Staff> unreadStaffOf(Notice n) => state.staff
      .where((s) => s.storeId == n.storeId && s.active && !n.readBy.containsKey(s.id))
      .toList();

  /// 안 읽은 직원에게 다시 알린다. 보낸 인원 수를 돌려준다.
  int remindUnread(String noticeId) {
    final n = noticeById(noticeId)!;
    final targets = unreadStaffOf(n);
    for (final s in targets) {
      _notifyStaff(s.id, 'notice', '필독 공지를 확인해 주세요', body: n.title, refId: n.id);
    }
    n.remindedAt = _iso(now);
    _commit();
    return targets.length;
  }

  // ───────────────────────── 서류 ─────────────────────────

  /// 알바생(나)이 보건증 갱신본을 등록한다.
  void uploadHealthCert({required DateTime expiry, required List<int> alertDays}) {
    final p = person(session.employeeId);
    p
      ..certExpiry = ymd(expiry)
      ..certAlertDays = alertDays
      ..certHasPhoto = true;
    for (final s in myMemberships) {
      _notifyOwner(s.storeId, 'cert', '${p.name}님이 보건증을 갱신했어요',
          body: '만료일 ${dotDate(expiry)}', refId: s.id);
    }
    _commit();
  }

  void requestCertRenewal(String staffId) {
    final s = staffById(staffId)!;
    final p = personOf(s);
    final left = certDaysLeft(p);
    _notifyStaff(staffId, 'cert',
        left == null ? '보건증을 등록해 주세요' : '보건증 만료 ${left >= 0 ? 'D-$left' : '지남'}',
        body: '내 서류에서 갱신본을 등록해 주세요');
    _commit();
  }

  /// 사장님이 계약서를 작성하고 서명해 보낸다.
  void createContract(String staffId, Contract c) {
    final s = staffById(staffId)!;
    c
      ..ownerSignedAt = _iso(now)
      ..employeeSignedAt = null;
    s.contract = c;
    _notifyStaff(staffId, 'contract', '근로계약서 서명 요청', body: '내 서류에서 확인하고 서명해 주세요');
    _commit();
  }

  /// 알바생(나)이 현재 매장 계약서에 서명한다.
  void signContract() {
    final s = myStaff!;
    s.contract!.employeeSignedAt = _iso(now);
    _notifyOwner(s.storeId, 'contract', '${me.name}님이 근로계약서에 서명했어요');
    _commit();
  }

  // ───────────────────────── 매장 ─────────────────────────

  /// 사장님 매장을 만든다. 데모 사장님은 이미 매장이 있으므로 그 매장 정보를 바꾼다.
  /// shortcut: 사장님 1인 1매장. 여러 매장을 운영하게 하려면 매장 목록·전환이 필요하다.
  Store createStore(
      {required String name,
      required String address,
      required bool isSmall,
      Deduction deduction = Deduction.biz33}) {
    final st = storeById(session.ownerStoreId)!;
    st
      ..name = name
      ..address = address
      ..isSmall = isSmall
      ..defaultDeduction = deduction;
    _commit();
    return st;
  }

  void updateStore({
    bool? isSmall,
    bool? noticeRequiredDefault,
    bool? substitutePush,
  }) {
    if (isSmall != null) store.isSmall = isSmall;
    if (noticeRequiredDefault != null) store.noticeRequiredDefault = noticeRequiredDefault;
    if (substitutePush != null) store.substitutePush = substitutePush;
    _commit();
  }
}
