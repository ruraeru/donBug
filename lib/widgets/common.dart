import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/app_scope.dart';
import '../data/format.dart';
import '../data/models.dart';
import '../data/payroll.dart';
import '../theme.dart';

/// assets/icons/ 의 Figma SVG. [color]를 주면 단색으로 칠한다(탭 선택 상태 등).
class AppIcon extends StatelessWidget {
  const AppIcon(this.name, {super.key, this.size = 24, this.color});

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        'assets/icons/$name.svg',
        width: size,
        height: size,
        colorFilter:
            color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
      );
}

/// 흰 배경 · radius 20 · padding 20 카드.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.color = AppColors.surface,
    this.padding = const EdgeInsets.all(20),
    this.radius = 20,
    this.onTap,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      );
}

/// 둥근 칩(pill). 기본은 primary-soft 배경 + primary 글자.
class Pill extends StatelessWidget {
  const Pill(
    this.label, {
    super.key,
    this.color = AppColors.primary,
    this.background = AppColors.primarySoft,
  });

  const Pill.accent(this.label, {super.key})
      : color = AppColors.accent,
        background = AppColors.accentSoft;

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
        child: Text(label, style: AppText.style(12, FontWeight.w500, color)),
      );
}

enum AppButtonVariant { primary, soft, surface, outline, danger }

/// 가로 꽉 찬 radius 14 버튼.
class AppButton extends StatelessWidget {
  const AppButton(
    this.label, {
    super.key,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.verticalPadding = 16,
    this.fontSize = 16,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  /// assets/icons/ 아이콘 이름. 글자색으로 칠해진다.
  final String? icon;
  final double verticalPadding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      AppButtonVariant.primary => (AppColors.primary, AppColors.onPrimary),
      AppButtonVariant.soft => (AppColors.primarySoft, AppColors.primary),
      AppButtonVariant.surface => (AppColors.surface, AppColors.primary),
      AppButtonVariant.outline => (AppColors.surface, AppColors.textPrimary),
      AppButtonVariant.danger => (AppColors.dangerSoft, AppColors.danger),
    };
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: variant == AppButtonVariant.outline
            ? const BorderSide(color: AppColors.border)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed ?? () {},
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                AppIcon(icon!, size: 20, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: AppText.style(fontSize, FontWeight.w500, fg)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Figma "Header": "‹ 제목" 왼쪽 정렬 + 오른쪽 액션. Scaffold.appBar 로 쓴다.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader(this.title, {super.key, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.bg,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 58,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 20),
              child: Row(
                children: [
                  if (Navigator.canPop(context)) ...[
                    Semantics(
                      button: true,
                      label: '뒤로',
                      child: InkWell(
                        onTap: () => Navigator.maybePop(context),
                        child: Text('‹',
                            style: AppText.style(32).copyWith(height: 1.15)),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(title,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.style(18, FontWeight.w500)),
                  ),
                  ...actions,
                ],
              ),
            ),
          ),
        ),
      );
}

/// 헤더 오른쪽 글자 액션 (본문 오른쪽 선에 맞춘다).
class HeaderTextAction extends StatelessWidget {
  const HeaderTextAction(this.label, {super.key, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(label, style: AppText.style(14, FontWeight.w500, AppColors.primary)),
        ),
      );
}

/// 이름 첫 글자 원형 아바타. [selected]면 primary 2px 테두리.
class LetterAvatar extends StatelessWidget {
  const LetterAvatar(
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
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border:
              selected ? Border.all(color: AppColors.primary, width: 2) : null,
        ),
        child: Text(letter,
            style: AppText.style(
                (size * 0.375).roundToDouble(), FontWeight.w500, color)),
      );
}

/// 흰 radius 16 리스트 행: 아바타 + 제목/부제 + 오른쪽 trailing.
class PersonRow extends StatelessWidget {
  const PersonRow({
    super.key,
    required this.avatar,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Widget avatar;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                avatar,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.style(15, FontWeight.w500)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(subtitle!,
                            style: AppText.style(
                                12, FontWeight.w400, AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      );
}

/// 왼쪽 회색 라벨 · 오른쪽 값 한 줄.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow(
    this.label,
    this.value, {
    super.key,
    this.valueWeight = FontWeight.w500,
    this.valueColor = AppColors.textPrimary,
    this.valueSize = 14,
    this.labelStyle,
  });

  final String label;
  final String value;
  final FontWeight valueWeight;
  final Color valueColor;
  final double valueSize;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => Row(
          children: [
            Expanded(
              child: Text(label,
                  style: labelStyle ??
                      AppText.style(14, FontWeight.w400, AppColors.textSecondary)),
            ),
            const SizedBox(width: 12),
            // 값은 제 폭대로(최대 60%), 남는 폭은 라벨이 쓴다. 금액 옆 라벨이 반 폭에서 줄바꿈되지 않게.
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: c.maxWidth * 0.6),
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: AppText.style(valueSize, valueWeight, valueColor)),
            ),
          ],
        ),
      );
}

/// Figma "Bottom Bar": 흰 배경 + 버튼(들). Scaffold.bottomNavigationBar 로 쓴다.
class BottomBar extends StatelessWidget {
  const BottomBar({super.key, this.child, this.children = const []});

  /// CTA 버튼 하나짜리 바.
  BottomBar.button(String label, {super.key, VoidCallback? onPressed})
      : child = AppButton(label, onPressed: onPressed, verticalPadding: 17),
        children = const [];

  final Widget? child;

  /// 세로로 10 간격을 두고 쌓는다.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final items = [?child, ...children];
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              items[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// 색 배경 안내 문구 박스(info / accent 등).
class NoteBox extends StatelessWidget {
  const NoteBox(this.text,
      {super.key, required this.color, required this.background});

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

/// 완료 화면 상단: 96px 체크 원 + 제목 + 설명.
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
                  color: AppColors.primarySoft, shape: BoxShape.circle),
              child:
                  const Icon(Icons.check_rounded, size: 52, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: AppText.style(22, FontWeight.w500)),
            const SizedBox(height: 12),
            Text(subtitle,
                textAlign: TextAlign.center,
                style:
                    AppText.style(15, FontWeight.w400, AppColors.textSecondary)),
          ],
        ),
      );
}

enum StepStatus { done, current, pending }

/// 진행 단계 한 줄: 24px 원(완료/진행 중/대기) + 제목/설명.
class StepRow extends StatelessWidget {
  const StepRow(this.status, this.title, this.caption, {super.key});

  final StepStatus status;
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: switch (status) {
                StepStatus.done => AppColors.primary,
                StepStatus.current => AppColors.accentSoft,
                StepStatus.pending => AppColors.bg,
              },
              border: status == StepStatus.current
                  ? Border.all(color: AppColors.accent)
                  : null,
            ),
            child: status == StepStatus.done
                ? const Icon(Icons.check, size: 16, color: AppColors.onPrimary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.style(
                    15,
                    FontWeight.w500,
                    status == StepStatus.pending
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(caption,
                    style: AppText.style(
                        12, FontWeight.w400, AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      );
}

/// 라벨(14 bold secondary) + 아래 내용. 값만 보여줄 땐 child 에 [FieldBox].
class LabeledField extends StatelessWidget {
  const LabeledField(this.label, {super.key, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppText.style(14, FontWeight.w500, AppColors.textSecondary)),
          const SizedBox(height: 8),
          child,
        ],
      );
}

/// 흰 배경 · border · radius 14 입력칸 모양. [onTap]을 주면 날짜·시간 선택 등 버튼으로 쓴다.
class FieldBox extends StatelessWidget {
  const FieldBox(this.value, {super.key, this.onTap});

  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(children: [
              Expanded(child: Text(value, style: AppText.style(15))),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
            ]),
          ),
        ),
      );
}

/// [FieldBox]와 같은 모양의 실제 입력칸.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.won = false,
    this.suffix,
  });

  final TextEditingController controller;
  final String? hint;

  /// true 면 숫자만 받고 천 단위 쉼표 + '원' 단위를 붙인다. 값은 `wonDigits` 로 읽는다.
  final bool won;

  /// 입력 칸 오른쪽 단위(예: '시간'). [won] 이면 기본 '원'.
  final String? suffix;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c),
        );
    return TextField(
      controller: controller,
      keyboardType: won ? TextInputType.number : keyboardType,
      inputFormatters: won ? const [WonInputFormatter()] : null,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      style: AppText.style(15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.style(15, FontWeight.w400, AppColors.textTertiary),
        suffixText: suffix ?? (won ? '원' : null),
        suffixStyle: AppText.style(15, FontWeight.w400, AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: border(AppColors.border),
        enabledBorder: border(AppColors.border),
        focusedBorder: border(AppColors.primary),
      ),
    );
  }
}

/// 키보드로 포커스가 올 때만 보이는 초록 링. 안쪽 위젯(InkWell 등)의 포커스를 따라간다.
class FocusRing extends StatefulWidget {
  const FocusRing({super.key, required this.child, this.radius = 12});

  final Widget child;
  final double radius;

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) => Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (v) => setState(() => _focused = v),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            border: _focused &&
                    FocusManager.instance.highlightMode == FocusHighlightMode.traditional
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: widget.child,
        ),
      );
}

/// 금액 입력: 숫자만 남기고 천 단위 쉼표를 넣는다. 커서는 오른쪽에서 센 숫자 개수를 지킨다.
class WonInputFormatter extends TextInputFormatter {
  const WonInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final text = comma(int.parse(digits));
    final after = next.text
        .substring(next.selection.end.clamp(0, next.text.length))
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;
    var offset = text.length, seen = 0;
    while (offset > 0 && seen < after) {
      offset--;
      if (text[offset] != ',') seen++;
    }
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: offset));
  }
}

/// 금액 입력 칸의 초기 텍스트('10,320').
String wonInput(int n) => comma(n);

/// 금액 입력 칸의 값. 비었으면 null.
int? wonDigits(String text) => int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), ''));

/// 상세 화면의 대상이 사라졌을 때(취소·거절·삭제) 보여주는 화면.
class MissingScreen extends StatelessWidget {
  const MissingScreen({super.key, this.title = ''});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppHeader(title),
        body: Center(
          child: Text('삭제되었거나 더 이상 없는 항목이에요',
              style: AppText.style(15, FontWeight.w500, AppColors.textSecondary)),
        ),
        bottomNavigationBar: BottomBar.button('닫기', onPressed: () => Navigator.pop(context)),
      );
}

/// 빈 목록 안내 한 줄.
class EmptyNote extends StatelessWidget {
  const EmptyNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(text,
              textAlign: TextAlign.center,
              style: AppText.style(14, FontWeight.w400, AppColors.textTertiary)),
        ),
      );
}

/// 아이콘 오른쪽 위 빨간 숫자 배지.
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(count > 99 ? '99+' : '$count',
                    style: AppText.style(10, FontWeight.w500, AppColors.onPrimary)
                        .copyWith(height: 1.2)),
              ),
            ),
        ],
      );
}

/// 화면 아래에 짧은 안내를 띄운다. 이미 떠 있는 것은 바로 바꾼다(연달아 누를 때 줄 서지 않게).
void showToast(BuildContext context, String text) =>
    showToastOn(ScaffoldMessenger.of(context), text);

/// 화면을 닫은 뒤에도 쓰도록 messenger 를 미리 잡아 둔 경우.
void showToastOn(ScaffoldMessengerState messenger, String text) => messenger
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text)));

/// 취소 / 확인 두 버튼 다이얼로그. 확인을 누르면 true.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  AppButtonVariant confirmVariant = AppButtonVariant.primary,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.style(18, FontWeight.w500)),
              const SizedBox(height: 8),
              Text(message,
                  style: AppText.style(
                      14, FontWeight.w400, AppColors.textSecondary)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButton('취소',
                        variant: AppButtonVariant.outline,
                        verticalPadding: 13,
                        fontSize: 15,
                        onPressed: () => Navigator.pop(context, false)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(confirmLabel,
                        variant: confirmVariant,
                        verticalPadding: 13,
                        fontSize: 15,
                        onPressed: () => Navigator.pop(context, true)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ) ??
    false;

/// 직원 글자 아바타 (Staff.tone 색).
class MemberAvatar extends StatelessWidget {
  const MemberAvatar(this.staff, {super.key, this.size = 40});

  final Staff staff;
  final double size;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final (fg, bg) = toneColors(staff.tone);
    return LetterAvatar(store.personOf(staff).letter, color: fg, background: bg, size: size);
  }
}

(Color, Color) toneColors(Tone t) => switch (t) {
      Tone.primary => (AppColors.primary, AppColors.primarySoft),
      Tone.accent => (AppColors.accent, AppColors.accentSoft),
      Tone.info => (AppColors.info, AppColors.infoSoft),
      Tone.danger => (AppColors.danger, AppColors.dangerSoft),
    };

/// Figma 토글(48x28, primary 트랙). 탭은 감싼 위젯이 처리.
class AppToggle extends StatelessWidget {
  const AppToggle(this.on, {super.key, this.enabled = true});

  final bool on;
  final bool enabled;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(3),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: !enabled
              ? AppColors.bg
              : on
                  ? AppColors.primary
                  : AppColors.border,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
        ),
      );
}

/// 제목 · 설명 + 오른쪽 토글 카드.
class ToggleCard extends StatelessWidget {
  const ToggleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.flat = false,
  });

  final String title;
  final String subtitle;
  final bool value;

  /// 카드 틀 없이 다른 입력 행과 같은 x 에 놓는다(웹 시트).
  final bool flat;

  /// null 이면 비활성.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => flat
      ? InkWell(
          onTap: onChanged == null ? null : () => onChanged!(!value),
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: _row()),
        )
      : AppCard(
        radius: 16,
        padding: const EdgeInsets.all(20),
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: _row(),
      );

  Widget _row() => Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppText.style(15, FontWeight.w500,
                          onChanged == null ? AppColors.textTertiary : AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AppToggle(value, enabled: onChanged != null),
          ],
        );
}

/// 기간 이동 컨트롤 '‹ [라벨] ›' (월 · 주 · 일 공용). null 이면 그 방향은 비활성.
class PeriodNav extends StatelessWidget {
  const PeriodNav(
      {super.key, required this.label, this.onPrev, this.onNext, this.prevTip = '이전', this.nextTip = '다음'});

  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final String prevTip;
  final String nextTip;

  @override
  Widget build(BuildContext context) {
    Widget arrow(IconData icon, String tip, VoidCallback? on) => IconButton(
          tooltip: tip,
          onPressed: on,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 32, height: 40),
          color: AppColors.textPrimary,
          disabledColor: AppColors.border,
          icon: Icon(icon, size: 24),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      arrow(Icons.chevron_left_rounded, prevTip, onPrev),
      Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Pill(label))),
      arrow(Icons.chevron_right_rounded, nextTip, onNext),
    ]);
  }
}

/// '‹ 5월 ›' 월 이동.
class MonthNav extends StatelessWidget {
  const MonthNav({super.key, required this.month, required this.onChanged, this.max});

  final DateTime month;
  final ValueChanged<DateTime> onChanged;

  /// 이 달 이후로는 못 간다.
  final DateTime? max;

  @override
  Widget build(BuildContext context) {
    final canNext = max == null || DateTime(month.year, month.month + 1).isBefore(
        DateTime(max!.year, max!.month + 1));
    return PeriodNav(
      label: '${month.month}월',
      prevTip: '이전 달',
      nextTip: '다음 달',
      onPrev: () => onChanged(DateTime(month.year, month.month - 1)),
      onNext: canNext ? () => onChanged(DateTime(month.year, month.month + 1)) : null,
    );
  }
}

/// 급여 내역 (급여 탭 · 명세서 공용): '지급 내역' 카드 + '공제 내역' 카드.
class PayBreakdown extends StatelessWidget {
  const PayBreakdown({super.key, required this.slip, required this.staff});

  final Payslip slip;
  final Staff staff;

  @override
  Widget build(BuildContext context) {
    const divider = Divider(height: 1, color: AppColors.border);
    const regular = FontWeight.w500;
    const gap = SizedBox(height: 14);
    final estimate = staff.deduction == Deduction.insurance ? ' · 예상' : '';
    Widget head(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(t, style: AppText.style(15, FontWeight.w500)),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              head('지급 내역'),
              KeyValueRow('기본급 (${hours(slip.minutes)} × ${wonText(staff.wage)})', won(slip.base),
                  valueWeight: regular),
              gap,
              KeyValueRow('주휴수당', won(slip.weeklyHoliday), valueWeight: regular),
              if (slip.premium > 0) ...[
                gap,
                KeyValueRow('야간·연장 가산', won(slip.premium), valueWeight: regular),
              ],
              gap,
              divider,
              gap,
              KeyValueRow('세전 합계', won(slip.gross),
                  labelStyle: AppText.style(14, FontWeight.w500), valueWeight: regular),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              head('공제 내역'),
              KeyValueRow('${staff.deduction.label}$estimate', won(-slip.deduction),
                  valueWeight: regular),
              gap,
              divider,
              gap,
              KeyValueRow('실수령액', won(slip.net),
                  labelStyle: AppText.style(16, FontWeight.w500), valueSize: 18),
            ],
          ),
        ),
      ],
    );
  }
}

/// 보건증 상태. 30일 넘게 남으면 조용한 글자, 임박 · 만료 · 미등록만 칩.
Widget certPill(int? daysLeft) {
  if (daysLeft == null) {
    return const Pill('미등록', color: AppColors.danger, background: AppColors.dangerSoft);
  }
  if (daysLeft < 0) {
    return const Pill('만료됨', color: AppColors.danger, background: AppColors.dangerSoft);
  }
  if (daysLeft > 30) {
    return Text('D-$daysLeft', style: AppText.style(13, FontWeight.w400, AppColors.textSecondary));
  }
  return Pill(daysLeft == 0 ? '만료 D-Day' : '만료 D-$daysLeft',
      color: AppColors.danger, background: AppColors.dangerSoft);
}
