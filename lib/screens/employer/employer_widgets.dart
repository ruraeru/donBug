import 'package:flutter/material.dart';

import '../../theme.dart';

/// Figma 변수 중 theme.dart 에 없는 색(danger/info).
class EmpColors {
  static const danger = Color(0xFFE5484D);
  static const dangerSoft = Color(0xFFFDECEC);
  static const info = Color(0xFF3B82F6);
  static const infoSoft = Color(0xFFE8F0FE);
}

/// 이름 첫 글자 원형 아바타(40).
class InitialAvatar extends StatelessWidget {
  const InitialAvatar(
    this.initial, {
    super.key,
    this.color = AppColors.primary,
    this.background = AppColors.primarySoft,
  });

  final String initial;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Text(initial, style: AppText.style(15, FontWeight.w700, color)),
      );
}

/// 흰 배경 radius 16 리스트 행(아바타 + 제목/부제 + trailing).
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
                      Text(title, style: AppText.style(15, FontWeight.w700)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle!,
                          style: AppText.style(
                              12, FontWeight.w400, AppColors.textSecondary),
                        ),
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

/// 왼쪽 회색 라벨 · 오른쪽 굵은 값.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(label,
              style: AppText.style(14, FontWeight.w400, AppColors.textSecondary)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppText.style(14, FontWeight.w700),
            ),
          ),
        ],
      );
}

/// 화면 하단 흰 바(버튼 영역).
class BottomBar extends StatelessWidget {
  const BottomBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                children[i],
              ],
            ],
          ),
        ),
      );
}
