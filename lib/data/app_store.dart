import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'autoschedule.dart' as auto;
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

/// 못 채운 칸 (생성 미리보기).
class UnfilledSlot {
  UnfilledSlot(this.date, this.part, this.startMin, this.endMin, this.missing);

  final String date, part;
  final int startMin, endMin, missing;
}

/// 근무표 생성 미리보기. [AppStore.previewGenerate] 가 만들고 [AppStore.applyGenerated] 가 저장한다.
class GeneratePreview {
  GeneratePreview({
    required this.planId,
    required this.month,
    required this.shifts,
    required this.lines,
    required this.laborCost,
    required this.unfilled,
    required this.replacing,
  });

  factory GeneratePreview.fromJson(Map<String, dynamic> j, String storeId) => GeneratePreview(
        planId: '${j['planId']}',
        month: j['month'],
        shifts: [
          for (final x in (j['shifts'] as List? ?? const []).cast<Map>())
            Shift(
                id: '',
                storeId: storeId,
                staffId: '${x['staffId']}',
                date: x['date'],
                startMin: x['startMin'],
                endMin: x['endMin'],
                part: x['part'] ?? '직원',
                breakMin: x['breakMin'] ?? 0)
        ],
        lines: [for (final l in (j['lines'] as List? ?? const [])) '$l'],
        laborCost: (j['laborCost'] as num?)?.toInt() ?? 0,
        unfilled: [
          for (final u in (j['unfilled'] as List? ?? const []).cast<Map>())
            UnfilledSlot(u['date'], '${u['part'] ?? '직원'}', u['startMin'], u['endMin'], u['missing'] ?? 1)
        ],
        replacing: (j['replacing'] as num?)?.toInt() ?? 0,
      );

  final String planId, month;

  /// 적용하면 생길 근무 전체(id 비어 있음).
  final List<Shift> shifts;
  final List<String> lines;
  final int laborCost;
  final List<UnfilledSlot> unfilled;

  /// 적용하면 지워질 기존 근무 수(오늘 이후, 출근 기록 없는 것).
  final int replacing;

  /// 직원 id → 총 근무 분.
  Map<String, int> get minutesByStaff {
    final m = <String, int>{};
    for (final x in shifts) {
      m[x.staffId] = (m[x.staffId] ?? 0) + x.scheduledMinutes;
    }
    return m;
  }

  // 데모 적용용 설정.
  HolidayPolicy weeklyHolidayPay = HolidayPolicy.minimize;
  SchedulePriority priority = SchedulePriority.fairness;
}

/// 앱 전체 상태 + 액션. 화면은 [AppScope]로 받아 쓴다.
///
/// 액션마다 상태를 바꾸고 [notifyListeners] 후 [onSave]로 JSON 을 넘긴다.
class AppStore extends ChangeNotifier {
  AppStore(this.state, {this.onSave, DateTime Function()? now, this.api})
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

  // ───────────────────────── 서버 연동 ─────────────────────────
  //
  // [api] 가 있으면 서버 모드. 액션은 지금처럼 로컬 상태를 먼저 바꿔 화면에 바로 보이고(동기 시그니처 유지),
  // 같은 변경을 서버에 보낸 뒤 [reload] 로 서버 상태(`GET /api/v1/me/state`)로 덮는다.
  // 실패하면 [remoteError] 에 메시지를 넣고 역시 [reload] 해서 로컬 변경을 되돌린다.

  /// 서버 클라이언트. null 이면 기기 안 데모 모드.
  final ApiClient? api;
  bool get remote => api != null;

  /// 서버 요청 실패 메시지. 화면(main)이 듣고 토스트로 보여 준다.
  final ValueNotifier<String?> remoteError = ValueNotifier(null);

  bool _versionWarned = false;
  int _reloadSeq = 0;

  /// 서버 상태를 한 번이라도 읽었는지. 그 전의 session 매장 id 는 데모 시드('st-cafe')라 서버에 보내지 않는다.
  bool _fromServer = false;

  /// 지금 매장 상태를 다시 읽는다 (당겨서 새로고침·변경 신호·주기 확인).
  /// [quiet] 면 통신 실패는 알리지 않는다. 앱 버전이 서버와 다르면 한 번 알린다.
  Future<void> refreshNow({bool quiet = false}) async {
    if (!remote || !api!.hasToken || !session.loggedIn) return;
    try {
      await reload(storeId: session.storeId);
    } on StateError {
      if (_versionWarned) return;
      _versionWarned = true;
      remoteError.value = '앱이 최신 버전이 아니에요. 앱을 업데이트해 주세요';
    } catch (_) {
      if (!quiet) remoteError.value = '새 정보를 가져오지 못했어요';
    }
  }

  /// 서버 상태로 덮는다. [storeId] 를 주면 그 매장을 지금 보는 매장으로.
  Future<void> reload({String? storeId}) async {
    final a = api;
    // 웹 근무표 초안에 저장 안 한 편집이 있으면 서버 상태로 덮지 않는다.
    if (a == null || scheduleDirty) return;
    final seq = ++_reloadSeq;
    // 지정이 없으면 지금 보는 매장을 유지한다(안 그러면 서버가 첫 매장으로 돌린다).
    // 첫 읽기(웹 새로고침·앱 재시작)는 마지막으로 고른 사장님 매장을 고른다.
    final saved = _fromServer || (storeId?.isNotEmpty ?? false) ? null : a.prefs.getString(ownerStoreKey);
    final want = storeId != null && storeId.isNotEmpty ? storeId : saved ?? session.storeId;
    final sid = !_fromServer && saved == null && want == session.storeId ? '' : want;
    Map<String, dynamic> j;
    try {
      j = await a.get('/api/v1/me/state${sid.isEmpty ? '' : '?storeId=$sid'}')
          as Map<String, dynamic>;
    } on ApiException catch (e) {
      // 4xx: 내보내졌거나 거절된 매장(403), 없는 매장(404), 잘못된 id(400).
      // 매장 지정 없이 다시 읽어 서버가 정한 매장으로.
      if (sid.isEmpty || e.status < 400 || e.status >= 500) rethrow;
      j = await a.get('/api/v1/me/state') as Map<String, dynamic>;
    }
    // 늦게 온 응답: 기다리는 사이 초안 편집이 생겼거나 더 나중에 시작한 reload 가 있으면 버린다.
    if (seq != _reloadSeq || scheduleDirty) return;
    final s = AppState.fromJson(j);
    if (s == null) throw StateError('서버 상태 버전이 앱과 달라요 (v=${j['v']})');
    state = s;
    _fromServer = true;
    if (role == Role.employer && session.ownerStoreId.isNotEmpty &&
        a.prefs.getString(ownerStoreKey) != session.ownerStoreId) {
      a.prefs.setString(ownerStoreKey, session.ownerStoreId);
    }
    _localIds.clear();
    _undo.clear();
    _redo.clear();
    notifyListeners();
  }

  /// [call] 을 서버에 보내고 서버 상태로 다시 읽는다. 데모 모드면 아무것도 안 한다.
  void _remote(Future<void> Function(ApiClient api) call) {
    final a = api;
    if (a == null || _skipRemote) return;
    () async {
      try {
        await call(a);
      } on ApiException catch (e) {
        remoteError.value = e.message;
      } catch (e) {
        remoteError.value = '서버와 통신하지 못했어요';
      }
      try {
        await reload();
      } catch (_) {}
    }();
  }

  /// 서버 모드 매장 만들기 (사장님 첫 로그인). 만든 뒤 그 매장으로 다시 읽는다.
  Future<void> createStoreRemote({
    required String name,
    required String address,
    required bool isSmall,
    Deduction deduction = Deduction.biz33,
  }) async {
    final j = await _try((api) => api.post('/api/v1/stores', {
      'name': name,
      'address': address,
      'isSmall': isSmall,
      'defaultDeduction': deduction.name,
    })) as Map<String, dynamic>;
    await reload(storeId: '${j['id']}');
  }

  String _sp(String storeId) => '/api/v1/stores/$storeId';
  // 서버 id 는 숫자. 문자열 숫자면 숫자로 보낸다.
  Object _n(String id) => int.tryParse(id) ?? id;

  /// 서버가 아직 id 를 안 준 방금 만든 항목([_localIds])이면 안내만 하고 true.
  final Set<String> _localIds = {};
  bool _tempId(String id) {
    if (!remote || !_localIds.contains(id)) return false;
    remoteError.value = '처리 중이에요. 잠시 후 다시 시도해 주세요';
    return true;
  }

  /// 서버 모드에서 아직 지원 안 하는 동작. 안내만 띄운다.
  void _unsupported() => remoteError.value = '추후 지원 예정이에요';

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

  /// 사장님(나) 소유 매장들 (id 순).
  List<Store> get ownedStores => state.stores
      .where((s) => s.ownerPersonId == session.ownerId)
      .toList()
    ..sort((a, b) {
      final x = int.tryParse(a.id), y = int.tryParse(b.id);
      return x != null && y != null ? x.compareTo(y) : a.id.compareTo(b.id);
    });

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

  /// 다른 매장에 퇴근하지 않은 내 출근 기록(서버는 매장과 상관없이 새 출근을 막는다).
  /// 그 매장은 `storeById(a.storeId)`, 퇴근은 `clockOut(a)`.
  Attendance? get myOpenAttendanceElsewhere {
    final mine = state.staff
        .where((s) => s.personId == session.employeeId && s.storeId != session.employeeStoreId)
        .map((s) => s.id)
        .toSet();
    return state.attendance.where((a) => mine.contains(a.staffId) && a.clockOut == null).firstOrNull;
  }

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

  /// 진행 중 요청. 근무가 이미 시작했으면 승인·배정할 수 없으니 뺀다(서버 `?status=pending` 과 같음).
  List<SubstituteRequest> get pendingSubs => storeSubs.where((r) {
        final sh = shiftById(r.shiftId);
        return r.pending && (sh == null || shiftStart(sh).isAfter(now));
      }).toList();

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
            shiftStart(shiftById(r.shiftId)!).isAfter(now) &&
            overlappingShift(m.id, shiftById(r.shiftId)!) == null)
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

  bool isNoticeReadByMe(Notice n) =>
      myStaff != null && (n.readBy.containsKey(myStaff!.id) || _noticeBeforeJoin(n, myStaff!));

  int get unreadNoticeCount =>
      storeNotices.where((n) => !isNoticeReadByMe(n)).length;

  /// 최신순. 같은 시각이면 나중에 생긴 것이 먼저. 지금 매장 알림 + 상태에 없는 매장(퇴사·가입 거절된 곳) 알림.
  List<AppNotification> get myNotifications {
    final all = state.notifications;
    final list = all
        .where((x) => x.toPersonId == session.meId && (x.storeId == store.id || storeById(x.storeId) == null))
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
    var missing = 0;
    // 주(월요일 키)별 주휴 근거: 예정 소정 분, 끝난 근무 결근 여부.
    final stdMin = <DateTime, int>{}, absent = <DateTime, bool>{};
    for (final s in scheduleOfStaff(staffId)) {
      final day = parseYmd(s.date);
      if (day.isBefore(from) || !day.isBefore(to)) continue;
      final monday = mondayOf(day);
      if (s.kind == ShiftKind.leave) {
        stdMin[monday] = (stdMin[monday] ?? 0) + s.scheduledMinutes;
      } else if (s.isWork && !s.isSubstitute) {
        stdMin[monday] = (stdMin[monday] ?? 0) + s.scheduledMinutes;
        if (shiftEnd(s).isBefore(now) && attendanceFor(s.id) == null) absent[monday] = true;
      }
      if (s.kind == ShiftKind.leave) {
        // 연차는 소정 시간만큼 유급. 지난 연차는 확정, 앞으로의 연차는 예상에만.
        final past = shiftEnd(s).isBefore(now);
        if (past || projected) {
          entries.add(WorkEntry(
              start: shiftStart(s), end: shiftEnd(s), breakMin: s.breakMin, planned: !past, leave: true));
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
      } else if (a != null && shiftEnd(s).isBefore(now)) {
        // 출근만 찍고 퇴근 미기록: 0원으로 빠진다. 경고용으로 센다.
        if (day.year == year && day.month == month) missing++;
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
    final weekBasis = <DateTime, WeekBasis>{};
    for (var monday = from; monday.isBefore(to); monday = monday.add(const Duration(days: 7))) {
      final sunday = monday.add(const Duration(days: 6));
      // 계약서 소정시간이 우선이지만, 그 주에 예정 근무가 하나도 없으면 주휴 없음.
      final std = staff.contract != null && stdMin.containsKey(monday)
          ? staff.contract!.weeklyHours * 60
          : (stdMin[monday] ?? 0);
      final stays = staff.leftAt == null || !parseYmd(staff.leftAt!).isBefore(sunday);
      final over = !monday.add(const Duration(days: 7)).isAfter(now);
      weekBasis[monday] = WeekBasis(
          std, std >= 15 * 60 && absent[monday] != true && stays && (projected || over));
    }
    return computePayslip(
      entries: entries,
      year: year,
      month: month,
      wageOn: staff.wageOn,
      weekBasis: weekBasis,
      deduction: staff.deduction,
      weeklyHolidayAuto: staff.weeklyHolidayAuto,
      premiumApplies: !st.isSmall && staff.premium,
      missingClockOut: missing,
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
    _remote((api) => api.post('/api/v1/me/notifications/$id/read'));
  }

  void markAllNotificationsRead() {
    final sid = store.id;
    // read-all 은 매장 단위라 떠난 매장 알림은 하나씩 읽음 처리한다.
    final gone = [for (final x in myNotifications) if (!x.read && x.storeId != sid) x.id];
    for (final x in myNotifications) {
      x.read = true;
    }
    _commit();
    _remote((api) async {
      await api.post('/api/v1/me/notifications/read-all?storeId=$sid');
      for (final id in gone) {
        await api.post('/api/v1/me/notifications/$id/read');
      }
    });
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
    api?.logout();
  }

  void switchRole(Role role) {
    if (remote) return;
    session.role = role;
    _commit();
  }

  /// 사장님 매장 전환. 웹 근무표 초안에 저장 안 한 변경이 있으면 전환하지 않고 false.
  bool switchOwnerStore(String storeId) {
    if (scheduleDirty) return false;
    session.ownerStoreId = storeId;
    _commit();
    if (remote) {
      reload(storeId: storeId).catchError((Object _) {
        remoteError.value = '서버와 통신하지 못했어요';
      });
    }
    return true;
  }

  /// 근무 중이면 전환하지 않고 false.
  bool switchStore(String storeId) {
    if (isWorking) return false;
    session.employeeStoreId = storeId;
    _commit();
    if (remote) {
      reload(storeId: storeId).catchError((Object _) {
        remoteError.value = '서버와 통신하지 못했어요';
      });
    }
    return true;
  }

  /// 시드로 되돌린다. 로그인·역할은 유지.
  void resetDemo() {
    if (remote) return;
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

  /// 서버 모드 출근: POS 에서 스캔한 [qrToken] 을 보내고 reload. 실패하면 ApiException. 출근 기록을 돌려준다.
  Future<Attendance> clockInRemote(String shiftId, String qrToken) async {
    final s = shiftById(shiftId)!;
    final Object? res;
    try {
      res = await api!.post('${_sp(s.storeId)}/shifts/$shiftId/clock-in', {'qrToken': qrToken});
    } on ApiException catch (e) {
      final other = e.code == 'ALREADY_CLOCKED_IN' ? myOpenAttendanceElsewhere : null;
      final name = other == null ? null : storeById(other.storeId)?.name;
      if (name == null) rethrow;
      throw ApiException(e.status, e.code, '$name에서 아직 퇴근하지 않았어요. 먼저 퇴근해 주세요');
    }
    try {
      await reload(storeId: s.storeId);
    } catch (_) {} // 출근은 서버에 저장됨 — reload 실패여도 응답으로 계속
    final known = attendanceFor(shiftId);
    if (known != null) return known;
    // reload 가 늦은 응답으로 버려졌을 때: 서버 응답으로 기록을 만든다.
    final m = res as Map;
    final a = Attendance(
      id: '${m['id']}',
      storeId: s.storeId,
      shiftId: shiftId,
      staffId: s.staffId,
      clockIn: '${m['clockIn']}',
      clockOut: m['clockOut'] == null ? null : '${m['clockOut']}',
      editReason: m['editReason'] as String?,
    );
    state.attendance.add(a);
    _commit();
    return a;
  }

  /// 지금 매장 출근 기록을 퇴근 처리. [open] 을 주면 그 기록(다른 매장 것도 됨).
  Attendance? clockOut([Attendance? open]) {
    final a = open ?? myOpenAttendance;
    if (a == null) return null;
    a.clockOut = _iso(now);
    _commit();
    _remote((api) => api.post('${_sp(a.storeId)}/attendance/clock-out'));
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
    _remote((api) => api.patch('${_sp(a.storeId)}/attendance/$attendanceId', {
          'clockIn': _iso(clockIn),
          if (clockOut case final clockOutV?) 'clockOut': _iso(clockOutV),
          'reason': reason,
        }));
  }

  /// 서버 모드 근태 저장: [attendanceId] 가 있으면 수정, 없으면 [shiftId] 근무에 새로 만든다.
  /// 서버 응답을 기다리며 실패하면 ApiException. 성공하면 reload.
  Future<void> saveAttendanceRemote(
      {String? attendanceId,
      String? shiftId,
      required DateTime clockIn,
      DateTime? clockOut,
      required String reason}) async {
    final body = {
      'clockIn': _iso(clockIn),
      if (clockOut != null) 'clockOut': _iso(clockOut),
      'reason': reason,
    };
    if (attendanceId != null) {
      final a = attendanceById(attendanceId)!;
      await api!.patch('${_sp(a.storeId)}/attendance/$attendanceId', body);
    } else {
      final s = shiftById(shiftId!)!;
      await api!.post('${_sp(s.storeId)}/shifts/$shiftId/attendance', body);
    }
    try {
      await reload();
    } catch (_) {}
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
    _remote((api) => api.post('${_sp(s.storeId)}/shifts/$shiftId/attendance', {
          'clockIn': _iso(clockIn),
          if (clockOut case final clockOutV?) 'clockOut': _iso(clockOutV),
          'reason': reason,
        }));
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
    if (remote) _localIds.add(r.id);
    final who = nameOf(s.staffId);
    _notifyOwner(s.storeId, 'sub', '$who님이 휴무·대타를 신청했어요',
        body: _shiftLabel(s), refId: r.id);
    if (notifyPeers) _notifyPeers(r, '$who님이 대타를 구해요');
    _commit();
    _remote((api) => api.post('${_sp(s.storeId)}/shifts/$shiftId/substitute-requests',
        {'reason': reason, 'notifyPeers': notifyPeers}));
    return r;
  }

  /// 서버 모드: 서버 답을 기다린 뒤 reload. 실패하면 예외를 던진다(호출 쪽이 알림).
  Future<dynamic> _remoteWait(Future<dynamic> Function(ApiClient api) call) async {
    final res = await call(api!);
    try {
      await reload();
    } catch (_) {}
    return res;
  }

  /// [requestSubstitute] 의 서버 모드판: 서버가 받아들인 뒤에만 요청을 돌려준다. 실패하면 예외.
  Future<SubstituteRequest> requestSubstituteRemote(String shiftId,
      {required String reason, bool notifyPeers = true}) async {
    if (!remote) return requestSubstitute(shiftId, reason: reason, notifyPeers: notifyPeers);
    final s = shiftById(shiftId)!;
    final res = await _remoteWait((api) => api.post(
        '${_sp(s.storeId)}/shifts/$shiftId/substitute-requests',
        {'reason': reason, 'notifyPeers': notifyPeers})) as Map;
    final id = '${res['id']}';
    final known = subById(id);
    if (known != null) return known;
    // reload 가 버려졌을 때(초안 편집 중 등): 서버 응답으로 요청을 만든다.
    final r = SubstituteRequest(
        id: id,
        storeId: s.storeId,
        shiftId: s.id,
        requesterId: s.staffId,
        reason: reason,
        notifyPeers: notifyPeers,
        createdAt: _iso(now));
    state.subs.add(r);
    _commit();
    return r;
  }

  Future<void> applySubstituteRemote(String requestId) async {
    if (!remote) return applySubstitute(requestId);
    final r = subById(requestId)!;
    await _remoteWait((api) => api.post('${_sp(r.storeId)}/substitute-requests/$requestId/apply'));
  }

  Future<void> cancelSubstituteRemote(String requestId) async {
    if (!remote) return cancelSubstitute(requestId);
    final r = subById(requestId)!;
    await _remoteWait((api) => api.post('${_sp(r.storeId)}/substitute-requests/$requestId/cancel'));
  }

  Future<void> approveSubstituteRemote(String requestId) async {
    if (!remote) return approveSubstitute(requestId);
    final r = subById(requestId)!;
    await _remoteWait((api) => api.post('${_sp(r.storeId)}/substitute-requests/$requestId/approve'));
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
    if (_tempId(requestId)) return;
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
    _remote((api) => api.post('${_sp(r.storeId)}/substitute-requests/$requestId/apply'));
  }

  /// 데모: 같은 시간에 근무가 없는 동료 한 명이 수락한 것으로 만든다.
  bool simulatePeerAccept(String requestId) {
    if (remote) return false;
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
    if (_tempId(requestId)) return;
    final r = subById(requestId)!;
    r.status = SubStatus.cancelled;
    for (final a in r.applicantIds) {
      _notifyStaff(a, 'sub', '${nameOf(r.requesterId)}님이 대타 요청을 취소했어요', refId: r.id);
    }
    _notifyOwner(r.storeId, 'sub', '${nameOf(r.requesterId)}님이 대타 요청을 취소했어요',
        refId: r.id);
    _commit();
    _remote((api) => api.post('${_sp(r.storeId)}/substitute-requests/$requestId/cancel'));
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
    _remote((api) => api.post('${_sp(r.storeId)}/substitute-requests/$requestId/approve'));
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
    _remote((api) => api.post('${_sp(r.storeId)}/substitute-requests/$requestId/reject'));
  }

  void resendSubstitute(String requestId) {
    if (_tempId(requestId)) return;
    final r = subById(requestId)!;
    r.notifiedAt = _iso(now);
    _notifyPeers(r, '${nameOf(r.requesterId)}님 대타를 다시 구해요');
    _commit();
    _remote((api) => api.post('${_sp(r.storeId)}/substitute-requests/$requestId/resend'));
  }

  /// 사장님이 직접 대타자를 정하고 바로 승인한다.
  void assignSubstitute(String requestId, String staffId) {
    final r = subById(requestId)!;
    if (!r.applicantIds.contains(staffId)) r.applicantIds.add(staffId);
    r.acceptedId = staffId;
    // 로컬 변경만 하고(approve 의 서버 호출은 건너뛴다) 서버에는 assign 한 번만 보낸다.
    final api0 = api;
    final sid = r.storeId;
    if (api0 == null) {
      approveSubstitute(requestId);
      return;
    }
    _localOnly(() => approveSubstitute(requestId));
    _remote((api) => api.post('${_sp(sid)}/substitute-requests/$requestId/assign',
        {'staffId': _n(staffId)}));
  }

  bool _skipRemote = false;
  void _localOnly(void Function() f) {
    _skipRemote = true;
    try {
      f();
    } finally {
      _skipRemote = false;
    }
  }

  // ───────────────────────── 웹 근무표 초안 ─────────────────────────
  //
  // 초안 모드(웹 편집기): 근무 편집(add/update/deleteShift, autoFill)은 서버로 안 보내고 로컬 + 되돌리기만.
  // 바뀐 달은 dirty. [saveSchedule] 이 그 달 근무를 통째로 PUT 한다.

  bool _draft = false;
  final _dirtyMonths = <String>{};
  Set<String> _clearedDirty = {}; // 되돌리기로 비운 dirty(다시하기가 복원)
  String? _draftBase; // 데모 모드 되돌리기 기준

  bool get scheduleDirty => _draft && _dirtyMonths.isNotEmpty;

  void setScheduleDraft(bool on) {
    if (on == _draft) return;
    _draft = on;
    _dirtyMonths.clear();
    _undo.clear();
    _redo.clear();
    _draftBase = on && !remote ? toJson() : null;
  }

  void _markDirty(String month) {
    if (_draft) _dirtyMonths.add(month);
  }

  /// 근무 편집의 서버 전송. 초안 모드면 보내지 않는다.
  void _shiftRemote(Future<void> Function(ApiClient api) call) {
    if (_draft) return;
    _remote(call);
  }

  /// 서버 호출을 [ApiException] 으로 던진다(화면이 메시지를 보여 준다).
  Future<T> _try<T>(Future<T> Function(ApiClient api) call) async {
    try {
      return await call(api!);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(0, 'network', '서버와 통신하지 못했어요');
    }
  }

  Future<void> _reloadQuiet() async {
    try {
      await reload();
    } catch (_) {}
  }

  /// [month] 근무를 서버에 통째로 저장한다. 성공하면 dirty 해제 후 다시 읽는다.
  /// 출근 기록 때문에 건너뛴 것이 있으면 [remoteError] 로 안내. 실패하면 [ApiException].
  Future<void> saveSchedule(String month) async {
    if (!remote) {
      _dirtyMonths.remove(month);
      _undo.clear();
      _redo.clear();
      _commit();
      return;
    }
    final body = {
      'shifts': [
        for (final x in state.shifts.where((x) => x.storeId == store.id && x.date.startsWith(month)))
          {
            // 로컬에서 새로 만든 근무(숫자 아닌 임시 id)는 id 없이 보낸다.
            'id': ?int.tryParse(x.id),
            'staffId': _n(x.staffId),
            'date': x.date,
            'startMin': x.startMin,
            'endMin': x.endMin,
            'part': x.part,
            'breakMin': x.breakMin,
            'kind': x.kind.name,
            'timeTbd': x.timeTbd,
          }
      ]
    };
    final r = await _try((a) => a.put('${_sp(store.id)}/schedules/$month/shifts', body));
    _dirtyMonths.remove(month);
    await _reloadQuiet();
    final skipped = r is Map ? (r['skipped'] as List? ?? const []) : const [];
    if (skipped.isNotEmpty) {
      remoteError.value = '출근 기록이 있는 근무 ${skipped.length}건은 바꾸지 않았어요';
    }
  }

  /// 저장 안 한 편집을 버린다.
  Future<void> discardScheduleDraft() async {
    _dirtyMonths.clear();
    _undo.clear();
    _redo.clear();
    final base = _draftBase;
    if (!remote && base != null) {
      state = AppState.fromJson(jsonDecode(base) as Map<String, dynamic>)!;
      _commit();
      return;
    }
    await _reloadQuiet();
  }

  // ───────────────────────── 근무표 ─────────────────────────

  // 되돌리기: 근무표를 바꾸기 직전 상태(JSON)를 쌓는다. 메모리에만 둔다.
  final _undo = <String>[];
  final _redo = <String>[];
  bool get canUndo => (!remote || _draft) && _undo.isNotEmpty;
  bool get canRedo => (!remote || _draft) && _redo.isNotEmpty;

  void _snapshot() {
    _undo.add(toJson());
    if (_undo.length > 50) _undo.removeAt(0);
    _redo.clear();
  }

  void _restore(List<String> from, List<String> to) {
    if ((remote && !_draft) || from.isEmpty) return;
    to.add(toJson());
    state = AppState.fromJson(jsonDecode(from.removeLast()) as Map<String, dynamic>)!;
    // 되돌리기로 처음 상태가 되면 dirty 해제(서버 갱신이 막히지 않게). 50개 상한에 밀린 경우는 못 잡는다.
    if (_draft) {
      if (_undo.isEmpty) {
        _clearedDirty = {..._dirtyMonths};
        _dirtyMonths.clear();
      } else if (identical(to, _undo)) {
        _dirtyMonths.addAll(_clearedDirty); // 다시하기로 처음 상태를 벗어남
      }
    }
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
    for (var w = 0; w < repeatWeeks; w++) {
      _markDirty(ym(dayOf(date).add(Duration(days: 7 * w))));
    }
    _shiftRemote((api) => api.post('${_sp(store.id)}/shifts', {
          'date': ymd(date),
          'startMin': startMin,
          'endMin': endMin,
          'part': part,
          'staffIds': [for (final id in staffIds) _n(id)],
          'breakMin': ?breakMin,
          if (repeatWeeks > 1) 'repeatWeeks': repeatWeeks,
          'kind': kind.name,
          'timeTbd': timeTbd,
        }));
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
    _markDirty(s.date.substring(0, 7));
    _shiftRemote((api) => api.delete('${_sp(s.storeId)}/shifts/$shiftId'));
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
    final before = _shiftLabel(s), oldStaff = s.staffId, wasWork = s.isWork, oldMonth = s.date.substring(0, 7);
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
    _markDirty(oldMonth);
    _markDirty(s.date.substring(0, 7));
    _shiftRemote((api) => api.patch('${_sp(s.storeId)}/shifts/$shiftId', {
          if (staffId case final staffIdV?) 'staffId': _n(staffIdV),
          if (date case final dateV?) 'date': ymd(dateV),
          'startMin': ?startMin,
          'endMin': ?endMin,
          'part': ?part,
          'breakMin': ?breakMin,
          'kind': ?kind?.name,
          'timeTbd': ?timeTbd,
        }));
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
      // 서버(ShiftService.fill)와 같게 직원 파트·그날 안 쓰는 파트는 건너뛴다.
      for (final p in store.parts.where((p) => !p.flex && p.appliesOn(day))) {
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
    _markDirty(ym(monday));
    _markDirty(ym(monday.add(const Duration(days: 6))));
    _shiftRemote((api) => api.post('${_sp(store.id)}/schedule/auto-fill', {'weekMonday': ymd(monday)}));
    return added;
  }

  /// 근무표 확정: 재직 직원 모두에게 알린다.
  void confirmSchedule(int year, int month) {
    store.scheduleConfirmedAt = _iso(now);
    for (final s in activeStaff) {
      _notifyStaff(s.id, 'sub', '$month월 근무표가 확정됐어요', body: '근무표에서 내 근무를 확인해 주세요');
    }
    _commit();
    _remote((api) => api.post('${_sp(store.id)}/schedule/confirm', {'year': year, 'month': month}));
  }

  /// 근무표 만들기(웹): [from]–[to] 의 오늘 이후 날짜에 파트별 [needs](store.parts 순서) 만큼 근무를 짠다.
  /// 상태는 바꾸지 않고 미리보기만 돌려준다.
  /// - [copyLastWeek]: 오늘이 든 주의 바로 전 주 근무(연차·휴무 제외, 재직자만)를 요일마다 반복한 뒤 빈칸을 채운다
  /// - 빈칸은 그 파트가 자기 파트인 근무자 먼저, 그다음 그 주 근무가 적은 사람부터. [excludeStaffIds] 는 빼고,
  ///   그 주 소정 분이 [weeklyMaxMin] 을 넘게 되는 사람은 건너뛴다
  /// - 이미 있는 근무 · 겹치는 시간은 그대로 두고 피한다
  // 서버 적용 때 미리보기를 다시 올리려고 마지막 인자를 기억한다.
  Map<String, dynamic>? _lastPlanArgs;

  SchedulePlan planSchedule({
    required DateTime from,
    required DateTime to,
    required List<int> needs,
    bool copyLastWeek = false,
    Set<String> excludeStaffIds = const {},
    int weeklyMaxMin = 40 * 60,
  }) {
    _lastPlanArgs = {
      'from': ymd(dayOf(from)),
      'to': ymd(dayOf(to)),
      'needs': needs,
      'copyLastWeek': copyLastWeek,
      'excludeStaffIds': [for (final id in excludeStaffIds) _n(id)],
      'weeklyMaxMin': weeklyMaxMin,
    };
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
          if (p.flex || !p.appliesOn(day)) continue; // 서버 ShiftService.fill 과 같다
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
    final sid = store.id;
    final sendNeeds = needs ?? [for (final p in store.parts) p.need];
    final body = _lastPlanArgs ??
        {
          'from': ymd(plan.from),
          'to': ymd(plan.to),
          'needs': sendNeeds,
          'copyLastWeek': false,
        };
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
    _remote((api) async {
      final r = await api.post('${_sp(sid)}/schedule-plans', {...body, 'needs': sendNeeds})
          as Map<String, dynamic>;
      await api.post('${_sp(sid)}/schedule-plans/${r['planId']}/apply', {'needs': sendNeeds});
    });
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
        // BE applyTemplate 과 같은 규칙: 실제 근무만, 지난 날 제외, 같은 직원·파트 있으면·겹치면 건너뜀.
        if (target.isBefore(today)) continue;
        for (final s in scheduleOn(target.subtract(const Duration(days: 7))).where((x) => x.isWork)) {
          final staffId = s.originalStaffId ?? s.staffId;
          final exists = scheduleOn(target).any((x) => x.isWork && x.staffId == staffId && x.part == s.part);
          if (exists || !(staffById(staffId)?.active ?? false)) continue;
          final draft = Shift(
            id: _id('s'),
            storeId: store.id,
            staffId: staffId,
            date: ymd(target),
            startMin: s.startMin,
            endMin: s.endMin,
            part: s.part,
            breakMin: s.breakMin,
          );
          if (overlappingShift(staffId, draft) != null) continue;
          state.shifts.add(draft);
          copied++;
        }
      }
    }
    _commit();
    _remote((api) => api.post('${_sp(store.id)}/schedule/template',
        {'needs': needs, 'copyLastWeek': copyLastWeek}));
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
      part: st.timerParts.firstOrNull?.name ?? '',
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

  /// 서버 모드 가입 신청. 서버 응답의 result 를 [JoinResult] 로 돌려준다. 신청이 됐으면 서버 상태로 다시 읽는다.
  /// 서버는 200 `{result, store}`(신청 201). 예전 서버는 notFound·already* 를 404/409 본문으로 준다 — 둘 다 읽는다.
  Future<(JoinResult, Store?)> requestJoinRemote(String code) async {
    Map<String, dynamic> j;
    try {
      j = await _try((api) => api.post('/api/v1/stores/join-requests', {'code': code.trim()}))
          as Map<String, dynamic>;
    } on ApiException catch (e) {
      final b = e.body;
      if ((e.status != 404 && e.status != 409) || b == null || b['result'] is! String) rethrow;
      j = b;
    }
    final result = JoinResult.values.firstWhere((r) => r.name == j['result'],
        orElse: () => JoinResult.notFound);
    final ref = j['store'] as Map<String, dynamic>?;
    if (result == JoinResult.requested || result == JoinResult.alreadyMember) {
      try {
        await reload();
      } catch (_) {}
    }
    if (ref == null) return (result, null);
    final id = '${ref['id']}';
    return (
      result,
      storeById(id) ??
          Store(id: id, name: '${ref['name']}', address: '', code: _normCode(code), parts: [])
    );
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
    _remote((api) => api.post('${_sp(s.storeId)}/staff/$staffId/approve', {
          'wage': wage,
          'deduction': ?deduction?.name,
        }));
  }

  void rejectJoin(String staffId) {
    final s = staffById(staffId)!;
    s.status = StaffStatus.rejected;
    _notifyStaff(s.id, 'join', '${storeById(s.storeId)!.name} 가입이 거절됐어요');
    _commit();
    _remote((api) => api.post('${_sp(s.storeId)}/staff/$staffId/reject'));
  }

  void updateStaff(String staffId,
      {int? wage,
      Deduction? deduction,
      bool? weeklyHolidayAuto,
      bool? premium,
      String? part,
      StaffKind? kind,
      List<List<String>>? fixedParts,
      List<WorkHours?>? workHours,
      List<WorkHours?>? availHours}) {
    final s = staffById(staffId)!;
    if (kind != null) s.kind = kind;
    if (fixedParts != null) s.fixedParts = [for (final l in fixedParts) [...l]];
    if (workHours != null) s.workHours = [...workHours];
    if (availHours != null) s.availHours = [...availHours];
    if (wage != null && wage != s.wage) {
      if (s.wages.isEmpty) s.wages.add(WageStep('2000-01-01', s.wage));
      s.wages.add(WageStep(ymd(today), wage));
    }
    if (wage != null) s.wage = wage;
    if (deduction != null) s.deduction = deduction;
    if (weeklyHolidayAuto != null) s.weeklyHolidayAuto = weeklyHolidayAuto;
    if (premium != null) s.premium = premium;
    if (part != null) s.part = part;
    _commit();
    _remote((api) => api.patch('${_sp(s.storeId)}/staff/$staffId', {
          'wage': ?wage,
          'deduction': ?deduction?.name,
          'weeklyHolidayAuto': ?weeklyHolidayAuto,
          'premium': ?premium,
          'part': ?part,
          'kind': ?kind?.name,
          'fixedParts': ?fixedParts,
          if (workHours != null) 'workHours': [for (final w in workHours) w?.toJson()],
          if (availHours != null) 'availHours': [for (final w in availHours) w?.toJson()],
        }));
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
    _remote((api) => api.delete('${_sp(s.storeId)}/staff/$staffId'));
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
    _remote((api) => api.post('${_sp(n.storeId)}/notices', {
          'title': title,
          'body': body,
          'category': category,
          'required': ?required,
        }));
    return n;
  }

  /// [publishNotice] 의 서버 모드판: 서버가 정한 id 의 공지를 돌려준다(임시 id 는 reload 로 사라진다).
  Future<Notice> publishNoticeRemote({
    required String title,
    required String body,
    bool? required,
    String category = '일반',
  }) async {
    if (!remote) return publishNotice(title: title, body: body, required: required, category: category);
    final sid = store.id;
    final res = await _remoteWait((api) => api.post('${_sp(sid)}/notices', {
          'title': title,
          'body': body,
          'category': category,
          'required': ?required,
        })) as Map;
    final id = '${res['id']}';
    final known = noticeById(id);
    if (known != null) return known;
    final n = Notice(
        id: id,
        storeId: sid,
        title: title,
        body: body,
        category: category,
        required: required ?? store.noticeRequiredDefault,
        createdAt: _iso(now));
    state.notices.add(n);
    _commit();
    return n;
  }

  /// 가입(승인)한 날보다 먼저 올라온 공지는 그 직원에게 해당 없음(읽은 것으로 친다).
  bool _noticeBeforeJoin(Notice n, Staff s) =>
      s.joinedAt.length >= 10 && n.createdAt.length >= 10 && n.createdAt.substring(0, 10).compareTo(s.joinedAt.substring(0, 10)) < 0;

  void markNoticeRead(String noticeId) {
    final m = myStaff;
    final n = noticeById(noticeId);
    if (m == null || n == null || n.readBy.containsKey(m.id)) return;
    n.readBy[m.id] = _iso(now);
    _commit();
    _remote((api) => api.post('${_sp(n.storeId)}/notices/$noticeId/read'));
  }

  void markAllNoticesRead() {
    final m = myStaff;
    if (m == null) return;
    for (final n in storeNotices) {
      n.readBy.putIfAbsent(m.id, () => _iso(now));
    }
    _commit();
    final sid = store.id;
    _remote((api) => api.post('${_sp(sid)}/notices/read-all'));
  }

  List<Staff> unreadStaffOf(Notice n) => state.staff
      .where((s) =>
          s.storeId == n.storeId && s.active && !n.readBy.containsKey(s.id) && !_noticeBeforeJoin(n, s))
      .toList();

  /// 재알림은 1시간에 한 번(서버 NoticeService 와 같음).
  static const remindCooldown = Duration(hours: 1);

  /// 다시 알릴 수 있을 때까지 남은 시간. 지금 알릴 수 있으면 null.
  Duration? remindWait(Notice n) {
    final at = n.remindedAt == null ? null : DateTime.tryParse(n.remindedAt!);
    if (at == null) return null;
    final left = at.add(remindCooldown).difference(now);
    return left > Duration.zero ? left : null;
  }

  /// 안 읽은 직원에게 다시 알린다. 보낸 인원 수를 돌려준다. 1시간 안이면 아무것도 안 하고 0.
  /// 서버 모드 화면은 결과를 기다리는 [remindUnreadRemote] 를 쓴다.
  int remindUnread(String noticeId) {
    final n = noticeById(noticeId)!;
    if (remindWait(n) != null) return 0;
    final targets = unreadStaffOf(n);
    for (final s in targets) {
      _notifyStaff(s.id, 'notice', '필독 공지를 확인해 주세요', body: n.title, refId: n.id);
    }
    n.remindedAt = _iso(now);
    _commit();
    _remote((api) => api.post('${_sp(n.storeId)}/notices/$noticeId/remind'));
    return targets.length;
  }

  /// [remindUnread] 의 결과를 기다리는 판. 서버가 실제로 보낸 인원 수를 돌려준다.
  /// 1시간 안이거나 서버가 거절하면 ApiException(`REMIND_TOO_SOON` 등).
  Future<int> remindUnreadRemote(String noticeId) async {
    final n = noticeById(noticeId)!;
    if (remindWait(n) != null) {
      throw ApiException(409, 'REMIND_TOO_SOON', '방금 알렸어요. 1시간 뒤에 다시 알릴 수 있어요');
    }
    if (!remote) return remindUnread(noticeId);
    final r = await _try((a) => a.post('${_sp(n.storeId)}/notices/$noticeId/remind'));
    await _reloadQuiet();
    return r is Map && r['sent'] is num ? (r['sent'] as num).toInt() : 0;
  }

  /// 공지 수정(사장님). 읽음 기록은 그대로 두고 알림도 다시 보내지 않는다. 서버가 거절하면 [ApiException].
  Future<void> updateNoticeRemote(String noticeId,
      {required String title, required String body, required bool required, required String category}) async {
    final n = noticeById(noticeId)!;
    if (remote) {
      await _try((a) => a.put('${_sp(n.storeId)}/notices/$noticeId',
          {'title': title, 'body': body, 'category': category, 'required': required}));
    }
    n
      ..title = title
      ..body = body
      ..category = category
      ..required = required;
    _commit();
    if (remote) await _reloadQuiet();
  }

  /// 공지 삭제(사장님). 그 공지를 가리키는 알림도 함께 사라진다. 서버가 거절하면 [ApiException].
  Future<void> deleteNoticeRemote(String noticeId) async {
    final n = noticeById(noticeId);
    if (n == null) return;
    if (remote) await _try((a) => a.delete('${_sp(n.storeId)}/notices/$noticeId'));
    state.notices.removeWhere((x) => x.id == noticeId);
    state.notifications.removeWhere((x) => x.type == 'notice' && x.refId == noticeId);
    _commit();
    if (remote) await _reloadQuiet();
  }

  // ───────────────────────── 서류 ─────────────────────────

  /// 알바생(나)이 보건증 갱신본을 등록한다.
  void uploadHealthCert({required DateTime expiry, required List<int> alertDays}) {
    if (remote) return _unsupported(); // 사진 업로드(multipart) 미구현
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

  /// 서버 모드 보건증 등록. 사진(multipart)이 올라간 뒤 다시 읽는다. 실패하면 던진다.
  Future<void> uploadHealthCertRemote(
      {required DateTime expiry,
      required List<int> alertDays,
      required List<int> photo,
      required String filename}) async {
    await api!.multipart('PUT', '/api/v1/me/health-cert',
        fields: {'expiry': ymd(expiry), 'alertDays': alertDays.join(',')},
        fileField: 'photo',
        bytes: photo,
        filename: filename);
    await reload(storeId: session.storeId);
  }

  /// 서명 PNG 를 올리고 서버 id(signatureUrl)를 돌려준다.
  Future<String> uploadSignatureRemote(List<int> png) async {
    final j = await api!.multipart('POST', '/api/v1/me/signatures',
        fileField: 'image', bytes: png, filename: 'signature.png') as Map<String, dynamic>;
    return j['signatureUrl'] as String;
  }

  /// 서버 모드 계약 서명 (알바생). 서명 이미지를 올린 뒤 서명한다. 실패하면 던진다.
  /// 지금 보고 있는 계약서 id 를 함께 보낸다. 그 사이 사장님이 다시 작성했으면(409) 새 계약서를 읽고 다시 확인하게 한다.
  Future<void> signContractRemote(List<int> png) async {
    final s = myStaff!;
    final contractId = s.contract?.id;
    final url = await uploadSignatureRemote(png);
    try {
      await api!.post('${_sp(s.storeId)}/staff/${s.id}/contract/sign',
          {'signatureUrl': url, if (contractId != null) 'contractId': int.tryParse(contractId) ?? contractId});
    } on ApiException catch (e) {
      if (e.status != 409 || e.code == 'ALREADY_SIGNED') rethrow;
      await _reloadQuiet();
      throw ApiException(409, e.code, '계약서 내용이 바뀌었어요. 바뀐 내용을 확인하고 다시 서명해 주세요');
    }
    await reload(storeId: session.storeId);
  }

  /// 서버 모드 계약서 작성 (사장님). 서명 이미지를 올린 뒤 보낸다. 실패하면 던진다.
  Future<void> createContractRemote(String staffId, Contract c, List<int> png) async {
    final s = staffById(staffId)!;
    final url = await uploadSignatureRemote(png);
    await api!.put('${_sp(s.storeId)}/staff/$staffId/contract', {
      'start': c.start,
      'end': c.end,
      'wage': c.wage,
      'weeklyHours': c.weeklyHours,
      'workDays': c.workDays,
      'duty': c.duty,
      'ownerSignatureUrl': url,
    });
    await reload(storeId: session.storeId);
  }

  // ───────────────────────── 프로필 ─────────────────────────

  /// 프로필 입력 검증(서버 규칙·문구와 같다). 문제 없으면 null. 이름 길이는 code point(이모지 1자).
  static String? profileError({String? fullName, String? contact}) {
    if (fullName != null) {
      final n = fullName.trim();
      if (n.isEmpty) return '이름을 입력해 주세요';
      if (n.runes.length > 50) return '이름은 50자 이하로 입력해 주세요';
    }
    if (contact != null && (!RegExp(r'^[0-9-]*$').hasMatch(contact) || contact.length > 20)) {
      return '연락처는 숫자와 - 로 20자 이하로 입력해 주세요';
    }
    return null;
  }

  /// 내 이름·연락처 저장. 보낸 값만 바뀐다(연락처 '' 는 지우기). 실패 시 [ApiException].
  Future<void> updateProfile({String? fullName, String? contact}) async {
    final err = profileError(fullName: fullName, contact: contact);
    if (err != null) throw ApiException(400, 'validation', err);
    if (remote) {
      await _try((a) => a.patch('/api/v1/me/profile', {
            'fullName': ?fullName?.trim(),
            'contact': ?contact,
          }));
      await _reloadQuiet();
      return;
    }
    final p = me;
    // 서버도 이름을 바꾸면 name = fullName 으로 맞춘다.
    if (fullName != null) p.fullName = p.name = fullName.trim();
    if (contact != null) p.contact = contact.isEmpty ? null : contact;
    _commit();
  }

  /// 데모 모드 프로필 사진(서버가 없어 메모리에만 둔다). 키는 사람 id.
  final Map<String, Uint8List> demoPhotos = {};

  /// 내 프로필 사진 올리기. 실패 시 [ApiException].
  Future<void> uploadProfilePhoto(Uint8List bytes, String filename) async {
    if (remote) {
      await _try((a) => a.multipart('PUT', '/api/v1/me/photo',
          fileField: 'photo', bytes: bytes, filename: filename));
      await _reloadQuiet();
      return;
    }
    demoPhotos[me.id] = bytes;
    me
      ..hasPhoto = true
      ..photoVer = '${now.millisecondsSinceEpoch}';
    _commit();
  }

  /// 내 프로필 사진 지우기. 실패 시 [ApiException].
  Future<void> deleteProfilePhoto() async {
    if (remote) {
      await _try((a) => a.delete('/api/v1/me/photo'));
      await _reloadQuiet();
      return;
    }
    demoPhotos.remove(me.id);
    me
      ..hasPhoto = false
      ..photoVer = null;
    _commit();
  }

  /// 프로필 사진 주소. Image.network 에 `api.authHeaders` 를 같이 넘긴다. `?v=` 가 캐시 키.
  String personPhotoUrl(Person p) => '${api!.baseUrl}/api/v1/people/${p.id}/photo?v=${p.photoVer}';

  /// 직원 보건증 사진 주소 (사장님). Image.network 에 `api.authHeaders` 를 같이 넘긴다.
  String staffCertPhotoUrl(Staff s) =>
      '${api!.baseUrl}${_sp(s.storeId)}/staff/${s.id}/health-cert/photo';

  void requestCertRenewal(String staffId) {
    final s = staffById(staffId)!;
    final p = personOf(s);
    final left = certDaysLeft(p);
    _notifyStaff(staffId, 'cert',
        left == null ? '보건증을 등록해 주세요' : '보건증 만료 ${left >= 0 ? 'D-$left' : '지남'}',
        body: '내 서류에서 갱신본을 등록해 주세요');
    _commit();
    _remote((api) => api.post('${_sp(s.storeId)}/staff/$staffId/cert-renewal-requests'));
  }

  /// 사장님이 계약서를 작성하고 서명해 보낸다.
  void createContract(String staffId, Contract c) {
    final s = staffById(staffId)!;
    c
      ..ownerSignedAt = _iso(now)
      ..employeeSignedAt = null;
    s.contract = c;
    if (s.wages.isEmpty) s.wages.add(WageStep('2000-01-01', s.wage));
    s.wages.add(WageStep(c.start, c.wage));
    s.wage = c.wage;
    _notifyStaff(staffId, 'contract', '근로계약서 서명 요청', body: '내 서류에서 확인하고 서명해 주세요');
    _commit();
    _remote((api) => api.put('${_sp(s.storeId)}/staff/$staffId/contract', {
          'start': c.start,
          'end': c.end,
          'wage': c.wage,
          'weeklyHours': c.weeklyHours,
          'workDays': c.workDays,
          'duty': c.duty,
        }));
  }

  /// 알바생(나)이 현재 매장 계약서에 서명한다.
  void signContract() {
    final s = myStaff!;
    s.contract!.employeeSignedAt = _iso(now);
    _notifyOwner(s.storeId, 'contract', '${me.name}님이 근로계약서에 서명했어요');
    _commit();
    // 서명 이미지는 아직 올리지 않는다. 서버는 비어 있지 않은 문자열만 요구한다.
    _remote((api) => api.post('${_sp(s.storeId)}/staff/${s.id}/contract/sign',
        {'signatureUrl': 'app-signature', if (s.contract!.id case final cid?) 'contractId': int.tryParse(cid) ?? cid}));
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
    _remote((api) => api.patch(_sp(st.id), {
          'name': name,
          'address': address,
          'isSmall': isSmall,
          'defaultDeduction': deduction.name,
        }));
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
    _remote((api) => api.patch('${_sp(store.id)}/settings', {
          'isSmall': ?isSmall,
          'noticeRequiredDefault': ?noticeRequiredDefault,
          'substitutePush': ?substitutePush,
        }));
  }

  // ───────────────────────── 매장 설정 · 파트 (웹) ─────────────────────────

  /// 영업시간 검증. 문제 없으면 null.
  static String? validateHours(int open, int close, int wOpen, int wClose) {
    if (close <= open) return '평일 영업 종료 시각은 시작 시각보다 늦어야 합니다.';
    if (wClose <= wOpen) return '주말·공휴일 영업 종료 시각은 시작 시각보다 늦어야 합니다.';
    if (close - open > 1440 || wClose - wOpen > 1440) return '영업시간은 24시간을 넘을 수 없습니다.';
    return null;
  }

  /// 매장 설정 저장. 실패 시 [ApiException].
  Future<void> updateStoreSettings({
    String? name,
    String? address,
    int? openMin,
    int? closeMin,
    int? weekendOpenMin,
    int? weekendCloseMin,
    SizeMode? sizeMode,
    bool? noticeRequiredDefault,
    bool? substitutePush,
    Deduction? defaultDeduction,
  }) async {
    final st = store;
    final err = validateHours(openMin ?? st.openMin, closeMin ?? st.closeMin,
        weekendOpenMin ?? st.weekendOpenMin, weekendCloseMin ?? st.weekendCloseMin);
    if (err != null) throw ApiException(400, 'validation', err);
    if (address != null && address.trim().isEmpty) {
      throw ApiException(400, 'STORE_REQUIRED_FIELDS', '주소를 입력해 주세요');
    }
    if (remote) {
      await _try((a) => a.patch('${_sp(st.id)}/settings', {
            'name': ?name,
            'address': ?address,
            'openMin': ?openMin,
            'closeMin': ?closeMin,
            'weekendOpenMin': ?weekendOpenMin,
            'weekendCloseMin': ?weekendCloseMin,
            'sizeMode': ?sizeMode?.name,
            'noticeRequiredDefault': ?noticeRequiredDefault,
            'substitutePush': ?substitutePush,
            'defaultDeduction': ?defaultDeduction?.name,
          }));
      await _reloadQuiet();
      return;
    }
    if (name != null) st.name = name;
    if (address != null) st.address = address.trim();
    if (openMin != null) st.openMin = openMin;
    if (closeMin != null) st.closeMin = closeMin;
    if (weekendOpenMin != null) st.weekendOpenMin = weekendOpenMin;
    if (weekendCloseMin != null) st.weekendCloseMin = weekendCloseMin;
    if (sizeMode != null) {
      st.sizeMode = sizeMode;
      st.isSmall = switch (sizeMode) {
        SizeMode.auto => state.staff.where((x) => x.storeId == st.id && x.active).length < 5,
        SizeMode.under5 => true,
        SizeMode.over5 => false,
      };
    }
    if (noticeRequiredDefault != null) st.noticeRequiredDefault = noticeRequiredDefault;
    if (substitutePush != null) st.substitutePush = substitutePush;
    if (defaultDeduction != null) st.defaultDeduction = defaultDeduction;
    _commit();
  }

  /// DB(utf8mb4_unicode_ci)가 같은 이름으로 보는 키: 대소문자·전각/반각 무시.
  static String partNameKey(String name) => String.fromCharCodes(name.runes.map((c) =>
          c >= 0xFF01 && c <= 0xFF5E ? c - 0xFEE0 : c == 0x3000 ? 0x20 : c))
      .toLowerCase();

  /// 파트 목록을 통째로 저장(추가·수정·삭제). 이름이 바뀌면 근무·직원·고정 파트의 이름도 따라 바뀐다. 실패 시 [ApiException].
  Future<void> saveParts(List<PartTemplate> parts) async {
    final names = <String>{};
    for (final p in parts) {
      final n = p.name.trim();
      if (n.isEmpty) throw ApiException(400, 'validation', '파트 이름을 입력하세요.');
      if (p.endMin <= p.startMin) {
        throw ApiException(400, 'validation', '$n 종료 시각은 시작 시각보다 늦어야 합니다.');
      }
      if (!names.add(partNameKey(n))) throw ApiException(400, 'validation', '파트 이름이 겹쳐요: $n');
    }
    final st = store;
    if (remote) {
      await _try((a) => a.put('${_sp(st.id)}/parts', {
            'parts': [
              for (final p in parts)
                {
                  if (p.id.isNotEmpty) 'id': _n(p.id),
                  'name': p.name.trim(),
                  'tone': p.tone.name,
                  'startMin': p.startMin,
                  'endMin': p.endMin,
                  'breakMin': p.breakMin,
                  'need': p.need,
                  'flex': p.flex,
                  'days': p.days.name,
                }
            ]
          }));
      await _reloadQuiet();
      return;
    }
    final old = {for (final p in st.parts) p.id: p.name};
    final renames = <String, String>{};
    final next = <PartTemplate>[];
    for (final p in parts) {
      final c = p.copy()..name = p.name.trim();
      if (c.id.isEmpty) {
        c.id = _id('part');
      } else if (old[c.id] case final o? when o != c.name) {
        renames[o] = c.name;
      }
      next.add(c);
    }
    st.parts = next;
    if (renames.isNotEmpty) {
      for (final x in state.shifts.where((x) => x.storeId == st.id)) {
        x.part = renames[x.part] ?? x.part;
      }
      for (final m in state.staff.where((x) => x.storeId == st.id)) {
        m.part = renames[m.part] ?? m.part;
        m.fixedParts = [
          for (final l in m.fixedParts) [for (final n in l) renames[n] ?? n]
        ];
      }
    }
    _commit();
  }

  // ───────────────────────── 월 근무표 · 템플릿 (웹) ─────────────────────────

  List<MonthSchedule> get schedules =>
      state.schedules.where((m) => m.storeId == store.id).toList()
        ..sort((a, b) => b.month.compareTo(a.month));

  MonthSchedule? monthSchedule(String month) =>
      state.schedules.where((m) => m.storeId == store.id && m.month == month).firstOrNull;

  List<ScheduleTemplate> get templates =>
      state.templates.where((t) => t.storeId == store.id).toList();

  /// 그 달 대상 날짜: max(월초, 오늘) ~ 월말.
  List<DateTime> _targetDates(String month) => auto.monthDates(month, today);

  List<Shift> _monthShifts(String month) =>
      state.shifts.where((x) => x.storeId == store.id && x.date.startsWith(month)).toList();

  MonthSchedule _metaFor(String month, ScheduleSource source) {
    var m = monthSchedule(month);
    if (m == null) {
      m = MonthSchedule(id: _id('ms'), storeId: store.id, month: month, source: source);
      state.schedules.add(m);
    }
    m
      ..source = source
      ..status = ScheduleStatus.draft
      ..updatedAt = _iso(now);
    return m;
  }

  void _addAll(List<Shift> list) {
    for (final x in list) {
      state.shifts.add(Shift(
        id: _id('s'),
        storeId: store.id,
        staffId: x.staffId,
        date: x.date,
        startMin: x.startMin,
        endMin: x.endMin,
        part: x.part,
        breakMin: x.breakMin,
        kind: x.kind,
        timeTbd: x.timeTbd,
      ));
    }
  }

  /// 오늘 이후·출근 기록 없는 그 달 근무를 지운다.
  void _clearFuture(String month) => state.shifts.removeWhere((x) =>
      x.storeId == store.id &&
      x.date.startsWith(month) &&
      !parseYmd(x.date).isBefore(today) &&
      attendanceFor(x.id) == null);

  /// 직접 만들기. 있으면 draft 를 manual 로 갱신. [prefillFixed] 면 고정 근무를 채운다.
  Future<void> createMonthSchedule(String month, {bool prefillFixed = true}) async {
    if (remote) {
      await _try((a) => a.post('${_sp(store.id)}/schedules', {'month': month, 'prefillFixed': prefillFixed}));
      await _reloadQuiet();
      return;
    }
    _snapshot();
    _metaFor(month, ScheduleSource.manual);
    if (prefillFixed) {
      _addAll(auto.autofill(_monthShifts(month), auto.fixedShifts(store, activeStaff, _targetDates(month))));
    }
    _commit();
  }

  /// 고정 근무 중 빠진 것만 추가. 웹 초안 모드에서는 로컬에서만 하고(저장 때 올라간다) 아니면 서버에서 한다.
  Future<void> autofillMonth(String month) async {
    if (remote && !_draft) {
      await _try((a) => a.post('${_sp(store.id)}/schedules/$month/autofill'));
      await _reloadQuiet();
      return;
    }
    _snapshot();
    final add = auto.autofill(_monthShifts(month), auto.fixedShifts(store, activeStaff, _targetDates(month)));
    if (add.isEmpty) {
      _undo.removeLast();
      return;
    }
    _addAll(add);
    _markDirty(month);
    _commit();
  }

  /// 근무표 생성 미리보기(저장 안 함). 서버: generate/preview. 데모: 직원 파트 + 고정 근무로 채운 결과.
  Future<GeneratePreview> previewGenerate(String month,
      {required HolidayPolicy weeklyHolidayPay, required SchedulePriority priority}) async {
    if (remote) {
      final r = await _try((a) => a.post('${_sp(store.id)}/schedules/generate/preview', {
            'month': month,
            'weeklyHolidayPay': weeklyHolidayPay.name,
            'priority': priority.name,
          })) as Map;
      return GeneratePreview.fromJson(r.cast<String, dynamic>(), store.id);
    }
    bool cleared(Shift x) => !parseYmd(x.date).isBefore(today) && attendanceFor(x.id) == null;
    final month0 = _monthShifts(month);
    final kept = month0.where((x) => !cleared(x)).toList();
    // 서버처럼 직원 파트를 직원으로 먼저 채우고, 그다음 고정 근무(직원은 그날 근무가 있으면 건너뜀).
    final flexAdd = auto.flexPartShifts(store, activeStaff, _targetDates(month), kept);
    final add = [
      ...flexAdd,
      ...auto.autofill([...kept, ...flexAdd], auto.fixedShifts(store, activeStaff, _targetDates(month))),
    ];
    return GeneratePreview(
      planId: 'demo',
      month: month,
      shifts: add,
      lines: const ['데모: AI 없이 고정 근무로 채웠어요'],
      laborCost: add.fold(0, (sum, x) => sum + plannedPay(x)),
      unfilled: const [],
      replacing: month0.where((x) => cleared(x) && x.kind == ShiftKind.work).length,
    )
      ..weeklyHolidayPay = weeklyHolidayPay
      ..priority = priority;
  }

  /// 미리보기 [p] 를 저장한다(그 달 오늘 이후·출근 기록 없는 근무를 지우고 바꾼다).
  /// 서버: generate/apply. 만료면 410 [ApiException]. AI 설명은 서버가 나중에 붙인다.
  Future<void> applyGenerated(GeneratePreview p) async {
    if (remote) {
      await _try((a) => a.post('${_sp(store.id)}/schedules/generate/apply', {'planId': p.planId}));
      await _reloadQuiet();
      return;
    }
    _snapshot();
    _clearFuture(p.month);
    _addAll(p.shifts);
    _metaFor(p.month, ScheduleSource.ai)
      ..aiComment = p.lines.join('\n')
      ..weeklyHolidayPay = p.weeklyHolidayPay
      ..priority = p.priority;
    _commit();
  }

  /// 확정. 시간 미정이 있으면 409 [ApiException].
  Future<void> confirmMonth(String month) async {
    if (remote) {
      await _try((a) => a.post('${_sp(store.id)}/schedules/$month/confirm'));
      await _reloadQuiet();
      return;
    }
    if (_monthShifts(month).any((x) => x.timeTbd)) {
      throw ApiException(409, 'conflict', '시간 미정을 먼저 해결하세요');
    }
    _metaFor(month, monthSchedule(month)?.source ?? ScheduleSource.manual).status = ScheduleStatus.confirmed;
    store.scheduleConfirmedAt = _iso(now);
    final mm = int.parse(month.substring(5));
    for (final x in activeStaff) {
      _notifyStaff(x.id, 'sub', '$mm월 근무표가 확정됐어요', body: '근무표에서 내 근무를 확인해 주세요');
    }
    _commit();
  }

  /// 그 달 근무표 삭제(출근 기록 없는 근무 + 메타).
  Future<void> deleteMonthSchedule(String month) async {
    if (remote) {
      await _try((a) => a.delete('${_sp(store.id)}/schedules/$month'));
      _dirtyMonths.remove(month);
      await _reloadQuiet();
      return;
    }
    _snapshot();
    state.shifts.removeWhere((x) =>
        x.storeId == store.id && x.date.startsWith(month) && attendanceFor(x.id) == null);
    state.schedules.removeWhere((m) => m.storeId == store.id && m.month == month);
    _dirtyMonths.remove(month);
    _commit();
  }

  Future<void> saveScheduleTemplate(String name, String month) async {
    if (remote) {
      await _try((a) => a.post('${_sp(store.id)}/schedule-templates', {'name': name, 'month': month}));
      await _reloadQuiet();
      return;
    }
    state.templates.add(ScheduleTemplate(
      id: _id('tp'),
      storeId: store.id,
      name: name,
      createdAt: _iso(now),
      shifts: auto.toPattern(_monthShifts(month), month),
    ));
    _commit();
  }

  /// 템플릿을 그 달에 적용(오늘 이후·출근 기록 없는 기존 근무는 교체).
  Future<void> applyScheduleTemplate(String templateId, String month) async {
    if (remote) {
      await _try((a) => a.post('${_sp(store.id)}/schedule-templates/$templateId/apply', {'month': month}));
      await _reloadQuiet();
      return;
    }
    final t = state.templates.where((x) => x.id == templateId).firstOrNull;
    if (t == null) throw ApiException(404, 'not_found', '템플릿을 찾을 수 없어요');
    _snapshot();
    _clearFuture(month);
    final activeIds = {for (final x in activeStaff) x.id};
    _addAll(auto.fillMonth([for (final x in t.shifts) if (activeIds.contains(x.staffId)) x], month, today));
    _metaFor(month, ScheduleSource.template).aiComment = '템플릿 "${t.name}"을 적용했어요';
    _commit();
  }

  Future<void> deleteScheduleTemplate(String templateId) async {
    if (remote) {
      await _try((a) => a.delete('${_sp(store.id)}/schedule-templates/$templateId'));
      await _reloadQuiet();
      return;
    }
    state.templates.removeWhere((x) => x.id == templateId);
    _commit();
  }
}

/// 서버 요청 실패를 사용자에게 보일 문구로.
String remoteErrorText(Object e) => e is ApiException ? e.message : '서버와 통신하지 못했어요';
