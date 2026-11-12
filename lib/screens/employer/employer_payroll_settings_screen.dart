import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../data/payroll.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_parts.dart';

/// 급여 설정 (Figma 48:136). 저장하면 이전 화면으로.
class EmployerPayrollSettingsScreen extends StatefulWidget {
  const EmployerPayrollSettingsScreen({super.key, required this.staffId});

  final String staffId;

  @override
  State<EmployerPayrollSettingsScreen> createState() => _EmployerPayrollSettingsScreenState();
}

class _EmployerPayrollSettingsScreenState extends State<EmployerPayrollSettingsScreen> {
  final _wage = TextEditingController();
  int _deduction = 0;
  bool _weeklyAllowance = true;
  bool _premium = false;

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context).staffById(widget.staffId);
    if (s != null) {
      _wage.text = wonInput(s.wage);
      _deduction = s.deduction.index;
      _weeklyAllowance = s.weeklyHolidayAuto;
      _premium = s.premium;
    }
  }

  @override
  void dispose() {
    _wage.dispose();
    super.dispose();
  }

  void _save() {
    final w = wonDigits(_wage.text);
    if (w == null || w < minimumWage2026) {
      return showToast(context, '시급은 2026 최저임금 ${wonText(minimumWage2026)} 이상이어야 해요');
    }
    AppScope.read(context).updateStaff(widget.staffId,
        wage: w,
        deduction: Deduction.values[_deduction],
        weeklyHolidayAuto: _weeklyAllowance,
        premium: _premium);
    Navigator.pop(context);
    showToast(context, '급여 설정을 저장했어요');
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final s = store.staffById(widget.staffId);
    if (s == null) return const MissingScreen(title: '급여 설정');
    final small = store.store.isSmall;
    final weekly = store
        .shiftsOfStaff(s.id)
        .where((x) => mondayOf(parseYmd(x.date)) == mondayOf(store.today))
        .length;
    return Scaffold(
      appBar: const AppHeader('급여 설정'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          AppCard(
            child: Row(
              children: [
                MemberAvatar(s),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store.personOf(s).name, style: AppText.style(16, FontWeight.w500)),
                      Text('${s.part} · 이번 주 $weekly일',
                          style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LabeledField('시급 (원)',
              child: AppTextField(controller: _wage, won: true)),
          const SizedBox(height: 8),
          Text('2026 최저임금 ${wonText(minimumWage2026)}',
              style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
          const SizedBox(height: 16),
          LabeledField(
            '공제 유형',
            child: SegmentedPicker(
              options: [for (final d in Deduction.values) d.short],
              selected: _deduction,
              onChanged: (i) => setState(() => _deduction = i),
            ),
          ),
          const SizedBox(height: 16),
          ToggleCard(
            title: '주휴수당 자동 적용',
            subtitle: '주 15시간 이상이면 자동 계산 (대타 근무 제외)',
            value: _weeklyAllowance,
            onChanged: (v) => setState(() => _weeklyAllowance = v),
          ),
          const SizedBox(height: 16),
          ToggleCard(
            title: '야간·연장 가산',
            subtitle: small ? '5인 미만 사업장은 법적으로 미적용 (매장 설정에서 변경)' : '야간(22–06)·하루 8시간 초과분 0.5배',
            value: _premium && !small,
            onChanged: small ? null : (v) => setState(() => _premium = v),
          ),
        ],
      ),
      bottomNavigationBar: BottomBar.button('저장', onPressed: _save),
    );
  }
}
