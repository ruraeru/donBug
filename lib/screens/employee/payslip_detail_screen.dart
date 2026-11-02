import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employee_parts.dart';
import 'employee_widgets.dart';
import 'work_log_screen.dart';

/// 급여 명세서 상세.
class PayslipDetailScreen extends StatelessWidget {
  const PayslipDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final section = AppText.style(14, FontWeight.w700, AppColors.textSecondary);
    const regular = FontWeight.w400;
    return Scaffold(
      appBar: const AppHeader('5월 급여 명세서'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          AppCard(
            color: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('실수령액',
                    style: AppText.style(13, FontWeight.w500, AppColors.onPrimary)),
                const SizedBox(height: 6),
                Text('₩ 842,257',
                    style: AppText.style(34, FontWeight.w700, AppColors.onPrimary)),
                const SizedBox(height: 6),
                Text('세전 ₩871,000 − 공제 ₩28,743 (3.3%)',
                    style: AppText.style(13, FontWeight.w400, AppColors.onPrimary)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('지급 내역', style: section),
                const SizedBox(height: 12),
                const KvRow('기본급 (62시간 × 10,030원)', '621,860원', valueWeight: regular),
                const SizedBox(height: 12),
                const KvRow('주휴수당', '120,360원', valueWeight: regular),
                const SizedBox(height: 12),
                const KvRow('야간·연장 가산', '128,780원', valueWeight: regular),
                const SizedBox(height: 12),
                const KvRow('휴일 가산', '0원', valueWeight: regular),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                const KvRow('세전 합계', '871,000원'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('공제 내역', style: section),
                const SizedBox(height: 12),
                const KvRow('사업소득세 3.3%', '−28,743원', valueWeight: regular),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            color: kInfoSoft,
            radius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkLogScreen()),
            ),
            child: Text('일자별 근무 내역 보기  ›',
                style: AppText.style(14, FontWeight.w700, kInfo)),
          ),
        ],
      ),
    );
  }
}
