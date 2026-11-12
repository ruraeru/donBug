import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../employer/employer_parts.dart';

/// 웹 콘텐츠 영역 좌우 여백: 넓으면 32, 좁으면 20.
double webGutter(double width) => width >= 1100 ? 32 : 20;

/// 웹 콘텐츠 영역 공통 틀: 제목/부제 + 오른쪽 액션, 아래로 스크롤되는 본문.
/// 한 줄에 들어가지 않으면 액션이 제목 아래로 내려간다.
class WebPage extends StatelessWidget {
  const WebPage({
    super.key,
    required this.title,
    this.titleWidget,
    this.subtitle,
    this.actions = const [],
    required this.children,
    this.gap = 20,
  });

  final String title;

  /// 제목 자리를 바꿀 때(예: ‹ 근무표 · 11월 › ). 없으면 [title].
  final Widget? titleWidget;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final pad = webGutter(c.maxWidth);
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            titleWidget ?? Text(title, style: AppText.style(28, FontWeight.w500)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  style: AppText.style(14, FontWeight.w400, AppColors.textSecondary)),
            ],
          ],
        );
        final bar = Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: actions,
        );
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad, 28, pad, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 제목과 액션이 한 줄에 들어가면 양 끝, 아니면 액션이 아래 줄로.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 14,
                children: [heading, if (actions.isNotEmpty) bar],
              ),
              for (final child in children) ...[SizedBox(height: gap), child],
            ],
          ),
        );
      });
}

enum WebButtonStyle { primary, outline, dark, soft, danger }

/// 높이 42 · radius 12 버튼. 폭은 글자에 맞춘다. [onPressed]가 null 이면 비활성.
class WebButton extends StatelessWidget {
  const WebButton(
    this.label, {
    super.key,
    this.style = WebButtonStyle.primary,
    this.onPressed,
    this.height = 42,
    this.fontSize = 14,
    this.radius = 12,
    this.expand = false,
    this.tooltip,
    this.icon,
  });

  final String label;
  final WebButtonStyle style;
  final VoidCallback? onPressed;
  final double height;
  final double fontSize;
  final double radius;

  /// 가로로 꽉 채울지.
  final bool expand;
  final String? tooltip;

  /// 글자 대신 아이콘(정사각 버튼). [label]은 접근성 이름으로 쓴다.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    var (bg, fg) = switch (style) {
      WebButtonStyle.primary => (AppColors.primary, AppColors.onPrimary),
      WebButtonStyle.outline => (AppColors.surface, AppColors.textPrimary),
      WebButtonStyle.dark => (AppColors.textPrimary, AppColors.surface),
      WebButtonStyle.soft => (AppColors.primarySoft, AppColors.primary),
      WebButtonStyle.danger => (AppColors.surface, AppColors.danger),
    };
    if (!enabled) (bg, fg) = (AppColors.surface, AppColors.textTertiary);
    final side = switch (style) {
      _ when !enabled => const BorderSide(color: AppColors.border),
      WebButtonStyle.outline => const BorderSide(color: AppColors.border),
      WebButtonStyle.danger => const BorderSide(color: AppColors.border),
      _ => BorderSide.none,
    };
    final button = Material(
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: side),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: height,
          width: expand ? double.infinity : null,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: icon == null ? 18 : (height - 20) / 2),
            child: Center(
              widthFactor: 1,
              child: icon == null
                  ? Text(label, maxLines: 1, style: AppText.style(fontSize, FontWeight.w500, fg))
                  : Icon(icon, size: 20, color: fg, semanticLabel: label),
            ),
          ),
        ),
      ),
    );
    final ringed = FocusRing(radius: radius, child: button);
    return tooltip == null ? ringed : Tooltip(message: tooltip!, child: ringed);
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
    this.maxLines = 1,
  });

  final String label;
  final int maxLines;
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
            maxLines: maxLines,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppText.style(fontSize, FontWeight.w500, color)),
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
    this.breakpoint = 960,
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
/// 한 줄에 [children] 수 · 그 절반 · 1개 중 들어가는 가장 많은 수로 놓아 어색한 3+1 배치를 피한다.
class WebRow extends StatelessWidget {
  const WebRow({
    super.key,
    required this.children,
    this.gap = 16,
    this.minItemWidth = 220,
  });

  final List<Widget> children;
  final double gap;
  final double minItemWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final n = children.length;
        final fits = ((c.maxWidth + gap) / (minItemWidth + gap)).floor();
        final perRow = fits >= n ? n : (fits >= (n / 2).ceil() ? (n / 2).ceil() : 1);
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
/// 폭이 [minWidth] 보다 좁으면 가로로 스크롤한다.
class WebTable extends StatelessWidget {
  const WebTable({
    super.key,
    required this.columns,
    required this.flex,
    required this.rows,
    this.rowHeight = 64,
    this.onRowTap,
    this.minWidth = 640,
    this.numeric = const {},
  });

  final List<String> columns;

  /// 오른쪽 정렬할 숫자 열 번호(금액·시간).
  final Set<int> numeric;
  final List<int> flex;
  final List<List<Widget>> rows;
  final double rowHeight;
  final double minWidth;

  /// 행을 누르면 그 행 번호로 불린다.
  final ValueChanged<int>? onRowTap;

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
              child: numeric.contains(i)
                  ? Padding(
                      padding: EdgeInsets.only(right: i == cells.length - 1 ? 0 : 16),
                      child: Align(alignment: Alignment.centerRight, child: cells[i]),
                    )
                  : Align(alignment: Alignment.centerLeft, child: cells[i]),
            ),
        ]),
      );

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final table = Column(children: [
          _row([
            for (final col in columns)
              Text(col,
                  maxLines: 1,
                  style: AppText.style(12, FontWeight.w500, AppColors.textSecondary)),
          ], 40, bg: AppColors.bg),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.border),
            onRowTap == null
                ? _row(rows[i], rowHeight)
                : FocusRing(
                    radius: 0, child: InkWell(onTap: () => onRowTap!(i), child: _row(rows[i], rowHeight))),
          ],
        ]);
        if (c.maxWidth >= minWidth) return table;
        return HScroll(width: minWidth, child: table);
      });
}

/// 좁을 때 쓰는 가로 스크롤. 스크롤바를 늘 보여 줘서 옆으로 더 있다는 단서를 준다.
class HScroll extends StatefulWidget {
  const HScroll({super.key, required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  State<HScroll> createState() => _HScrollState();
}

class _HScrollState extends State<HScroll> {
  final _c = ScrollController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
        controller: _c,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _c,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(width: widget.width, child: widget.child),
        ),
      );
}

/// 표 안의 회색 본문 글자.
Widget webCellText(String s,
        {Color color = AppColors.textSecondary, FontWeight weight = FontWeight.w400}) =>
    Text(s, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.style(14, weight, color));

/// 파트 칸: 파트 색 점 + 이름. 파트 색은 근무표와 같다(오픈 초록 · 미들 파랑 · 마감 주황 · 직원 보라).
Widget webPartCell(String part, [String? label]) => Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: partColors(part).$1, shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Flexible(child: webCellText(label ?? part)),
    ]);

/// 표 첫 열: 직원 아바타 + 굵은 이름.
Widget webStaffCell(AppStore store, Staff s) => Row(children: [
      MemberAvatar(s, size: 32),
      const SizedBox(width: 8),
      Flexible(
          child: webCellText(store.personOf(s).name,
              color: AppColors.textPrimary, weight: FontWeight.w500)),
    ]);

/// 카드 제목 줄: 제목 + 오른쪽 위젯.
Widget webCardTitle(String title, {Widget? trailing}) => Row(children: [
      Expanded(child: Text(title, style: AppText.style(16, FontWeight.w500))),
      ?trailing,
    ]);

/// 흰 테두리 박스 안의 세그먼트 탭.
class WebSegmented extends StatelessWidget {
  const WebSegmented({
    super.key,
    required this.labels,
    required this.selected,
    this.onChanged,
    this.itemWidth,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int>? onChanged;

  /// null이면 글자 폭 + 좌우 14.
  final double? itemWidth;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Material(
                color: i == selected ? AppColors.primarySoft : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: onChanged == null ? null : () => onChanged!(i),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 32,
                    width: itemWidth,
                    padding:
                        itemWidth == null ? const EdgeInsets.symmetric(horizontal: 14) : null,
                    alignment: Alignment.center,
                    child: Text(
                      labels[i],
                      style: AppText.style(
                        13,
                        FontWeight.w500,
                        i == selected ? AppColors.primary : AppColors.textSecondary,
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

/// 범례 한 칸: 색 점 + 라벨. [dashed] 면 빨간 점선 원.
class WebLegend extends StatelessWidget {
  const WebLegend(this.color, this.label, {super.key, this.dashed = false});

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dashed
              ? CustomPaint(
                  size: const Size(10, 10),
                  painter: DashedBorderPainter(color: color, radius: 5, dash: 2, gap: 2))
              : Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                ),
          const SizedBox(width: 6),
          Text(label, style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
        ],
      );
}

/// 둥근 사각형 점선 테두리(시간 미정 블록).
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter(
      {required this.color, this.radius = 8, this.dash = 5, this.gap = 3, this.width = 1.2});

  final Color color;
  final double radius, dash, gap, width;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += dash + gap) {
        canvas.drawPath(m.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) => old.color != color;
}

/// Figma "근무 추가 창" 스타일 대화상자: 제목 + 닫기, 본문, 아래 버튼.
/// [builder] 는 다이얼로그 안에서 setState 를 쓸 수 있게 StatefulBuilder 로 감싼다.
Future<T?> showWebDialog<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext context, StateSetter setState) builder,
  List<Widget> Function(BuildContext context, StateSetter setState)? actions,
  Widget Function(BuildContext context, StateSetter setState)? leading,
  double width = 460,
}) =>
    showDialog<T>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
                  child: Row(children: [
                    Expanded(child: Text(title, style: AppText.style(18, FontWeight.w500))),
                    IconButton(
                      tooltip: '닫기',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                    ),
                  ]),
                ),
                const Divider(height: 1, color: AppColors.border),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: builder(context, setState),
                  ),
                ),
                if (actions != null) ...[
                  const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                    child: Row(children: [
                      if (leading != null) leading(context, setState),
                      const Spacer(),
                      for (final (i, a) in actions(context, setState).indexed) ...[
                        if (i > 0) const SizedBox(width: 8),
                        a,
                      ],
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

/// 오른쪽에서 밀려 나오는 시트(직원 상세 등). 폭은 [width], 좁은 창에서는 화면 폭.
Future<T?> showWebSheet<T>(BuildContext context,
        {required String title, required WidgetBuilder builder, double width = 480}) =>
    showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, _) => Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: AppColors.bg,
          child: SizedBox(
            width: width,
            height: double.infinity,
            child: SafeArea(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
                  child: Row(children: [
                    Expanded(child: Text(title, style: AppText.style(18, FontWeight.w500))),
                    IconButton(
                      tooltip: '닫기',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                    ),
                  ]),
                ),
                const Divider(height: 1, color: AppColors.border),
                Expanded(child: builder(context)),
              ]),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, a, _, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );

/// [FieldBox] 모양 드롭다운.
class WebSelect<T> extends StatelessWidget {
  const WebSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        padding: const EdgeInsets.only(left: 14, right: 8),
        decoration: BoxDecoration(
          color: enabled ? AppColors.surface : AppColors.bg,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            borderRadius: BorderRadius.circular(12),
            dropdownColor: AppColors.surface,
            // DropdownButton 의 style 은 테마 글꼴을 물려받지 않아 주변 스타일과 합친다.
            style: DefaultTextStyle.of(context).style.merge(AppText.style(
                15, FontWeight.w400, enabled ? AppColors.textPrimary : AppColors.textSecondary)),
            items: [
              for (final (v, label) in items)
                DropdownMenuItem<T>(value: v, child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: enabled ? (v) => v == null ? null : onChanged(v) : null,
          ),
        ),
      );
}

/// 다이얼로그 안 두 칸 나란히(출근/퇴근 등).
Widget webPair(Widget a, Widget b) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: a),
      const SizedBox(width: 12),
      Expanded(child: b),
    ]);

/// 다이얼로그 라벨 + 칸 (+ 아래 작은 안내).
Widget webField(String label, Widget child, {String? help}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.style(13, FontWeight.w500)),
        const SizedBox(height: 8),
        child,
        if (help != null) ...[
          const SizedBox(height: 6),
          Text(help, style: AppText.style(11, FontWeight.w400, AppColors.textTertiary)),
        ],
      ],
    );
