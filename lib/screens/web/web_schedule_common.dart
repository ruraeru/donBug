import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_common.dart';

/// 웹 근무표 변형(W2-A~E)이 함께 쓰는 색상·더미 데이터·작은 위젯.
class ScheduleColors {
  static const blueSoft = Color(0xFFEAF1FE);
  static const purple = Color(0xFF8B5CF6);
  static const purpleSoft = Color(0xFFF0EAFE);
}

class WebStaff {
  const WebStaff(this.name, this.color);

  final String name;
  final Color color;

  String get initial => name.substring(0, 1);
}

const webStaff = [
  WebStaff('지민', Color(0xFF1F8A5B)),
  WebStaff('수빈', Color(0xFF3B82F6)),
  WebStaff('하윤', Color(0xFFF5A524)),
  WebStaff('도현', Color(0xFF8B5CF6)),
  WebStaff('서연', Color(0xFF14B8A6)),
];

const webWeekdays = ['월', '화', '수', '목', '금', '토', '일'];

/// 5/12–5/18 주 근무 코드 (직원 순서 = [webStaff]).
/// 'O' 오픈, 'C' 마감, `X<n>` 휴무(월 누적 n), 'S' 대타 구함, 'R' 휴무 신청, 그 외 'HH:MM' 가변 시작.
const webWeekCodes = [
  ['10:00', '10:30', '11:00', 'X2', 'O', 'C', 'X3'],
  ['O', '11:30', '09:00', 'O', 'X2', '10:30', 'C'],
  ['X2', 'O', 'C', '10:00', 'C', '11:30', '11:30'],
  ['09:00', 'X3', 'O', 'C', '11:00', '10:00', 'O'],
  ['C', 'C', 'X2', '11:30', '09:00', 'O', '10:30'],
];

/// 토(5) 파랑, 일(6) 빨강, 평일은 null.
(Color bg, Color fg)? webWeekendColors(int day) => switch (day) {
      5 => (ScheduleColors.blueSoft, AppColors.info),
      6 => (AppColors.dangerSoft, AppColors.danger),
      _ => null,
    };

enum ShiftKind { time, open, close, off, sub, offRequest }

typedef Shift = ({ShiftKind kind, String label, String range, int offCount});

Shift parseShift(String code) => switch (code[0]) {
      'O' => (kind: ShiftKind.open, label: '오픈', range: '07:00–16:00', offCount: 0),
      'C' => (kind: ShiftKind.close, label: '마감', range: '12:00–21:00', offCount: 0),
      'X' => (
          kind: ShiftKind.off,
          label: '휴무',
          range: '',
          offCount: int.parse(code.substring(1)),
        ),
      'S' => (kind: ShiftKind.sub, label: '대타 구함', range: '', offCount: 0),
      'R' => (kind: ShiftKind.offRequest, label: '휴무 신청', range: '', offCount: 0),
      _ => (kind: ShiftKind.time, label: code, range: '$code–${_plus9(code)}', offCount: 0),
    };

/// 가변 시작 근무는 9시간(휴게 포함).
String _plus9(String t) {
  final [h, m] = t.split(':');
  return '${(int.parse(h) + 9).toString().padLeft(2, '0')}:$m';
}

/// 근무 코드 한 칸. [compact]는 월간(D)용 작은 칸.
class WebShiftCell extends StatelessWidget {
  const WebShiftCell(
    this.code, {
    super.key,
    this.width,
    this.height = 42,
    this.showRange = true,
    this.compact = false,
    this.circleBadge = true,
    this.fontSize = 13,
    this.radius = 8,
  });

  final String code;
  final double? width;
  final double height;
  final bool showRange;
  final bool compact;
  final bool circleBadge;
  final double fontSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final s = parseShift(code);
    final (Color bg, Color fg, Color? side) = switch (s.kind) {
      ShiftKind.time => (AppColors.surface, AppColors.textPrimary, AppColors.border),
      ShiftKind.open => (AppColors.primarySoft, AppColors.primary, null),
      ShiftKind.close => (ScheduleColors.blueSoft, AppColors.info, null),
      ShiftKind.off => (AppColors.border, AppColors.textSecondary, null),
      ShiftKind.sub => (AppColors.accentSoft, AppColors.accent, null),
      ShiftKind.offRequest => (AppColors.dangerSoft, AppColors.danger, AppColors.danger),
    };
    final weight = s.kind == ShiftKind.off ? FontWeight.w500 : FontWeight.w700;

    final Widget content;
    if (compact) {
      content = Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.label, style: AppText.style(fontSize, weight, fg)),
            if (s.offCount > 0) ...[
              const SizedBox(width: 4),
              Text('${s.offCount}', style: AppText.style(8, FontWeight.w500, fg)),
            ],
          ],
        ),
      );
    } else {
      content = Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.label, style: AppText.style(fontSize, weight, fg)),
                if (showRange && s.range.isNotEmpty)
                  Text(
                    s.range,
                    style: AppText.style(
                      10,
                      FontWeight.w400,
                      s.kind == ShiftKind.time ? AppColors.textTertiary : fg,
                    ),
                  ),
              ],
            ),
          ),
          if (s.offCount > 0)
            Positioned(
              top: circleBadge ? 4 : 2,
              right: circleBadge ? 6 : 8,
              child: circleBadge
                  ? Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Text('${s.offCount}',
                          style: AppText.style(10, FontWeight.w700, fg)),
                    )
                  : Text('${s.offCount}',
                      style: AppText.style(9, FontWeight.w700, fg)),
            ),
        ],
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        // shortcut: 휴무 신청은 Figma에서 점선 테두리, 여기선 실선.
        border: side == null ? null : Border.all(color: side),
      ),
      child: content,
    );
  }
}

class StaffAvatar extends StatelessWidget {
  const StaffAvatar(this.staff, {super.key, this.size = 34, this.solid = false});

  final WebStaff staff;
  final double size;
  final bool solid;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: solid ? staff.color : staff.color.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Text(
          staff.initial,
          style: AppText.style(
            size * 0.41,
            FontWeight.w700,
            solid ? AppColors.onPrimary : staff.color,
          ),
        ),
      );
}

/// 흰 테두리 박스 안의 세그먼트 탭.
class WebSegmented extends StatelessWidget {
  const WebSegmented({
    super.key,
    required this.labels,
    required this.selected,
    this.onChanged,
    this.itemWidth = 56,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int>? onChanged;

  /// null이면 글자 폭 + 좌우 14.
  final double? itemWidth;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              GestureDetector(
                onTap: onChanged == null ? null : () => onChanged!(i),
                child: Container(
                  height: 32,
                  width: itemWidth,
                  padding: itemWidth == null
                      ? const EdgeInsets.symmetric(horizontal: 14)
                      : null,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    labels[i],
                    style: AppText.style(
                      13,
                      FontWeight.w700,
                      i == selected ? AppColors.onPrimary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}

/// "근무표" 제목 + 부제 + 보조 버튼 + 게시하기.
class WebScheduleHeader extends StatelessWidget {
  const WebScheduleHeader({super.key, required this.subtitle, required this.action});

  final String subtitle;
  final String action;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('근무표', style: AppText.style(28, FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: AppText.style(14, FontWeight.w400, AppColors.textSecondary)),
              ],
            ),
          ),
          WebButton(action, style: WebButtonStyle.outline),
          const SizedBox(width: 10),
          const WebButton('게시하기'),
        ],
      );
}

/// 날짜 이동 + 보기 모드 + 오른쪽 칩.
class WebScheduleToolbar extends StatelessWidget {
  const WebScheduleToolbar({
    super.key,
    required this.dateLabel,
    required this.modes,
    required this.selectedMode,
    this.chips = const [],
  });

  final String dateLabel;
  final List<String> modes;
  final int selectedMode;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 40,
        child: Row(
          children: [
            const _NavButton('‹'),
            const SizedBox(width: 4),
            SizedBox(
              width: 150,
              child: Text(dateLabel,
                  textAlign: TextAlign.center,
                  style: AppText.style(16, FontWeight.w700)),
            ),
            const SizedBox(width: 4),
            const _NavButton('›'),
            const SizedBox(width: 12),
            WebSegmented(labels: modes, selected: selectedMode),
            const Spacer(),
            for (var i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              chips[i],
            ],
          ],
        ),
      );
}

class _NavButton extends StatelessWidget {
  const _NavButton(this.glyph);

  final String glyph;

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(glyph,
            style: AppText.style(20, FontWeight.w400, AppColors.textSecondary)
                .copyWith(height: 1)),
      );
}

/// 회색 칩.
class WebGreyChip extends StatelessWidget {
  const WebGreyChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) =>
      Pill(label, color: AppColors.textSecondary, background: AppColors.bg);
}

/// 범례 한 칸: 14px 색 상자 + 라벨.
class WebLegend extends StatelessWidget {
  const WebLegend(this.color, this.label, {super.key, this.borderColor});

  final Color color;
  final String label;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: borderColor == null ? null : Border.all(color: borderColor!),
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
        ],
      );
}
