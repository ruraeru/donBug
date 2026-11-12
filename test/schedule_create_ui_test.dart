// 웹 근무표 만들기 창. 스크린샷: SHOTS_DIR=<폴더> flutter test test/schedule_create_ui_test.dart --update-goldens
import 'dart:io';

import 'package:donbug/data/app_scope.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/format.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/data/seed.dart';
import 'package:donbug/screens/web/web_schedule_create_dialog.dart';
import 'package:donbug/screens/web/web_shell.dart';
import 'package:donbug/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 5, 14, 14, 30);
const _sizes = [Size(1440, 900), Size(1280, 800), Size(1024, 768), Size(800, 1000)];

/// 인자를 기록하고, [fake] 가 있으면 그 결과를 돌려주는 store.
class _Spy extends AppStore {
  _Spy({this.fake}) : super(buildSeed(_now), now: () => _now);

  final SchedulePlan Function(DateTime from, DateTime to)? fake;
  final calls = <Map<String, Object?>>[];

  @override
  SchedulePlan planSchedule({
    required DateTime from,
    required DateTime to,
    required List<int> needs,
    bool copyLastWeek = false,
    Set<String> excludeStaffIds = const {},
    int weeklyMaxMin = 40 * 60,
  }) {
    calls.add({
      'from': from,
      'to': to,
      'needs': [...needs],
      'copy': copyLastWeek,
      'exclude': {...excludeStaffIds},
      'max': weeklyMaxMin,
    });
    return fake?.call(from, to) ?? super.planSchedule(from: from, to: to, needs: needs);
  }

  @override
  int applySchedulePlan(SchedulePlan plan, {List<int>? needs}) => plan.shifts.length;
}

SchedulePlan _fakePlan(AppStore s, DateTime from, DateTime to) {
  final staff = s.partStaff.take(3).toList();
  return SchedulePlan(
    from: from,
    to: to,
    shifts: [
      for (var i = 0; i < 12; i++)
        Shift(
            id: '',
            storeId: s.store.id,
            staffId: staff[i % 3].id,
            date: ymd(from.add(Duration(days: i))),
            startMin: 600,
            endMin: 960,
            part: '오픈'),
    ],
    unfilled: 3,
    minutesByStaff: {for (final (i, p) in staff.indexed) p.id: (30 - i * 8) * 60},
    cost: 2145600,
  );
}

Future<void> _pump(WidgetTester tester, AppStore store, Size size, {Widget? home}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  store.switchRole(Role.employer);
  await tester.pumpWidget(AppScope(
      store: store,
      child: MaterialApp(
          debugShowCheckedModeBanner: false, theme: appTheme, home: home ?? const WebShell())));
  await tester.pumpAndSettle();
}

/// 근무표 메뉴로 간다: 사이드바 글자 → 아이콘 레일 툴팁 → 서랍.
Future<void> _gotoSchedule(WidgetTester tester) async {
  if (find.text('근무표').evaluate().isEmpty && find.byTooltip('근무표').evaluate().isEmpty) {
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('근무표').evaluate().isNotEmpty ? find.text('근무표').first : find.byTooltip('근무표').first);
  await tester.pumpAndSettle();
}

Future<void> _openDialog(WidgetTester tester) async {
  await _gotoSchedule(tester);
  await tester.tap(find.widgetWithText(InkWell, '근무표 만들기').first);
  await tester.pumpAndSettle();
}

Future<void> _loadFonts() async {
  final loader = FontLoader('Noto Sans KR');
  for (final w in ['Regular', 'Medium', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/NotoSansKR-$w.otf'));
  }
  await loader.load();
  final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

Future<void> _shot(WidgetTester tester, String name) async {
  if (!autoUpdateGoldenFiles) return;
  final dir = Platform.environment['SHOTS_DIR'] ?? 'build/web_shots';
  await expectLater(find.byType(MaterialApp),
      matchesGoldenFile(Uri.file('${Directory(dir).absolute.path}/$name.png')));
}

void main() {
  testWidgets('헤더 버튼으로 창이 열리고 설정을 바꾸면 planSchedule 인자가 바뀐다', (tester) async {
    final store = _Spy();
    await _pump(tester, store, const Size(1440, 900));
    await _openDialog(tester);
    expect(find.text('미리보기'), findsOneWidget);

    var c = store.calls.last;
    expect(c['from'], DateTime(2026, 5, 14)); // 오늘 이후만
    expect(c['to'], DateTime(2026, 5, 31));
    expect(c['copy'], false);
    expect(c['max'], 40 * 60);
    final needs0 = [...(c['needs'] as List<int>)];

    await tester.tap(find.text('다음 달'));
    await tester.pumpAndSettle();
    c = store.calls.last;
    expect(c['from'], DateTime(2026, 6, 1));
    expect(c['to'], DateTime(2026, 6, 30));

    await tester.tap(find.text('지난주 반복'));
    await tester.pumpAndSettle();
    expect(store.calls.last['copy'], true);

    await tester.tap(find.byTooltip('오픈 인원 늘리기'));
    await tester.pumpAndSettle();
    expect((store.calls.last['needs'] as List<int>)[0], needs0[0] + 1);

    final first = store.partStaff.first;
    await tester.tap(find.text(store.nameOf(first.id)).first);
    await tester.pumpAndSettle();
    expect(store.calls.last['exclude'], {first.id});

    await tester.ensureVisible(find.text('40시간'));
    await tester.tap(find.text('40시간'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15시간 미만').last);
    await tester.pumpAndSettle();
    expect(store.calls.last['max'], 14 * 60 + 59);
  });

  testWidgets('새 근무 0건이면 만들기가 비활성', (tester) async {
    final store = _Spy(); // 기본 구현은 빈 결과
    await _pump(tester, store, const Size(1440, 900));
    await _openDialog(tester);
    final btn = find.widgetWithText(InkWell, '근무표 만들기').last;
    expect(tester.widget<InkWell>(btn).onTap, isNull);
  });

  testWidgets('결과가 있으면 만들기가 눌리고 창이 닫힌다', (tester) async {
    late _Spy store;
    store = _Spy(fake: (f, t) => _fakePlan(store, f, t));
    await _pump(tester, store, const Size(1440, 900));
    await _openDialog(tester);
    expect(find.text('새 근무 12건'), findsOneWidget);
    expect(find.text('못 채운 칸 3'), findsOneWidget);
    expect(find.text('예상 인건비 2,145,600원'), findsOneWidget);
    await tester.tap(find.widgetWithText(InkWell, '근무표 만들기').last);
    await tester.pumpAndSettle();
    expect(find.text('미리보기'), findsNothing);
    expect(find.text('5월 근무 12건을 만들었어요'), findsOneWidget);
  });

  for (final size in _sizes) {
    testWidgets('창 · 헤더 넘침 없음 ${size.width.toInt()}', (tester) async {
      await tester.runAsync(_loadFonts);
      late _Spy store;
      store = _Spy(fake: (f, t) => _fakePlan(store, f, t));
      await _pump(tester, store, size);
      await _gotoSchedule(tester);
      expect(tester.takeException(), isNull, reason: '헤더 @ $size');
      await tester.tap(find.widgetWithText(InkWell, '근무표 만들기').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '창 @ $size');
      await _shot(tester, 'create_${size.width.toInt()}');
    });
  }
}
