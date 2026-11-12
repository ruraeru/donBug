import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../data/payroll.dart';
import '../../widgets/common.dart';
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
    bool isLast(int i) => i == trend.length - 1;
    void later() => showToast(context, '추후 개발 예정이에요');

    return WebPage(
      title: '인건비 · 급여 정산',
      subtitle: '${month.year}년 ${month.month}월 · 근태 기록 기준 자동 계산'
          '${current ? ' · 남은 근무는 예정대로 계산' : ''}',
      actions: [
        SizedBox(
          height: 42,
          child: MonthNav(month: month, max: thisMonth, onChanged: (m) => setState(() => _month = m)),
        ),
        WebButton('PDF 내보내기', style: WebButtonStyle.outline, onPressed: later),
        WebButton('정산 확정', onPressed: later),
      ],
      children: [
        WebRow(children: [
          _Stat(current ? '이번 달 예상 인건비' : '${month.month}월 인건비', wonText(total)),
          _Stat('지급 대상', '${rows.length}명'),
          _Stat('지난달 대비', '${diff > 0 ? '+' : ''}$diff%',
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
                Text('직원별 정산', style: AppText.style(16, FontWeight.w500)),
                const SizedBox(height: 14),
                LayoutBuilder(builder: (context, c) {
                  // 좁아서 가로 스크롤이 생기면 실수령 열을 이름 바로 뒤로 당긴다.
                  final narrow = c.maxWidth < 640;
                  List<T> order<T>(List<T> l) => narrow ? [l[0], l[6], ...l.sublist(1, 6)] : l;
                  return WebTable(
                    columns: order(const ['직원', '근무시간', '기본급', '주휴', '가산', '공제', '실수령']),
                    flex: order(const [130, 100, 120, 100, 100, 100, 120]),
                    numeric: const {1, 2, 3, 4, 5, 6},
                    onRowTap: (i) => _showDetail(context, rows[i].$1, rows[i].$2, month),
                    rows: [
                      for (final (s, p) in rows)
                        order([
                          webStaffCell(store, s),
                          webCellText(hours(p.minutes)),
                          webCellText(comma(p.base)),
                          webCellText(comma(p.weeklyHoliday)),
                          webCellText(comma(p.premium)),
                          webCellText(p.deduction == 0 ? '0' : '-${comma(p.deduction)}'),
                          webCellText(comma(p.net),
                              color: AppColors.textPrimary, weight: FontWeight.w500),
                        ]),
                    ],
                  );
                }),
                if (rows.isEmpty) const EmptyNote('정산할 직원이 없어요'),
              ],
            ),
          ),
          right: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('월별 인건비 추이', style: AppText.style(16, FontWeight.w500)),
                const SizedBox(height: 14),
                SizedBox(
                  height: 260,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < trend.length; i++)
                        Expanded(
                          child: Tooltip(
                            message: wonText(trend[i].$2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // 만 원 단위 값. 이번 달만 강조색, 나머지는 회색.
                                Text('${comma((trend[i].$2 / 10000).round())}만',
                                    style: AppText.style(
                                        11,
                                        isLast(i) ? FontWeight.w500 : FontWeight.w400,
                                        isLast(i) ? AppColors.primary : AppColors.textTertiary)),
                                const SizedBox(height: 4),
                                Container(
                                  height: 200 * trend[i].$2 / maxTrend,
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: isLast(i) ? AppColors.primary : AppColors.border,
                                    borderRadius:
                                        const BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                ),
                                const Divider(height: 1, thickness: 1, color: AppColors.border),
                                const SizedBox(height: 8),
                                Text('${trend[i].$1.month}월',
                                    style: AppText.style(11, FontWeight.w400,
                                        isLast(i) ? AppColors.textPrimary : AppColors.textSecondary)),
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
  const _Stat(this.label, this.value, {this.valueColor});

  final String label, value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: AppText.style(28, FontWeight.w500, valueColor ?? AppColors.textPrimary)),
            ),
          ],
        ),
      );
}

/// 직원 한 명의 그 달 급여 내역 + 근무 기록.
Future<void> _showDetail(BuildContext context, Staff s, Payslip slip, DateTime month) {
  final store = AppScope.read(context);
  return showWebDialog<void>(
    context,
    title: '${store.personOf(s).fullName} · ${month.month}월 급여',
    width: 560,
    builder: (ctx, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PayBreakdown(slip: slip, staff: s),
      const SizedBox(height: 16),
      // 위 금액 카드 안쪽 글자와 같은 x 로 맞춘다.
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('근무 기록 ${slip.entries.length}건', style: AppText.style(14, FontWeight.w500)),
      ),
      const SizedBox(height: 8),
      for (final e in slip.entries)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(children: [
            Expanded(child: Text(md(e.day), style: AppText.style(13, FontWeight.w500))),
            Text('${clock(e.start)}–${clock(e.end)}${e.planned ? ' (예정)' : ''}',
                style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
            const SizedBox(width: 16),
            SizedBox(
              width: 70,
              child: Text(hours(e.minutes),
                  textAlign: TextAlign.right, style: AppText.style(13, FontWeight.w500)),
            ),
          ]),
        ),
    ]),
  );
}
