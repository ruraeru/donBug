import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_widgets.dart';

/// AI 답변 상세.
class AiAnswerDetailScreen extends StatelessWidget {
  const AiAnswerDetailScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('AI 노무 도우미'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 290),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('5인 미만 사업장도 주휴수당을 줘야 하나요?',
                    style: AppText.style(
                            14, FontWeight.w400, AppColors.onPrimary)
                        .copyWith(height: 1.5)),
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              radius: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('네, 주휴수당은 사업장 규모와 상관없이 적용돼요.',
                      style: AppText.style(15, FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text(
                    '1주 소정근로시간이 15시간 이상이고, 소정근로일을 개근한 근로자에게 유급 주휴일을 줘야 해요. 5인 미만 사업장도 동일하게 적용돼요.',
                    style: AppText.style(
                            14, FontWeight.w400, AppColors.textSecondary)
                        .copyWith(height: 22 / 14),
                  ),
                  const SizedBox(height: 12),
                  const Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Pill('근로기준법 제55조',
                          color: EmpColors.info,
                          background: EmpColors.infoSoft),
                      Pill('적용 대상 확인',
                          color: AppColors.textSecondary,
                          background: AppColors.bg),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              color: AppColors.accentSoft,
              child: Text(
                '5인 미만 사업장은 연장·야간·휴일 가산수당과 연차 규정이 달라요. 구체적인 상황은 노무사 확인을 권장해요.',
                style: AppText.style(12, FontWeight.w400, AppColors.accent)
                    .copyWith(height: 1.5),
              ),
            ),
            const SizedBox(height: 12),
            Text('이어서 물어보기',
                style: AppText.style(
                    14, FontWeight.w700, AppColors.textSecondary)),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [Pill('해고 예고 수당'), Pill('연차 적용 여부')],
            ),
          ],
        ),
      );
}
