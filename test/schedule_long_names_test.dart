// 근무표에서 긴 직원 이름(예: '정민준(수목금 오픈)', 최대 50자)이 잘리지 않는지.
//
// 평소 `flutter test` 에서는 넘침 예외와 (한 달·인원별 보기) 이름이 말줄임 없이 다 나오는지 본다.
// `SHOTS_DIR=<폴더> flutter test test/schedule_long_names_test.dart --update-goldens` 로 돌리면
// 실제 폰트로 PNG 를 쓴다(커밋하지 않음).
import 'package:donbug/data/app_scope.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/format.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/screens/employee/employee_schedule_screen.dart';
import 'package:donbug/screens/employee/shift_detail_screen.dart';
import 'package:donbug/screens/employer/employer_schedule_screen.dart';
import 'package:donbug/screens/employer/shift_add_screen.dart';
import 'package:donbug/screens/web/web_schedule_generate.dart';
import 'package:donbug/screens/web/web_schedule_screen.dart';
import 'package:donbug/screens/web/web_shell.dart';
import 'package:donbug/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mobile_shots.dart';

/// 실제로 쓰는 긴 이름(괄호 메모 포함).
const _long = {
  'p-jihun': '김도현(매니저)',
  'p-jimin': '정민준(수목금 오픈)',
  'p-subin': '이서준(월화 오픈)',
  'p-hayun': '최하윤(주말 마감)',
  'p-taewoo': '김태우(화목토 미들)',
  'p-seoyeon': '이서연(평일 마감)',
  'p-yuna': '정유나(토일 미들)',
  'p-dohyun': '박도현(신입 대기)',
};

/// 이름 최대 길이 50자: 모든 사람.
final _max = {
  for (final e in _long.entries)
    e.key: '${e.value} 월수금 오픈 · 화목 미들 · 주말 마감 대타 가능 · 보건증 갱신 예정 메모'.substring(0, 50)
};

AppStore _named(AppStore store, Map<String, String> names) {
  for (final p in store.state.persons) {
    final n = names[p.id];
    if (n != null) {
      p
        ..name = n
        ..fullName = n;
    }
  }
  return store;
}

/// [name] 을 담은 글자가 화면에 있고, 줄 수 제한·말줄임으로 잘리지 않았다.
void _expectFull(WidgetTester tester, String name) {
  final ps = tester.renderObjectList<RenderParagraph>(
      find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains(name)));
  expect(ps, isNotEmpty, reason: name);
  for (final p in ps) {
    expect(p.didExceedMaxLines, isFalse, reason: '$name 이 잘림: "${p.text.toPlainText()}"');
  }
}

Future<AppStore> _web(WidgetTester tester, Widget home, Size size, Map<String, String> names) async {
  final store = _named(AppStore.seeded(now: shotNow)..switchRole(Role.employer), names);
  await store.createMonthSchedule('2026-05', prefillFixed: false);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AppScope(
      store: store,
      child: MaterialApp(debugShowCheckedModeBanner: false, theme: appTheme, home: Scaffold(body: home))));
  await tester.pumpAndSettle();
  return store;
}

void main() {
  for (final (tag, names) in [('long', _long), ('max', _max)]) {
    for (final w in [1440.0, 1024.0]) {
      testWidgets('웹 근무표 4보기 · $tag 이름 @ $w', (tester) async {
        await tester.runAsync(loadShotFonts);
        await _web(tester, const WebScheduleScreen(month: '2026-05'), Size(w, 2400), names);
        for (final v in ['한 달', '파트별', '인원별', '일간']) {
          await tester.tap(find.text(v));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$v @ $w');
          if (tag == 'long' && (v == '한 달' || v == '인원별')) {
            // 이 달 근무가 있는 사람만(대기 중인 도현은 근무 없음).
            for (final n in _long.values.where((n) => n != _long['p-dohyun'])) {
              _expectFull(tester, n);
            }
          }
          await shot(tester, 'names_${tag}_web_${w.toInt()}_$v');
        }
      });
    }

    testWidgets('웹 대시보드 · $tag 이름', (tester) async {
      await tester.runAsync(loadShotFonts);
      await _web(tester, const WebShell(), const Size(1440, 2000), names);
      await shot(tester, 'names_${tag}_web_dashboard');
      await tester.tap(find.text('오늘 근무').first);
      await tester.pumpAndSettle();
      await shot(tester, 'names_${tag}_web_dashboard_today');
    });

    testWidgets('웹 자동 생성 미리보기 · $tag 이름', (tester) async {
      await tester.runAsync(loadShotFonts);
      final store = _named(AppStore.seeded(now: shotNow)..switchRole(Role.employer), names);
      final shifts = store.state.shifts.where((s) => s.storeId == store.store.id && s.date.startsWith('2026-05')).toList();
      final preview = GeneratePreview(
          planId: 'p', month: '2026-05', shifts: shifts, lines: const [], laborCost: 0, unfilled: const [], replacing: 0);
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(AppScope(
          store: store,
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: appTheme,
              home: Scaffold(
                  body: Center(child: SizedBox(width: 520, child: GeneratePreviewView(preview: preview)))))));
      await tester.pumpAndSettle();
      if (tag == 'long') _expectFull(tester, _long['p-taewoo']!);
      await shot(tester, 'names_${tag}_web_generate');
    });

    testWidgets('모바일 근무표 · $tag 이름', (tester) async {
      await tester.runAsync(loadShotFonts);
      final boss = _named(shotStore(role: Role.employer), names);
      await pumpShot(tester, const Scaffold(body: EmployerScheduleScreen()), store: boss, height: 1400);
      await shot(tester, 'names_${tag}_m_employer_schedule');
      await pumpShot(tester, ShiftAddScreen(date: boss.today), store: boss, height: 1400);
      await shot(tester, 'names_${tag}_m_shift_add');

      final emp = _named(shotStore(), names);
      await pumpShot(tester, const Scaffold(body: EmployeeScheduleScreen()), store: emp);
      await shot(tester, 'names_${tag}_m_employee_schedule');
      final mine = emp.myShifts.firstWhere((s) => s.date == ymd(emp.today));
      await pumpShot(tester, ShiftDetailScreen(shiftId: mine.id), store: emp);
      await shot(tester, 'names_${tag}_m_shift_detail');
    });
  }
}
