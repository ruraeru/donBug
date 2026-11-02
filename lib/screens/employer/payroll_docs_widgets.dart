import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';

/// 인건비 · 서류 화면 공용 조각. theme.dart에 없는 Figma 토큰은 여기 둔다.
const kInfo = Color(0xFF3B82F6);
const kInfoSoft = Color(0xFFE8F0FE);
const kDanger = Color(0xFFE5484D);
const kDangerSoft = Color(0xFFFDECEC);

/// 이름 첫 글자 원형 아바타.
class InitialAvatar extends StatelessWidget {
  const InitialAvatar(
    this.initial, {
    super.key,
    this.size = 36,
    this.color = AppColors.primary,
    this.background = AppColors.primarySoft,
  });

  final String initial;
  final double size;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Text(initial,
            style: AppText.style(size >= 40 ? 15 : 14, FontWeight.w700, color)),
      );
}

/// 라벨 ··· 값 한 줄.
class LabelValueRow extends StatelessWidget {
  const LabelValueRow(this.label, this.value, {super.key, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(label,
                style: AppText.style(14, FontWeight.w400, AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: AppText.style(14, bold ? FontWeight.w700 : FontWeight.w400)),
        ],
      );
}

/// 섹션 라벨 + 흰 입력 박스(표시용).
class LabeledField extends StatelessWidget {
  const LabeledField(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppText.style(14, FontWeight.w700, AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(value, style: AppText.style(15)),
          ),
        ],
      );
}

/// Figma "Bottom Bar": 흰 배경 위 CTA 하나.
class BottomCta extends StatelessWidget {
  const BottomCta(this.label, {super.key, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: SafeArea(
          top: false,
          child: AppButton(label, onPressed: onPressed, verticalPadding: 17),
        ),
      );
}

enum ProgressState { done, current, upcoming }

typedef StepItem = ({ProgressState state, String title, String subtitle});

/// 완료 화면: 큰 체크 + 제목/설명 + 단계 타임라인 카드 + 하단 CTA.
class SuccessStepsScaffold extends StatelessWidget {
  const SuccessStepsScaffold({
    super.key,
    required this.title,
    required this.message,
    required this.steps,
    required this.ctaLabel,
    required this.onCta,
    this.stepsHeader,
  });

  final String title;
  final String message;
  final String? stepsHeader;
  final List<StepItem> steps;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                const SizedBox(height: 28),
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: AppColors.primarySoft, shape: BoxShape.circle),
                  child: Text('✓',
                      style: AppText.style(44, FontWeight.w700, AppColors.primary)),
                ),
                const SizedBox(height: 12),
                Text(title,
                    textAlign: TextAlign.center,
                    style: AppText.style(22, FontWeight.w700)),
                const SizedBox(height: 12),
                Text(message,
                    textAlign: TextAlign.center,
                    style: AppText.style(15, FontWeight.w400, AppColors.textSecondary)),
                const SizedBox(height: 24),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (stepsHeader != null) ...[
                        Text(stepsHeader!,
                            style: AppText.style(
                                14, FontWeight.w700, AppColors.textSecondary)),
                        const SizedBox(height: 16),
                      ],
                      for (var i = 0; i < steps.length; i++) ...[
                        if (i > 0) const SizedBox(height: 16),
                        _StepRow(steps[i]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomCta(ctaLabel, onPressed: onCta),
      );
}

class _StepRow extends StatelessWidget {
  const _StepRow(this.step);

  final StepItem step;

  @override
  Widget build(BuildContext context) {
    final dot = switch (step.state) {
      ProgressState.done => BoxDecoration(
          color: AppColors.primary, shape: BoxShape.circle),
      ProgressState.current => BoxDecoration(
          color: AppColors.accentSoft,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.accent)),
      ProgressState.upcoming =>
        const BoxDecoration(color: AppColors.bg, shape: BoxShape.circle),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: dot,
          child: step.state == ProgressState.done
              ? Text('✓',
                  style: AppText.style(13, FontWeight.w700, AppColors.onPrimary))
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.title,
                  style: AppText.style(
                      15,
                      FontWeight.w700,
                      step.state == ProgressState.upcoming
                          ? AppColors.textTertiary
                          : AppColors.textPrimary)),
              Text(step.subtitle,
                  style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
