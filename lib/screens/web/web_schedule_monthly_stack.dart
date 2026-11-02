import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_schedule_common.dart';

/// W2-D 월간 4주 스택 (Figma 57:308).
class WebScheduleMonthlyStack extends StatelessWidget {
  const WebScheduleMonthlyStack({super.key});

  static const _weeks = [
    (
      '1주차 · 5/5 – 5/11',
      [5, 6, 7, 8, 9, 10, 11],
      [
        ['X1', 'C', '10:30', '11:00', 'O', 'O', 'C'],
        ['O', 'X1', '11:30', 'C', '09:00', 'C', '10:30'],
        ['C', '11:00', 'X1', 'O', '10:30', '10:30', '11:30'],
        ['11:00', '09:00', 'O', 'X1', 'C', '11:30', 'X2'],
        ['09:00', 'O', 'C', '11:00', 'X1', '10:00', 'O'],
      ],
    ),
    ('2주차 · 5/12 – 5/18', [12, 13, 14, 15, 16, 17, 18], webWeekCodes),
    (
      '3주차 · 5/19 – 5/25',
      [19, 20, 21, 22, 23, 24, 25],
      [
        ['10:30', 'X4', '11:30', 'O', 'C', '10:30', '11:00'],
        ['11:30', '11:30', 'X3', 'C', '10:30', 'O', '09:00'],
        ['O', 'O', 'C', 'X3', '11:30', '09:00', 'X4'],
        ['C', 'C', 'O', '11:00', 'X4', '10:30', 'O'],
        ['X3', '11:00', '11:30', '09:00', 'O', 'C', 'C'],
      ],
    ),
    (
      '4주차 · 5/26 – 6/1',
      [26, 27, 28, 29, 30, 31, 1],
      [
        ['11:00', 'C', 'O', 'O', 'X5', '11:00', '11:30'],
        ['X4', 'O', 'C', '10:30', '11:00', '09:00', 'O'],
        ['O', 'X5', '10:30', 'C', '09:00', 'O', 'C'],
        ['C', '10:30', 'X5', '09:00', 'C', '11:00', '11:00'],
        ['11:00', '11:30', '09:00', 'X4', 'O', 'C', 'X5'],
      ],
    ),
  ];

  static const _distLabels = ['오픈', '마감', '가변 시간', '휴무'];
  static const _distColors = [
    AppColors.primary,
    WebColors.blue,
    AppColors.textSecondary,
    AppColors.textTertiary,
  ];

  /// 직원별 (오픈, 마감, 가변, 휴무) 횟수.
  static const _dist = [
    [6, 5, 12, 5],
    [6, 5, 13, 4],
    [6, 6, 11, 5],
    [5, 6, 12, 5],
    [5, 6, 12, 5],
  ];
  static const _distMax = 13;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WebScheduleHeader(
            subtitle: 'D · 월간 — 4주를 겹쳐 보고 휴무 누적과 오픈·마감 분배를 점검',
            action: '월간 PDF',
          ),
          const SizedBox(height: 16),
          const WebScheduleToolbar(
            dateLabel: '2026년 5월',
            modes: ['주간', '월간'],
            selectedMode: 1,
            chips: [
              WebGreyChip('휴무 칸의 숫자 = 월 누적 휴무'),
              WebGreyChip('직원 5명 · 고정 파트 3명'),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                for (var r = 0; r < 2; r++) ...[
                  if (r > 0) const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _week(_weeks[r * 2])),
                      const SizedBox(width: 20),
                      Expanded(child: _week(_weeks[r * 2 + 1])),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('직원별 5월 근무 분배',
                          style: AppText.style(16, FontWeight.w700)),
                    ),
                    const Pill('휴무 편차 1회 · 오픈 편차 1회 · 마감 편차 1회'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 150),
                    for (final l in _distLabels)
                      Expanded(
                        child: Text(l,
                            style: AppText.style(
                                11, FontWeight.w400, AppColors.textSecondary)),
                      ),
                  ],
                ),
                for (var i = 0; i < webStaff.length; i++) _distRow(i),
              ],
            ),
          ),
        ],
      );

  Widget _week((String, List<int>, List<List<String>>) week) {
    final (title, dates, codes) = week;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.style(13, FontWeight.w700)),
        const SizedBox(height: 4),
        Row(
          children: [
            const SizedBox(width: 56),
            for (var d = 0; d < 7; d++) Expanded(child: _dayHeader(d, dates[d])),
          ],
        ),
        for (var i = 0; i < webStaff.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text(webStaff[i].name,
                      style: AppText.style(11, FontWeight.w700)),
                ),
                for (final c in codes[i])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: WebShiftCell(
                        c,
                        height: 20,
                        compact: true,
                        fontSize: 11,
                        radius: 6,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _dayHeader(int d, int date) {
    final weekend = webWeekendColors(d);
    return Container(
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: weekend?.$1 ?? AppColors.bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('${webWeekdays[d]} $date',
          style: AppText.style(10, FontWeight.w500, weekend?.$2 ?? AppColors.textSecondary)),
    );
  }

  Widget _distRow(int i) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            SizedBox(
              width: 150,
              child: Row(
                children: [
                  WebAvatar(webStaff[i], size: 20),
                  const SizedBox(width: 8),
                  Text(webStaff[i].name, style: AppText.style(13, FontWeight.w700)),
                ],
              ),
            ),
            for (var k = 0; k < _distLabels.length; k++)
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: LinearProgressIndicator(
                          value: _dist[i][k] / _distMax,
                          minHeight: 8,
                          color: _distColors[k],
                          backgroundColor: AppColors.bg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 48,
                      child: Text('${_dist[i][k]}회',
                          style: AppText.style(13, FontWeight.w700)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}
