import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'join_approved_screen.dart';

/// 가입 승인 대기.
class JoinPendingScreen extends StatelessWidget {
  const JoinPendingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('가입 신청 현황'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 28, bottom: 8),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: AppColors.accentSoft, shape: BoxShape.circle),
                    child: Text('…',
                        style:
                            AppText.style(44, FontWeight.w700, AppColors.accent)),
                  ),
                  const SizedBox(height: 12),
                  Text('사장님 승인을 기다리고 있어요',
                      textAlign: TextAlign.center,
                      style: AppText.style(22, FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text('승인되면 알림으로 알려드릴게요',
                      textAlign: TextAlign.center,
                      style: AppText.style(
                          15, FontWeight.w400, AppColors.textSecondary)),
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
                          child: Text('카페 커푸치노',
                              style: AppText.style(17, FontWeight.w700))),
                      const Pill.accent('승인 대기'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('신청 일시  2026.05.14 09:41',
                      style: AppText.style(
                          13, FontWeight.w400, AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Text('신청자  김태우 (알바생)',
                      style: AppText.style(
                          13, FontWeight.w400, AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 더미: 새로고침하면 승인된 것으로 간주.
              AppButton(
                '새로고침',
                onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const JoinApprovedScreen())),
              ),
              const SizedBox(height: 10),
              AppButton('코드 다시 입력',
                  variant: AppButtonVariant.outline,
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      );
}
