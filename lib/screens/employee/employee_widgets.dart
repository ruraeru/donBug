import 'package:flutter/material.dart';

import '../../theme.dart';

/// Figma danger / info 변수 (theme.dart 에 토큰 없음).
const kDanger = Color(0xFFE5484D);
const kDangerSoft = Color(0xFFFDECEC);
const kInfo = Color(0xFF3B82F6);
const kInfoSoft = Color(0xFFE8F0FE);

/// 40px 원 안에 한 글자.
class LetterAvatar extends StatelessWidget {
  const LetterAvatar(this.letter, {super.key, required this.color, required this.background});

  final String letter;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Text(letter, style: AppText.style(15, FontWeight.w700, color)),
      );
}

/// 흰 radius 16 행: 아바타 + 제목/부제 + 오른쪽 trailing.
class AvatarRow extends StatelessWidget {
  const AvatarRow({
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
                      Text(title, style: AppText.style(15, FontWeight.w700)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
          ),
        ),
      );
}

/// 24px 초록 원 체크 + 라벨.
class CheckLine extends StatelessWidget {
  const CheckLine(this.label, {super.key, this.caption});

  final String label;
  final String? caption;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 16, color: AppColors.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.style(15, FontWeight.w500)),
                if (caption != null)
                  Text(caption!, style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      );
}

/// Figma "Bottom Bar": 흰 배경 + 버튼. Scaffold.bottomNavigationBar 로 쓴다.
class BottomBar extends StatelessWidget {
  const BottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: SafeArea(top: false, child: child),
      );
}
