/// 프로토타입 데이터 모델. 백엔드 없이 기기 안 JSON 한 덩어리로 저장한다.
///
/// - id 는 [AppState.nextId] 카운터로 만든 문자열('s12').
/// - 근무 날짜는 'yyyy-MM-dd' + 하루 기준 분(startMin/endMin). end <= start 면 다음날까지(야간).
/// - 시각(출근·생성 시각)만 ISO 문자열.
library;

import 'package:flutter/foundation.dart' show debugPrint;

import 'format.dart' show ymd;

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

/// 근무표 파트 색 계열.
enum PartTone { open, middle, close }

/// 사업장 규모 설정. auto 면 재직 인원으로 판단.
enum SizeMode { auto, under5, over5 }

enum ScheduleStatus { draft, confirmed }

enum ScheduleSource { ai, template, manual }

/// 주휴수당 최소화/허용.
enum HolidayPolicy { minimize, allow }

/// 공평 배분 / 인건비 절감.
enum SchedulePriority { fairness, cost }

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

  // runes: 이모지(서로게이트 쌍)로 시작하는 이름도 깨지지 않게
  String get letter => name.isEmpty ? '?' : String.fromCharCode(name.runes.first);

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

/// 요일별 출퇴근 시각(분). 직원(매니저·정직원)의 고정 근무 시간.
class WorkHours {
  WorkHours(this.startMin, this.endMin);

  int startMin;
  int endMin;

  Map<String, dynamic> toJson() => {'startMin': startMin, 'endMin': endMin};

  factory WorkHours.fromJson(Map<String, dynamic> j) => WorkHours(j['startMin'], j['endMin']);
}

class PartTemplate {
  /// [id] 는 서버 id 문자열. 새 파트는 ''.
  PartTemplate(this.name, this.startMin, this.endMin, this.need,
      {this.id = '', this.tone = PartTone.open, this.breakMin = 0});

  String id;
  String name;
  PartTone tone;
  int startMin;
  int endMin;
  int breakMin;
  int need;

  PartTemplate copy() => PartTemplate(name, startMin, endMin, need, id: id, tone: tone, breakMin: breakMin);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tone': tone.name,
        'startMin': startMin,
        'endMin': endMin,
        'breakMin': breakMin,
        'need': need,
      };

  factory PartTemplate.fromJson(Map<String, dynamic> j) => PartTemplate(
        j['name'],
        j['startMin'],
        j['endMin'],
        j['need'],
        id: '${j['id'] ?? ''}',
        tone: _enum(PartTone.values, j['tone'], PartTone.open),
        breakMin: j['breakMin'] ?? 0,
      );
}

/// 한 달 근무표 메타. 근무 자체는 [Shift] 날짜별 행.
class MonthSchedule {
  MonthSchedule({
    required this.id,
    required this.storeId,
    required this.month,
    this.status = ScheduleStatus.draft,
    this.source = ScheduleSource.manual,
    this.aiComment = '',
    this.weeklyHolidayPay = HolidayPolicy.allow,
    this.priority = SchedulePriority.fairness,
    this.updatedAt = '',
  });

  final String id;
  final String storeId;

  /// 'yyyy-MM'
  final String month;
  ScheduleStatus status;
  ScheduleSource source;
  String aiComment;
  HolidayPolicy weeklyHolidayPay;
  SchedulePriority priority;
  String updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'storeId': storeId,
        'month': month,
        'status': status.name,
        'source': source.name,
        'aiComment': aiComment,
        'weeklyHolidayPay': weeklyHolidayPay.name,
        'priority': priority.name,
        'updatedAt': updatedAt,
      };

  factory MonthSchedule.fromJson(Map<String, dynamic> j) => MonthSchedule(
        id: '${j['id']}',
        storeId: '${j['storeId']}',
        month: j['month'],
        status: _enum(ScheduleStatus.values, j['status'], ScheduleStatus.draft),
        source: _enum(ScheduleSource.values, j['source'], ScheduleSource.manual),
        aiComment: j['aiComment'] ?? '',
        weeklyHolidayPay: _enum(HolidayPolicy.values, j['weeklyHolidayPay'], HolidayPolicy.allow),
        priority: _enum(SchedulePriority.values, j['priority'], SchedulePriority.fairness),
        updatedAt: j['updatedAt'] ?? '',
      );
}

/// 템플릿 안 근무 한 칸. [dayIndex] 0=월.
class TemplateShift {
  TemplateShift({
    required this.dayIndex,
    required this.staffId,
    required this.startMin,
    required this.endMin,
    this.part = '',
    this.breakMin = 0,
    this.kind = ShiftKind.work,
    this.timeTbd = false,
  });

  final int dayIndex;
  final String staffId;
  final int startMin;
  final int endMin;
  final String part;
  final int breakMin;
  final ShiftKind kind;
  final bool timeTbd;

  Map<String, dynamic> toJson() => {
        'dayIndex': dayIndex,
        'staffId': staffId,
        'startMin': startMin,
        'endMin': endMin,
        'part': part,
        'breakMin': breakMin,
        'kind': kind.name,
        'timeTbd': timeTbd,
      };

  factory TemplateShift.fromJson(Map<String, dynamic> j) => TemplateShift(
        dayIndex: j['dayIndex'],
        staffId: '${j['staffId']}',
        startMin: j['startMin'],
        endMin: j['endMin'],
        part: j['part'] ?? '',
        breakMin: j['breakMin'] ?? 0,
        kind: _enum(ShiftKind.values, j['kind'], ShiftKind.work),
        timeTbd: j['timeTbd'] ?? false,
      );
}

/// 이름 있는 주간 템플릿.
class ScheduleTemplate {
  ScheduleTemplate({
    required this.id,
    required this.storeId,
    required this.name,
    required this.createdAt,
    required this.shifts,
  });

  final String id;
  final String storeId;
  String name;
  final String createdAt;
  final List<TemplateShift> shifts;

  Map<String, dynamic> toJson() => {
        'id': id,
        'storeId': storeId,
        'name': name,
        'createdAt': createdAt,
        'shifts': [for (final s in shifts) s.toJson()],
      };

  factory ScheduleTemplate.fromJson(Map<String, dynamic> j) => ScheduleTemplate(
        id: '${j['id']}',
        storeId: '${j['storeId']}',
        name: j['name'],
        createdAt: j['createdAt'] ?? '',
        shifts: [
          for (final s in (j['shifts'] as List? ?? const []))
            TemplateShift.fromJson((s as Map).cast<String, dynamic>())
        ],
      );
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
    this.openMin = 480,
    this.closeMin = 1320,
    this.weekendOpenMin = 480,
    this.weekendCloseMin = 1320,
    this.sizeMode = SizeMode.auto,
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

  /// 영업시간(분). 마감이 1440 초과면 익일.
  int openMin, closeMin, weekendOpenMin, weekendCloseMin;

  /// 사업장 규모 설정. [isSmall] 은 실제 적용값.
  SizeMode sizeMode;

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
        'openMin': openMin,
        'closeMin': closeMin,
        'weekendOpenMin': weekendOpenMin,
        'weekendCloseMin': weekendCloseMin,
        'sizeMode': sizeMode.name,
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
        parts: [for (final p in j['parts']) PartTemplate.fromJson((p as Map).cast<String, dynamic>())],
        monthlyTotals: ((j['monthlyTotals'] ?? const {}) as Map).cast<String, int>(),
        scheduleConfirmedAt: j['scheduleConfirmedAt'],
        openMin: j['openMin'] ?? 480,
        closeMin: j['closeMin'] ?? 1320,
        weekendOpenMin: j['weekendOpenMin'] ?? 480,
        weekendCloseMin: j['weekendCloseMin'] ?? 1320,
        sizeMode: _enum(SizeMode.values, j['sizeMode'], SizeMode.auto),
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
    this.id,
  });

  /// 서버 계약서 id (서명할 때 본 계약서를 보낸다). 데모는 null.
  final String? id;
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
        if (id != null) 'id': id,
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
        id: j['id']?.toString(),
      );
}

/// 시급 이력 한 건: [from] 날짜부터 [wage].
class WageStep {
  const WageStep(this.from, this.wage);

  final String from;
  final int wage;

  Map<String, dynamic> toJson() => {'from': from, 'wage': wage};

  factory WageStep.fromJson(Map<String, dynamic> j) => WageStep(j['from'], j['wage']);
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
    this.leftAt,
    List<WageStep>? wages,
    List<List<String>>? fixedParts,
    List<WorkHours?>? workHours,
    List<WorkHours?>? availHours,
  })  : wages = wages ?? [],
        fixedParts = fixedParts ?? List.generate(7, (_) => <String>[]),
        workHours = workHours ?? List.filled(7, null),
        availHours = availHours ?? List.filled(7, null);

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

  /// 퇴사일 'yyyy-MM-dd' (재직 중이면 null).
  String? leftAt;

  /// 시급 이력(from 오름차순). 비어 있으면 [wage] 하나.
  List<WageStep> wages;

  /// [day] 의 시급: from ≤ day 인 가장 늦은 항목(같은 날이면 뒤쪽), 없으면 [wage].
  int wageOn(DateTime day) {
    final k = ymd(day);
    for (var i = wages.length - 1; i >= 0; i--) {
      if (wages[i].from.compareTo(k) <= 0) return wages[i].wage;
    }
    return wage;
  }

  /// 알바생 고정 근무 파트 이름 (월~일 7칸).
  List<List<String>> fixedParts;

  /// 직원(매니저·정직원) 요일별 출퇴근 (월~일 7칸, null=쉼).
  List<WorkHours?> workHours;

  /// 알바생 추가 근무 가능 시간 (월~일 7칸, null=그 요일 추가 근무 불가). 빈칸 채우기 후보 범위.
  List<WorkHours?> availHours;

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
        'leftAt': leftAt,
        'wages': [for (final w in wages) w.toJson()],
        'fixedParts': fixedParts,
        'workHours': [for (final w in workHours) w?.toJson()],
        'availHours': [for (final w in availHours) w?.toJson()],
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
        leftAt: j['leftAt'],
        wages: [
          for (final w in (j['wages'] as List? ?? const [])) WageStep.fromJson((w as Map).cast<String, dynamic>())
        ],
        fixedParts: _fixedParts(j['fixedParts']),
        workHours: _workHours(j['workHours']),
        availHours: _workHours(j['availHours']),
      );
}

List<List<String>> _fixedParts(Object? v) {
  final l = v is List ? v : const [];
  return List.generate(7, (i) => i < l.length && l[i] is List ? [for (final x in l[i] as List) '$x'] : <String>[]);
}

List<WorkHours?> _workHours(Object? v) {
  final l = v is List ? v : const [];
  return List.generate(
      7, (i) => i < l.length && l[i] is Map ? WorkHours.fromJson((l[i] as Map).cast<String, dynamic>()) : null);
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
        isSubstitute: j['isSubstitute'] ?? false,
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
    List<MonthSchedule>? schedules,
    List<ScheduleTemplate>? templates,
  })  : schedules = schedules ?? [],
        templates = templates ?? [];

  static const version = 4;

  Session session;
  List<Person> persons;
  List<Store> stores;
  List<Staff> staff;
  List<Shift> shifts;
  List<Attendance> attendance;
  List<SubstituteRequest> subs;
  List<Notice> notices;
  List<AppNotification> notifications;
  List<MonthSchedule> schedules;
  List<ScheduleTemplate> templates;
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
        'schedules': [for (final x in schedules) x.toJson()],
        'templates': [for (final x in templates) x.toJson()],
      };

  /// 버전이 다르면 null (호출하는 쪽에서 시드로 되돌린다).
  static AppState? fromJson(Map<String, dynamic> j) {
    if (j['v'] != version) return null;
    // 깨진 행 하나가 상태 전체를 막지 않게 그 행만 버린다.
    List<T> list<T>(String k, T Function(Map<String, dynamic>) f) {
      final out = <T>[];
      for (final x in (j[k] as List?) ?? const []) {
        try {
          out.add(f((x as Map).cast<String, dynamic>()));
        } catch (e) {
          debugPrint('AppState.$k 행 파싱 실패: $e');
        }
      }
      return out;
    }
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
      schedules: j['schedules'] == null ? [] : list('schedules', MonthSchedule.fromJson),
      templates: j['templates'] == null ? [] : list('templates', ScheduleTemplate.fromJson),
    );
  }
}
