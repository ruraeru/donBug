import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../data/payroll.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_contract_write_screen.dart';
import 'employer_staff_documents_screen.dart';

/// B2 서류·컴플라이언스 (Figma 48:179, 계약서 variant 48:335). 탭 루트.
/// 체크리스트는 직원 데이터로 계산한다.
class EmployerDocumentsScreen extends StatelessWidget {
  const EmployerDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final staff = store.activeStaff;
    final unsigned = staff.where((s) => !(s.contract?.signed ?? false)).length;
    final underpaid = staff.where((s) => s.wage < minimumWage2026).length;
    final noHoliday = staff.where((s) => !s.weeklyHolidayAuto).length;
    final certDue = staff.where((s) {
      final d = store.certDaysLeft(store.personOf(s));
      return d == null || d <= 30;
    }).length;
    final checks = [
      (unsigned == 0 ? '근로계약서 작성 · 교부' : '근로계약서 미서명 · $unsigned명', unsigned == 0),
      (underpaid == 0
          ? '최저임금 준수 (시급 ${wonText(minimumWage2026)})'
          : '최저임금 미달 · $underpaid명', underpaid == 0),
      (noHoliday == 0 ? '주휴수당 지급' : '주휴수당 미적용 · $noHoliday명', noHoliday == 0),
      (certDue == 0 ? '보건증 유효' : '보건증 갱신 필요 · $certDue명', certDue == 0),
    ];

    void openStaff(Staff s) => Navigator.push(
        context, MaterialPageRoute(builder: (_) => EmployerStaffDocumentsScreen(staffId: s.id)));

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text('서류 · 컴플라이언스', style: AppText.style(22, FontWeight.w500)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('노무 체크리스트', style: AppText.style(15, FontWeight.w500))),
                          Text(store.store.isSmall ? '5인 미만 사업장' : '5인 이상 사업장',
                              style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
                        ],
                      ),
                      for (var i = 0; i < checks.length; i++) ...[
                        if (i > 0) const Divider(height: 1, color: AppColors.border),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: _checkRow(checks[i].$1, ok: checks[i].$2),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('근로자별 서류', style: AppText.style(15, FontWeight.w500)),
                      for (var i = 0; i < staff.length; i++) ...[
                        if (i > 0) const Divider(height: 1, color: AppColors.border),
                        InkWell(
                          onTap: () => openStaff(staff[i]),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                    child: Text(store.personOf(staff[i]).name,
                                        style: AppText.style(15, FontWeight.w500))),
                                contractPill(staff[i].contract),
                                const SizedBox(width: 8),
                                certPill(store.certDaysLeft(store.personOf(staff[i]))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  '전자 근로계약서 작성',
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const EmployerContractWriteScreen())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkRow(String label, {required bool ok}) => Row(
        children: [
          AppIcon(ok ? 'check' : 'alert_circle', size: 20,
              color: ok ? AppColors.textSecondary : AppColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: ok ? AppText.style(14) : AppText.style(14, FontWeight.w500, AppColors.danger)),
          ),
        ],
      );
}

/// 계약서 상태 칩.
Widget contractPill(Contract? c) => c == null
    ? const Pill('계약서 없음', color: AppColors.danger, background: AppColors.dangerSoft)
    : c.signed
        ? Text('계약서 완료', style: AppText.style(13, FontWeight.w400, AppColors.textSecondary))
        : const Pill.accent('서명 대기');
