import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_widgets.dart';

/// 직원 상세 (더미: 수빈).
class StaffDetailScreen extends StatelessWidget {
  const StaffDetailScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('수빈'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const InitialAvatar('수',
                          color: AppColors.accent,
                          background: AppColors.accentSoft),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('수빈', style: AppText.style(18, FontWeight.w700)),
                            const SizedBox(height: 1),
                            Text('알바생 · 2026.03 입사',
                                style: AppText.style(12, FontWeight.w400,
                                    AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Pill('재직'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),
                  const KeyValueRow('시급', '10,030원'),
                  const SizedBox(height: 12),
                  const KeyValueRow('공제 유형', '사업소득세 3.3%'),
                  const SizedBox(height: 12),
                  const KeyValueRow('근무 요일', '월 · 수 · 금'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('서류 상태',
                      style: AppText.style(
                          14, FontWeight.w700, AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  const _DocRow('보건증',
                      Pill('만료 D-12',
                          color: EmpColors.danger,
                          background: EmpColors.dangerSoft)),
                  const SizedBox(height: 10),
                  const _DocRow('근로계약서', Pill('서명 완료')),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomBar(children: [
          const AppButton('급여 설정'),
          Material(
            color: EmpColors.dangerSoft,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {},
              child: SizedBox(
                height: 54,
                child: Center(
                  child: Text('매장에서 내보내기',
                      style: AppText.style(
                          16, FontWeight.w700, EmpColors.danger)),
                ),
              ),
            ),
          ),
        ]),
      );
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
