/// 급여 계산 (순수 함수). 노무 규칙을 단순화한 프로토타입용 근사치다.
///
/// - 기본급 = 실근무 분 × 시급 / 60
/// - 주휴수당: 그 주(월–일) 대타 제외 근무가 15시간 이상이면 min(주시간, 40) / 40 × 8 × 시급.
///   주의 일요일이 속한 달에 지급한다.
/// - 가산수당(5인 이상 + 직원 설정): 야간(22–06)과 하루 8시간 초과분에 0.5배 추가. 휴일가산은 0.
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
  });

  final DateTime start;
  final DateTime end;
  final int breakMin;
  final bool isSubstitute;

  /// 아직 일하지 않은 예정 근무(예상 급여 계산용).
  final bool planned;

  DateTime get day => dayOf(start);

  int get minutes {
    final span = end.difference(start).inMinutes;
    return max(0, span > breakMin ? span - breakMin : span);
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
  });

  final int minutes;
  final int base;
  final int weeklyHoliday;
  final int premium;
  final int deduction;

  /// 그 달에 속한 근무(날짜순).
  final List<WorkEntry> entries;

  int get gross => base + weeklyHoliday + premium;
  int get net => gross - deduction;
}

int deductionOf(int gross, Deduction d) => switch (d) {
      Deduction.biz33 => (gross * 0.033).floor(),
      Deduction.insurance => (gross * insuranceRate).floor(),
      Deduction.none => 0,
    };

int payFor(int minutes, int wage) => (minutes * wage / 60).round();

/// 주휴수당 (한 주의 대타 제외 근무 분 기준).
int weeklyHolidayPay(int weekMinutes, int wage) {
  if (weekMinutes < 15 * 60) return 0;
  final h = min(weekMinutes, 40 * 60) / 60;
  return (h / 40 * 8 * wage).round();
}

/// [entries] 는 그 달 앞뒤 주까지 포함해도 된다(주휴 계산에 필요).
Payslip computePayslip({
  required List<WorkEntry> entries,
  required int year,
  required int month,
  required int wage,
  required Deduction deduction,
  bool weeklyHolidayAuto = true,
  bool premiumApplies = false,
}) {
  bool inMonth(DateTime d) => d.year == year && d.month == month;
  final monthEntries = entries.where((e) => inMonth(e.day)).toList()
    ..sort((a, b) => a.start.compareTo(b.start));

  final minutes = monthEntries.fold(0, (s, e) => s + e.minutes);
  final base = payFor(minutes, wage);

  var holiday = 0;
  if (weeklyHolidayAuto) {
    final weeks = <DateTime, int>{};
    for (final e in entries.where((e) => !e.isSubstitute)) {
      final w = mondayOf(e.day);
      weeks[w] = (weeks[w] ?? 0) + e.minutes;
    }
    weeks.forEach((monday, m) {
      if (inMonth(monday.add(const Duration(days: 6)))) {
        holiday += weeklyHolidayPay(m, wage);
      }
    });
  }

  var premium = 0;
  if (premiumApplies) {
    final perDay = <DateTime, int>{};
    for (final e in monthEntries) {
      premium += payFor(e.nightMinutes, wage) ~/ 2;
      perDay[e.day] = (perDay[e.day] ?? 0) + e.minutes;
    }
    for (final m in perDay.values) {
      if (m > 480) premium += payFor(m - 480, wage) ~/ 2;
    }
  }

  final gross = base + holiday + premium;
  return Payslip(
    minutes: minutes,
    base: base,
    weeklyHoliday: holiday,
    premium: premium,
    deduction: deductionOf(gross, deduction),
    entries: monthEntries,
  );
}
