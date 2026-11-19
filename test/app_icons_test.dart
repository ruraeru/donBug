// 앱·웹 아이콘 PNG 를 assets/images/app_icon.svg 에서 만든다.
// 다시 만들기: GEN_ICONS=1 ./flutter/bin/flutter test test/app_icons_test.dart (평소 test 는 크기·불투명만 확인)
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// 경로 → (한 변 픽셀, 꽉 채움(불투명) 여부, 로고 배율).
/// 꽉 채움 = iOS(OS 가 모서리를 깎는다)·maskable(가운데 80% 안전 영역에 들어가게 0.8배).
Map<String, (int, bool, double)> _targets() {
  const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  final images = (jsonDecode(File('$ios/Contents.json').readAsStringSync())
      as Map)['images'] as List;
  return {
    for (final (dir, px) in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)])
      'android/app/src/main/res/mipmap-$dir/ic_launcher.png': (px, false, 1.0),
    for (final i in images.cast<Map>())
      '$ios/${i['filename']}': (
        (double.parse((i['size'] as String).split('x').first) *
                int.parse((i['scale'] as String).replaceAll('x', '')))
            .round(),
        true,
        1.0,
      ),
    'web/favicon.png': (16, false, 1.0),
    'web/icons/Icon-192.png': (192, false, 1.0),
    'web/icons/Icon-512.png': (512, false, 1.0),
    'web/icons/Icon-maskable-192.png': (192, true, 0.8),
    'web/icons/Icon-maskable-512.png': (512, true, 0.8),
  };
}

/// SVG 의 둥근 사각형 배경색(AppColors.primary).
const _bg = Color(0xFF1F8A5B);

/// 알파 채널 없는 RGB PNG. App Store 는 1024 아이콘에 알파 채널만 있어도 거부한다.
List<int> _rgbPng(ByteData rgba, int px) {
  final raw = <int>[];
  for (var y = 0; y < px; y++) {
    raw.add(0); // 필터 없음
    for (var x = 0; x < px; x++) {
      final i = (y * px + x) * 4;
      raw.addAll([rgba.getUint8(i), rgba.getUint8(i + 1), rgba.getUint8(i + 2)]);
    }
  }
  List<int> chunk(String type, List<int> data) {
    final body = [...ascii.encode(type), ...data];
    var c = 0xFFFFFFFF;
    for (final b in body) {
      c ^= b;
      for (var k = 0; k < 8; k++) {
        c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
      }
    }
    return [..._u32(data.length), ...body, ..._u32(c ^ 0xFFFFFFFF)];
  }

  return [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    ...chunk('IHDR', [..._u32(px), ..._u32(px), 8, 2, 0, 0, 0]), // 8비트 RGB
    ...chunk('IDAT', zlib.encode(raw)),
    ...chunk('IEND', []),
  ];
}

List<int> _u32(int v) => [v >> 24 & 0xFF, v >> 16 & 0xFF, v >> 8 & 0xFF, v & 0xFF];

void main() {
  test('앱 아이콘 PNG (GEN_ICONS=1 이면 다시 만든다)', () async {
    final targets = _targets();
    if (Platform.environment['GEN_ICONS'] == '1') {
      final svg = File('assets/images/app_icon.svg').readAsStringSync();
      final info = await vg.loadPicture(SvgStringLoader(svg), null);
      for (final MapEntry(key: path, value: (px, fill, scale)) in targets.entries) {
        final rec = ui.PictureRecorder();
        final canvas = Canvas(rec);
        final s = px / info.size.width;
        if (fill) canvas.drawRect(Rect.fromLTWH(0, 0, px.toDouble(), px.toDouble()), Paint()..color = _bg);
        canvas
          ..translate(px * (1 - scale) / 2, px * (1 - scale) / 2)
          ..scale(s * scale)
          ..drawPicture(info.picture);
        final img = await rec.endRecording().toImage(px, px);
        final bytes = fill
            ? _rgbPng((await img.toByteData(format: ui.ImageByteFormat.rawRgba))!, px)
            : (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
        File(path).writeAsBytesSync(bytes);
      }
    }
    for (final MapEntry(key: path, value: (px, fill, _)) in targets.entries) {
      final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
      final img = (await codec.getNextFrame()).image;
      expect((img.width, img.height), (px, px), reason: path);
      final rgba = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      // 가운데 픽셀은 배경색(초록)이어야 한다 = 기본 Flutter 아이콘이 아님.
      final c = (px ~/ 2 * px + px ~/ 10) * 4;
      expect([rgba.getUint8(c), rgba.getUint8(c + 1), rgba.getUint8(c + 2)], [0x1F, 0x8A, 0x5B], reason: path);
      if (fill) {
        for (var i = 3; i < rgba.lengthInBytes; i += 4) {
          if (rgba.getUint8(i) != 255) fail('$path 투명 픽셀 ${i ~/ 4}');
        }
      }
    }
  });
}
