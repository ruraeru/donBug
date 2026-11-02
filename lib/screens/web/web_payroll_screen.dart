import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_common.dart';

/// W4 인건비·급여 정산 (콘텐츠 영역).
class WebPayrollScreen extends StatelessWidget {
  const WebPayrollScreen({super.key});

  // (이름, 아바타색, 배경, 근무시간, 기본급, 주휴, 가산, 공제, 실수령)
  static const _rows = [
    ('지민', AppColors.primary, AppColors.primarySoft, '74h', '742,220', '120,360', '45,000', '−31,600', '968,300'),
    ('수빈', AppColors.accent, AppColors.accentSoft, '88h', '882,640', '150,540', '125,520', '−38,300', '1,120,400'),
    ('하윤', WebColors.info, WebColors.infoSoft, '62h', '621,860', '120,360', '128,780', '−28,743', '842,257'),
    ('도현', WebColors.danger, WebColors.dangerSoft, '78h', '782,340', '150,540', '95,000', '−41,180', '986,700'),
    ('서연', AppColors.primary, AppColors.primarySoft, '70h', '735,000', '120,360', '62,000', '−23,017', '894,343'),
  ];

  // 월별 막대 높이(Figma px). 마지막(이번 달)만 진한 색.
  static const _trend = [('12월', 160.0), ('1월', 172.0), ('2월', 150.0), ('3월', 180.0), ('4월', 195.0), ('5월', 188.0)];

  @override
  Widget build(BuildContext context) => WebPage(
        title: '인건비 · 급여 정산',
        subtitle: '2026년 5월 · 근태 기록 기준 자동 계산',
        actions: const [
          WebButton('PDF 내보내기', style: WebButtonStyle.outline),
          WebButton('정산 확정'),
        ],
        children: [
          const WebRow(children: [
            _Stat('이번 달 예상 인건비', '₩4,812,000', primary: true),
            _Stat('지급 대상', '5명'),
            _Stat('전월 대비', '−3%', valueColor: WebColors.danger),
          ]),
          WebSplit(
            rightWidth: 300,
            gap: 20,
            left: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('직원별 정산', style: AppText.style(16, FontWeight.w700)),
                  const SizedBox(height: 14),
                  WebTable(
                    columns: const ['직원', '근무시간', '기본급', '주휴', '가산', '공제', '실수령'],
                    flex: const [130, 100, 120, 100, 100, 100, 120],
                    rows: [
                      for (final r in _rows)
                        [
                          webNameCell(r.$1, r.$2, r.$3),
                          webCellText(r.$4),
                          webCellText(r.$5),
                          webCellText(r.$6),
                          webCellText(r.$7),
                          webCellText(r.$8),
                          webCellText(r.$9),
                        ],
                    ],
                  ),
                ],
              ),
            ),
            right: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('월별 인건비 추이', style: AppText.style(16, FontWeight.w700)),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 240,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < _trend.length; i++)
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: _trend[i].$2,
                                  decoration: BoxDecoration(
                                    color: i == _trend.length - 1
                                        ? AppColors.primary
                                        : AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(_trend[i].$1,
                                    style: AppText.style(
                                        11, FontWeight.w400, AppColors.textSecondary)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.primary = false, this.valueColor});

  final String label, value;
  final bool primary;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => AppCard(
        color: primary ? AppColors.primary : AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppText.style(13, FontWeight.w400,
                    primary ? AppColors.onPrimary : AppColors.textSecondary)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: AppText.style(
                      30,
                      FontWeight.w700,
                      valueColor ??
                          (primary ? AppColors.onPrimary : AppColors.textPrimary))),
            ),
          ],
        ),
      );
}
