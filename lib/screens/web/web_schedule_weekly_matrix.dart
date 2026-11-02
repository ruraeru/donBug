import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_schedule_common.dart';

/// W2-C 주간 매트릭스: 직원 × 요일 · 오픈/마감/휴무 (Figma 57:2).
class WebScheduleWeeklyMatrix extends StatelessWidget {
  const WebScheduleWeeklyMatrix({super.key});

  static const _nameW = 195.0;
  static const _cellW = 108.0;
  static const _gap = 6.0;
  static const _today = 2;
  static const _monthlyOff = [3, 2, 2, 3, 2];

  /// 고정 파트 행: (라벨, 라벨색, 칸배경, 칸글자색, 요일별 시간).
  static const _fixedRows = [
    ('사장님', ScheduleColors.purple, ScheduleColors.purpleSoft, ScheduleColors.purple,
        [null, null, null, null, null, '9:00', '8:00']),
    ('평일 마감 · 민준', AppColors.textSecondary, AppColors.bg, AppColors.textSecondary,
        ['16:00~21:00', '16:00~21:00', '16:00~21:00', '16:00~21:00', '15:30~21:00', null, null]),
    ('주말 오전 · 유진', AppColors.textSecondary, AppColors.bg, AppColors.textSecondary,
        [null, null, null, null, null, '7:30~15:30', '9:30~16:00']),
    ('주말 마감 · 예린', AppColors.textSecondary, AppColors.bg, AppColors.textSecondary,
        [null, null, null, null, null, '15:30~21:00', '16:00~21:00']),
    ('특이사항 (시간 변동)', AppColors.accent, AppColors.accentSoft, AppColors.accent,
        [null, null, null, null, null, '6:30~15:30', null]),
  ];

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WebScheduleHeader(
            subtitle: 'C · 주간 매트릭스 — 오픈·마감·시작 시간·휴무를 한 장에',
            action: '엑셀 가져오기',
          ),
          const SizedBox(height: 16),
          const WebScheduleToolbar(
            dateLabel: '5/12 – 5/18',
            modes: ['주간', '월간'],
            selectedMode: 0,
            chips: [
              WebGreyChip('휴무 칸의 숫자 = 월 누적 휴무'),
              WebGreyChip('직원 5명 · 고정 파트 3명'),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _nameW + 7 * (_cellW + _gap),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const SizedBox(width: _nameW),
                          for (var d = 0; d < 7; d++) _dayHeader(d),
                        ]),
                        for (var i = 0; i < webStaff.length; i++) _staffRow(i),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: AppColors.border),
                        ),
                        for (final r in _fixedRows) _fixedRow(r),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    WebLegend(AppColors.primarySoft, '오픈'),
                    WebLegend(ScheduleColors.blueSoft, '마감'),
                    WebLegend(AppColors.surface, '가변 시작 시간', borderColor: AppColors.border),
                    WebLegend(AppColors.border, '휴무 (N = 월 누적)'),
                    WebLegend(AppColors.accentSoft, '대타'),
                    WebLegend(AppColors.dangerSoft, '휴무 신청'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < webStaff.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: _offCard(i)),
              ],
            ],
          ),
        ],
      );

  Widget _dayHeader(int d) {
    final weekend = webWeekendColors(d);
    final today = d == _today;
    return Container(
      width: _cellW,
      height: 52,
      margin: const EdgeInsets.only(right: _gap, bottom: _gap),
      decoration: BoxDecoration(
        color: weekend?.$1 ?? AppColors.surface,
        border: weekend == null ? Border.all(color: AppColors.border) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(webWeekdays[d],
              style: AppText.style(14, FontWeight.w700, weekend?.$2 ?? AppColors.textPrimary)),
          Text(today ? '${12 + d} · 오늘' : '${12 + d}',
              style: AppText.style(
                12,
                today ? FontWeight.w700 : FontWeight.w400,
                today ? AppColors.primary : weekend?.$2 ?? AppColors.textSecondary,
              )),
        ],
      ),
    );
  }

  Widget _staffRow(int i) {
    final codes = webWeekCodes[i];
    final open = codes.where((c) => c == 'O').length;
    final close = codes.where((c) => c == 'C').length;
    final off = codes.where((c) => c.startsWith('X')).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: _gap),
      child: Row(
        children: [
          SizedBox(
            width: _nameW,
            child: Row(
              children: [
                StaffAvatar(webStaff[i], size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(webStaff[i].name, style: AppText.style(14, FontWeight.w700)),
                      Text('오픈 $open · 마감 $close · 휴무 $off',
                          style: AppText.style(11, FontWeight.w400, AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final c in codes)
            Padding(
              padding: const EdgeInsets.only(right: _gap),
              child: WebShiftCell(c, width: _cellW),
            ),
        ],
      ),
    );
  }

  Widget _fixedRow((String, Color, Color, Color, List<String?>) r) {
    final (label, labelColor, bg, fg, times) = r;
    return Padding(
      padding: const EdgeInsets.only(bottom: _gap),
      child: Row(
        children: [
          SizedBox(
            width: _nameW,
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(label, style: AppText.style(12, FontWeight.w700, labelColor)),
            ),
          ),
          for (final t in times)
            Container(
              width: _cellW,
              height: 30,
              margin: const EdgeInsets.only(right: _gap),
              alignment: Alignment.center,
              decoration: t == null
                  ? null
                  : BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
              child: t == null
                  ? null
                  : Text(t, style: AppText.style(12, FontWeight.w700, fg)),
            ),
        ],
      ),
    );
  }

  Widget _offCard(int i) {
    final staff = webStaff[i];
    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StaffAvatar(staff, size: 28, solid: true),
              const SizedBox(width: 8),
              Text(staff.name, style: AppText.style(15, FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text('5/18까지 누적 휴무 ${_monthlyOff[i]}회',
              style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _monthlyOff[i] / 7.5,
            minHeight: 4,
            color: staff.color,
            backgroundColor: AppColors.bg,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }
}
