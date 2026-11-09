/// 데모 초기 데이터. [buildSeed]에 넘긴 시각 기준으로 지난달 1일이 있는 주부터 다음 주까지 만든다.
library;

import 'format.dart';
import 'models.dart';

const cafeId = 'st-cafe';
const moaId = 'st-moa';
const ownerPersonId = 'p-owner';
const meEmployeePersonId = 'p-taewoo';

class _Pattern {
  const _Pattern(this.part, this.start, this.end, this.breakMin, this.days);
  final String part;
  final int start;
  final int end;
  final int breakMin;
  final Set<int> days;
}

AppState buildSeed(DateTime now) {
  final today = dayOf(now);
  var next = 1;
  String id(String p) => '$p${next++}';
  String iso(DateTime t) => t.toIso8601String();
  String daysFrom(int d) => ymd(today.add(Duration(days: d)));

  final persons = [
    Person(id: ownerPersonId, name: '사장님', fullName: '사장님'),
    Person(id: 'p-jimin', name: '지민', fullName: '김지민', certExpiry: daysFrom(250)),
    Person(id: 'p-subin', name: '수빈', fullName: '이수빈', certExpiry: daysFrom(12)),
    Person(id: 'p-hayun', name: '하윤', fullName: '최하윤', certExpiry: daysFrom(170)),
    Person(id: meEmployeePersonId, name: '태우', fullName: '김태우', certExpiry: daysFrom(12)),
    Person(id: 'p-seoyeon', name: '서연', fullName: '이서연', certExpiry: daysFrom(300)),
    Person(id: 'p-dohyun', name: '도현', fullName: '박도현'),
  ];

  List<PartTemplate> cafeParts() => [
        PartTemplate('오픈', 600, 960, 2),
        PartTemplate('미들', 840, 1200, 2),
        PartTemplate('마감', 1080, 1320, 2),
      ];

  final monthly = <String, int>{};
  const history = [5000000, 4900000, 4200000, 4600000];
  for (var i = 0; i < history.length; i++) {
    monthly[ym(DateTime(today.year, today.month - 2 - i, 1))] = history[i];
  }

  final stores = [
    Store(
      id: cafeId,
      name: '카페 커푸치노',
      address: '서울특별시 마포구 와우산로 94',
      code: 'CAFE-8K2D',
      ownerPersonId: ownerPersonId,
      parts: cafeParts(),
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

  Contract signedContract(int wage, int weeklyHours, String days, String duty,
          {bool employeeSigned = true}) =>
      Contract(
        start: daysFrom(-60),
        end: daysFrom(305),
        wage: wage,
        weeklyHours: weeklyHours,
        workDays: days,
        duty: duty,
        ownerSignedAt: iso(now.subtract(const Duration(days: 2))),
        employeeSignedAt:
            employeeSigned ? iso(now.subtract(const Duration(days: 1))) : null,
      );

  final staff = <Staff>[];
  Staff add(String store, String person, String part, int wage,
      {Deduction deduction = Deduction.biz33,
      Tone tone = Tone.primary,
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
      tone: tone,
      joinedAt: daysFrom(-joinedDaysAgo),
      status: status,
      contract: contract,
      requestedAt: status == StaffStatus.pending
          ? iso(now.subtract(const Duration(minutes: 64)))
          : null,
    );
    staff.add(s);
    return s;
  }

  final jimin = add(cafeId, 'p-jimin', '오픈', 10320,
      contract: signedContract(10320, 22, '월·화·수·목', '홀 서빙'), joinedDaysAgo: 400);
  final subin = add(cafeId, 'p-subin', '오픈', 10320,
      deduction: Deduction.insurance,
      tone: Tone.accent,
      contract: signedContract(10320, 16, '월·수·금', '홀 서빙'),
      joinedDaysAgo: 70);
  final hayun = add(cafeId, 'p-hayun', '마감', 10320,
      deduction: Deduction.insurance,
      tone: Tone.info,
      contract: signedContract(10320, 20, '화–토', '주방'),
      joinedDaysAgo: 200);
  final taewoo = add(cafeId, meEmployeePersonId, '미들', 10320,
      contract: signedContract(10320, 16, '월·수·금', '홀 서빙', employeeSigned: false),
      joinedDaysAgo: 90);
  final seoyeon = add(cafeId, 'p-seoyeon', '미들', 10500,
      tone: Tone.danger,
      contract: signedContract(10500, 22, '화·목·토·일', '홀 서빙', employeeSigned: false),
      joinedDaysAgo: 30);
  add(cafeId, 'p-dohyun', '미들', 10320, status: StaffStatus.pending, joinedDaysAgo: 0);
  final taewooMoa = add(moaId, meEmployeePersonId, '야간', 10500,
      contract: signedContract(10500, 16, '토·일', '계산 · 진열'), joinedDaysAgo: 150);

  final patterns = <Staff, _Pattern>{
    jimin: const _Pattern('오픈', 600, 960, 30, {1, 2, 3, 4}),
    subin: const _Pattern('오픈', 600, 960, 30, {1, 3, 5}),
    hayun: const _Pattern('마감', 1080, 1320, 0, {2, 3, 4, 5, 6}),
    taewoo: const _Pattern('미들', 840, 1200, 30, {1, 3, 5}),
    seoyeon: const _Pattern('미들', 840, 1200, 30, {2, 4, 6, 7}),
    taewooMoa: const _Pattern('야간', 1320, 360, 60, {6, 7}),
  };

  final shifts = <Shift>[];
  final from = mondayOf(DateTime(today.year, today.month - 1, 1));
  final to = mondayOf(today).add(const Duration(days: 13));
  for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1))) {
    patterns.forEach((s, p) {
      final isToday = d == today && s == taewoo;
      if (p.days.contains(d.weekday) || isToday) {
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
      }
    });
  }

  DateTime startOf(Shift s) => parseYmd(s.date).add(Duration(minutes: s.startMin));
  DateTime endOf(Shift s) => parseYmd(s.date).add(Duration(minutes: s.endAbs));

  // 지난 근무 + 오늘 이미 시작한 근무의 출근 기록. 태우의 오늘 근무는 데모에서 직접 한다.
  final attendance = <Attendance>[];
  for (var i = 0; i < shifts.length; i++) {
    final s = shifts[i];
    final mine = s.staffId == taewoo.id || s.staffId == taewooMoa.id;
    if (!startOf(s).isBefore(now) || (mine && s.date == ymd(today))) continue;
    final late = s.staffId == subin.id && s.date == ymd(today) ? 12 : 0;
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
      x.staffId == s.id && parseYmd(x.date).isAfter(after ?? today));

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
    createdAt: iso(now.subtract(const Duration(days: 2))),
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
    createdAt: iso(now.subtract(const Duration(minutes: 3))),
  );
  final hayunReq = SubstituteRequest(
    id: id('r'),
    storeId: cafeId,
    shiftId: firstFuture(hayun).id,
    requesterId: hayun.id,
    reason: '개인 사정',
    createdAt: iso(now.subtract(const Duration(minutes: 70))),
  );
  subs.addAll([subinReq, hayunReq]);

  final notices = [
    Notice(
      id: id('n'),
      storeId: cafeId,
      title: '매장 위생 점검 안내',
      body: '이번 주 토요일 구청 위생 점검이 있어요. 오픈 조는 30분 일찍 와서 냉장고 온도 기록지를 확인해 주세요.',
      category: '중요',
      required: true,
      pinned: true,
      createdAt: iso(now.subtract(const Duration(hours: 5))),
      readBy: {jimin.id: iso(now.subtract(const Duration(hours: 4))), subin.id: iso(now.subtract(const Duration(hours: 3)))},
    ),
    Notice(
      id: id('n'),
      storeId: cafeId,
      title: '마감 청소 방법 안내',
      body: '1. 음료 머신 세척 (15분)\n2. 바닥 물걸레 후 건조\n3. 쓰레기 분리배출 후 사진 업로드',
      required: true,
      createdAt: iso(now.subtract(const Duration(days: 2, hours: 2))),
      readBy: {
        jimin.id: iso(now.subtract(const Duration(days: 2))),
        subin.id: iso(now.subtract(const Duration(days: 2))),
        hayun.id: iso(now.subtract(const Duration(days: 1))),
      },
    ),
    Notice(
      id: id('n'),
      storeId: cafeId,
      title: '다음 달 근무표 확정 안내',
      body: '다음 달 근무표가 확정되었어요. 휴무 신청은 25일까지 앱에서 해 주세요.',
      createdAt: iso(now.subtract(const Duration(days: 1, hours: 6))),
      readBy: {jimin.id: iso(now.subtract(const Duration(days: 1))), hayun.id: iso(now.subtract(const Duration(days: 1)))},
    ),
    Notice(
      id: id('n'),
      storeId: cafeId,
      title: '보건증 만료 30일 전 알림 안내',
      body: '보건증이 만료되기 30일 전부터 앱에서 알림을 보내요. 갱신본은 내 서류에서 등록해 주세요.',
      category: '노무',
      createdAt: iso(now.subtract(const Duration(days: 4))),
      readBy: {
        for (final s in [jimin, subin, hayun, taewoo, seoyeon])
          s.id: iso(now.subtract(const Duration(days: 3))),
      },
    ),
    Notice(
      id: id('n'),
      storeId: moaId,
      title: '야간 근무 시 금고 점검',
      body: '새벽 3시 정산 전에 금고 잔액을 확인하고 일지에 적어 주세요.',
      required: true,
      createdAt: iso(now.subtract(const Duration(days: 3))),
    ),
  ];

  final notifications = <AppNotification>[
    AppNotification(
      id: id('x'),
      storeId: cafeId,
      toPersonId: meEmployeePersonId,
      type: 'sub',
      title: '대타 승인 완료',
      body: '${md(parseYmd(seoShift.date))} ${range(seoShift.startMin, seoShift.endMin)} 서연님 근무를 맡게 됐어요',
      createdAt: iso(now.subtract(const Duration(days: 1, hours: 3))),
      refId: subs.first.id,
    ),
    AppNotification(
      id: id('x'),
      storeId: cafeId,
      toPersonId: meEmployeePersonId,
      type: 'notice',
      title: '새 필독 공지',
      body: '마감 청소 방법 안내',
      createdAt: iso(now.subtract(const Duration(days: 2, hours: 2))),
      refId: notices[1].id,
    ),
    AppNotification(
      id: id('x'),
      storeId: cafeId,
      toPersonId: meEmployeePersonId,
      type: 'cert',
      title: '보건증 만료 D-12',
      body: '갱신본을 등록해 주세요',
      createdAt: iso(now.subtract(const Duration(days: 1))),
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
    AppNotification(
      id: id('x'),
      storeId: cafeId,
      toPersonId: ownerPersonId,
      type: 'join',
      title: '도현님이 가입을 신청했어요',
      body: '직원 관리에서 승인해 주세요',
      createdAt: iso(now.subtract(const Duration(minutes: 64))),
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
