import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'substitute_done_screen.dart';
import 'employee_parts.dart';

/// 동료 대타 상세 ("대타 구해요").
class SubstituteDetailScreen extends StatelessWidget {
  const SubstituteDetailScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('대타 구해요'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            const ShiftHeroCard(
              date: '5/14(수)',
              chip: '대타 구해요',
              time: '18:00 – 22:00',
              caption: '4시간 · 홀 서빙',
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Row(
                children: [
                  const LetterAvatar('수',
                      color: AppColors.accent, background: AppColors.accentSoft),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('수빈님의 요청', style: AppText.style(15, FontWeight.w700)),
                        const SizedBox(height: 1),
                        Text('사유: 병원 진료 · 방금 전',
                            style: AppText.style(
                                12, FontWeight.w400, AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('내 상황 확인',
                      style: AppText.style(14, FontWeight.w700, AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  const KeyValueRow('이 시간 내 근무', '없음'),
                  const SizedBox(height: 12),
                  const KeyValueRow('예상 수입', '₩40,120'),
                  const SizedBox(height: 12),
                  const KeyValueRow('이번 주 근무', '15시간'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const NoteBox('대타 근무는 주휴수당 계산에서 제외돼요. 사장님 승인 후 확정됩니다.',
                color: AppColors.accent, background: AppColors.accentSoft),
          ],
        ),
        bottomNavigationBar: BottomBar(
          child: AppButton(
            '지원하기',
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const SubstituteDoneScreen(SubstituteDoneKind.apply),
              ),
            ),
          ),
        ),
      );
}
