import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
        child: Text(label, style: AppText.style(12, FontWeight.w700, color)),
      );
}

enum AppButtonVariant { primary, soft, surface, outline }

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
              Text(label, style: AppText.style(fontSize, FontWeight.w700, fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 하위 화면 상단 바: 뒤로가기 + 제목 + 오른쪽 액션.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader(this.title, {super.key, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) => AppBar(
        title: Text(title, style: AppText.style(17, FontWeight.w700)),
        centerTitle: true,
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: actions,
      );
}
