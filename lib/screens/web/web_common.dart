import 'package:flutter/material.dart';

import '../../theme.dart';

/// 웹 콘텐츠 영역 공통 틀: 제목/부제 + 오른쪽 액션, 아래로 스크롤되는 본문.
class WebPage extends StatelessWidget {
  const WebPage({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    required this.children,
    this.gap = 20,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 12,
              spacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AppText.style(28, FontWeight.w700)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!,
                          style: AppText.style(
                              14, FontWeight.w400, AppColors.textSecondary)),
                    ],
                  ],
                ),
                Wrap(spacing: 10, runSpacing: 10, children: actions),
              ],
            ),
            for (final c in children) ...[SizedBox(height: gap), c],
          ],
        ),
      );
}

enum WebButtonStyle { primary, outline, dark, soft }

/// 높이 42 · radius 12 버튼(가로 폭은 글자에 맞춤).
class WebButton extends StatelessWidget {
  const WebButton(
    this.label, {
    super.key,
    this.style = WebButtonStyle.primary,
    this.onPressed,
    this.height = 42,
    this.fontSize = 14,
    this.radius = 12,
  });

  final String label;
  final WebButtonStyle style;
  final VoidCallback? onPressed;
  final double height;
  final double fontSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (style) {
      WebButtonStyle.primary => (AppColors.primary, AppColors.onPrimary),
      WebButtonStyle.outline => (AppColors.surface, AppColors.textPrimary),
      WebButtonStyle.dark => (AppColors.textPrimary, AppColors.surface),
      WebButtonStyle.soft => (AppColors.primarySoft, AppColors.primary),
    };
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: style == WebButtonStyle.outline
            ? const BorderSide(color: AppColors.border)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed ?? () {},
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          child: Text(label, style: AppText.style(fontSize, FontWeight.w700, fg)),
        ),
      ),
    );
  }
}

/// radius 10 태그(근무 시간·상태 등).
class WebTag extends StatelessWidget {
  const WebTag(
    this.label, {
    super.key,
    this.color = AppColors.primary,
    this.background = AppColors.primarySoft,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.radius = 10,
    this.border,
  });

  final String label;
  final Color color;
  final Color background;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? border;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
          border: border == null ? null : Border.all(color: border!),
        ),
        child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.style(fontSize, FontWeight.w700, color)),
      );
}

/// 이니셜 원형 아바타.
class WebAvatar extends StatelessWidget {
  const WebAvatar(
    this.letter, {
    super.key,
    this.color = AppColors.primary,
    this.background = AppColors.primarySoft,
    this.size = 32,
  });

  final String letter;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Text(letter,
            style: AppText.style(size * 0.44, FontWeight.w700, color)),
      );
}

/// 좌(가변) · 우(고정 폭) 2단. [leftWidth] 를 주면 좌가 고정 · 우가 가변.
/// 창이 좁으면 위아래로 쌓는다.
class WebSplit extends StatelessWidget {
  const WebSplit({
    super.key,
    required this.left,
    required this.right,
    this.rightWidth = 380,
    this.leftWidth,
    this.gap = 16,
    this.breakpoint = 900,
  });

  final Widget left;
  final Widget right;
  final double rightWidth;
  final double? leftWidth;
  final double gap;
  final double breakpoint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => c.maxWidth >= breakpoint
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: leftWidth == null
                    ? [
                        Expanded(child: left),
                        SizedBox(width: gap),
                        SizedBox(width: rightWidth, child: right),
                      ]
                    : [
                        SizedBox(width: leftWidth, child: left),
                        SizedBox(width: gap),
                        Expanded(child: right),
                      ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [left, SizedBox(height: gap), right],
              ),
      );
}

/// 같은 폭으로 나란히 놓되, 좁으면 줄바꿈되는 카드 행(KPI 등).
class WebRow extends StatelessWidget {
  const WebRow({
    super.key,
    required this.children,
    this.gap = 16,
    this.minItemWidth = 200,
  });

  final List<Widget> children;
  final double gap;
  final double minItemWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final perRow = ((c.maxWidth + gap) / (minItemWidth + gap))
            .floor()
            .clamp(1, children.length);
        // floor: 소수점 오차로 마지막 칸이 줄바꿈되는 것 방지.
        final w = ((c.maxWidth - gap * (perRow - 1)) / perRow).floorToDouble();
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final child in children) SizedBox(width: w, child: child)],
        );
      });
}

/// 회색 헤더 행 + 구분선 행 표. [flex] 는 Figma 열 폭 비율.
class WebTable extends StatelessWidget {
  const WebTable({
    super.key,
    required this.columns,
    required this.flex,
    required this.rows,
    this.rowHeight = 64,
  });

  final List<String> columns;
  final List<int> flex;
  final List<List<Widget>> rows;
  final double rowHeight;

  Widget _row(List<Widget> cells, double height, {Color? bg}) => Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: bg == null
            ? null
            : BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: flex[i],
              child: Align(alignment: Alignment.centerLeft, child: cells[i]),
            ),
        ]),
      );

  @override
  Widget build(BuildContext context) => Column(children: [
        _row([
          for (final c in columns)
            Text(c,
                maxLines: 1,
                style: AppText.style(12, FontWeight.w700, AppColors.textSecondary)),
        ], 40, bg: AppColors.bg),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.border),
          _row(rows[i], rowHeight),
        ],
      ]);
}

/// 표 안의 회색 본문 글자.
Widget webCellText(String s, {Color color = AppColors.textSecondary, FontWeight weight = FontWeight.w400}) =>
    Text(s, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.style(14, weight, color));

/// 표 첫 열: 이니셜 아바타 + 굵은 이름.
Widget webNameCell(String name, Color color, Color background) => Row(children: [
      WebAvatar(name.substring(0, 1), color: color, background: background),
      const SizedBox(width: 8),
      Flexible(
          child: webCellText(name, color: AppColors.textPrimary, weight: FontWeight.w700)),
    ]);
