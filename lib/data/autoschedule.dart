/// 근무표 규칙 순수 함수 (레퍼런스 rules.ts · autofill.ts · mock.ts 이식). 데모 모드와 웹 편집기가 쓴다.
/// 새로 만든 근무는 id·storeId 가 비어 있다(호출한 쪽이 채운다).
library;

import 'holidays.dart';
import 'models.dart';

/// 직원(매니저·정직원) 근무의 part 값.
const flexPart = '직원';

/// 근로기준법 제54조: 4시간 이상 30분, 8시간 이상 1시간. [workMin] 은 휴게 뺀 근무 분.
int requiredBreak(int workMin) => workMin >= 480 ? 60 : workMin >= 240 ? 30 : 0;

/// 체류 시간(출근~퇴근 분)에 필요한 최소 휴게.
int minBreakFor(int duration) =>
    const [0, 30, 60].firstWhere((b) => b >= requiredBreak(duration - b), orElse: () => 60);

/// 파트 휴게 기본값: 근무 4시간마다 30분.
int partBreakFor(int duration) => duration ~/ 240 * 30;

/// 시작·종료(분, 종료 > 1440 이면 익일)의 법정 최소 휴게.
int breakFor(int startMin, int endMin) => minBreakFor(endMin - startMin);

/// 0=월 … 6=일.
int dayIndexOf(DateTime d) => d.weekday - 1;

/// 그 날의 영업시간 (평일 / 주말·공휴일).
({int open, int close}) hoursOn(Store store, DateTime date) =>
    dayIndexOf(date) >= 5 || isHoliday(date)
        ? (open: store.weekendOpenMin, close: store.weekendCloseMin)
        : (open: store.openMin, close: store.closeMin);

/// 종료 분을 Shift 저장 형식(0..1440, 넘으면 익일로 접기)으로.
int _fold(int end) => end > 1440 ? end - 1440 : end;

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Shift _blank(String staffId, DateTime date, int start, int end, String part, int br) => Shift(
      id: '',
      storeId: '',
      staffId: staffId,
      date: _ymd(date),
      startMin: start,
      endMin: _fold(end),
      part: part,
      breakMin: br,
    );

int _byDateStart(Shift a, Shift b) {
  final c = a.date.compareTo(b.date);
  return c != 0 ? c : a.startMin.compareTo(b.startMin);
}

/// 고정 근무를 [dates] 에 깐다. 알바생(partTimer·minor)은 그 요일에 고른 파트마다,
/// 직원(manager·fulltime)은 요일별 출퇴근(영업시간 밖이면 뺀다). 날짜·시작 시각 순.
List<Shift> fixedShifts(Store store, List<Staff> staff, List<DateTime> dates) {
  final out = <Shift>[];
  for (final st in staff) {
    for (final date in dates) {
      final di = dayIndexOf(date);
      if (!st.kind.flex) {
        final names = st.fixedParts[di];
        for (final p in store.parts.where((p) => names.contains(p.name))) {
          out.add(_blank(st.id, date, p.startMin, p.endMin, p.name, p.breakMin));
        }
      } else {
        final w = st.workHours[di];
        final h = hoursOn(store, date);
        if (w == null || w.startMin < h.open || w.endMin > h.close) continue;
        out.add(_blank(st.id, date, w.startMin, w.endMin, flexPart, breakFor(w.startMin, w.endMin)));
      }
    }
  }
  return out..sort(_byDateStart);
}

/// [existing] 은 그대로 두고, 고정 근무 [fixed] 중 빠진 것만 돌려준다.
/// 연차인 날은 넣지 않는다. 직원은 그 날 근무가 하나라도 있으면, 알바생은 같은 파트 근무가 있으면 건너뛴다.
List<Shift> autofill(List<Shift> existing, List<Shift> fixed) => [
      for (final f in fixed)
        if (!existing.any((s) =>
            s.staffId == f.staffId &&
            s.date == f.date &&
            (s.kind == ShiftKind.leave || f.part == flexPart || s.part == f.part)))
          f
    ];

DateTime _monthStart(String month) {
  final p = month.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]));
}

/// 그 달 날짜들 중 [from] 이후(포함)만.
List<DateTime> monthDates(String month, DateTime from) {
  final start = _monthStart(month);
  final end = DateTime(start.year, start.month + 1, 0);
  final f = DateTime(from.year, from.month, from.day);
  return [
    for (var d = start; !d.isAfter(end); d = DateTime(d.year, d.month, d.day + 1))
      if (!d.isBefore(f)) d
  ];
}

/// [shifts] (그 달 근무)의 첫 완전한 월~일 주를 요일 패턴으로. 완전한 주가 없으면 빈 목록.
List<TemplateShift> toPattern(List<Shift> shifts, String month) {
  final start = _monthStart(month);
  final end = DateTime(start.year, start.month + 1, 0);
  var mon = start.add(Duration(days: (8 - start.weekday) % 7));
  if (mon.add(const Duration(days: 6)).isAfter(end)) return [];
  final week = {for (var i = 0; i < 7; i++) _ymd(DateTime(mon.year, mon.month, mon.day + i)): i};
  return [
    for (final s in shifts.toList()..sort(_byDateStart))
      if (week[s.date] case final di?)
        TemplateShift(
          dayIndex: di,
          staffId: s.staffId,
          startMin: s.startMin,
          endMin: s.endMin,
          part: s.part,
          breakMin: s.breakMin,
          kind: s.kind,
          timeTbd: s.timeTbd,
        )
  ];
}

/// 요일 패턴을 그 달 [from] 이후 같은 요일마다 반복. 연차는 그 요일 첫 날에만 둔다.
List<Shift> fillMonth(List<TemplateShift> pattern, String month, DateTime from) {
  final dates = monthDates(month, from);
  final out = <Shift>[];
  final leaveDone = <int>{};
  for (final d in dates) {
    final di = dayIndexOf(d);
    for (final t in pattern.where((t) => t.dayIndex == di)) {
      if (t.kind == ShiftKind.leave && !leaveDone.add(di)) continue;
      out.add(Shift(
        id: '',
        storeId: '',
        staffId: t.staffId,
        date: _ymd(d),
        startMin: t.startMin,
        endMin: t.endMin,
        part: t.part,
        breakMin: t.breakMin,
        kind: t.kind,
        timeTbd: t.timeTbd,
      ));
    }
  }
  return out..sort(_byDateStart);
}
