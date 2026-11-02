import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_payroll_settings_screen.dart';
import 'payroll_docs_widgets.dart';

/// 직원 급여 상세 (Figma 48:101).
class EmployerPayrollDetailScreen extends StatelessWidget {
  const EmployerPayrollDetailScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('수빈 · 5월 급여'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            AppCard(
              color: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('실수령 예정액',
                      style: AppText.style(13, FontWeight.w500, AppColors.onPrimary)),
                  const SizedBox(height: 6),
                  Text('₩ 1,120,400',
                      style: AppText.style(34, FontWeight.w700, AppColors.onPrimary)),
                  const SizedBox(height: 6),
                  Text('세전 ₩1,158,700 − 공제 ₩38,300 (3.3%)',
                      style: AppText.style(13, FontWeight.w400, AppColors.onPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('지급 내역',
                      style: AppText.style(14, FontWeight.w700, AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  const LabelValueRow('기본급 (88시간 × 10,030원)', '882,640원'),
                  const SizedBox(height: 12),
                  const LabelValueRow('주휴수당', '150,540원'),
                  const SizedBox(height: 12),
                  const LabelValueRow('야간·연장 가산', '125,520원'),
                  const SizedBox(height: 12),
                  const LabelValueRow('휴일 가산', '0원'),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),
                  const LabelValueRow('세전 합계', '1,158,700원', bold: true),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: kInfoSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '근태 기록(QR 인증 · 연장 12분 포함)을 기준으로 자동 계산된 금액이에요.',
                style: AppText.style(13, FontWeight.w400, kInfo),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomCta(
          '급여 설정 변경',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmployerPayrollSettingsScreen()),
          ),
        ),
      );
}
