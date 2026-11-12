// 시연 영상 녹화 도우미 (테스트 파일 아님 — test/demo/*_test.dart 에서 import).
//
// `VIDEO_DIR=<폴더> flutter test test/demo/<이름>_test.dart --update-goldens` 로 돌리면
// 실제 화면을 탭하며 <폴더>/<이름>/NNNN.png 프레임과 frames.txt(ffmpeg concat 목록)를 쓴다.
// 평소 `flutter test` 에서는 프레임을 쓰지 않고 시연 흐름이 예외 없이 끝나는지만 본다.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mobile_shots.dart';

class Recorder {
  Recorder(this.tester, this.name);

  final WidgetTester tester;
  final String name;

  static const captionHeight = 88.0;
  static const scale = 2.0;

  final _caption = ValueNotifier<String>('');
  final _tapAt = ValueNotifier<Offset?>(null);
  final _rootKey = GlobalKey();
  final _frames = <(String, int)>[];

  bool get _on => autoUpdateGoldenFiles;
  String get dir => Directory(
          '${Platform.environment['VIDEO_DIR'] ?? 'build/demo_video'}/$name')
      .absolute
      .path;

  /// [app] 을 폰 화면(390×844) + 아래 자막 줄로 그리고 첫 프레임을 찍는다.
  Future<void> start(Widget app, {String caption = ''}) async {
    await loadShotFonts();
    tester.view.physicalSize =
        Size(phone.width * scale, (phone.height + captionHeight) * scale);
    tester.view.devicePixelRatio = scale;
    addTearDown(tester.view.reset);
    if (_on) {
      final d = Directory(dir);
      if (d.existsSync()) d.deleteSync(recursive: true);
    }
    _caption.value = caption;
    await tester.pumpWidget(_frame(app));
    await settle(tester);
    await _shot(1200);
  }

  Widget _frame(Widget app) => RepaintBoundary(
        key: _rootKey,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ColoredBox(
            color: const Color(0xFF191F28),
            child: Column(children: [
              SizedBox.fromSize(
                size: phone,
                child: Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(size: phone),
                    child: Stack(children: [
                      Positioned.fill(child: app),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ValueListenableBuilder<Offset?>(
                            valueListenable: _tapAt,
                            builder: (_, p, _) => p == null
                                ? const SizedBox.shrink()
                                : CustomPaint(painter: _TapPainter(p)),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              SizedBox(
                height: captionHeight,
                width: phone.width,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ValueListenableBuilder<String>(
                      valueListenable: _caption,
                      builder: (_, t, _) => Text(t,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: const TextStyle(
                              fontFamily: 'Noto Sans KR',
                              fontSize: 17,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFFFFFFF))),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );

  /// 자막을 바꾸고 [ms] 동안 보여 준다.
  Future<void> say(String text, {int ms = 1600}) async {
    _caption.value = text;
    await tester.pump();
    await _shot(ms);
  }

  /// 지금 화면을 [ms] 더 보여 준다.
  Future<void> hold([int ms = 1000]) async {
    await tester.pump();
    if (_frames.isEmpty) return _shot(ms);
    final (f, d) = _frames.removeLast();
    _frames.add((f, d + ms));
  }

  /// 탭 위치를 보여 준 뒤 탭하고, 화면 전환을 프레임으로 담는다.
  Future<void> tap(Finder finder, {String? caption, int ms = 1200}) async {
    final target = finder.first;
    await tester.ensureVisible(target);
    await tester.pump(const Duration(milliseconds: 100));
    if (caption != null) _caption.value = caption;
    _tapAt.value = tester.getCenter(target);
    await tester.pump();
    await _shot(caption != null ? 900 : 450);
    await tester.tap(target, warnIfMissed: false);
    _tapAt.value = null;
    await transition(ms: ms);
  }

  /// 글자를 입력하고 보여 준다.
  Future<void> enter(Finder finder, String text, {int ms = 900}) async {
    await tester.ensureVisible(finder.first);
    await tester.enterText(finder.first, text);
    await transition(ms: ms);
  }

  /// [finder] 를 [offset] 만큼 끌어 스크롤(또는 서명)하며 프레임을 담는다.
  Future<void> drag(Finder finder, Offset offset,
      {int steps = 8, int ms = 900}) async {
    final g = await tester.startGesture(tester.getCenter(finder.first));
    for (var i = 0; i < steps; i++) {
      await g.moveBy(offset / steps.toDouble());
      await tester.pump(const Duration(milliseconds: 40));
      await _shot(40);
    }
    await g.up();
    await transition(ms: ms);
  }

  /// 애니메이션 · 화면 전환을 50ms 간격으로 담고 [ms] 머문다.
  Future<void> transition({int ms = 1200}) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await _shot(50);
    }
    await settle(tester);
    await _shot(ms);
  }

  Future<void> _shot(int ms) async {
    expect(tester.takeException(), isNull, reason: '$name 프레임 ${_frames.length}');
    if (!_on) return;
    final f = '${_frames.length.toString().padLeft(4, '0')}.png';
    final ro = _rootKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final img = await ro.toImage(pixelRatio: scale);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      return data!.buffer.asUint8List();
    });
    File('$dir/$f')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!);
    _frames.add((f, ms));
  }

  /// frames.txt(ffmpeg concat 목록)를 쓴다. 테스트 끝에 부른다.
  Future<void> finish({int tailMs = 1500}) async {
    await hold(tailMs);
    if (!_on || _frames.isEmpty) return;
    final b = StringBuffer();
    for (final (f, ms) in _frames) {
      b.writeln("file '$f'");
      b.writeln('duration ${(ms / 1000).toStringAsFixed(3)}');
    }
    b.writeln("file '${_frames.last.$1}'");
    File('$dir/frames.txt').writeAsStringSync(b.toString());
  }
}

class _TapPainter extends CustomPainter {
  _TapPainter(this.p);
  final Offset p;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(p, 22, Paint()..color = const Color(0x33191F28));
    canvas.drawCircle(
        p,
        22,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0x99191F28));
  }

  @override
  bool shouldRepaint(_TapPainter old) => old.p != p;
}
