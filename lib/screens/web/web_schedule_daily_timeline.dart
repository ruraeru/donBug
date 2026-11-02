import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_schedule_common.dart';
import 'web_common.dart';

/// W2-A 일간 타임라인 (Figma 53:3, 콘텐츠 영역 53:35).
class WebScheduleDailyTimeline extends StatelessWidget {
  const WebScheduleDailyTimeline({super.key});

  static const _hourW = 65.0;
  static const _labelW = 170.0;
  static const _firstHour = 9;
  static const _hours = 14; // 09:00–23:00

  /// 10시~21시 (필요, 현재) 인원.
  static const _need = [
    (1, 1), (1, 2), (2, 2), (2, 2), (1, 3), (1, 2),
    (1, 1), (2, 1), (2, 2), (1, 2), (1, 1), (1, 1),
  ];

  static const _rows = [
    _TimelineRow(0, '주 18h', 9, 17, 10, 16, '10:00–16:00'),
    _TimelineRow(1, '주 21h', 10, 15, 11, 15, '11:00–15:00'),
    _TimelineRow(2, '주 23h', 16, 23, 18, 22, '18:00–22:00 · 대타'),
    _TimelineRow(3, '주 19h', 17, 22, 17, 19, '+ 추천', suggested: true),
    _TimelineRow(4, '주 24h', 13, 22, 14, 20, '14:00–20:00'),
  ];

  static const _tips = [
    ('17:00–19:00 도현 추가', '도현 수요일 17–22시 가능 · 부족 구간 해소', '배정'),
    ('수빈 11:00 → 12:00 시작', '과다 배치(11시) 완화 · 가용 시간 안', '적용'),
    ('서연 14:00 → 15:00 시작', '14시 3명 → 2명 · 인건비 −₩10,030', '적용'),
  ];

  static double _x(num hour) => _labelW + (hour - _firstHour) * _hourW;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WebScheduleHeader(
            subtitle: 'A · 일간 타임라인 — 직원별 시간대와 가용 시간을 한눈에',
            action: '자동 배정 제안',
          ),
          const SizedBox(height: 16),
          const WebScheduleToolbar(
            dateLabel: '5/14 (수)',
            modes: ['일간', '주간', '월간'],
            selectedMode: 0,
            chips: [
              WebGreyChip('전체 파트'),
              WebGreyChip('직원 5명'),
              Pill('가용 시간 표시'),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _plot(),
                ),
                const SizedBox(height: 12),
                const Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    WebLegend(AppColors.primarySoft, '가용 시간'),
                    WebLegend(AppColors.border, '가용 불가'),
                    WebLegend(AppColors.textPrimary, '배정'),
                    WebLegend(AppColors.accentSoft, '대타 확정'),
                    WebLegend(AppColors.dangerSoft, '인원 부족'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('빈 시간대 추천', style: AppText.style(16, FontWeight.w700)),
                    ),
                    const Pill(
                      '17:00 1명 부족 · 11·14·15·19시 과다',
                      color: AppColors.danger,
                      background: AppColors.dangerSoft,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < _tips.length; i++) ...[
                      if (i > 0) const SizedBox(width: 14),
                      Expanded(child: _tipCard(_tips[i])),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      );

  Widget _plot() => SizedBox(
        width: _labelW + _hours * _hourW,
        height: 408,
        child: Stack(
          children: [
            for (var i = 0; i <= _hours; i++)
              Positioned(
                left: _x(_firstHour + i),
                top: 30,
                bottom: 0,
                child: Container(width: 1, color: AppColors.border),
              ),
            Column(
              children: [
                SizedBox(
                  height: 30,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: _labelW),
                      for (var h = _firstHour; h < _firstHour + _hours; h++)
                        SizedBox(
                          width: _hourW,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${h.toString().padLeft(2, '0')}:00',
                              textAlign: TextAlign.center,
                              style: AppText.style(
                                  12, FontWeight.w500, AppColors.textSecondary),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 74,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: _labelW,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('필요 / 현재 인원',
                                  style: AppText.style(13, FontWeight.w700)),
                              Text('피크 12–14 · 17–19시',
                                  style: AppText.style(
                                      11, FontWeight.w400, AppColors.textTertiary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: _hourW),
                      for (final (need, cur) in _need) _needBox(need, cur),
                    ],
                  ),
                ),
                for (var i = 0; i < _rows.length; i++) _row(_rows[i], i.isEven),
              ],
            ),
          ],
        ),
      );

  Widget _needBox(int need, int cur) {
    final (bg, fg) = cur < need
        ? (AppColors.dangerSoft, AppColors.danger)
        : cur > need
            ? (AppColors.accentSoft, AppColors.accent)
            : (AppColors.primarySoft, AppColors.primary);
    return Container(
      width: _hourW - 6,
      height: 58,
      margin: const EdgeInsets.only(top: 6, left: 3, right: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('필요 $need', style: AppText.style(10, FontWeight.w400, fg)),
          Text('$cur', style: AppText.style(20, FontWeight.w700, fg).copyWith(height: 1.2)),
        ],
      ),
    );
  }

  Widget _row(_TimelineRow r, bool striped) {
    final staff = webStaff[r.staff];
    final barLeft = _x(r.shiftStart) + 2;
    final barWidth = (r.shiftEnd - r.shiftStart) * _hourW - 4;
    return Container(
      height: 60,
      decoration: striped
          ? BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8))
          : null,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(height: 1, color: AppColors.border),
          ),
          Positioned(left: 4, top: 13, child: StaffAvatar(staff)),
          Positioned(
            left: 48,
            top: 11,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff.name, style: AppText.style(14, FontWeight.w700)),
                Text('${r.weekly} · 희망 20h',
                    style: AppText.style(11, FontWeight.w400, AppColors.textSecondary)),
              ],
            ),
          ),
          Positioned(
            left: _labelW,
            top: 8,
            width: _hours * _hourW,
            height: 44,
            child: _bar(AppColors.border),
          ),
          Positioned(
            left: _x(r.availStart),
            top: 8,
            width: (r.availEnd - r.availStart) * _hourW,
            height: 44,
            child: _bar(AppColors.primarySoft),
          ),
          Positioned(
            left: barLeft,
            top: 12,
            width: barWidth,
            height: 36,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: r.suggested ? staff.color.withValues(alpha: 0.12) : staff.color,
                borderRadius: BorderRadius.circular(10),
                // shortcut: Figma는 점선 테두리, 여기선 실선.
                border: r.suggested ? Border.all(color: staff.color, width: 2) : null,
              ),
              child: Text(
                r.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.style(12, FontWeight.w700,
                    r.suggested ? staff.color : AppColors.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(Color color) => DecoratedBox(
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      );

  Widget _tipCard((String, String, String) tip) {
    final (title, body, action) = tip;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.style(14, FontWeight.w700)),
          const SizedBox(height: 6),
          Text(body, style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
          const SizedBox(height: 6),
          WebButton(action, style: WebButtonStyle.soft),
        ],
      ),
    );
  }
}

class _TimelineRow {
  const _TimelineRow(
    this.staff,
    this.weekly,
    this.availStart,
    this.availEnd,
    this.shiftStart,
    this.shiftEnd,
    this.label, {
    this.suggested = false,
  });

  final int staff;
  final String weekly;
  final int availStart;
  final int availEnd;
  final int shiftStart;
  final int shiftEnd;
  final String label;
  final bool suggested;
}
