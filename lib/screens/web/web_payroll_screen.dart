import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../employer/employer_payroll_detail_screen.dart';
import 'web_common.dart';

/// W4 인건비·급여 정산 (콘텐츠 영역). 이번 달은 남은 예정 근무까지 포함한 예상치.
class WebPayrollScreen extends StatefulWidget {
  const WebPayrollScreen({super.key});

  @override
  State<WebPayrollScreen> createState() => _WebPayrollScreenState();
}

class _WebPayrollScreenState extends State<WebPayrollScreen> {
  DateTime? _month;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final t = store.today;
    final thisMonth = DateTime(t.year, t.month);
    final month = _month ?? thisMonth;
    final current = month == thisMonth;
    final total = store.laborTotal(month.year, month.month, projected: current);
    final last = store.laborTotal(month.year, month.month - 1);
    final diff = last == 0 ? 0 : ((total - last) / last * 100).round();
    // 인건비 합계와 같은 대상(가입 대기 제외). 퇴사자는 그 달 급여가 있을 때만.
    final rows = [
      for (final s in store.state.staff)
        if (s.storeId == store.store.id && s.status != StaffStatus.pending)
          (s, store.payslip(s.id, month.year, month.month, projected: current)),
    ].where((r) => r.$1.active || r.$2.gross > 0).toList();
    final trend = [
      for (var i = 5; i >= 0; i--)
        (
          DateTime(month.year, month.month - i),
          store.laborTotal(month.year, month.month - i, projected: current && i == 0),
        ),
    ];
    final maxTrend = trend.fold(1, (m, x) => x.$2 > m ? x.$2 : m);
    void later() => showToast(context, '추후 개발 예정이에요');

    return WebPage(
      title: '인건비 · 급여 정산',
      subtitle: '${month.year}년 ${month.month}월 · 근태 기록 기준 자동 계산'
          '${current ? ' · 남은 근무는 예정대로 계산' : ''}',
      actions: [
        MonthNav(month: month, max: thisMonth, onChanged: (m) => setState(() => _month = m)),
        WebButton('PDF 내보내기', style: WebButtonStyle.outline, onPressed: later),
        WebButton('정산 확정', onPressed: later),
      ],
      children: [
        WebRow(children: [
          _Stat(current ? '이번 달 예상 인건비' : '${month.month}월 인건비', won(total), primary: true),
          _Stat('지급 대상', '${rows.length}명'),
          _Stat('전월 대비', '${diff > 0 ? '+' : ''}$diff%',
              valueColor: diff > 0 ? AppColors.danger : AppColors.primary),
        ]),
        WebSplit(
          rightWidth: 300,
          gap: 20,
          left: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('직원별 정산', style: AppText.style(16, FontWeight.w700)),
                const SizedBox(height: 14),
                WebTable(
                  columns: const ['직원', '근무시간', '기본급', '주휴', '가산', '공제', '실수령'],
                  flex: const [130, 100, 120, 100, 100, 100, 120],
                  onRowTap: (i) => showMobilePanel(
                      context, EmployerPayrollDetailScreen(staffId: rows[i].$1.id, month: month)),
                  rows: [
                    for (final (s, p) in rows)
                      [
                        webStaffCell(store, s),
                        webCellText(hours(p.minutes)),
                        webCellText(comma(p.base)),
                        webCellText(comma(p.weeklyHoliday)),
                        webCellText(comma(p.premium)),
                        webCellText(p.deduction == 0 ? '0' : '−${comma(p.deduction)}'),
                        webCellText(comma(p.net),
                            color: AppColors.textPrimary, weight: FontWeight.w700),
                      ],
                  ],
                ),
                if (rows.isEmpty) const EmptyNote('정산할 직원이 없어요'),
              ],
            ),
          ),
          right: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('월별 인건비 추이', style: AppText.style(16, FontWeight.w700)),
                const SizedBox(height: 14),
                SizedBox(
                  height: 240,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < trend.length; i++)
                        Expanded(
                          child: Tooltip(
                            message: won(trend[i].$2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: 200 * trend[i].$2 / maxTrend,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: i == trend.length - 1
                                        ? AppColors.primary
                                        : AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text('${trend[i].$1.month}월',
                                    style: AppText.style(
                                        11, FontWeight.w400, AppColors.textSecondary)),
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
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.primary = false, this.valueColor});

  final String label, value;
  final bool primary;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => AppCard(
        color: primary ? AppColors.primary : AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppText.style(13, FontWeight.w400,
                    primary ? AppColors.onPrimary : AppColors.textSecondary)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: AppText.style(
                      30,
                      FontWeight.w700,
                      valueColor ??
                          (primary ? AppColors.onPrimary : AppColors.textPrimary))),
            ),
          ],
        ),
      );
}
