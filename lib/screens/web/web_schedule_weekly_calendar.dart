import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_schedule_common.dart';

/// W2-B 주간 캘린더: 시간대 × 요일 (Figma 53:221).
class WebScheduleWeeklyCalendar extends StatelessWidget {
  const WebScheduleWeeklyCalendar({super.key});

  static const _timeW = 58.0;
  static const _dayW = 146.0;
  static const _hourH = 46.0;
  static const _firstHour = 10;
  static const _lastHour = 22;
  static const _peaks = [(12, 14), (17, 19)];
  static const _today = 2;
  static const _shortHours = [6, 5, 1, 5, 2, 3, 8];
  static const _weeklyHours = [18, 21, 23, 19, 24];

  /// 요일별 근무 블록 (직원, 시작, 끝, 레인, 레인 수).
  static const _blocks = [
    [_Block(0, 10, 16, 0, 2), _Block(4, 14, 20, 1, 2)],
    [_Block(1, 10, 15, 0, 1), _Block(2, 16, 22, 0, 1)],
    [
      _Block(0, 10, 16, 0, 3),
      _Block(1, 11, 15, 1, 3),
      _Block(4, 14, 20, 2, 3),
      _Block(2, 18, 22, 0, 3, '하윤 · 대타'),
    ],
    [_Block(1, 12, 18, 0, 2), _Block(3, 17, 22, 1, 2)],
    [_Block(1, 10, 16, 0, 2), _Block(0, 11, 17, 1, 2), _Block(2, 17, 22, 0, 2)],
    [_Block(3, 10, 18, 0, 3), _Block(4, 12, 18, 1, 3), _Block(2, 14, 22, 2, 3)],
    [_Block(3, 10, 16, 0, 2), _Block(4, 14, 20, 1, 2)],
  ];

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WebScheduleHeader(
            subtitle: 'B · 주간 캘린더 — 시간축으로 겹침과 빈 시간을 확인',
            action: '템플릿 복사',
          ),
          const SizedBox(height: 16),
          const WebScheduleToolbar(
            dateLabel: '5/12 – 5/18',
            modes: ['일간', '주간', '월간'],
            selectedMode: 1,
            chips: [
              WebGreyChip('전체 파트'),
              WebGreyChip('직원 5명'),
              Pill('가용 시간 표시'),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: _timeW),
                          for (var d = 0; d < 7; d++) _dayHeader(d),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _timeColumn(),
                          for (var d = 0; d < 7; d++) _dayColumn(_blocks[d]),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < webStaff.length; i++)
                      WebLegend(webStaff[i].color,
                          '${webStaff[i].name} 주 ${_weeklyHours[i]}h'),
                    const WebLegend(AppColors.accentSoft, '피크 시간'),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

  Widget _dayHeader(int d) {
    final today = d == _today;
    return Container(
      width: _dayW - 4,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: today ? AppColors.primary : AppColors.surface,
        border: today ? null : Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${webWeekdays[d]} ${12 + d}',
              style: AppText.style(14, FontWeight.w700,
                  today ? AppColors.onPrimary : AppColors.textPrimary)),
          Text('부족 ${_shortHours[d]}h',
              style: AppText.style(11, FontWeight.w700,
                  today ? AppColors.onPrimary : AppColors.danger)),
        ],
      ),
    );
  }

  Widget _timeColumn() => Column(
        children: [
          for (var h = _firstHour; h < _lastHour; h++)
            SizedBox(
              width: _timeW,
              height: _hourH,
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, left: 10),
                  child: Text('${h.toString().padLeft(2, '0')}:00',
                      style: AppText.style(11, FontWeight.w400, AppColors.textTertiary)),
                ),
              ),
            ),
        ],
      );

  Widget _dayColumn(List<_Block> blocks) => SizedBox(
        width: _dayW,
        height: (_lastHour - _firstHour) * _hourH,
        child: Stack(
          children: [
            for (final (from, to) in _peaks)
              Positioned(
                left: 0,
                right: 0,
                top: (from - _firstHour) * _hourH,
                height: (to - from) * _hourH,
                child: const ColoredBox(color: AppColors.accentSoft),
              ),
            for (var h = 0; h <= _lastHour - _firstHour; h++)
              Positioned(
                left: 0,
                right: 0,
                top: h * _hourH,
                child: Container(height: 1, color: AppColors.border),
              ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 1, color: AppColors.border),
            ),
            for (final b in blocks) _block(b),
          ],
        ),
      );

  Widget _block(_Block b) {
    final staff = webStaff[b.staff];
    final laneW = (_dayW - 4) / b.lanes;
    return Positioned(
      left: 4 + b.lane * laneW,
      top: (b.start - _firstHour) * _hourH + 2,
      width: laneW - 4,
      height: (b.end - b.start) * _hourH - 4,
      child: Container(
        padding: const EdgeInsets.all(6),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(color: staff.color, borderRadius: BorderRadius.circular(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(b.label ?? staff.name,
                style: AppText.style(12, FontWeight.w700, AppColors.onPrimary)),
            Text('${b.start}–${b.end}시',
                style: AppText.style(
                    11, FontWeight.w400, AppColors.onPrimary.withValues(alpha: 0.9))),
          ],
        ),
      ),
    );
  }
}

class _Block {
  const _Block(this.staff, this.start, this.end, this.lane, this.lanes, [this.label]);

  final int staff;
  final int start;
  final int end;
  final int lane;
  final int lanes;
  final String? label;
}
