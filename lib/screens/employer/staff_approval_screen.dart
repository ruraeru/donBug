import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_shell.dart';
import 'employer_parts.dart';

/// 직원 가입 승인 (Figma 47:100). 온보딩 마지막 → EmployerShell.
class StaffApprovalScreen extends StatelessWidget {
  const StaffApprovalScreen({super.key});

  static const _requests = [
    (initial: '태', name: '김태우', at: '5/14 09:41 신청', color: AppColors.primary, bg: AppColors.primarySoft),
    (initial: '서', name: '이서연', at: '5/14 09:13 신청', color: AppColors.info, bg: AppColors.infoSoft),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppHeader('가입 신청 ${_requests.length}건'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            for (final r in _requests) ...[
              AppCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        LetterAvatar(r.initial, color: r.color, background: r.bg),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.name, style: AppText.style(16, FontWeight.w700)),
                              Text(r.at,
                                  style: AppText.style(
                                      12, FontWeight.w400, AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const Pill('알바생',
                            color: AppColors.textSecondary,
                            background: AppColors.bg),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Expanded(child: SmallButton.outline('거절')),
                        SizedBox(width: 8),
                        Expanded(child: SmallButton('승인하고 시급 설정')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
        bottomNavigationBar: BottomBar(children: [
          AppButton(
            '대시보드로 이동',
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const EmployerShell()),
              (_) => false,
            ),
          ),
        ]),
      );
}
