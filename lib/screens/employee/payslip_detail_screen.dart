import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'work_log_screen.dart';

/// 급여 명세서 상세.
class PayslipDetailScreen extends StatelessWidget {
  const PayslipDetailScreen({super.key, required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final me = store.myStaff!;
    final current = month.year == store.today.year && month.month == store.today.month;
    final slip = store.payslip(me.id, month.year, month.month, projected: current);
    return Scaffold(
      appBar: AppHeader('${month.month}월 급여 명세서'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          AppCard(
            color: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(current ? '실수령액 (예정 근무 포함 예상)' : '실수령액',
                    style: AppText.style(13, FontWeight.w500, AppColors.onPrimary)),
                const SizedBox(height: 6),
                Text(won(slip.net), style: AppText.style(34, FontWeight.w500, AppColors.onPrimary)),
                const SizedBox(height: 6),
                Text('세전 ${won(slip.gross)} − 공제 ${won(slip.deduction)} (${me.deduction.short})',
                    style: AppText.style(13, FontWeight.w400, AppColors.onPrimary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PayBreakdown(slip: slip, staff: me),
          const SizedBox(height: 16),
          Material(
            color: AppColors.infoSoft,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WorkLogScreen(month: month)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  Expanded(
                      child: Text('일자별 근무 내역 보기',
                          style: AppText.style(14, FontWeight.w500, AppColors.info))),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.info),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
