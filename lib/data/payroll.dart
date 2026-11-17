/// 급여 계산 (순수 함수). 노무 규칙을 단순화한 프로토타입용 근사치다.
///
/// - 시급은 근무 날짜 기준 이력(`wageOn`). 기본급 = Σ 근무 분 × 그 날 시급 / 60
/// - 주휴수당(주 단위, 월–일): 소정시간(계약서 주 소정시간, 없으면 그 주 본인 예정 근무+연차) ≥ 15시간
///   AND 개근(끝난 본인 근무 모두 출근 기록 있음, 연차는 출근) AND 계속근로(퇴사일이 그 주 일요일 이상)일 때
///   min(소정, 40h) / 40 × 8 × 일요일 시급. 일요일이 속한 달에 지급한다. 주 정보는 [WeekBasis] 로 받는다
///   (안 주면 entries 의 대타 제외 근무 분으로 근사).
/// - 가산수당(5인 이상 + 직원 설정): 야간(22–06)과 하루 8시간 초과분에 0.5배 추가. 휴일가산은 0.
///   연차(leave)는 가산 제외. 야간 분은 실근로 분(휴게 제외)을 넘지 않게 자른다(휴게 시각 모름). BE PayrollCalculator 와 같은 규칙.
///   주 40시간 초과분(실근로 주합 − 40h)이 그 주 일별 8h 초과 합보다 크면 그 차이도 0.5배 추가(중복 없음, 일요일 시급).
/// - 공제: 3.3%(원 단위 내림) · 4대보험(근사 요율) · 없음.
library;

import 'dart:math';

import 'format.dart';
import 'models.dart';

/// shortcut: 2026 4대보험 근로자 부담 근사 요율(국민연금 4.5 + 건강 3.545 + 장기요양 0.459 + 고용 0.9).
/// 실제 신고용이 아니다. 정밀 계산이 필요하면 항목별 상·하한을 반영해야 한다.
const insuranceRate = 0.094;

const minimumWage2026 = 10320;

/// 실근무(또는 예정) 한 건.
class WorkEntry {
  const WorkEntry({
    required this.start,
    required this.end,
    this.breakMin = 0,
    this.isSubstitute = false,
    this.planned = false,
    this.leave = false,
  });

  final DateTime start;
  final DateTime end;
  final int breakMin;
  final bool isSubstitute;

  /// 아직 일하지 않은 예정 근무(예상 급여 계산용).
  final bool planned;

  /// 연차(유급 소정 시간). 가산수당 대상 아님.
  final bool leave;

  DateTime get day => dayOf(start);

  int get minutes {
    final span = end.difference(start).inMinutes;
    return max(0, span - breakMin);
  }

  /// 22:00–06:00 과 겹치는 분.
  int get nightMinutes {
    var total = 0;
    for (var d = day.subtract(const Duration(days: 1));
        !d.isAfter(dayOf(end));
        d = d.add(const Duration(days: 1))) {
      final ws = DateTime(d.year, d.month, d.day, 22);
      final we = DateTime(d.year, d.month, d.day + 1, 6);
      final s = start.isAfter(ws) ? start : ws;
      final e = end.isBefore(we) ? end : we;
      if (e.isAfter(s)) total += e.difference(s).inMinutes;
    }
    return total;
  }
}

class Payslip {
  const Payslip({
    required this.minutes,
    required this.base,
    required this.weeklyHoliday,
    required this.premium,
    required this.deduction,
    required this.entries,
    this.missingClockOut = 0,
  });

  final int minutes;
  final int base;
  final int weeklyHoliday;
  final int premium;
  final int deduction;

  /// 그 달에 속한 근무(날짜순).
  final List<WorkEntry> entries;

  /// 이 달 지난 근무 중 출근만 있고 퇴근 기록이 없어 0원으로 빠진 건수.
  final int missingClockOut;

  int get gross => base + weeklyHoliday + premium;
  int get net => gross - deduction;
}

int deductionOf(int gross, Deduction d) => switch (d) {
      Deduction.biz33 => (gross * 0.033).floor(),
      Deduction.insurance => (gross * insuranceRate).floor(),
      Deduction.none => 0,
    };

/// 한 주의 주휴 판단 근거. [standardMinutes] 소정 분, [eligible] 개근·계속근로 충족 여부.
class WeekBasis {
  const WeekBasis(this.standardMinutes, this.eligible);

  final int standardMinutes;
  final bool eligible;
}

int payFor(int minutes, int wage) => (minutes * wage / 60).round();

/// 주휴수당 (한 주의 대타 제외 근무 분 기준).
int weeklyHolidayPay(int weekMinutes, int wage) {
  if (weekMinutes < 15 * 60) return 0;
  final h = min(weekMinutes, 40 * 60) / 60;
  return (h / 40 * 8 * wage).round();
}

/// [entries] 는 그 달 앞뒤 주까지 포함해도 된다(주휴 계산에 필요).
/// [weekBasis] 는 월요일 키 → 주휴 근거. 없으면 entries 로 근사.
Payslip computePayslip({
  required List<WorkEntry> entries,
  required int year,
  required int month,
  required int Function(DateTime day) wageOn,
  required Deduction deduction,
  bool weeklyHolidayAuto = true,
  bool premiumApplies = false,
  int missingClockOut = 0,
  Map<DateTime, WeekBasis>? weekBasis,
}) {
  bool inMonth(DateTime d) => d.year == year && d.month == month;
  DateTime sundayOf(DateTime monday) => monday.add(const Duration(days: 6));
  final monthEntries = entries.where((e) => inMonth(e.day)).toList()
    ..sort((a, b) => a.start.compareTo(b.start));

  final minutes = monthEntries.fold(0, (s, e) => s + e.minutes);
  final base = monthEntries.fold(0, (s, e) => s + payFor(e.minutes, wageOn(e.day)));

  var holiday = 0;
  if (weeklyHolidayAuto) {
    final weeks = weekBasis;
    if (weeks == null) {
      final m = <DateTime, int>{};
      for (final e in entries.where((e) => !e.isSubstitute)) {
        final w = mondayOf(e.day);
        m[w] = (m[w] ?? 0) + e.minutes;
      }
      m.forEach((monday, mins) {
        if (inMonth(sundayOf(monday))) holiday += weeklyHolidayPay(mins, wageOn(sundayOf(monday)));
      });
    } else {
      weeks.forEach((monday, b) {
        final sun = sundayOf(monday);
        if (inMonth(sun) && b.eligible) holiday += weeklyHolidayPay(b.standardMinutes, wageOn(sun));
      });
    }
  }

  var premium = 0;
  if (premiumApplies) {
    final perDay = <DateTime, int>{};
    for (final e in monthEntries.where((e) => !e.leave)) {
      premium += payFor(min(e.nightMinutes, e.minutes), wageOn(e.day)) ~/ 2;
      perDay[e.day] = (perDay[e.day] ?? 0) + e.minutes;
    }
    for (final d in perDay.entries) {
      if (d.value > 480) premium += payFor(d.value - 480, wageOn(d.key)) ~/ 2;
    }
    // 주 40h 초과 중 일별 8h 초과와 겹치지 않는 부분.
    final weekMin = <DateTime, int>{}, weekDailyOver = <DateTime, int>{};
    final days = <DateTime, int>{};
    for (final e in entries.where((e) => !e.leave)) {
      days[e.day] = (days[e.day] ?? 0) + e.minutes;
    }
    days.forEach((d, m) {
      final w = mondayOf(d);
      weekMin[w] = (weekMin[w] ?? 0) + m;
      weekDailyOver[w] = (weekDailyOver[w] ?? 0) + max(0, m - 480);
    });
    weekMin.forEach((monday, m) {
      final sun = sundayOf(monday);
      if (!inMonth(sun)) return;
      final extra = m - 2400 - weekDailyOver[monday]!;
      if (extra > 0) premium += payFor(extra, wageOn(sun)) ~/ 2;
    });
  }

  final gross = base + holiday + premium;
  return Payslip(
    minutes: minutes,
    base: base,
    weeklyHoliday: holiday,
    premium: premium,
    deduction: deductionOf(gross, deduction),
    entries: monthEntries,
    missingClockOut: missingClockOut,
  );
}
