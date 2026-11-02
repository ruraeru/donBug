import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_payroll_detail_screen.dart';
import 'payroll_docs_widgets.dart';

/// B5 인건비 대시보드 (Figma 48:3). 탭 루트.
class EmployerLaborCostScreen extends StatelessWidget {
  const EmployerLaborCostScreen({super.key});

  static const _bars = [
    ('12월', '4.4M', 70.0),
    ('1월', '4.6M', 74.0),
    ('2월', '4.2M', 67.0),
    ('3월', '4.9M', 78.0),
    ('4월', '5.0M', 79.0),
    ('5월', '4.8M', 77.0),
  ];

  static const _workers = [
    ('지', '지민', '62시간 · 3.3%', '₩ 842,257', AppColors.primary, AppColors.primarySoft),
    ('수', '수빈', '80시간 · 4대보험', '₩ 1,120,400', AppColors.accent, AppColors.accentSoft),
    ('하', '하윤', '69시간 · 4대보험', '₩ 968,300', kInfo, kInfoSoft),
  ];

  @override
  Widget build(BuildContext context) {
    void openDetail() => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmployerPayrollDetailScreen()),
        );

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                    child: Text('인건비', style: AppText.style(24, FontWeight.w700))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('2026년 5월', style: AppText.style(13, FontWeight.w700)),
                      const SizedBox(width: 4),
                      Text('▾',
                          style: AppText.style(
                              11, FontWeight.w400, AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                _totalCard(),
                const SizedBox(height: 14),
                _chartCard(),
                const SizedBox(height: 14),
                AppCard(
                  onTap: openDetail,
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text('근로자별 지급 예정',
                                  style: AppText.style(15, FontWeight.w700)),
                            ),
                            Text('전체 5명 ›',
                                style: AppText.style(
                                    12, FontWeight.w500, AppColors.primary)),
                          ],
                        ),
                      ),
                      for (final w in _workers)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              InitialAvatar(w.$1, color: w.$5, background: w.$6),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(w.$2,
                                        style: AppText.style(14, FontWeight.w700)),
                                    Text(w.$3,
                                        style: AppText.style(12, FontWeight.w400,
                                            AppColors.textTertiary)),
                                  ],
                                ),
                              ),
                              Text(w.$4, style: AppText.style(15, FontWeight.w700)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalCard() => AppCard(
        color: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이번 달 예상 인건비',
                style: AppText.style(13, FontWeight.w500, AppColors.onPrimary)),
            const SizedBox(height: 6),
            Text('₩ 4,812,000',
                style: AppText.style(30, FontWeight.w700, AppColors.onPrimary)),
            const SizedBox(height: 6),
            Text('주휴수당·4대보험·세금 자동 반영 · 지난달 대비 -3%',
                style: AppText.style(12, FontWeight.w400, AppColors.onPrimary)),
          ],
        ),
      );

  Widget _chartCard() => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child:
                      Text('인건비 지출 추이', style: AppText.style(15, FontWeight.w700)),
                ),
                Text('최근 6개월',
                    style:
                        AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < _bars.length; i++)
                    _bar(_bars[i], current: i == _bars.length - 1),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _bar((String, String, double) b, {required bool current}) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(b.$2,
              style: AppText.style(
                  10,
                  current ? FontWeight.w700 : FontWeight.w500,
                  current ? AppColors.primary : AppColors.textTertiary)),
          const SizedBox(height: 6),
          Container(
            width: 30,
            height: b.$3,
            decoration: BoxDecoration(
              color: current ? AppColors.primary : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 6),
          Text(b.$1,
              style: AppText.style(
                  11,
                  current ? FontWeight.w700 : FontWeight.w500,
                  current ? AppColors.textPrimary : AppColors.textTertiary)),
        ],
      );
}
