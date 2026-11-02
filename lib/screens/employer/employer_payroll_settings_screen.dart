import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'payroll_docs_widgets.dart';

/// 급여 설정 (Figma 48:136). 저장 시 인건비 대시보드로 복귀.
class EmployerPayrollSettingsScreen extends StatefulWidget {
  const EmployerPayrollSettingsScreen({super.key});

  @override
  State<EmployerPayrollSettingsScreen> createState() =>
      _EmployerPayrollSettingsScreenState();
}

class _EmployerPayrollSettingsScreenState
    extends State<EmployerPayrollSettingsScreen> {
  static const _deductions = ['3.3%', '4대보험', '없음'];
  int _deduction = 0;
  bool _weeklyAllowance = true;
  bool _premium = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('급여 설정'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            AppCard(
              child: Row(
                children: [
                  const InitialAvatar('수',
                      size: 40,
                      color: AppColors.accent,
                      background: AppColors.accentSoft),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('수빈', style: AppText.style(16, FontWeight.w700)),
                        Text('오픈 · 주 3일',
                            style: AppText.style(
                                12, FontWeight.w400, AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const LabeledField('시급', '10,030원'),
            const SizedBox(height: 14),
            Text('공제 유형',
                style: AppText.style(14, FontWeight.w700, AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _deductions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(child: _segment(i)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _toggleCard('주휴수당 자동 적용', '주 15시간 이상 · 개근 조건 자동 판별',
                _weeklyAllowance, (v) => setState(() => _weeklyAllowance = v)),
            const SizedBox(height: 14),
            _toggleCard('야간·연장·휴일 가산', '5인 미만 사업장은 법적으로 미적용', _premium,
                (v) => setState(() => _premium = v)),
          ],
        ),
        bottomNavigationBar: BottomCta(
          '저장',
          // 설정 → 급여 상세 → 대시보드
          onPressed: () => Navigator.of(context)
            ..pop()
            ..pop(),
        ),
      );

  Widget _segment(int i) {
    final selected = i == _deduction;
    return GestureDetector(
      onTap: () => setState(() => _deduction = i),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(_deductions[i],
            style: AppText.style(14, FontWeight.w700,
                selected ? AppColors.onPrimary : AppColors.textTertiary)),
      ),
    );
  }

  Widget _toggleCard(
          String title, String sub, bool value, ValueChanged<bool> onChanged) =>
      AppCard(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.style(15, FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: AppText.style(
                          12, FontWeight.w400, AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Figma 48×28 커스텀 스위치
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              height: 28,
              padding: const EdgeInsets.all(3),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                color: value ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                    color: AppColors.surface, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      );
}
