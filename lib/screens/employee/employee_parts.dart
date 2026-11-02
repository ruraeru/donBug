import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';

/// 라벨 ··· 값 한 줄 (급여 내역, 내 상황 확인 등).
class KvRow extends StatelessWidget {
  const KvRow(
    this.label,
    this.value, {
    super.key,
    this.valueWeight = FontWeight.w700,
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
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(label,
                style: labelStyle ??
                    AppText.style(14, FontWeight.w400, AppColors.textSecondary)),
          ),
          const SizedBox(width: 12),
          Text(value, style: AppText.style(valueSize, valueWeight, valueColor)),
        ],
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
                    FontWeight.w700,
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

/// 색 배경 안내 박스 (info / accent).
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

/// 완료 화면 상단: 96px 체크 원 + 제목 + 설명.
class DoneHero extends StatelessWidget {
  const DoneHero({super.key, required this.title, required this.subtitle});

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
              child: const Icon(Icons.check, size: 52, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: AppText.style(22, FontWeight.w700)),
            const SizedBox(height: 12),
            Text(subtitle,
                textAlign: TextAlign.center,
                style:
                    AppText.style(15, FontWeight.w400, AppColors.textSecondary)),
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
