import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';

/// 흰 트랙 안 선택 칩(5인 미만/이상, 파트 등).
class SegmentedPicker extends StatelessWidget {
  const SegmentedPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selected ? AppColors.primary : null,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      options[i],
                      style: AppText.style(
                        14,
                        FontWeight.w700,
                        i == selected
                            ? AppColors.onPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}

/// − n명 + 카운터.
class CountStepper extends StatelessWidget {
  const CountStepper({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  Widget _circle(String label, Color bg, Color fg, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Text(label, style: AppText.style(16, FontWeight.w700, fg)),
        ),
      );

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _circle('−', AppColors.bg, AppColors.textSecondary,
              () => onChanged(value > 0 ? value - 1 : 0)),
          const SizedBox(width: 14),
          Text('$value명', style: AppText.style(16, FontWeight.w700)),
          const SizedBox(width: 14),
          _circle('+', AppColors.primary, AppColors.onPrimary,
              () => onChanged(value + 1)),
        ],
      );
}

/// 작은 버튼(높이 36 · radius 10). filled=false 면 흰 배경 + border.
class SmallButton extends StatelessWidget {
  const SmallButton(
    this.label, {
    super.key,
    this.onPressed,
    this.background = AppColors.primary,
    this.color = AppColors.onPrimary,
    this.outlined = false,
  });

  const SmallButton.outline(this.label, {super.key, this.onPressed})
      : background = AppColors.surface,
        color = AppColors.textSecondary,
        outlined = true;

  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) => Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: outlined
              ? const BorderSide(color: AppColors.border)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed ?? () {},
          child: Container(
            height: 36,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(label, style: AppText.style(13, FontWeight.w700, color)),
          ),
        ),
      );
}

typedef StepItem = ({StepStatus state, String title, String subtitle});

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
                        StepRow(steps[i].state, steps[i].title, steps[i].subtitle),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomBar.button(ctaLabel, onPressed: onCta),
      );
}
