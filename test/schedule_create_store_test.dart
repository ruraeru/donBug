import 'package:flutter_test/flutter_test.dart';

import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/format.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/data/seed.dart';

AppStore makeStore() {
  final t = DateTime(2026, 5, 14, 14, 30);
  return AppStore(buildSeed(t), now: () => t);
}

final juneFrom = DateTime(2026, 6, 1), juneTo = DateTime(2026, 6, 30);

void main() {
  test('미리보기는 상태를 바꾸지 않는다', () {
    final s = makeStore();
    final before = s.toJson();
    final plan = s.planSchedule(from: juneFrom, to: juneTo, needs: [1, 2, 1], copyLastWeek: true);
    expect(plan.shifts, isNotEmpty);
    expect(s.toJson(), before);
    expect(s.canUndo, isFalse);
  });

  test('다음 달: 같은 날 한 사람 한 근무, 겹침 없음, 필요 인원만큼', () {
    final s = makeStore();
    final plan = s.planSchedule(from: juneFrom, to: juneTo, needs: [1, 1, 1]);
    expect(plan.shifts.length + plan.unfilled, 30 * 3);
    final keys = plan.shifts.map((x) => '${x.date}/${x.staffId}');
    expect(keys.toSet().length, keys.length);
    expect(plan.shifts.every((x) => x.id.isEmpty && s.staffById(x.staffId)!.active), isTrue);
  });

  test('이번 달은 오늘 이전 날짜를 만들지 않는다', () {
    final s = makeStore();
    final plan = s.planSchedule(
        from: DateTime(2026, 5, 1), to: DateTime(2026, 5, 31), needs: [3, 3, 3]);
    expect(plan.from, DateTime(2026, 5, 1));
    expect(plan.shifts.every((x) => x.date.compareTo('2026-05-14') >= 0), isTrue);
  });

  test('제외 직원은 배정되지 않고 유동 근무자도 자동 배정 안 된다', () {
    final s = makeStore();
    final skip = s.partStaff.first.id;
    final plan = s.planSchedule(
        from: juneFrom, to: juneTo, needs: [1, 1, 1], excludeStaffIds: {skip});
    final flex = s.flexStaff.map((m) => m.id).toSet();
    expect(plan.shifts.any((x) => x.staffId == skip || flex.contains(x.staffId)), isFalse);
  });

  test('주 최대 분을 지키고 못 채우면 unfilled', () {
    final s = makeStore();
    const max = 14 * 60 + 59;
    final plan = s.planSchedule(from: juneFrom, to: juneTo, needs: [1, 1, 1], weeklyMaxMin: max);
    final perWeek = <String, int>{};
    for (final x in plan.shifts) {
      final k = '${x.staffId}/${ymd(mondayOf(parseYmd(x.date)))}';
      perWeek[k] = (perWeek[k] ?? 0) + x.scheduledMinutes;
    }
    expect(perWeek.values.every((m) => m <= max), isTrue);
    expect(plan.unfilled, greaterThan(0));
  });

  test('cost 는 새 근무 기본급 합, minutesByStaff 는 기존 + 새 근무', () {
    final s = makeStore();
    final plan = s.planSchedule(from: DateTime(2026, 5, 18), to: DateTime(2026, 5, 24), needs: [1, 1, 1]);
    expect(plan.cost, plan.shifts.fold(0, (a, x) => a + s.plannedPay(Shift(
        id: x.id, storeId: x.storeId, staffId: x.staffId, date: x.date,
        startMin: x.startMin, endMin: x.endMin, part: x.part, breakMin: x.breakMin))));
    final total = plan.minutesByStaff.values.fold(0, (a, b) => a + b);
    final existing = s.activeStaff
        .expand((m) => s.shiftsOfStaff(m.id))
        .where((x) => x.date.compareTo('2026-05-18') >= 0 && x.date.compareTo('2026-05-24') <= 0)
        .fold(0, (a, x) => a + x.scheduledMinutes);
    expect(total, existing + plan.shifts.fold(0, (a, x) => a + x.scheduledMinutes));
  });

  test('지난주 반복: 지난주 근무 요일을 따라간다', () {
    final s = makeStore();
    final plan = s.planSchedule(from: juneFrom, to: juneTo, needs: [0, 0, 0], copyLastWeek: true);
    expect(plan.shifts, isNotEmpty);
    expect(plan.unfilled, 0);
  });

  test('apply: 한 번에 되돌려지고 필요 인원 저장 · 직원마다 알림 한 건', () {
    final s = makeStore();
    final before = s.toJson();
    final plan = s.planSchedule(from: juneFrom, to: juneTo, needs: [1, 2, 1]);
    final n = s.applySchedulePlan(plan, needs: [1, 2, 1]);
    expect(n, plan.shifts.length);
    expect(s.store.parts.map((p) => p.need), [1, 2, 1]);
    final noti = s.state.notifications.where((x) => x.title == '6월 근무가 추가됐어요');
    expect(noti.length, plan.shifts.map((x) => x.staffId).toSet().length);
    s.undo();
    expect(s.toJson(), before);
  });

  test('apply: 0건이면 되돌리기에 안 쌓는다', () {
    final s = makeStore();
    final plan = s.planSchedule(from: juneFrom, to: juneTo, needs: [0, 0, 0]);
    expect(s.applySchedulePlan(plan, needs: [0, 0, 0]), 0);
    expect(s.canUndo, isFalse);
  });

  test('자동 배정은 자기 파트 근무자부터 쓴다', () {
    final s = AppStore(buildSeed(DateTime(2026, 5, 14, 14, 30)), now: () => DateTime(2026, 5, 14, 14, 30));
    final plan = s.planSchedule(
        from: DateTime(2026, 6, 1), to: DateTime(2026, 6, 30), needs: [for (final p in s.store.parts) p.need]);
    final own = plan.shifts.where((x) => s.staffById(x.staffId)!.part == x.part).length;
    expect(own / plan.shifts.length, greaterThan(0.8));
  });
}
