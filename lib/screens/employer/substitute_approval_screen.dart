import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'substitute_done_screen.dart';

/// B4 대타 승인 (Figma 47:573).
class SubstituteApprovalScreen extends StatelessWidget {
  const SubstituteApprovalScreen({super.key});

  Future<void> _reject(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: '대타 요청을 거절할까요?',
      message: '5/14(수) 18:00 – 22:00 근무는 수빈님이 그대로 맡아요. '
          '수빈님과 지민님에게 결과를 알려요.',
      confirmLabel: '거절하기',
      confirmVariant: AppButtonVariant.danger,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(content: Text('대타 요청을 거절했어요')));
  }

  @override
  Widget build(BuildContext context) {
    final tertiary = AppText.style(12, FontWeight.w400, AppColors.textTertiary);
    final secondary = AppText.style(13, FontWeight.w400, AppColors.textSecondary);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleSpacing: 0,
        title: Text('대타 승인', style: AppText.style(24, FontWeight.w700)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: Center(child: _SmallChip('승인 대기 2', AppColors.accent, AppColors.accentSoft)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _SmallChip('사장님 승인 필요', AppColors.onPrimary, AppColors.accent),
                    const Spacer(),
                    Text('방금 전', style: tertiary),
                  ],
                ),
                const SizedBox(height: 14),
                Text('5/14(수) 18:00 – 22:00', style: AppText.style(19, FontWeight.w700)),
                const SizedBox(height: 2),
                Text('홀 서빙 · 4시간', style: secondary),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: _PersonChip('수', '수빈', '요청 · 병원 진료',
                          AppColors.accent, AppColors.accentSoft),
                    ),
                    const SizedBox(width: 10),
                    Text('→',
                        style: AppText.style(16, FontWeight.w700, AppColors.textTertiary)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: _PersonChip('지', '지민', '수락 · 5/13 21:08',
                          AppColors.primary, AppColors.primarySoft),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _Steps(),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.infoSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '승인 전까지는 수빈님이 근무 책임을 유지해요. 승인하면 근무표가 자동 변경돼요.',
                    style: AppText.style(12, FontWeight.w400, AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: AppButton('거절',
                          variant: AppButtonVariant.outline,
                          verticalPadding: 13,
                          fontSize: 14,
                          onPressed: () => _reject(context)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        '승인하고 반영',
                        verticalPadding: 13,
                        fontSize: 14,
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SubstituteDoneScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _SmallChip('동료 응답 대기', AppColors.info, AppColors.infoSoft),
                    const Spacer(),
                    Text('1시간 전', style: tertiary),
                  ],
                ),
                const SizedBox(height: 12),
                Text('5/16(금) 10:00 – 16:00', style: AppText.style(17, FontWeight.w700)),
                const SizedBox(height: 2),
                Text('주방 · 6시간 · 요청 하윤 (개인 사정)', style: secondary),
                const SizedBox(height: 12),
                Text('동료 4명에게 알림을 보냈고 아직 수락한 사람이 없어요.', style: tertiary),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(
                      child: AppButton('다시 알림 보내기',
                          variant: AppButtonVariant.outline,
                          verticalPadding: 13,
                          fontSize: 14),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: AppButton('직접 배정',
                          variant: AppButtonVariant.outline,
                          verticalPadding: 13,
                          fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 11px 칩 (Pill 은 12px 고정이라 따로).
class _SmallChip extends StatelessWidget {
  const _SmallChip(this.label, this.color, this.background);

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: AppText.style(11, FontWeight.w700, color)),
      );
}

class _PersonChip extends StatelessWidget {
  const _PersonChip(this.initial, this.name, this.note, this.color, this.background);

  final String initial;
  final String name;
  final String note;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            LetterAvatar(initial, color: color, background: background, size: 30),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppText.style(13, FontWeight.w700)),
                  Text(note,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.style(11, FontWeight.w400, AppColors.textTertiary)),
                ],
              ),
            ),
          ],
        ),
      );
}

/// 휴무 신청 → 동료 수락 → 사장님 승인(현재).
class _Steps extends StatelessWidget {
  const _Steps();

  Widget _step(String label, {required bool done}) => Column(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done ? AppColors.primary : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Text(done ? '✓' : '●',
                style: AppText.style(done ? 12 : 10, FontWeight.w700,
                    done ? AppColors.onPrimary : AppColors.primary)),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: AppText.style(11, done ? FontWeight.w500 : FontWeight.w700)),
        ],
      );

  Widget _line(Color color) => Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.only(top: 11),
          color: color,
        ),
      );

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _step('휴무 신청', done: true),
          const SizedBox(width: 6),
          _line(AppColors.primary),
          const SizedBox(width: 6),
          _step('동료 수락', done: true),
          const SizedBox(width: 6),
          _line(AppColors.border),
          const SizedBox(width: 6),
          _step('사장님 승인', done: false),
        ],
      );
}
