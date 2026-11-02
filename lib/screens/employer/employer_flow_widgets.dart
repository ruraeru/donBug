import 'package:flutter/material.dart';

import '../../theme.dart';

/// 카카오 버튼 노랑(Figma --kakao).
const kKakao = Color(0xFFFEE500);

/// 라벨(14 bold secondary) + 아래 내용.
class LabeledField extends StatelessWidget {
  const LabeledField(this.label, {super.key, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppText.style(14, FontWeight.w700, AppColors.textSecondary)),
          const SizedBox(height: 8),
          child,
        ],
      );
}

/// 흰 배경 · border · radius 14 입력칸 모양(더미 값 표시).
class FieldBox extends StatelessWidget {
  const FieldBox(this.value, {super.key});

  final String value;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(value, style: AppText.style(15)),
      );
}

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

/// 이름 첫 글자 원형 아바타.
class Avatar extends StatelessWidget {
  const Avatar(
    this.letter, {
    super.key,
    this.color = AppColors.primary,
    this.background = AppColors.primarySoft,
    this.size = 40,
    this.selected = false,
  });

  final String letter;
  final Color color;
  final Color background;
  final double size;

  /// primary 2px 테두리.
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Text(letter,
            style: AppText.style(size * 0.375, FontWeight.w700, color)),
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

/// 색 배경 안내 문구 박스.
class NoteBox extends StatelessWidget {
  const NoteBox(this.text, {super.key, required this.color, required this.background});

  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(text, style: AppText.style(13, FontWeight.w400, color)),
      );
}

/// 완료 화면 상단: 큰 체크 원 + 제목 + 설명.
class SuccessHero extends StatelessWidget {
  const SuccessHero({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 8),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Text('✓',
                  style: AppText.style(44, FontWeight.w700, AppColors.primary)),
            ),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: AppText.style(22, FontWeight.w700)),
            const SizedBox(height: 12),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: AppText.style(15, FontWeight.w400, AppColors.textSecondary)),
          ],
        ),
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
