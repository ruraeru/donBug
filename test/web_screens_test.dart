// 웹 화면 스크린샷 하네스.
//
// 평소 `flutter test` 에서는 메뉴 × 화면 폭마다 넘침 예외만 확인한다.
// `flutter test test/web_screens_test.dart --update-goldens` 로 돌리면
// 실제 폰트로 PNG 를 SHOTS_DIR(기본: build/web_shots)에 쓴다. 눈으로 확인하는 용도이며 커밋하지 않는다.
import 'dart:io';

import 'package:donbug/data/app_scope.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/format.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/screens/web/web_pos_qr_screen.dart';
import 'package:donbug/screens/web/web_schedule_views.dart';
import 'package:donbug/screens/web/web_shell.dart';
import 'package:donbug/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 5, 14, 14, 30);

const _sizes = [Size(1440, 900), Size(1280, 800), Size(1024, 768), Size(800, 1000)];

Future<void> _loadFonts() async {
  final loader = FontLoader('Noto Sans KR');
  for (final w in ['Regular', 'Medium', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/NotoSansKR-$w.otf'));
  }
  await loader.load();
  final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

Future<AppStore> _pump(WidgetTester tester, Size size) async {
  final store = AppStore.seeded(now: _now)..switchRole(Role.employer);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AppScope(
      store: store,
      child: MaterialApp(
          debugShowCheckedModeBanner: false, theme: appTheme, home: const WebShell())));
  await tester.pumpAndSettle();
  return store;
}

/// 사이드바 메뉴 이름. 접힌 사이드바(아이콘)에서도 툴팁으로 찾는다.
Finder _menu(String label) {
  final text = find.text(label);
  if (text.evaluate().isNotEmpty) return text.first;
  final tip = find.byTooltip(label);
  return tip.evaluate().isNotEmpty ? tip.first : tip;
}

Future<void> _shot(WidgetTester tester, String name) async {
  if (!autoUpdateGoldenFiles) return;
  final dir = Platform.environment['SHOTS_DIR'] ?? 'build/web_shots';
  await expectLater(find.byType(MaterialApp),
      matchesGoldenFile(Uri.file('${Directory(dir).absolute.path}/$name.png')));
}

void main() {
  const menus = ['대시보드', '근무표', '직원 관리', '대타 승인', '인건비', '서류·컴플라이언스', '공지', 'AI 노무 도우미'];

  for (final size in _sizes) {
    testWidgets('웹 메뉴 화면 ${size.width.toInt()}', (tester) async {
      await tester.runAsync(_loadFonts);
      await _pump(tester, size);
      for (final m in menus) {
        final f = _menu(m);
        if (f.evaluate().isEmpty) continue; // 좁은 폭에서 메뉴가 Drawer 안에 있을 때
        await tester.tap(f);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$m @ $size');
        await _shot(tester, '${size.width.toInt()}_$m');
      }
    });
  }

  Future<AppStore> open(WidgetTester tester, String menu, {Size size = const Size(1440, 900)}) async {
    final store = await _pump(tester, size);
    await tester.tap(_menu(menu));
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('근무표: 4개 보기 · 주 이동', (tester) async {
    await tester.runAsync(_loadFonts);
    await open(tester, '근무표');
    for (final v in ['한 달', '인원별', '일간', '파트별']) {
      await tester.tap(find.text(v));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: v);
      await _shot(tester, 'schedule_$v');
    }
    await tester.tap(find.textContaining('4주차'));
    await tester.pumpAndSettle();
    expect(find.text('월 5/18'), findsOneWidget);
  });

  testWidgets('근무표: 빈 칸 클릭 → 추가 창 저장 → 되돌리기', (tester) async {
    await tester.runAsync(_loadFonts);
    final store = await open(tester, '근무표');
    final before = store.state.shifts.length;
    // 파트별 보기 수요일(5/13)은 유동 근무 칸이 비어 있다. 지난 날짜라도 추가는 된다.
    final cells = find.byWidgetPredicate((w) => w is DragTarget<String>);
    await tester.tapAt(tester.getBottomLeft(cells.at(3 * 7 + 2)) + const Offset(20, -10));
    await tester.pumpAndSettle();
    expect(find.textContaining('근무 추가'), findsOneWidget);
    await _shot(tester, 'dialog_add');
    await tester.tap(find.text('저장').last);
    await tester.pumpAndSettle();
    expect(store.state.shifts.length, before + 1);
    expect(store.state.shifts.last.part, '직원');
    await tester.tap(find.byTooltip('되돌리기'));
    await tester.pumpAndSettle();
    expect(store.state.shifts.length, before);
  });

  testWidgets('근무표: 블록을 끌어 다른 요일로 옮긴다', (tester) async {
    await tester.runAsync(_loadFonts);
    final store = await open(tester, '근무표');
    // 금요일 오픈(수빈) → 다음 칸(토) 은 이미 수빈 근무라 겹침으로 막히고, 하윤 금 마감 → 일 마감은 된다.
    final fri = store.today.add(const Duration(days: 1));
    final hayun = store.shiftsOn(fri).firstWhere((s) => s.part == '마감');
    final from = tester.getCenter(find.byWidgetPredicate((w) => w is ShiftBlock && w.shift.id == hayun.id));
    final sun = find.byWidgetPredicate((w) => w is DragTarget<String>).at(2 * 7 + 6);
    final g = await tester.startGesture(from);
    await g.moveBy(const Offset(10, 0));
    await g.moveTo(tester.getCenter(sun));
    await g.up();
    await tester.pumpAndSettle();
    expect(store.shiftById(hayun.id)!.date, ymd(store.today.add(const Duration(days: 3))));
  });

  testWidgets('근무표: 자동 채우기 · 확정하기(미정이 있으면 막힘)', (tester) async {
    await tester.runAsync(_loadFonts);
    final store = await open(tester, '근무표');
    await tester.tap(find.textContaining('4주차'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('자동 채우기'));
    await tester.pumpAndSettle();
    expect(find.text('빈 칸 1개를 채웠어요'), findsOneWidget);
    await tester.tap(find.text('확정하기'));
    await tester.pumpAndSettle();
    expect(find.text('시간 미정 1건을 먼저 정해 주세요'), findsOneWidget);
    expect(store.store.scheduleConfirmedAt, isNull);
  });

  testWidgets('직원 상세 시트: 시급 저장(최저임금 검사)', (tester) async {
    await tester.runAsync(_loadFonts);
    final store = await open(tester, '직원 관리');
    await tester.tap(find.text('상세 ›').at(1));
    await tester.pumpAndSettle();
    await _shot(tester, 'sheet_staff');
    final field = find.byType(TextField).last;
    await tester.enterText(field, '9000');
    await tester.tap(find.text('저장'));
    await tester.pump();
    expect(find.textContaining('최저임금'), findsWidgets);
    await tester.enterText(field, '11000');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(store.activeStaff[1].wage, 11000);
  });

  testWidgets('직원 관리: 가입 승인', (tester) async {
    await tester.runAsync(_loadFonts);
    final store = await open(tester, '직원 관리');
    await tester.tap(find.text('승인하고 시급 설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('승인'));
    await tester.pumpAndSettle();
    expect(store.pendingStaff, isEmpty);
  });

  testWidgets('대타 승인 페이지: 승인 → 근무자 교체', (tester) async {
    await tester.runAsync(_loadFonts);
    final store = await open(tester, '대타 승인');
    final req = store.pendingSubs.firstWhere((r) => r.status == SubStatus.accepted);
    await tester.tap(find.text('승인').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('승인').last);
    await tester.pumpAndSettle();
    expect(store.subById(req.id)!.status, SubStatus.approved);
    expect(store.shiftById(req.shiftId)!.staffId, req.acceptedId);
  });

  testWidgets('공지: 작성 창 → 올리기 · 리마인드', (tester) async {
    await tester.runAsync(_loadFonts);
    final store = await open(tester, '공지');
    await tester.tap(find.text('+ 공지 작성'));
    await tester.pumpAndSettle();
    await _shot(tester, 'dialog_notice');
    await tester.enterText(find.byType(TextField).at(0), '새 공지');
    await tester.enterText(find.byType(TextField).at(1), '내용');
    await tester.tap(find.text('올리기'));
    await tester.pumpAndSettle();
    expect(store.storeNotices.any((n) => n.title == '새 공지'), isTrue);
    await tester.tap(find.text('미확인자 리마인드'));
    await tester.pumpAndSettle();
    expect(find.textContaining('명에게 다시 알렸어요'), findsOneWidget);
  });

  testWidgets('대시보드: 알림 · 오늘 근무 창', (tester) async {
    await tester.runAsync(_loadFonts);
    final store = await open(tester, '대시보드');
    await tester.tap(find.byTooltip('알림'));
    await tester.pumpAndSettle();
    await _shot(tester, 'dialog_notifications');
    await tester.tap(find.text('모두 읽음'));
    await tester.pumpAndSettle();
    expect(store.unreadNotificationCount, 0);
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('오늘 근무'));
    await tester.pumpAndSettle();
    await _shot(tester, 'dialog_today');
    expect(tester.takeException(), isNull);
  });

  testWidgets('좁은 창: 서랍 메뉴', (tester) async {
    await tester.runAsync(_loadFonts);
    await _pump(tester, const Size(700, 900));
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('근무표'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _shot(tester, '700_근무표');
  });

  testWidgets('POS: QR 을 누르면 다음 근무자 출근', (tester) async {
    await tester.runAsync(_loadFonts);
    final store = AppStore.seeded(now: _now)..switchRole(Role.employer);
    for (final size in [const Size(1440, 900), const Size(1024, 700)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(AppScope(
          store: store, child: MaterialApp(theme: appTheme, home: const WebPosQrScreen())));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '$size');
      await _shot(tester, 'pos_${size.width.toInt()}');
    }
    addTearDown(tester.view.reset);
    final waiting = store.shiftsOn(store.today).where((s) => store.attendanceFor(s.id) == null).length;
    await tester.tap(find.text('QR'));
    await tester.pump();
    expect(find.textContaining('출근 완료'), findsOneWidget);
    expect(store.shiftsOn(store.today).where((s) => store.attendanceFor(s.id) == null).length,
        waiting - 1);
    await tester.pump(const Duration(seconds: 4));
    expect(find.textContaining('출근 완료'), findsNothing);
  });
}
