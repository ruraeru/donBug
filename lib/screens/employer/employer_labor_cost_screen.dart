import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_payroll_detail_screen.dart';

/// B5 인건비 대시보드 (Figma 48:3). 탭 루트. 이번 달은 예정 근무 포함 예상치.
class EmployerLaborCostScreen extends StatefulWidget {
  const EmployerLaborCostScreen({super.key});

  @override
  State<EmployerLaborCostScreen> createState() => _EmployerLaborCostScreenState();
}

class _EmployerLaborCostScreenState extends State<EmployerLaborCostScreen> {
  DateTime? _month;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final month = _month ?? DateTime(store.today.year, store.today.month);
    final current = month.year == store.today.year && month.month == store.today.month;
    final total = store.laborTotal(month.year, month.month, projected: current);
    final last = store.laborTotal(month.year, month.month - 1);
    final diff = last == 0 ? 0 : ((total - last) / last * 100).round();
    final bars = [
      for (var i = 5; i >= 0; i--)
        (DateTime(month.year, month.month - i),
            store.laborTotal(month.year, month.month - i, projected: current && i == 0)),
    ];
    final workers = [
      for (final s in store.state.staff.where((s) => s.storeId == store.store.id))
        (s, store.payslip(s.id, month.year, month.month, projected: current)),
    ].where((w) => w.$2.gross > 0).toList()
      ..sort((a, b) => b.$2.net.compareTo(a.$2.net));

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            child: Row(
              children: [
                Expanded(child: Text('인건비', style: AppText.style(24, FontWeight.w500))),
                MonthNav(month: month, max: store.today, onChanged: (m) => setState(() => _month = m)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                AppCard(
                  color: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(current ? '이번 달 예상 인건비' : '${month.month}월 인건비',
                          style: AppText.style(13, FontWeight.w500, AppColors.onPrimary)),
                      const SizedBox(height: 8),
                      Text(won(total), style: AppText.style(30, FontWeight.w500, AppColors.onPrimary)),
                      const SizedBox(height: 8),
                      Text('세전 · 주휴수당 포함 · 지난달 대비 ${diff >= 0 ? '+' : ''}$diff%',
                          style: AppText.style(12, FontWeight.w400, AppColors.onPrimary)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _chart(bars),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(current ? '근로자별 지급 예정' : '근로자별 지급액',
                                  style: AppText.style(15, FontWeight.w500)),
                            ),
                            Text('전체 ${workers.length}명',
                                style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      if (workers.isEmpty) const EmptyNote('이 달 근무 기록이 없어요'),
                      for (final (s, p) in workers)
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => EmployerPayrollDetailScreen(staffId: s.id, month: month)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                MemberAvatar(s),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(store.personOf(s).name, style: AppText.style(14, FontWeight.w500)),
                                      Text('${hours(p.minutes)} · ${s.deduction.short}',
                                          style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
                                    ],
                                  ),
                                ),
                                Text(won(p.net), style: AppText.style(15, FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
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

  Widget _chart(List<(DateTime, int)> bars) {
    final max = bars.fold(1, (m, b) => b.$2 > m ? b.$2 : m);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('인건비 지출 추이', style: AppText.style(15, FontWeight.w500))),
              Text('최근 6개월', style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: MediaQuery.textScalerOf(context).scale(130),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < bars.length; i++)
                  _bar(bars[i], max, current: i == bars.length - 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar((DateTime, int) b, int max, {required bool current}) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${comma((b.$2 / 10000).round())}만',
              style: AppText.style(10, current ? FontWeight.w500 : FontWeight.w400,
                  current ? AppColors.primary : AppColors.textTertiary)),
          const SizedBox(height: 8),
          Container(
            width: 30,
            height: 4 + 76 * b.$2 / max,
            decoration: BoxDecoration(
              color: current ? AppColors.primary : AppColors.border,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ),
          const SizedBox(height: 8),
          Text('${b.$1.month}월',
              style: AppText.style(11, current ? FontWeight.w500 : FontWeight.w400,
                  current ? AppColors.textPrimary : AppColors.textTertiary)),
        ],
      );
}
