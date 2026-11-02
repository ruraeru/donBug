import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';

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

/// 날짜 + 칩 / 큰 시간 / 설명 카드 (근무 상세, 대타 상세).
class ShiftHeroCard extends StatelessWidget {
  const ShiftHeroCard({
    super.key,
    required this.date,
    required this.chip,
    required this.time,
    required this.caption,
  });

  final String date;
  final String chip;
  final String time;
  final String caption;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(date, style: AppText.style(22, FontWeight.w700))),
                Pill.accent(chip),
              ],
            ),
            const SizedBox(height: 12),
            Text(time, style: AppText.style(30, FontWeight.w700)),
            const SizedBox(height: 12),
            Text(caption,
                style:
                    AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
          ],
        ),
      );
}

/// 탭 루트 화면 상단: 큰 제목 + 오른쪽 칩.
class TabTitle extends StatelessWidget {
  const TabTitle(this.title, {super.key, this.chip});

  final String title;
  final String? chip;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(child: Text(title, style: AppText.style(24, FontWeight.w700))),
            if (chip != null) Pill(chip!),
          ],
        ),
      );
}
