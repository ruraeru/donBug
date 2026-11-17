// 웹 근무표 목록·편집기(초안 모드)·템플릿 화면. 데모 store(서버 없음) 기준.
import 'package:donbug/data/app_scope.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/screens/web/web_schedule_screen.dart';
import 'package:donbug/screens/web/web_schedule_views.dart';
import 'package:donbug/screens/web/web_schedules_screen.dart';
import 'package:donbug/screens/web/web_templates_screen.dart';
import 'package:donbug/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 5, 14, 14, 30);
const _sizes = [Size(1440, 900), Size(1280, 800), Size(1024, 768), Size(800, 1000)];

Future<AppStore> _pump(WidgetTester tester, Widget home, Size size, {bool schedule = true}) async {
  final store = AppStore.seeded(now: _now)..switchRole(Role.employer);
  if (schedule) await store.createMonthSchedule('2026-05', prefillFixed: false);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AppScope(
      store: store,
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          home: Scaffold(body: home))));
  await tester.pumpAndSettle();
  return store;
}

void main() {
  for (final size in _sizes) {
    testWidgets('목록 · 편집기(4보기) · 템플릿 넘침 없음 ${size.width.toInt()}', (tester) async {
      final store = await _pump(tester, const WebSchedulesScreen(), size);
      expect(find.text('5월'), findsOneWidget);
      await store.saveScheduleTemplate('기본', '2026-05');
      await tester.pumpAndSettle();
      await tester.tap(find.text('5월'));
      await tester.pumpAndSettle();
      for (final v in ['한 달', '파트별', '인원별', '일간']) {
        await tester.tap(find.text(v));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$v @ $size');
      }
      await tester.pumpWidget(AppScope(
          store: store,
          child: MaterialApp(theme: appTheme, home: const Scaffold(body: WebTemplatesScreen()))));
      await tester.pumpAndSettle();
      expect(find.text('기본'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('편집기: 빈 칸 클릭 → 추가는 로컬(저장 안 됨) → 되돌리기 → 저장', (tester) async {
    final store = await _pump(tester, const WebScheduleScreen(month: '2026-05'), const Size(1440, 900));
    expect(store.scheduleDirty, isFalse);
    final before = store.state.shifts.length;
    // 인원별 보기: 첫 직원 행의 첫 칸.
    final cells = find.byWidgetPredicate((w) => w is DragTarget<String>);
    await tester.tapAt(tester.getBottomLeft(cells.at(6)) + const Offset(20, -10));
    await tester.pumpAndSettle();
    expect(find.textContaining('근무 추가'), findsOneWidget);
    await tester.tap(find.text('저장').last);
    await tester.pumpAndSettle();
    expect(store.state.shifts.length, before + 1);
    expect(store.scheduleDirty, isTrue);
    expect(find.text('저장 안 됨'), findsOneWidget);
    await tester.tap(find.byTooltip('되돌리기 (Ctrl/⌘ Z)'));
    await tester.pumpAndSettle();
    expect(store.state.shifts.length, before);
    await tester.tap(find.byTooltip('되돌리기 (Ctrl/⌘ Z)'), warnIfMissed: false);
    // 다시하기 후 저장하면 dirty 해제.
    await tester.tap(find.byTooltip('다시하기 (Shift Ctrl/⌘ Z)'));
    await tester.pumpAndSettle();
    expect(store.scheduleDirty, isTrue);
    await tester.tap(find.text('저장').first);
    await tester.pumpAndSettle();
    expect(store.scheduleDirty, isFalse);
    expect(find.text('저장 안 됨'), findsNothing);
  });

  testWidgets('편집기: 미정이 있으면 확정하기 막힘', (tester) async {
    final store = await _pump(tester, const WebScheduleScreen(month: '2026-05'), const Size(1440, 900));
    final staff = store.flexStaff.first;
    store.addShift(
        date: DateTime(2026, 5, 20), startMin: 540, endMin: 1080, part: '직원', staffIds: [staff.id], timeTbd: true);
    await tester.pumpAndSettle();
    expect(find.textContaining('미정 '), findsWidgets);
    final confirm = tester.widget<InkWell>(find.ancestor(of: find.text('확정하기'), matching: find.byType(InkWell)).first);
    expect(confirm.onTap, isNull);
  });

  testWidgets('일간 보기: 블록 끝을 끌면 15분 단위로 시간 조정, 몸통을 끌면 이동', (tester) async {
    final store = await _pump(tester, const WebScheduleScreen(month: '2026-05'), const Size(1440, 900));
    final day = DateTime(2026, 5, 20);
    final staff = store.flexStaff.first;
    store.addShift(date: day, startMin: 600, endMin: 900, part: '직원', staffIds: [staff.id], breakMin: 30);
    final id = store.scheduleOn(day).firstWhere((s) => s.staffId == staff.id).id;
    await tester.tap(find.text('일간'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('4주차'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('수 5/20'));
    await tester.pumpAndSettle();
    final block = find.byWidgetPredicate((w) => w is TimelineBlock && w.shift.id == id);
    expect(block, findsOneWidget);
    // 트랙 폭 W 에서 15분 = W/ (to-from) * 15 px. 오른쪽 끝 핸들을 오른쪽으로 끈다.
    final rect = tester.getRect(block);
    final track = tester.getRect(find.ancestor(of: block, matching: find.byType(Container)).first);
    final perMin = track.width / (1440 - 360);
    final g = await tester.startGesture(Offset(rect.right - 1, rect.center.dy));
    await g.moveBy(Offset(perMin * 15 * 2 + 1, 0));
    await g.moveBy(const Offset(1, 0));
    await g.up();
    await tester.pumpAndSettle();
    final s1 = store.shiftById(id)!;
    expect(s1.startMin, 600);
    expect(s1.endMin, 930);
    expect(s1.breakMin, AppStore.defaultBreak(330));
    // 너무 짧게 줄이면 최소 60분.
    final r2 = tester.getRect(block);
    final g2 = await tester.startGesture(Offset(r2.right - 1, r2.center.dy));
    await g2.moveBy(Offset(-perMin * 600, 0));
    await g2.moveBy(const Offset(-1, 0));
    await g2.up();
    await tester.pumpAndSettle();
    expect(store.shiftById(id)!.endAbs - store.shiftById(id)!.startMin, 60);
    // 몸통을 끌면 이동(길이 유지).
    final r3 = tester.getRect(block);
    final g3 = await tester.startGesture(r3.center);
    for (var i = 0; i < 8; i++) {
      await g3.moveBy(Offset(perMin * 22.5, 0)); // 8 × 22.5분 = 180분, 한 번에 큰 점프 대신 실제 마우스처럼
    }
    await g3.up();
    await tester.pumpAndSettle();
    final s3 = store.shiftById(id)!;
    expect(s3.endAbs - s3.startMin, 60);
    expect(s3.startMin, greaterThan(600));
    expect(s3.startMin % 15, 0);
  });

  test('scheduleSummary: 알바생 주 15시간 이상이면 주휴수당 대상', () async {
    final store = AppStore.seeded(now: _now)..switchRole(Role.employer);
    final sum = scheduleSummary(store, DateTime(2026, 5));
    expect(sum.workMin, greaterThan(0));
    expect(sum.cost, greaterThanOrEqualTo(sum.holidayPay));
    expect(sum.holidayCount, greaterThan(0));
  });

  testWidgets('목록: 삭제 확인 → 근무표 삭제', (tester) async {
    final store = await _pump(tester, const WebSchedulesScreen(), const Size(1440, 900));
    await tester.tap(find.byTooltip('5월 근무표 삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제').last);
    await tester.pumpAndSettle();
    expect(store.monthSchedule('2026-05'), isNull);
    expect(find.text('근무표가 없어요'), findsOneWidget);
  });

  test('초안: 되돌려 처음 상태가 되면 dirty 해제', () {
    final store = AppStore.seeded(now: _now)..switchRole(Role.employer);
    final staff = store.activeStaff.first;
    store.setScheduleDraft(true);
    store.addShift(date: DateTime(2026, 5, 20), startMin: 600, endMin: 900, part: '직원', staffIds: [staff.id]);
    expect(store.scheduleDirty, isTrue);
    store.undo();
    expect(store.scheduleDirty, isFalse);
  });

  test('scheduleSummary: 주휴수당은 일요일이 속한 달에, 주 전체 근무로 계산', () {
    final store = AppStore.seeded(now: _now)..switchRole(Role.employer);
    final st = store.activeStaff.firstWhere((x) => !x.kind.flex);
    // 2026-04-27(월)~05-03(일): 월~금 8h. 4월 분이 32h 라도 일요일(5/3)이 5월이라 5월에 지급.
    store.state.shifts.removeWhere((x) => !store.staffById(x.staffId)!.kind.flex);
    for (final d in [27, 28, 29, 30]) {
      store.addShift(date: DateTime(2026, 4, d), startMin: 540, endMin: 1080, part: st.part, staffIds: [st.id], breakMin: 60);
    }
    store.addShift(date: DateTime(2026, 5, 1), startMin: 540, endMin: 1080, part: st.part, staffIds: [st.id], breakMin: 60);
    expect(scheduleSummary(store, DateTime(2026, 4)).holidayPay, 0);
    expect(scheduleSummary(store, DateTime(2026, 5)).holidayPay, greaterThan(0));
  });
}
