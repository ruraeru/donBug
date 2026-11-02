import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employee_parts.dart';
import 'employee_widgets.dart';
import 'payslip_detail_screen.dart';

/// A5 급여 정산 (탭 루트).
class EmployeeSalaryScreen extends StatelessWidget {
  const EmployeeSalaryScreen({super.key});

  static const _logs = [
    ('5/12(월)', '14:02 – 20:01', '5.9h'),
    ('5/10(토)', '16:00 – 22:05', '6.1h'),
    ('5/09(금)', '10:01 – 16:00', '6.0h'),
  ];

  @override
  Widget build(BuildContext context) {
    const divider = Divider(height: 1, color: AppColors.border);
    return SafeArea(
      child: Column(
        children: [
          const TabTitle('급여', chip: '5월'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                AppCard(
                  color: AppColors.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PayslipDetailScreen()),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('이번 달 예상 실수령액',
                          style: AppText.style(13, FontWeight.w500, AppColors.onPrimary)),
                      const SizedBox(height: 8),
                      Text('₩ 842,257',
                          style: AppText.style(34, FontWeight.w700, AppColors.onPrimary)),
                      const SizedBox(height: 8),
                      Text('급여일 5/25 · 누적 근무 62시간',
                          style: AppText.style(13, FontWeight.w400, AppColors.onPrimary)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('급여 내역', style: AppText.style(15, FontWeight.w700)),
                      const SizedBox(height: 14),
                      const KvRow('기본급 (62시간 × 10,320원)', '₩ 639,840',
                          valueWeight: FontWeight.w500),
                      const SizedBox(height: 14),
                      const KvRow('주휴수당', '₩ 231,160', valueWeight: FontWeight.w500),
                      const SizedBox(height: 14),
                      divider,
                      const SizedBox(height: 14),
                      const KvRow('총 급여', '₩ 871,000', valueWeight: FontWeight.w500),
                      const SizedBox(height: 14),
                      const KvRow('원천징수 (3.3%)', '-₩ 28,743',
                          valueWeight: FontWeight.w500, valueColor: kDanger),
                      const SizedBox(height: 14),
                      divider,
                      const SizedBox(height: 14),
                      KvRow('실수령액', '₩ 842,257',
                          labelStyle: AppText.style(16, FontWeight.w700),
                          valueSize: 18,
                          valueColor: AppColors.primary),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('최근 출퇴근 기록', style: AppText.style(15, FontWeight.w700)),
                      for (final (date, time, hours) in _logs) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: Text(date,
                                    style: AppText.style(14, FontWeight.w500))),
                            Expanded(
                              flex: 2,
                              child: Text(time,
                                  textAlign: TextAlign.center,
                                  style: AppText.style(
                                      14, FontWeight.w400, AppColors.textSecondary)),
                            ),
                            Expanded(
                              child: Text(hours,
                                  textAlign: TextAlign.right,
                                  style: AppText.style(14, FontWeight.w700)),
                            ),
                          ],
                        ),
                      ],
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
}
