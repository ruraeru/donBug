/// 프로토타입 데이터 모델. 백엔드 없이 기기 안 JSON 한 덩어리로 저장한다.
///
/// - id 는 [AppState.nextId] 카운터로 만든 문자열('s12').
/// - 근무 날짜는 'yyyy-MM-dd' + 하루 기준 분(startMin/endMin). end <= start 면 다음날까지(야간).
/// - 시각(출근·생성 시각)만 ISO 문자열.
library;

enum Role { employee, employer }

enum Deduction {
  biz33('원천징수 (3.3%)', '3.3%'),
  insurance('4대보험', '4대보험'),
  none('공제 없음', '없음');

  const Deduction(this.label, this.short);
  final String label;
  final String short;
}

enum StaffStatus { pending, active, left, rejected }

enum SubStatus { open, accepted, approved, rejected, cancelled }

/// 직원 유형. 매니저·정직원은 파트에 묶이지 않는 유동 근무(시간 직접 지정).
enum StaffKind {
  manager('매니저'),
  fulltime('정직원'),
  partTimer('알바'),
  minor('연소자');

  const StaffKind(this.label);
  final String label;

  bool get flex => this == manager || this == fulltime;
}

/// 근무표 칸 종류. 연차는 유급, 휴무는 무급.
enum ShiftKind {
  work('근무'),
  leave('연차'),
  off('휴무');

  const ShiftKind(this.label);
  final String label;
}

/// LetterAvatar 색 조합 인덱스.
enum Tone { primary, accent, info, danger }

T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.firstWhere((v) => v.name == name, orElse: () => fallback);

/// 사람. 한 사람이 여러 매장에 [Staff]로 소속될 수 있다. 보건증은 사람 단위.
class Person {
  Person({
    required this.id,
    required this.name,
    required this.fullName,
    this.certExpiry,
    List<int>? certAlertDays,
    this.certHasPhoto = false,
  }) : certAlertDays = certAlertDays ?? [30, 14, 7, 0];

  final String id;
  String name;
  String fullName;
  String? certExpiry;
  List<int> certAlertDays;
  bool certHasPhoto;

  String get letter => name.isEmpty ? '?' : name.substring(0, 1);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fullName': fullName,
        'certExpiry': certExpiry,
        'certAlertDays': certAlertDays,
        'certHasPhoto': certHasPhoto,
      };

  factory Person.fromJson(Map<String, dynamic> j) => Person(
        id: j['id'],
        name: j['name'],
        fullName: j['fullName'],
        certExpiry: j['certExpiry'],
        certAlertDays: (j['certAlertDays'] as List).cast<int>(),
        certHasPhoto: j['certHasPhoto'] ?? false,
      );
}

class PartTemplate {
  PartTemplate(this.name, this.startMin, this.endMin, this.need);

  String name;
  int startMin;
  int endMin;
  int need;

  Map<String, dynamic> toJson() =>
      {'name': name, 'startMin': startMin, 'endMin': endMin, 'need': need};

  factory PartTemplate.fromJson(Map<String, dynamic> j) =>
      PartTemplate(j['name'], j['startMin'], j['endMin'], j['need']);
}

class Store {
  Store({
    required this.id,
    required this.name,
    required this.address,
    required this.code,
    this.ownerPersonId,
    this.isSmall = true,
    this.noticeRequiredDefault = true,
    this.substitutePush = true,
    this.defaultDeduction = Deduction.biz33,
    required this.parts,
    Map<String, int>? monthlyTotals,
    this.scheduleConfirmedAt,
  }) : monthlyTotals = monthlyTotals ?? {};

  final String id;
  String name;
  String address;
  String code;
  String? ownerPersonId;

  /// 상시 5인 미만 사업장(사장님이 설정). 가산수당 미적용.
  bool isSmall;
  bool noticeRequiredDefault;
  bool substitutePush;

  /// 직원 가입 승인 때 기본으로 고르는 공제.
  Deduction defaultDeduction;
  List<PartTemplate> parts;

  /// 'yyyy-MM' → 지난 달 인건비 합계(추이 차트용 상수).
  Map<String, int> monthlyTotals;

  /// 근무표를 마지막으로 확정한 시각(ISO).
  String? scheduleConfirmedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'code': code,
        'ownerPersonId': ownerPersonId,
        'isSmall': isSmall,
        'noticeRequiredDefault': noticeRequiredDefault,
        'substitutePush': substitutePush,
        'defaultDeduction': defaultDeduction.name,
        'parts': [for (final p in parts) p.toJson()],
        'monthlyTotals': monthlyTotals,
        'scheduleConfirmedAt': scheduleConfirmedAt,
      };

  factory Store.fromJson(Map<String, dynamic> j) => Store(
        id: j['id'],
        name: j['name'],
        address: j['address'],
        code: j['code'],
        ownerPersonId: j['ownerPersonId'],
        isSmall: j['isSmall'],
        noticeRequiredDefault: j['noticeRequiredDefault'],
        substitutePush: j['substitutePush'],
        defaultDeduction: _enum(Deduction.values, j['defaultDeduction'], Deduction.biz33),
        parts: [for (final p in j['parts']) PartTemplate.fromJson(p)],
        monthlyTotals: (j['monthlyTotals'] as Map).cast<String, int>(),
        scheduleConfirmedAt: j['scheduleConfirmedAt'],
      );
}

class Contract {
  Contract({
    required this.start,
    required this.end,
    required this.wage,
    required this.weeklyHours,
    required this.workDays,
    this.duty = '',
    this.ownerSignedAt,
    this.employeeSignedAt,
  });

  String start;
  String end;
  int wage;
  int weeklyHours;
  String workDays;
  String duty;
  String? ownerSignedAt;
  String? employeeSignedAt;

  bool get signed => ownerSignedAt != null && employeeSignedAt != null;

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
        'wage': wage,
        'weeklyHours': weeklyHours,
        'workDays': workDays,
        'duty': duty,
        'ownerSignedAt': ownerSignedAt,
        'employeeSignedAt': employeeSignedAt,
      };

  factory Contract.fromJson(Map<String, dynamic> j) => Contract(
        start: j['start'],
        end: j['end'],
        wage: j['wage'],
        weeklyHours: j['weeklyHours'],
        workDays: j['workDays'],
        duty: j['duty'] ?? '',
        ownerSignedAt: j['ownerSignedAt'],
        employeeSignedAt: j['employeeSignedAt'],
      );
}

/// 매장 소속 직원. 가입 신청은 status=pending 인 Staff.
class Staff {
  Staff({
    required this.id,
    required this.storeId,
    required this.personId,
    required this.part,
    required this.wage,
    this.deduction = Deduction.biz33,
    this.weeklyHolidayAuto = true,
    this.premium = false,
    this.tone = Tone.primary,
    this.kind = StaffKind.partTimer,
    required this.joinedAt,
    this.status = StaffStatus.active,
    this.requestedAt,
    this.contract,
  });

  final String id;
  final String storeId;
  final String personId;
  String part;
  int wage;
  Deduction deduction;
  bool weeklyHolidayAuto;
  bool premium;
  Tone tone;
  StaffKind kind;
  String joinedAt;
  StaffStatus status;
  String? requestedAt;
  Contract? contract;

  bool get active => status == StaffStatus.active;

  Map<String, dynamic> toJson() => {
        'id': id,
        'storeId': storeId,
        'personId': personId,
        'part': part,
        'wage': wage,
        'deduction': deduction.name,
        'weeklyHolidayAuto': weeklyHolidayAuto,
        'premium': premium,
        'tone': tone.name,
        'kind': kind.name,
        'joinedAt': joinedAt,
        'status': status.name,
        'requestedAt': requestedAt,
        'contract': contract?.toJson(),
      };

  factory Staff.fromJson(Map<String, dynamic> j) => Staff(
        id: j['id'],
        storeId: j['storeId'],
        personId: j['personId'],
        part: j['part'],
        wage: j['wage'],
        deduction: _enum(Deduction.values, j['deduction'], Deduction.biz33),
        weeklyHolidayAuto: j['weeklyHolidayAuto'],
        premium: j['premium'],
        tone: _enum(Tone.values, j['tone'], Tone.primary),
        kind: _enum(StaffKind.values, j['kind'], StaffKind.partTimer),
        joinedAt: j['joinedAt'],
        status: _enum(StaffStatus.values, j['status'], StaffStatus.active),
        requestedAt: j['requestedAt'],
        contract: j['contract'] == null ? null : Contract.fromJson(j['contract']),
      );
}

class Shift {
  Shift({
    required this.id,
    required this.storeId,
    required this.staffId,
    required this.date,
    required this.startMin,
    required this.endMin,
    required this.part,
    this.breakMin = 0,
    this.isSubstitute = false,
    this.originalStaffId,
    this.kind = ShiftKind.work,
    this.timeTbd = false,
  });

  final String id;
  final String storeId;
  String staffId;
  String date;
  int startMin;
  int endMin;
  String part;
  int breakMin;
  bool isSubstitute;

  /// 대타로 바뀐 경우 원래 근무자.
  String? originalStaffId;

  ShiftKind kind;

  /// 시간 미정(확정 전 본인 확인 필요). 시각은 추천값.
  bool timeTbd;

  /// 출근·근태·급여에 쓰는 실제 근무인지.
  bool get isWork => kind == ShiftKind.work && !timeTbd;

  /// 야간이면 1440 을 더한 종료 분.
  int get endAbs => endMin <= startMin ? endMin + 1440 : endMin;
  int get scheduledMinutes => endAbs - startMin - breakMin;

  Map<String, dynamic> toJson() => {
        'id': id,
        'storeId': storeId,
        'staffId': staffId,
        'date': date,
        'startMin': startMin,
        'endMin': endMin,
        'part': part,
        'breakMin': breakMin,
        'isSubstitute': isSubstitute,
        'originalStaffId': originalStaffId,
        'kind': kind.name,
        'timeTbd': timeTbd,
      };

  factory Shift.fromJson(Map<String, dynamic> j) => Shift(
        id: j['id'],
        storeId: j['storeId'],
        staffId: j['staffId'],
        date: j['date'],
        startMin: j['startMin'],
        endMin: j['endMin'],
        part: j['part'],
        breakMin: j['breakMin'],
        isSubstitute: j['isSubstitute'],
        originalStaffId: j['originalStaffId'],
        kind: _enum(ShiftKind.values, j['kind'], ShiftKind.work),
        timeTbd: j['timeTbd'] ?? false,
      );
}

class Attendance {
  Attendance({
    required this.id,
    required this.storeId,
    required this.shiftId,
    required this.staffId,
    required this.clockIn,
    this.clockOut,
    this.editReason,
  });

  final String id;
  final String storeId;
  final String shiftId;
  final String staffId;
  String clockIn;
  String? clockOut;
  String? editReason;

  Map<String, dynamic> toJson() => {
        'id': id,
        'storeId': storeId,
        'shiftId': shiftId,
        'staffId': staffId,
        'clockIn': clockIn,
        'clockOut': clockOut,
        'editReason': editReason,
      };

  factory Attendance.fromJson(Map<String, dynamic> j) => Attendance(
        id: j['id'],
        storeId: j['storeId'],
        shiftId: j['shiftId'],
        staffId: j['staffId'],
        clockIn: j['clockIn'],
        clockOut: j['clockOut'],
        editReason: j['editReason'],
      );
}

class SubstituteRequest {
  SubstituteRequest({
    required this.id,
    required this.storeId,
    required this.shiftId,
    required this.requesterId,
    required this.reason,
    this.notifyPeers = true,
    this.status = SubStatus.open,
    List<String>? applicantIds,
    this.acceptedId,
    required this.createdAt,
    String? notifiedAt,
  })  : applicantIds = applicantIds ?? [],
        notifiedAt = notifiedAt ?? createdAt;

  final String id;
  final String storeId;
  final String shiftId;

  /// 요청한 직원(Staff id).
  final String requesterId;
  String reason;
  bool notifyPeers;
  SubStatus status;
  List<String> applicantIds;

  /// 대타로 확정될 직원(Staff id). 동료 수락 또는 사장님 직접 배정.
  String? acceptedId;
  String createdAt;
  String notifiedAt;

  bool get pending =>
      status == SubStatus.open || status == SubStatus.accepted;

  Map<String, dynamic> toJson() => {
        'id': id,
        'storeId': storeId,
        'shiftId': shiftId,
        'requesterId': requesterId,
        'reason': reason,
        'notifyPeers': notifyPeers,
        'status': status.name,
        'applicantIds': applicantIds,
        'acceptedId': acceptedId,
        'createdAt': createdAt,
        'notifiedAt': notifiedAt,
      };

  factory SubstituteRequest.fromJson(Map<String, dynamic> j) =>
      SubstituteRequest(
        id: j['id'],
        storeId: j['storeId'],
        shiftId: j['shiftId'],
        requesterId: j['requesterId'],
        reason: j['reason'],
        notifyPeers: j['notifyPeers'],
        status: _enum(SubStatus.values, j['status'], SubStatus.open),
        applicantIds: (j['applicantIds'] as List).cast<String>(),
        acceptedId: j['acceptedId'],
        createdAt: j['createdAt'],
        notifiedAt: j['notifiedAt'],
      );
}

class Notice {
  Notice({
    required this.id,
    required this.storeId,
    required this.title,
    required this.body,
    this.category = '일반',
    this.required = false,
    this.pinned = false,
    required this.createdAt,
    Map<String, String>? readBy,
    this.remindedAt,
  }) : readBy = readBy ?? {};

  final String id;
  final String storeId;
  String title;
  String body;
  String category;
  bool required;
  bool pinned;
  String createdAt;

  /// Staff id → 읽은 시각.
  Map<String, String> readBy;
  String? remindedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'storeId': storeId,
        'title': title,
        'body': body,
        'category': category,
        'required': required,
        'pinned': pinned,
        'createdAt': createdAt,
        'readBy': readBy,
        'remindedAt': remindedAt,
      };

  factory Notice.fromJson(Map<String, dynamic> j) => Notice(
        id: j['id'],
        storeId: j['storeId'],
        title: j['title'],
        body: j['body'],
        category: j['category'],
        required: j['required'],
        pinned: j['pinned'],
        createdAt: j['createdAt'],
        readBy: (j['readBy'] as Map).cast<String, String>(),
        remindedAt: j['remindedAt'],
      );
}

/// 알림 센터 한 줄. type: sub(대타) · notice(공지) · cert(보건증) · pay(급여) · join(가입) · contract(계약서).
class AppNotification {
  AppNotification({
    required this.id,
    required this.storeId,
    required this.toPersonId,
    required this.type,
    required this.title,
    this.body = '',
    required this.createdAt,
    this.read = false,
    this.refId,
  });

  final String id;
  final String storeId;
  final String toPersonId;
  final String type;
  final String title;
  final String body;
  final String createdAt;
  bool read;
  final String? refId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'storeId': storeId,
        'toPersonId': toPersonId,
        'type': type,
        'title': title,
        'body': body,
        'createdAt': createdAt,
        'read': read,
        'refId': refId,
      };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'],
        storeId: j['storeId'],
        toPersonId: j['toPersonId'],
        type: j['type'],
        title: j['title'],
        body: j['body'] ?? '',
        createdAt: j['createdAt'],
        read: j['read'],
        refId: j['refId'],
      );
}

/// 데모 세션. 한 기기에서 알바생(태우)과 사장님을 오간다.
class Session {
  Session({
    this.loggedIn = false,
    this.role = Role.employee,
    required this.employeeId,
    required this.ownerId,
    required this.employeeStoreId,
    required this.ownerStoreId,
  });

  bool loggedIn;
  Role role;

  /// 알바생 역할일 때의 나(Person id).
  String employeeId;

  /// 사장님 역할일 때의 나(Person id).
  String ownerId;
  String employeeStoreId;
  String ownerStoreId;

  String get meId => role == Role.employee ? employeeId : ownerId;
  String get storeId => role == Role.employee ? employeeStoreId : ownerStoreId;

  Map<String, dynamic> toJson() => {
        'loggedIn': loggedIn,
        'role': role.name,
        'employeeId': employeeId,
        'ownerId': ownerId,
        'employeeStoreId': employeeStoreId,
        'ownerStoreId': ownerStoreId,
      };

  factory Session.fromJson(Map<String, dynamic> j) => Session(
        loggedIn: j['loggedIn'],
        role: _enum(Role.values, j['role'], Role.employee),
        employeeId: j['employeeId'],
        ownerId: j['ownerId'],
        employeeStoreId: j['employeeStoreId'],
        ownerStoreId: j['ownerStoreId'],
      );
}

class AppState {
  AppState({
    required this.session,
    required this.persons,
    required this.stores,
    required this.staff,
    required this.shifts,
    required this.attendance,
    required this.subs,
    required this.notices,
    required this.notifications,
    this.nextId = 1,
  });

  static const version = 2;

  Session session;
  List<Person> persons;
  List<Store> stores;
  List<Staff> staff;
  List<Shift> shifts;
  List<Attendance> attendance;
  List<SubstituteRequest> subs;
  List<Notice> notices;
  List<AppNotification> notifications;
  int nextId;

  Map<String, dynamic> toJson() => {
        'v': version,
        'nextId': nextId,
        'session': session.toJson(),
        'persons': [for (final x in persons) x.toJson()],
        'stores': [for (final x in stores) x.toJson()],
        'staff': [for (final x in staff) x.toJson()],
        'shifts': [for (final x in shifts) x.toJson()],
        'attendance': [for (final x in attendance) x.toJson()],
        'subs': [for (final x in subs) x.toJson()],
        'notices': [for (final x in notices) x.toJson()],
        'notifications': [for (final x in notifications) x.toJson()],
      };

  /// 버전이 다르면 null (호출하는 쪽에서 시드로 되돌린다).
  static AppState? fromJson(Map<String, dynamic> j) {
    if (j['v'] != version) return null;
    List<T> list<T>(String k, T Function(Map<String, dynamic>) f) =>
        [for (final x in j[k] as List) f((x as Map).cast<String, dynamic>())];
    return AppState(
      nextId: j['nextId'],
      session: Session.fromJson((j['session'] as Map).cast<String, dynamic>()),
      persons: list('persons', Person.fromJson),
      stores: list('stores', Store.fromJson),
      staff: list('staff', Staff.fromJson),
      shifts: list('shifts', Shift.fromJson),
      attendance: list('attendance', Attendance.fromJson),
      subs: list('subs', SubstituteRequest.fromJson),
      notices: list('notices', Notice.fromJson),
      notifications: list('notifications', AppNotification.fromJson),
    );
  }
}
