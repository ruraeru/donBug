import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_payroll_settings_screen.dart';

/// 직원 급여 상세 (Figma 48:101).
class EmployerPayrollDetailScreen extends StatelessWidget {
  const EmployerPayrollDetailScreen({super.key, required this.staffId, required this.month});

  final String staffId;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final s = store.staffById(staffId);
    if (s == null) return const MissingScreen(title: '급여 상세');
    final current = month.year == store.today.year && month.month == store.today.month;
    final p = store.payslip(s.id, month.year, month.month, projected: current);
    final edited = store.state.attendance
        .where((a) =>
            a.staffId == s.id &&
            a.editReason != null &&
            (store.shiftById(a.shiftId)?.date.startsWith(ym(month)) ?? false))
        .length;
    return Scaffold(
      appBar: AppHeader('${store.personOf(s).name} · ${month.month}월 급여'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          AppCard(
            color: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(current ? '실수령 예정액 (예정 근무 포함)' : '실수령액',
                    style: AppText.style(13, FontWeight.w500, AppColors.onPrimary)),
                const SizedBox(height: 8),
                Text(won(p.net), style: AppText.style(34, FontWeight.w500, AppColors.onPrimary)),
                const SizedBox(height: 8),
                Text('세전 ${won(p.gross)} − 공제 ${won(p.deduction)} (${s.deduction.short})',
                    style: AppText.style(13, FontWeight.w400, AppColors.onPrimary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PayBreakdown(slip: p, staff: s, title: '지급 · 공제 내역'),
          const SizedBox(height: 16),
          NoteBox(
            '근태 기록(QR 인증${edited > 0 ? ' · 수동 수정 $edited건' : ''})을 기준으로 자동 계산된 금액이에요',
            color: AppColors.textSecondary,
            background: AppColors.bg,
          ),
        ],
      ),
      bottomNavigationBar: BottomBar.button(
        '급여 설정 변경',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EmployerPayrollSettingsScreen(staffId: s.id)),
        ),
      ),
    );
  }
}
