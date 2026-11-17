import 'package:flutter_test/flutter_test.dart';

import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/format.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/data/payroll.dart';
import 'package:donbug/data/seed.dart';

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
      wageOn: (_) => 10320,
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
          wageOn: (_) => 10000,
          deduction: Deduction.none,
          premiumApplies: premium,
        );
    expect(calc(false).premium, 0);
    expect(calc(true).premium, 35000); // 야간 min(480, 실근로 420)분 × 10,000 × 0.5
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
        entries: entries, year: 2026, month: 4, wageOn: (_) => 10000, deduction: Deduction.none);
    final may = computePayslip(
        entries: entries, year: 2026, month: 5, wageOn: (_) => 10000, deduction: Deduction.none);
    expect(april.weeklyHoliday, 0);
    expect(may.weeklyHoliday, 40000); // 20h → 20/40 × 8 × 10,000
  });

  test('근무가 휴게보다 짧으면 0분', () {
    final e = WorkEntry(
        start: DateTime(2026, 5, 11, 14), end: DateTime(2026, 5, 11, 14, 20), breakMin: 30);
    expect(e.minutes, 0);
  });

  test('연차는 가산수당 제외, 야간 분은 실근로 분 이하', () {
    final leave = WorkEntry(
        start: DateTime(2026, 5, 12, 18),
        end: DateTime(2026, 5, 13, 3),
        breakMin: 60,
        leave: true);
    final work = WorkEntry(
        start: DateTime(2026, 5, 11, 22), end: DateTime(2026, 5, 12, 2), breakMin: 60);
    final p = computePayslip(
      entries: [leave, work],
      year: 2026,
      month: 5,
      wageOn: (_) => 10000,
      deduction: Deduction.none,
      premiumApplies: true,
    );
    // 근무 4h-휴게 1h = 180분 → 야간 min(240,180)=180분 × 10,000 × 0.5
    expect(p.premium, 15000);
  });

  group('주휴 조건 (AppStore.payslip)', () {
    // 2026-06-01(월)~06-07(일) 주. 기준 시각은 6/20 이라 그 주는 이미 지났다.
    late AppStore store;
    late Staff st;
    var now = DateTime(2026, 6, 20, 12);
    var n = 0;

    // [days] 일(월=0) 각각 [hours] 시간 근무. [attend] 면 출근 기록도 만든다.
    void work(List<int> days, int hours, {bool attend = true, int week = 1}) {
      for (final d in days) {
        final id = 'T${n++}';
        store.state.shifts.add(Shift(
          id: id,
          storeId: st.storeId,
          staffId: st.id,
          date: ymd(DateTime(2026, 6, week + d)),
          startMin: 600,
          endMin: 600 + hours * 60,
          part: '미들',
        ));
        if (attend) {
          final day = DateTime(2026, 6, week + d, 10);
          store.state.attendance.add(Attendance(
              id: 'A$id',
              storeId: st.storeId,
              shiftId: id,
              staffId: st.id,
              // 지각 30분
              clockIn: day.add(const Duration(minutes: 30)).toIso8601String(),
              clockOut: day.add(Duration(hours: hours)).toIso8601String()));
        }
      }
    }

    setUp(() {
      now = DateTime(2026, 6, 20, 12);
      store = AppStore(buildSeed(now), now: () => now);
      st = store.myStaff!;
      final mine = store.state.shifts.where((x) => x.staffId == st.id).map((x) => x.id).toSet();
      store.state.shifts.removeWhere((x) => mine.contains(x.id));
      store.state.attendance.removeWhere((a) => mine.contains(a.shiftId));
      st
        ..wage = 10000
        ..wages = []
        ..contract = null
        ..leftAt = null
        ..weeklyHolidayAuto = true;
    });

    int holiday({bool projected = false}) =>
        store.payslip(st.id, 2026, 6, projected: projected).weeklyHoliday;

    test('개근이고 지각만 했으면 지급', () {
      work([0, 1, 2, 3, 4], 4); // 20h
      expect(holiday(), 40000); // 20/40 × 8 × 10,000
    });

    test('결근한 주는 0', () {
      work([0, 1, 2, 3], 5); // 20h 출근
      work([4], 5, attend: false); // 금요일 결근
      expect(holiday(), 0);
    });

    test('토요일(일요일 전) 퇴사면 0, 일요일이면 지급', () {
      work([0, 1, 2, 3, 4], 4);
      st.leftAt = '2026-06-06';
      expect(holiday(), 0);
      st.leftAt = '2026-06-07';
      expect(holiday(), 40000);
    });

    test('계약서 주 소정시간이 우선: 14h 면 0, 20h 면 20/40×8×시급', () {
      work([0, 1, 2, 3, 4], 5); // 실제는 25h
      Contract c(int h) => Contract(
          start: '2026-01-01', end: '2026-12-31', wage: 10000, weeklyHours: h, workDays: '월~금');
      st.contract = c(14);
      expect(holiday(), 0);
      st.contract = c(20);
      expect(holiday(), 40000);
    });

    test('확정 급여는 진행 중인 주 미지급, 예상 급여는 지급', () {
      work([0, 1, 2, 3, 4], 4, week: 15); // 6/15~6/19 근무, 일요일 6/21 은 아직
      expect(holiday(), 0);
      expect(holiday(projected: true), 40000);
    });

    test('아직 끝나지 않은 근무는 예상 급여에서 출근할 것으로 본다', () {
      work([0, 1, 2], 4, week: 15);
      work([3, 4], 4, attend: false, week: 15); // 6/18·6/19 — 이미 끝난 미출근 → 결근
      expect(holiday(projected: true), 0);
      now = DateTime(2026, 6, 15, 9); // 월요일 아침: 아직 아무것도 안 끝남
      expect(holiday(projected: true), 40000);
    });

    test('시급 이력: 7/1 부터 새 시급', () {
      st.wages = [const WageStep('2026-07-01', 12000)];
      st.wage = 12000;
      expect(st.wageOn(DateTime(2026, 6, 30)), 12000); // 첫 항목 이전은 wage
      st.wages = [const WageStep('2000-01-01', 10000), const WageStep('2026-07-01', 12000)];
      expect(st.wageOn(DateTime(2026, 6, 30)), 10000);
      expect(st.wageOn(DateTime(2026, 7, 1)), 12000);
      final e = [
        entry(DateTime(2026, 6, 30, 10), 5),
        entry(DateTime(2026, 7, 1, 10), 5),
      ];
      final jun = computePayslip(
          entries: e, year: 2026, month: 6, wageOn: st.wageOn, deduction: Deduction.none);
      final jul = computePayslip(
          entries: e, year: 2026, month: 7, wageOn: st.wageOn, deduction: Deduction.none);
      expect(jun.base, 50000);
      expect(jul.base, 60000);
    });

    test('updateStaff 로 시급을 바꾸면 이력이 쌓인다', () {
      store.updateStaff(st.id, wage: 11000);
      expect(st.wages.map((w) => w.wage), [10000, 11000]);
      expect(st.wageOn(DateTime(2026, 6, 19)), 10000);
      expect(st.wageOn(DateTime(2026, 6, 20)), 11000);
    });
  });

  group('주 40시간 연장', () {
    Payslip calc(List<WorkEntry> e) => computePayslip(
        entries: e,
        year: 2026,
        month: 6,
        wageOn: (_) => 10000,
        deduction: Deduction.none,
        weeklyHolidayAuto: false,
        premiumApplies: true);

    test('하루 7h × 6일(42h): 2h × 0.5', () {
      final p = calc([for (var d = 0; d < 6; d++) entry(DateTime(2026, 6, 1 + d, 9), 7)]);
      expect(p.premium, 10000); // 120분 × 10,000 × 0.5
    });

    test('하루 10h × 5일: 일 초과 10h 와 주 초과 10h 는 중복 없이 10h', () {
      final p = calc([for (var d = 0; d < 5; d++) entry(DateTime(2026, 6, 1 + d, 9), 10)]);
      expect(p.premium, 50000); // 600분 × 10,000 × 0.5
    });

    test('5인 미만이면 없음', () {
      final p = computePayslip(
          entries: [for (var d = 0; d < 6; d++) entry(DateTime(2026, 6, 1 + d, 9), 7)],
          year: 2026,
          month: 6,
          wageOn: (_) => 10000,
          deduction: Deduction.none);
      expect(p.premium, 0);
    });
  });
}
