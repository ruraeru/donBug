import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';

/// 직원 상세 (더미: 수빈).
class StaffDetailScreen extends StatelessWidget {
  const StaffDetailScreen({super.key});

  Future<void> _remove(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: '수빈님을 매장에서 내보낼까요?',
      message: '근무표와 직원 목록에서 빠져요. 다시 함께하려면 매장 코드로 재가입해야 해요.',
      confirmLabel: '내보내기',
      confirmVariant: AppButtonVariant.danger,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(content: Text('수빈님을 매장에서 내보냈어요')));
  }

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
                      const LetterAvatar('수',
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
                          color: AppColors.danger,
                          background: AppColors.dangerSoft)),
                  const SizedBox(height: 10),
                  const _DocRow('근로계약서', Pill('서명 완료')),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomBar(children: [
          const AppButton('급여 설정'),
          AppButton('매장에서 내보내기',
              variant: AppButtonVariant.danger,
              onPressed: () => _remove(context)),
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
