import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'payslip_detail_screen.dart';

/// A5 급여 정산 (탭 루트). 이번 달은 예정 근무까지 포함한 예상치.
class EmployeeSalaryScreen extends StatefulWidget {
  const EmployeeSalaryScreen({super.key});

  @override
  State<EmployeeSalaryScreen> createState() => _EmployeeSalaryScreenState();
}

class _EmployeeSalaryScreenState extends State<EmployeeSalaryScreen> {
  DateTime? _month;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final me = store.myStaff!;
    final month = _month ?? DateTime(store.today.year, store.today.month);
    final current = month.year == store.today.year && month.month == store.today.month;
    final slip = store.payslip(me.id, month.year, month.month, projected: current);
    final logs = slip.entries.where((e) => !e.planned).toList().reversed.take(3);
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            child: Row(children: [
              Expanded(child: Text('급여', style: AppText.style(24, FontWeight.w700))),
              MonthNav(month: month, max: store.today, onChanged: (m) => setState(() => _month = m)),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                AppCard(
                  color: AppColors.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PayslipDetailScreen(month: month)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(current ? '이번 달 예상 실수령액' : '${month.month}월 실수령액',
                          style: AppText.style(13, FontWeight.w500, AppColors.onPrimary)),
                      const SizedBox(height: 8),
                      Text(won(slip.net),
                          style: AppText.style(34, FontWeight.w700, AppColors.onPrimary)),
                      const SizedBox(height: 8),
                      Text(
                          '급여일 ${month.month}/25 · ${current ? '예정 포함 ' : ''}근무 ${hours(slip.minutes)}  ›',
                          style: AppText.style(13, FontWeight.w400, AppColors.onPrimary)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PayBreakdown(slip: slip, staff: me, title: '급여 내역'),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('최근 출퇴근 기록', style: AppText.style(15, FontWeight.w700)),
                      if (logs.isEmpty) const EmptyNote('이 달 출퇴근 기록이 없어요'),
                      for (final e in logs) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: Text(md(e.day), style: AppText.style(14, FontWeight.w500))),
                            Expanded(
                              flex: 2,
                              child: Text('${clock(e.start)} – ${clock(e.end)}',
                                  textAlign: TextAlign.center,
                                  style: AppText.style(14, FontWeight.w400, AppColors.textSecondary)),
                            ),
                            Expanded(
                              child: Text(hours(e.minutes),
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
