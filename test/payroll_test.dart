import 'package:flutter_test/flutter_test.dart';

import 'package:donbug/data/models.dart';
import 'package:donbug/data/payroll.dart';

WorkEntry entry(DateTime start, int hours, {int breakMin = 0, bool sub = false}) =>
    WorkEntry(
      start: start,
      end: start.add(Duration(hours: hours)),
      breakMin: breakMin,
      isSubstitute: sub,
    );

void main() {
  test('주휴수당은 주 15시간부터', () {
    expect(weeklyHolidayPay(14 * 60 + 30, 10320), 0);
    expect(weeklyHolidayPay(15 * 60, 10320), 30960); // 15/40 × 8 × 10,320
    expect(weeklyHolidayPay(50 * 60, 10320), 82560); // 40시간 상한
  });

  test('대타 근무는 주휴 계산에서 빠진다', () {
    // 2026-05-11(월) 주: 6h × 2 + 대타 6h → 대타 제외 12h 라 주휴 없음.
    final mon = DateTime(2026, 5, 11, 10);
    final p = computePayslip(
      entries: [
        entry(mon, 6),
        entry(mon.add(const Duration(days: 1)), 6),
        entry(mon.add(const Duration(days: 2)), 6, sub: true),
      ],
      year: 2026,
      month: 5,
      wage: 10320,
      deduction: Deduction.none,
    );
    expect(p.minutes, 18 * 60);
    expect(p.weeklyHoliday, 0);
    expect(p.base, 18 * 10320);
  });

  test('5인 미만이면 가산수당 없음, 5인 이상이면 야간 0.5배', () {
    final night = WorkEntry(
      start: DateTime(2026, 5, 16, 22),
      end: DateTime(2026, 5, 17, 6),
      breakMin: 60,
    );
    expect(night.minutes, 420);
    expect(night.nightMinutes, 480);
    Payslip calc(bool premium) => computePayslip(
          entries: [night],
          year: 2026,
          month: 5,
          wage: 10000,
          deduction: Deduction.none,
          premiumApplies: premium,
        );
    expect(calc(false).premium, 0);
    expect(calc(true).premium, 40000); // 8h × 10,000 × 0.5
  });

  test('3.3% 공제는 원 단위 내림', () {
    expect(deductionOf(871000, Deduction.biz33), 28743);
    expect(deductionOf(100001, Deduction.biz33), 3300);
    expect(deductionOf(100000, Deduction.none), 0);
  });

  test('주휴는 일요일이 속한 달에 지급', () {
    // 2026-04-27(월)~05-03(일): 일요일이 5월 → 4월 급여에는 없고 5월 급여에 있다.
    final entries = [
      for (var d = 0; d < 5; d++) entry(DateTime(2026, 4, 27 + d, 10), 4),
    ];
    final april = computePayslip(
        entries: entries, year: 2026, month: 4, wage: 10000, deduction: Deduction.none);
    final may = computePayslip(
        entries: entries, year: 2026, month: 5, wage: 10000, deduction: Deduction.none);
    expect(april.weeklyHoliday, 0);
    expect(may.weeklyHoliday, 40000); // 20h → 20/40 × 8 × 10,000
  });
}
