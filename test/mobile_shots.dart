// 모바일 화면 스크린샷 도우미 (테스트 파일 아님 — *_test.dart 에서 import).
//
// `flutter test test/mobile_shots_<이름>_test.dart --update-goldens` 로 돌리면
// 실제 폰트로 PNG 를 SHOTS_DIR(기본: build/mobile_shots)에 쓴다. 눈으로 확인하는 용도이며 PNG 는 커밋하지 않는다.
// 평소 `flutter test` 에서는 화면이 예외 없이 그려지는지만 본다.
import 'dart:io';

import 'package:donbug/data/app_scope.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 고정 시각 2026-05-14(목) 14:30 — widget_test.dart 와 같다.
final shotNow = DateTime(2026, 5, 14, 14, 30);

const phone = Size(390, 844);

AppStore shotStore({Role role = Role.employee}) =>
    AppStore.seeded(now: shotNow)..switchRole(role);

Future<void> loadShotFonts() async {
  final loader = FontLoader('Noto Sans KR');
  for (final w in ['Regular', 'Medium', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/NotoSansKR-$w.otf'));
  }
  await loader.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

/// [home] 을 폰 크기로 그린다. 근무 중 카드의 1초 타이머 때문에 pumpAndSettle 대신 pump.
/// [tall] 이면 세로를 늘려 스크롤 아래까지 한 장에 담는다.
Future<AppStore> pumpShot(WidgetTester tester, Widget home,
    {AppStore? store, double height = 844}) async {
  final s = store ?? shotStore();
  tester.view.physicalSize = Size(phone.width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AppScope(
      store: s,
      child: MaterialApp(debugShowCheckedModeBanner: false, theme: appTheme, home: home)));
  await settle(tester);
  return s;
}

/// 애니메이션 · 화면 전환이 끝날 만큼 시간을 흘린다.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> shot(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull, reason: name);
  if (!autoUpdateGoldenFiles) return;
  final dir = Platform.environment['SHOTS_DIR'] ?? 'build/mobile_shots';
  await expectLater(find.byType(MaterialApp),
      matchesGoldenFile(Uri.file('${Directory(dir).absolute.path}/$name.png')));
}
