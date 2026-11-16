import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import 'web_common.dart';
import 'web_settings_screen.dart' show toneColor;

/// 하루 06~24시 타임라인 (레퍼런스 components/TodayStrip.tsx).
/// 파트별 줄 + '직원'(파트에 없는 유동 근무) 줄에 사람마다 막대, [nowMin] 이 있으면 지금 시각 세로선.
class TodayStrip extends StatelessWidget {
  const TodayStrip({super.key, required this.shifts, this.nowMin});

  final List<Shift> shifts;
  final int? nowMin;

  static const _from = 6 * 60, _to = 24 * 60, _label = 72.0, _row = 30.0, _minWidth = 640.0;
  static const _ticks = [6, 9, 12, 15, 18, 21, 24];

  static double _x(int m, double w) => (m.clamp(_from, _to) - _from) / (_to - _from) * w;

  /// '10–16', 정각이 아니면 '14:30'.
  static String _t(int m) => m % 60 == 0 ? (m ~/ 60).toString().padLeft(2, '0') : hm(m);

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final parts = [...store.store.parts]..sort((a, b) => a.startMin.compareTo(b.startMin));
    final names = {for (final p in parts) p.name};
    final lanes = <(String, Color, List<Shift>)>[
      for (final p in parts) (p.name, toneColor(p.tone), shifts.where((s) => s.part == p.name).toList()),
      ('직원', AppColors.textSecondary, shifts.where((s) => !names.contains(s.part)).toList()),
    ].where((l) => l.$3.isNotEmpty).toList();
    if (lanes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text('이 날은 근무가 없어요',
            style: AppText.style(14, FontWeight.w400, AppColors.textTertiary)),
      );
    }
    return LayoutBuilder(builder: (context, c) {
      final width = c.maxWidth < _minWidth ? _minWidth : c.maxWidth;
      final w = width - _label - 12;
      Widget lane((String, Color, List<Shift>) l) {
        final items = [...l.$3]..sort((a, b) => a.startMin.compareTo(b.startMin));
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: _label,
              child: Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text(l.$1, style: AppText.style(12, FontWeight.w500, AppColors.textSecondary)),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: w,
              height: items.length * (_row + 4) - 4,
              child: Stack(children: [
                for (final h in _ticks)
                  Positioned(left: _x(h * 60, w), top: 0, bottom: 0, child: Container(width: 1, color: AppColors.border)),
                for (var i = 0; i < items.length; i++) _bar(store.nameOf(items[i].staffId), items[i], l.$2, w, i),
              ]),
            ),
          ]),
        );
      }

      final strip = SizedBox(
        width: width,
        child: Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(left: _label + 12),
              child: SizedBox(
                width: w,
                height: 18,
                child: Stack(children: [
                  for (final h in _ticks)
                    // 지금 시각 라벨과 겹치는 눈금 숫자는 숨긴다.
                    if (nowMin == null || (h * 60 - nowMin!).abs() > 50)
                    Positioned(
                      left: (_x(h * 60, w) - (h == 6 ? 0 : h == 24 ? 16 : 8)).clamp(0, w - 16),
                      child: Text(h.toString().padLeft(2, '0'),
                          style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
                    ),
                ]),
              ),
            ),
            for (final l in lanes) lane(l),
          ]),
          if (nowMin != null && nowMin! >= _from && nowMin! <= _to)
            Positioned(
              left: _label + 12 + _x(nowMin!, w),
              top: 0,
              bottom: 0,
              width: 1.5,
              child: IgnorePointer(
                child: Stack(clipBehavior: Clip.none, children: [
                  Positioned(left: 0, top: 18, bottom: 0, child: Container(width: 1.5, color: AppColors.textPrimary)),
                  Positioned(
                    left: -18,
                    top: 0,
                    child: Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Text(hm(nowMin!), style: AppText.style(12, FontWeight.w500)),
                    ),
                  ),
                ]),
              ),
            ),
        ]),
      );
      return c.maxWidth < _minWidth
          ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: strip)
          : strip;
    });
  }

  Widget _bar(String name, Shift s, Color tone, double w, int row) {
    final left = _x(s.startMin, w);
    final right = _x(s.endMin, w);
    final label = Row(mainAxisSize: MainAxisSize.min, children: [
      Text(name, style: AppText.style(12, FontWeight.w500, tone)),
      const SizedBox(width: 6),
      Text(s.timeTbd ? '시간 미정' : '${_t(s.startMin)}–${_t(s.endMin)}',
          style: AppText.style(12, FontWeight.w400, tone)),
    ]);
    final box = Container(
      height: _row,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: s.timeTbd ? AppColors.surface : tone.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: label),
    );
    return Positioned(
      left: left,
      width: (right - left).clamp(24, w - left),
      top: row * (_row + 4),
      child: Tooltip(
        message: '$name ${hm(s.startMin)}–${hm(s.endMin)}',
        child: s.timeTbd
            ? CustomPaint(foregroundPainter: DashedBorderPainter(color: tone, radius: 6), child: box)
            : box,
      ),
    );
  }
}
