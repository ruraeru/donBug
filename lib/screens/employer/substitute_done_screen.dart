import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';

/// 대타 승인 완료 (Figma 47:670).
class SubstituteDoneScreen extends StatelessWidget {
  const SubstituteDoneScreen({super.key});

  static const _done = [
    ('근무표 반영 완료', '하윤님 일정으로 교체'),
    ('예상 급여 재할당', '수빈 −4h · 하윤 +4h'),
    ('알림 발송', '두 분께 승인 알림 전송'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              const SuccessHero(
                title: '대타가 확정됐어요',
                subtitle: '5/14(수) 18:00–22:00 · 수빈 → 하윤',
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  children: [
                    for (var i = 0; i < _done.length; i++) ...[
                      if (i > 0) const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text('✓',
                                style: AppText.style(
                                    13, FontWeight.w700, AppColors.onPrimary)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_done[i].$1,
                                    style: AppText.style(15, FontWeight.w700)),
                                Text(_done[i].$2,
                                    style: AppText.style(12, FontWeight.w400,
                                        AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const NoteBox(
                '대타 근무는 하윤님의 주휴수당 계산에서 제외돼요.',
                color: AppColors.accent,
                background: AppColors.accentSoft,
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomBar(children: [
          AppButton(
            '대시보드로 이동',
            // 셸(대시보드 탭)까지 되돌아간다.
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ]),
      );
}
