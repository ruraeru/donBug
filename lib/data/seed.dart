/// 데모 초기 데이터. [buildSeed]에 넘긴 시각 기준으로 지난달 1일이 있는 주부터 다음 주(또는 이번 달 끝 주)까지 만든다.
///
/// 카페 근무표는 파트(오픈 · 미들 · 마감)마다 필요 인원 1명을 매일 채운다. 데모용으로 일부러 남긴 것:
/// - 다음 주 일요일 마감 1칸 비움(자동 채우기 시연)
/// - 매니저 지훈의 다음 주 토요일 근무는 시간 미정
/// - 매니저 지훈의 이번 주 연차 1건
library;

import 'format.dart';
import 'models.dart';

const cafeId = 'st-cafe';
const moaId = 'st-moa';
const ownerPersonId = 'p-owner';
const meEmployeePersonId = 'p-taewoo';

/// 파트 근무 패턴(요일 1=월 … 7=일).
class _Pattern {
  const _Pattern(this.part, this.start, this.end, this.breakMin, this.days);
  final String part;
  final int start;
  final int end;
  final int breakMin;
  final Set<int> days;

  int get weeklyMinutes =>
      days.length * ((end <= start ? end + 1440 : end) - start - breakMin);
}

/// 매니저 지훈의 요일별 출퇴근(분). 수·일 휴무.
const _managerTimes = {
  1: (540, 1080),
  2: (630, 1170),
  4: (780, 1320),
  5: (660, 1200),
  6: (480, 1020),
};

const _weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];

String _daysLabel(Iterable<int> days) =>
    (days.toList()..sort()).map((d) => _weekdayNames[d - 1]).join('·');

AppState buildSeed(DateTime now) {
  final today = dayOf(now);
  var next = 1;
  String id(String p) => '$p${next++}';
  String iso(DateTime t) => t.toIso8601String();
  String daysFrom(int d) => ymd(today.add(Duration(days: d)));
  DateTime ago({int days = 0, int hours = 0, int minutes = 0}) =>
      now.subtract(Duration(days: days, hours: hours, minutes: minutes));

  final persons = [
    Person(id: ownerPersonId, name: '사장님', fullName: '사장님'),
    Person(id: 'p-jihun', name: '지훈', fullName: '오지훈', certExpiry: daysFrom(330)),
    Person(id: 'p-jimin', name: '지민', fullName: '김지민', certExpiry: daysFrom(250)),
    Person(id: 'p-subin', name: '수빈', fullName: '이수빈', certExpiry: daysFrom(12)),
    Person(id: 'p-hayun', name: '하윤', fullName: '최하윤', certExpiry: daysFrom(170)),
    Person(id: meEmployeePersonId, name: '태우', fullName: '김태우', certExpiry: daysFrom(25)),
    Person(id: 'p-seoyeon', name: '서연', fullName: '이서연', certExpiry: daysFrom(300)),
    Person(id: 'p-yuna', name: '유나', fullName: '정유나', certExpiry: daysFrom(210)),
    Person(id: 'p-dohyun', name: '도현', fullName: '박도현'),
  ];

  // 미들은 태우가 오늘 포함 격일 3일, 서연이 나머지 4일. 데모 알바생(태우)은 오늘 항상 근무한다.
  final w = today.weekday;
  final taewooDays = {for (final d in [w, w + 2, w + 4]) (d - 1) % 7 + 1};
  final seoyeonDays = {for (var d = 1; d <= 7; d++) d}.difference(taewooDays);

  const open = (600, 960), middle = (840, 1200), close = (1080, 1320);
  const jiminDays = {1, 2, 3, 4}, subinDays = {5, 6, 7};
  const hayunDays = {2, 3, 4, 5, 6}, yunaDays = {1, 7};

  final staff = <Staff>[];
  Staff add(String store, String person, String part, int wage,
      {Deduction deduction = Deduction.biz33,
      Tone tone = Tone.primary,
      StaffKind kind = StaffKind.partTimer,
      StaffStatus status = StaffStatus.active,
      Contract? contract,
      int joinedDaysAgo = 120}) {
    final s = Staff(
      id: id('m'),
      storeId: store,
      personId: person,
      part: part,
      wage: wage,
      deduction: deduction,
      // 카페는 5인 이상이라 가산수당 적용.
      premium: store == cafeId,
      tone: tone,
      kind: kind,
      joinedAt: daysFrom(-joinedDaysAgo),
      status: status,
      contract: contract,
      requestedAt: status == StaffStatus.pending ? iso(ago(minutes: 64)) : null,
    );
    staff.add(s);
    return s;
  }

  Contract contract(int wage, int weeklyHours, String days, String duty,
          {bool employeeSigned = true}) =>
      Contract(
        start: daysFrom(-60),
        end: daysFrom(305),
        wage: wage,
        weeklyHours: weeklyHours,
        workDays: days,
        duty: duty,
        ownerSignedAt: iso(ago(days: 3)),
        employeeSignedAt: employeeSigned ? iso(ago(days: 2)) : null,
      );

  // 패턴을 먼저 정해 계약서의 근무 요일 · 주 시간과 맞춘다.
  final cafePatterns = <String, _Pattern>{
    'p-jimin': _Pattern('오픈', open.$1, open.$2, 30, jiminDays),
    'p-subin': _Pattern('오픈', open.$1, open.$2, 30, subinDays),
    'p-hayun': _Pattern('마감', close.$1, close.$2, 0, hayunDays),
    meEmployeePersonId: _Pattern('미들', middle.$1, middle.$2, 30, taewooDays),
    'p-seoyeon': _Pattern('미들', middle.$1, middle.$2, 30, seoyeonDays),
    'p-yuna': _Pattern('마감', close.$1, close.$2, 0, yunaDays),
  };
  Contract partContract(String person, int wage, String duty, {bool employeeSigned = true}) {
    final p = cafePatterns[person]!;
    return contract(wage, (p.weeklyMinutes / 60).round(), _daysLabel(p.days), duty,
        employeeSigned: employeeSigned);
  }

  final jihun = add(cafeId, 'p-jihun', '직원', 12500,
      deduction: Deduction.insurance,
      tone: Tone.info,
      kind: StaffKind.manager,
      contract: contract(12500, 40, _daysLabel(_managerTimes.keys), '매장 운영 · 발주'),
      joinedDaysAgo: 600);
  final jimin = add(cafeId, 'p-jimin', '오픈', 10320,
      contract: partContract('p-jimin', 10320, '홀 서빙'), joinedDaysAgo: 400);
  final subin = add(cafeId, 'p-subin', '오픈', 10320,
      deduction: Deduction.insurance,
      tone: Tone.accent,
      contract: partContract('p-subin', 10320, '홀 서빙'),
      joinedDaysAgo: 70);
  final hayun = add(cafeId, 'p-hayun', '마감', 10320,
      deduction: Deduction.insurance,
      tone: Tone.info,
      contract: partContract('p-hayun', 10320, '주방'),
      joinedDaysAgo: 200);
  final taewoo = add(cafeId, meEmployeePersonId, '미들', 10320,
      contract: partContract(meEmployeePersonId, 10320, '홀 서빙', employeeSigned: false),
      joinedDaysAgo: 90);
  final seoyeon = add(cafeId, 'p-seoyeon', '미들', 10500,
      tone: Tone.danger,
      contract: partContract('p-seoyeon', 10500, '홀 서빙', employeeSigned: false),
      joinedDaysAgo: 30);
  final yuna = add(cafeId, 'p-yuna', '마감', 10320,
      tone: Tone.accent,
      kind: StaffKind.minor,
      contract: partContract('p-yuna', 10320, '주방 보조'),
      joinedDaysAgo: 45);
  add(cafeId, 'p-dohyun', '미들', 10320, status: StaffStatus.pending, joinedDaysAgo: 0);
  final taewooMoa = add(moaId, meEmployeePersonId, '야간', 10500,
      contract: contract(10500, 14, '토·일', '계산 · 진열'), joinedDaysAgo: 150);

  final byPerson = {for (final s in staff) if (s.storeId == cafeId) s.personId: s};
  final patterns = <Staff, _Pattern>{
    for (final e in cafePatterns.entries) byPerson[e.key]!: e.value,
    taewooMoa: const _Pattern('야간', 1320, 360, 60, {6, 7}),
  };

  // 인건비 추이: 2달 전 이전은 근무를 만들지 않으므로, 패턴으로 낸 한 달 인건비(주휴 포함)에 작은 변동을 준다.
  var monthlyBase = 0.0;
  void addMonthly(int weeklyMin, int wage) {
    final h = weeklyMin / 60;
    final holiday = h >= 15 ? (h > 40 ? 40 : h) / 40 * 8 : 0;
    monthlyBase += (h + holiday) * wage * 4.345;
  }

  patterns.forEach((s, p) {
    if (s.storeId == cafeId) addMonthly(p.weeklyMinutes, s.wage);
  });
  addMonthly(_managerTimes.values.fold(0, (sum, t) => sum + t.$2 - t.$1 - 60), jihun.wage);
  final monthly = <String, int>{};
  const drift = [0.97, 1.03, 0.95, 0.99];
  for (var i = 0; i < drift.length; i++) {
    monthly[ym(DateTime(today.year, today.month - 2 - i, 1))] =
        (monthlyBase * drift[i] / 1000).round() * 1000;
  }

  final stores = [
    Store(
      id: cafeId,
      name: '카페 커푸치노',
      address: '서울특별시 마포구 와우산로 94',
      code: 'CAFE-8K2D',
      ownerPersonId: ownerPersonId,
      // 재직 7명: 상시 5인 이상.
      isSmall: false,
      parts: [
        PartTemplate('오픈', open.$1, open.$2, 1),
        PartTemplate('미들', middle.$1, middle.$2, 1),
        PartTemplate('마감', close.$1, close.$2, 1),
      ],
      monthlyTotals: monthly,
    ),
    Store(
      id: moaId,
      name: '편의점 모아',
      address: '서울특별시 마포구 어울마당로 35',
      code: 'MOA-27QX',
      parts: [PartTemplate('야간', 1320, 360, 1)],
    ),
  ];

  final shifts = <Shift>[];
  final from = mondayOf(DateTime(today.year, today.month - 1, 1));
  final nextMonday = mondayOf(today).add(const Duration(days: 7));
  // 다음 주까지, 그리고 이번 달 끝이 든 주까지(이번 달 예상 인건비가 빠지지 않게).
  final monthEndWeek = mondayOf(DateTime(today.year, today.month + 1, 0)).add(const Duration(days: 6));
  final nextSunday = nextMonday.add(const Duration(days: 6));
  final to = monthEndWeek.isAfter(nextSunday) ? monthEndWeek : nextSunday;
  final gapDay = nextSunday; // 다음 주 일요일: 마감 비움
  final leaveDay = today.add(Duration(
      days: [1, 2, 3, 4, 5, 6].firstWhere((d) => _managerTimes.containsKey((w + d - 1) % 7 + 1))));
  final tbdDay = nextMonday.add(const Duration(days: 5)); // 다음 주 토요일
  for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1))) {
    patterns.forEach((s, p) {
      if (!p.days.contains(d.weekday)) return;
      if (d == gapDay && s == yuna) return;
      shifts.add(Shift(
        id: id('s'),
        storeId: s.storeId,
        staffId: s.id,
        date: ymd(d),
        startMin: p.start,
        endMin: p.end,
        part: p.part,
        breakMin: p.breakMin,
      ));
    });
    final mt = _managerTimes[d.weekday];
    if (mt != null) {
      shifts.add(Shift(
        id: id('s'),
        storeId: cafeId,
        staffId: jihun.id,
        date: ymd(d),
        startMin: d == tbdDay ? 720 : mt.$1,
        endMin: d == tbdDay ? 1260 : mt.$2,
        part: '직원',
        breakMin: 60,
        kind: d == leaveDay ? ShiftKind.leave : ShiftKind.work,
        timeTbd: d == tbdDay,
      ));
    }
  }

  DateTime startOf(Shift s) => parseYmd(s.date).add(Duration(minutes: s.startMin));
  DateTime endOf(Shift s) => parseYmd(s.date).add(Duration(minutes: s.endAbs));

  // 지난 근무 + 오늘 이미 시작한 근무의 출근 기록. 태우의 오늘 근무는 데모에서 직접 한다.
  // 오늘 오픈 근무자는 12분 지각.
  final attendance = <Attendance>[];
  for (var i = 0; i < shifts.length; i++) {
    final s = shifts[i];
    final mine = s.staffId == taewoo.id || s.staffId == taewooMoa.id;
    if (!s.isWork || !startOf(s).isBefore(now) || (mine && s.date == ymd(today))) continue;
    final late = s.part == '오픈' && s.date == ymd(today) ? 12 : 0;
    final inAt = startOf(s).add(Duration(minutes: late + (i * 7) % 5 - 2));
    final out = endOf(s).add(Duration(minutes: (i * 3) % 6));
    attendance.add(Attendance(
      id: id('a'),
      storeId: s.storeId,
      shiftId: s.id,
      staffId: s.staffId,
      clockIn: iso(inAt),
      clockOut: out.isBefore(now) ? iso(out) : null,
    ));
  }

  Shift firstFuture(Staff s, {DateTime? after}) => shifts.firstWhere((x) =>
      x.staffId == s.id && x.isWork && parseYmd(x.date).isAfter(after ?? today));

  // 서연 → 태우 대타(승인 완료), 수빈 요청(지민 수락, 사장님 승인 대기), 하윤 요청(지원 대기).
  final subs = <SubstituteRequest>[];
  final seoShift = firstFuture(seoyeon, after: today.add(const Duration(days: 1)));
  subs.add(SubstituteRequest(
    id: id('r'),
    storeId: cafeId,
    shiftId: seoShift.id,
    requesterId: seoyeon.id,
    reason: '가족 행사',
    status: SubStatus.approved,
    applicantIds: [taewoo.id],
    acceptedId: taewoo.id,
    createdAt: iso(ago(days: 2)),
  ));
  seoShift
    ..originalStaffId = seoyeon.id
    ..staffId = taewoo.id
    ..isSubstitute = true;
  final subinReq = SubstituteRequest(
    id: id('r'),
    storeId: cafeId,
    shiftId: firstFuture(subin).id,
    requesterId: subin.id,
    reason: '병원 진료',
    status: SubStatus.accepted,
    applicantIds: [jimin.id],
    acceptedId: jimin.id,
    createdAt: iso(ago(hours: 2)),
  );
  final hayunReq = SubstituteRequest(
    id: id('r'),
    storeId: cafeId,
    shiftId: firstFuture(hayun).id,
    requesterId: hayun.id,
    reason: '개인 사정',
    createdAt: iso(ago(hours: 5)),
  );
  subs.addAll([subinReq, hayunReq]);

  String readAt({int days = 0, int hours = 0}) => iso(ago(days: days, hours: hours));
  final notices = [
    Notice(
      id: id('n'),
      storeId: cafeId,
      title: '매장 위생 점검 안내',
      body: '이번 주 토요일 구청 위생 점검이 있어요. 오픈 조는 30분 일찍 와서 냉장고 온도 기록지를 확인해 주세요.',
      category: '중요',
      required: true,
      pinned: true,
      createdAt: readAt(hours: 6),
      readBy: {
        jihun.id: readAt(hours: 5),
        jimin.id: readAt(hours: 4),
        subin.id: readAt(hours: 3),
      },
    ),
    Notice(
      id: id('n'),
      storeId: cafeId,
      title: '마감 청소 방법 안내',
      body: '1. 음료 머신 세척 (15분)\n2. 바닥 물걸레 후 건조\n3. 쓰레기 분리배출 후 사진 업로드',
      required: true,
      createdAt: readAt(days: 3),
      readBy: {
        jihun.id: readAt(days: 3),
        jimin.id: readAt(days: 2),
        subin.id: readAt(days: 2),
        hayun.id: readAt(days: 2),
        yuna.id: readAt(days: 1),
      },
    ),
    Notice(
      id: id('n'),
      storeId: cafeId,
      title: '다음 달 근무표 작성 안내',
      body: '다음 달 근무표는 25일에 확정해요. 휴무 신청은 그 전까지 앱에서 해 주세요.',
      createdAt: readAt(days: 5),
      readBy: {
        for (final s in [jihun, jimin, hayun, seoyeon, yuna]) s.id: readAt(days: 4),
      },
    ),
    Notice(
      id: id('n'),
      storeId: cafeId,
      title: '보건증 만료 알림 안내',
      body: '보건증이 만료되기 30일 전부터 앱에서 알림을 보내요. 갱신본은 내 서류에서 등록해 주세요.',
      category: '노무',
      createdAt: readAt(days: 9),
      readBy: {
        for (final s in [jihun, jimin, subin, hayun, taewoo, seoyeon, yuna])
          s.id: readAt(days: 8),
      },
    ),
    Notice(
      id: id('n'),
      storeId: moaId,
      title: '야간 근무 시 금고 점검',
      body: '새벽 3시 정산 전에 금고 잔액을 확인하고 일지에 적어 주세요.',
      required: true,
      createdAt: readAt(days: 3),
    ),
  ];

  final notifications = <AppNotification>[
    // 알바생(태우)
    AppNotification(
      id: id('x'),
      storeId: cafeId,
      toPersonId: meEmployeePersonId,
      type: 'notice',
      title: '새 필독 공지',
      body: '마감 청소 방법 안내',
      createdAt: notices[1].createdAt,
      refId: notices[1].id,
    ),
    AppNotification(
      id: id('x'),
      storeId: cafeId,
      toPersonId: meEmployeePersonId,
      type: 'sub',
      title: '대타 근무가 확정됐어요',
      body: '${md(parseYmd(seoShift.date))} ${range(seoShift.startMin, seoShift.endMin)} · 서연님 근무',
      createdAt: readAt(days: 1, hours: 20),
      refId: subs.first.id,
    ),
    AppNotification(
      id: id('x'),
      storeId: cafeId,
      toPersonId: meEmployeePersonId,
      type: 'cert',
      title: '보건증 만료 D-25',
      body: '내 서류에서 갱신본을 등록해 주세요',
      createdAt: readAt(days: 0, hours: 9),
    ),
    // 사장님
    AppNotification(
      id: id('x'),
      storeId: cafeId,
      toPersonId: ownerPersonId,
      type: 'contract',
      title: '유나님이 근로계약서에 서명했어요',
      createdAt: readAt(days: 2),
      read: true,
    ),
    AppNotification(
      id: id('x'),
      storeId: cafeId,
      toPersonId: ownerPersonId,
      type: 'cert',
      title: '수빈님 보건증 만료 D-12',
      body: '갱신 요청을 보내 주세요',
      createdAt: readAt(hours: 9),
      refId: subin.id,
    ),
    AppNotification(
      id: id('x'),
      storeId: cafeId,
      toPersonId: ownerPersonId,
      type: 'sub',
      title: '하윤님이 휴무·대타를 신청했어요',
      body: '동료 지원을 기다리고 있어요',
      createdAt: hayunReq.createdAt,
      refId: hayunReq.id,
      read: true,
    ),
    AppNotification(
      id: id('x'),
      storeId: cafeId,
      toPersonId: ownerPersonId,
      type: 'join',
      title: '도현님이 가입을 신청했어요',
      body: '직원 관리에서 승인해 주세요',
      createdAt: iso(ago(minutes: 64)),
    ),
    AppNotification(
      id: id('x'),
      storeId: cafeId,
      toPersonId: ownerPersonId,
      type: 'sub',
      title: '지민님이 수빈님 대타를 수락했어요',
      body: '승인하면 근무표에 반영돼요',
      createdAt: subinReq.createdAt,
      refId: subinReq.id,
    ),
  ];

  return AppState(
    session: Session(
      employeeId: meEmployeePersonId,
      ownerId: ownerPersonId,
      employeeStoreId: cafeId,
      ownerStoreId: cafeId,
    ),
    persons: persons,
    stores: stores,
    staff: staff,
    shifts: shifts,
    attendance: attendance,
    subs: subs,
    notices: notices,
    notifications: notifications,
    nextId: next,
  );
}
