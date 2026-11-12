import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_payroll_settings_screen.dart';

/// 직원 상세.
class StaffDetailScreen extends StatelessWidget {
  const StaffDetailScreen({super.key, required this.staffId});

  final String staffId;

  Future<void> _remove(BuildContext context, String name) async {
    final ok = await showConfirmDialog(
      context,
      title: '$name님을 매장에서 내보낼까요?',
      message: '근무표와 직원 목록에서 빠져요. 다시 함께하려면 매장 코드로 재가입해야 해요.',
      confirmLabel: '내보내기',
      confirmVariant: AppButtonVariant.danger,
    );
    if (!ok || !context.mounted) return;
    AppScope.read(context).removeStaff(staffId);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text('$name님을 매장에서 내보냈어요')));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final s = store.staffById(staffId);
    if (s == null || !s.active) return const MissingScreen(title: '직원 상세');
    final p = store.personOf(s);
    final joined = parseYmd(s.joinedAt);
    final days = store
        .shiftsOfStaff(s.id)
        .where((x) => !parseYmd(x.date).isBefore(store.today))
        .take(14)
        .map((x) => parseYmd(x.date).weekday)
        .toSet()
        .toList()
      ..sort();
    final c = s.contract;
    return Scaffold(
      appBar: AppHeader(p.name),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    MemberAvatar(s),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.fullName, style: AppText.style(18, FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text('${s.part} · ${joined.year}.${joined.month.toString().padLeft(2, '0')} 입사',
                              style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('재직', style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                KeyValueRow('시급', wonText(s.wage)),
                const SizedBox(height: 12),
                KeyValueRow('공제 유형', s.deduction.label),
                const SizedBox(height: 12),
                KeyValueRow('근무 요일',
                    days.isEmpty ? '예정 근무 없음' : days.map((d) => weekday(DateTime(2024, 1, d))).join(' · ')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('서류 상태', style: AppText.style(14, FontWeight.w500, AppColors.textSecondary)),
                const SizedBox(height: 12),
                _DocRow('보건증', certPill(store.certDaysLeft(p))),
                const SizedBox(height: 12),
                _DocRow(
                    '근로계약서',
                    c == null
                        ? Text('없음', style: AppText.style(13, FontWeight.w400, AppColors.textSecondary))
                        : c.signed
                            ? Text('서명 완료', style: AppText.style(13, FontWeight.w400, AppColors.textSecondary))
                            : const Pill.accent('서명 대기')),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(children: [
        AppButton('급여 설정',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => EmployerPayrollSettingsScreen(staffId: s.id)))),
        AppButton('매장에서 내보내기',
            variant: AppButtonVariant.danger, onPressed: () => _remove(context, p.name)),
      ]),
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow(this.label, this.chip);

  final String label;
  final Widget chip;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(label, style: AppText.style(14))),
          chip,
        ],
      );
}
