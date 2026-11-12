import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../employer/employer_parts.dart';
import 'web_common.dart';
import 'web_shift_dialog.dart';

/// 토 파랑 · 일 빨강 · 평일 기본.
Color dayColor(DateTime d, [Color normal = AppColors.textPrimary]) => switch (d.weekday) {
      6 => AppColors.info,
      7 => AppColors.danger,
      _ => normal,
    };

/// 유동 근무 칸인지(파트 템플릿에 없는 파트).
bool isFlexShift(AppStore store, Shift s) => !store.store.parts.any((p) => p.name == s.part);

/// 블록 색: (막대, 배경).
(Color, Color) blockColors(AppStore store, Shift s) {
  if (s.kind != ShiftKind.work) return (AppColors.textTertiary, AppColors.bg);
  if (isFlexShift(store, s)) return (AppColors.purple, AppColors.purpleSoft);
  return partColors(s.part);
}

String _hourText(int minutes) => hours(minutes).replaceAll('h', '');

/// 근무 블록 한 개(Figma 근무표/ShiftBlock). 누르면 수정 창, 끌면 다른 칸으로 이동.
class ShiftBlock extends StatelessWidget {
  const ShiftBlock(this.shift, {super.key, this.dense = false});

  final Shift shift;

  /// 파트 이름 대신 시간을 제목으로(유동 근무 · 인원별 보기).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final s = shift;
    final (bar, bg) = blockColors(store, s);
    final flex = isFlexShift(store, s);
    final sub = store.pendingSubFor(s.id) != null;
    final span = s.endAbs - s.startMin;
    final (title, caption, titleColor) = switch (s) {
      Shift(timeTbd: true) => ('시간 미정', '추천 ${_short(s.startMin)}–${_short(s.endMin)}시', AppColors.danger),
      Shift(kind: ShiftKind.leave) => ('연차', '${_hourText(span - s.breakMin)}h 유급', AppColors.textSecondary),
      Shift(kind: ShiftKind.off) => ('휴무', '', AppColors.textSecondary),
      _ when flex || dense && flex => (
          '${hm(s.startMin)}–${hm(s.endMin)}',
          '${_hourText(span)}h · 휴게 ${s.breakMin >= 60 ? '${s.breakMin ~/ 60}h' : '${s.breakMin}분'}',
          AppColors.textPrimary
        ),
      _ => (s.part, '${hm(s.startMin)}–${hm(s.endMin)}${sub ? ' · 대타 모집' : ''}', AppColors.textPrimary),
    };
    final body = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
      decoration: BoxDecoration(
        color: s.timeTbd ? AppColors.surface : bg,
        borderRadius: BorderRadius.circular(8),
        border: s.timeTbd ? null : Border(left: BorderSide(color: sub ? AppColors.accent : bar, width: 3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.style(12, FontWeight.w500, titleColor)),
        if (caption.isNotEmpty)
          Text(caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.style(11, FontWeight.w400, AppColors.textSecondary)),
      ]),
    );
    final block = s.timeTbd
        ? CustomPaint(
            foregroundPainter: const DashedBorderPainter(color: AppColors.danger), child: body)
        : body;
    final tappable = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => showShiftDialog(context, shift: s, date: parseYmd(s.date)),
        child: block,
      ),
    );
    return Draggable<String>(
      data: s.id,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 130, child: Opacity(opacity: 0.9, child: block)),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: block),
      child: tappable,
    );
  }
}

String _short(int m) => m % 60 == 0 ? '${(m ~/ 60) % 24}' : hm(m);

/// 칸: 비어 있는 곳을 누르면 추가, 블록을 놓으면 이동.
class _Cell extends StatelessWidget {
  const _Cell({
    required this.day,
    required this.onAdd,
    required this.onDrop,
    required this.children,
    this.highlight = false,
  });

  final DateTime day;
  final VoidCallback? onAdd;
  final ValueChanged<String> onDrop;
  final List<Widget> children;
  final bool highlight;

  @override
  Widget build(BuildContext context) => DragTarget<String>(
        onAcceptWithDetails: (e) => onDrop(e.data),
        builder: (context, hover, _) => InkWell(
          onTap: onAdd,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.all(6),
            color: hover.isNotEmpty
                ? AppColors.primarySoft
                : highlight
                    ? AppColors.dangerSoft.withValues(alpha: 0.5)
                    : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, c) in children.indexed) ...[if (i > 0) const SizedBox(height: 6), c],
              ],
            ),
          ),
        ),
      );
}

/// 블록 위 이름 + 블록.
Widget _named(AppStore store, Shift s) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(store.personOf(store.staffById(s.staffId)!).fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.style(11, FontWeight.w400, AppColors.textSecondary)),
        const SizedBox(height: 3),
        ShiftBlock(s),
      ],
    );

/// 표 틀: 흰 카드 + 머리 행 + 행들(세로 구분선).
class _Grid extends StatelessWidget {
  const _Grid({required this.labelWidth, required this.header, required this.rows});

  final double labelWidth;
  final List<Widget> header; // [라벨, 요일 7개]
  final List<List<Widget>> rows; // 각 행: [라벨, 칸 7개] · 길이 1이면 그룹 머리 행

  @override
  Widget build(BuildContext context) {
    const line = BorderSide(color: AppColors.border);
    Widget row(List<Widget> cells, {Color? bg}) => IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(width: labelWidth, child: cells.first),
            for (final c in cells.skip(1))
              Expanded(
                child: DecoratedBox(
                    decoration: const BoxDecoration(border: Border(left: line)), child: c),
              ),
          ]),
        );
    return LayoutBuilder(builder: (context, c) {
      final grid = Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          row(header),
          for (final r in rows) ...[
            const Divider(height: 1, color: AppColors.border),
            if (r.length == 1) ColoredBox(color: AppColors.bg, child: r.first) else row(r),
          ],
        ]),
      );
      // 7칸이 너무 좁아지면 가로 스크롤.
      final min = labelWidth + 7 * 110;
      return c.maxWidth >= min
          ? grid
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal, child: SizedBox(width: min, child: grid));
    });
  }
}

Widget _dayHead(AppStore store, DateTime d) => Container(
      height: 44,
      alignment: Alignment.center,
      color: d == store.today ? AppColors.primarySoft : null,
      child: Text('${weekday(d)} ${d.month}/${d.day}',
          style: AppText.style(13, FontWeight.w500, dayColor(d))),
    );

Widget _labelHead(String text) => Container(
      height: 44,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(text, style: AppText.style(12, FontWeight.w500, AppColors.textSecondary)),
    );

/// 이동 처리 공통: 문제가 있으면 토스트, 아니면 [apply].
void _drop(BuildContext context, String shiftId, DateTime day,
    {String? staffId, PartTemplate? part}) {
  final store = AppScope.read(context);
  final s = store.shiftById(shiftId);
  if (s == null) return;
  final problem = moveProblem(store, s,
      day: day, staffId: staffId, start: part?.startMin, end: part?.endMin);
  if (problem != null) return showToast(context, problem);
  store.updateShift(shiftId,
      date: day,
      staffId: staffId,
      part: part?.name,
      startMin: part?.startMin,
      endMin: part?.endMin);
}

/// 파트별 보기 (Figma 151:9517): 파트 행 + 유동 근무 행 × 요일.
class PartWeekView extends StatelessWidget {
  const PartWeekView({super.key, required this.monday});

  final DateTime monday;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final days = [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
    Widget partLabel(Color color, String name, String caption) => Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 4, height: 34, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(name, style: AppText.style(15, FontWeight.w500)),
                Text(caption, style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
              ]),
            ),
          ]),
        );
    return _Grid(
      labelWidth: 190,
      header: [_labelHead('파트'), for (final d in days) _dayHead(store, d)],
      rows: [
        for (final p in store.store.parts)
          [
            partLabel(partColors(p.name).$1, p.name, '${range(p.startMin, p.endMin)} · 필요 ${p.need}명'),
            for (final d in days)
              Builder(builder: (context) {
                final list = store.scheduleOn(d).where((s) => s.part == p.name).toList();
                final working = list.where((s) => s.kind == ShiftKind.work).length;
                final short = working < p.need && !d.isBefore(store.today);
                return _Cell(
                  day: d,
                  highlight: short,
                  onAdd: () => showShiftDialog(context, date: d, part: p.name),
                  onDrop: (id) => _drop(context, id, d, part: isFlexShift(store, store.shiftById(id)!) ? null : p),
                  children: [
                    for (final s in list) _named(store, s),
                    if (short)
                      Text('인원 부족 $working/${p.need}',
                          style: AppText.style(11, FontWeight.w500, AppColors.danger)),
                  ],
                );
              }),
          ],
        [
          partLabel(AppColors.purple, '유동 근무', '직원 · 시간 직접 지정'),
          for (final d in days)
            _Cell(
              day: d,
              onAdd: () => showShiftDialog(context, date: d, part: flexPart),
              onDrop: (id) => _drop(context, id, d),
              children: [
                for (final s in store.scheduleOn(d).where((s) => isFlexShift(store, s))) _named(store, s),
              ],
            ),
        ],
      ],
    );
  }
}

/// 인원별 보기 (Figma 151:9748): 직원 · 유동 근무 / 알바생 · 파트 근무 그룹 × 요일.
class PeopleWeekView extends StatelessWidget {
  const PeopleWeekView({super.key, required this.monday});

  final DateTime monday;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final days = [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
    int weekMin(Staff s) => store
        .scheduleOfStaff(s.id)
        .where((x) => days.any((d) => ymd(d) == x.date) && !x.timeTbd && x.kind != ShiftKind.off)
        .fold(0, (sum, x) => sum + x.scheduledMinutes);
    Widget group(String title, String caption) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            Text(title, style: AppText.style(12, FontWeight.w500)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
            ),
          ]),
        );
    List<Widget> row(Staff s) {
      final m = weekMin(s);
      final (chipFg, chipBg) = switch (s.kind) {
        StaffKind.manager => (AppColors.purple, AppColors.purpleSoft),
        StaffKind.fulltime => (AppColors.info, AppColors.infoSoft),
        StaffKind.minor => (AppColors.danger, AppColors.dangerSoft),
        StaffKind.partTimer => (AppColors.textSecondary, AppColors.bg),
      };
      final caption = s.kind.flex
          ? '${_hourText(m)} / 40h'
          : m >= 900
              ? '${_hourText(m)}h · 주휴수당 대상'
              : '${_hourText(m)}h';
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            MemberAvatar(s, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Flexible(
                    child: Text(store.personOf(s).fullName,
                        overflow: TextOverflow.ellipsis, style: AppText.style(14, FontWeight.w500)),
                  ),
                  const SizedBox(width: 6),
                  WebTag(s.kind.label,
                      color: chipFg,
                      background: chipBg,
                      fontSize: 11,
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2)),
                ]),
                const SizedBox(height: 2),
                Text(caption,
                    style: AppText.style(11, FontWeight.w400,
                        !s.kind.flex && m >= 900 ? AppColors.primary : AppColors.textSecondary)),
              ]),
            ),
          ]),
        ),
        for (final d in days)
          Builder(builder: (context) {
            final list = store.scheduleOfStaff(s.id).where((x) => x.date == ymd(d)).toList();
            return _Cell(
              day: d,
              onAdd: () => showShiftDialog(context, date: d, staffId: s.id),
              onDrop: (id) => _drop(context, id, d, staffId: s.id),
              children: [
                for (final x in list) ShiftBlock(x, dense: true),
                if (list.isEmpty && s.kind.flex)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text('휴무',
                        textAlign: TextAlign.center,
                        style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
                  ),
              ],
            );
          }),
      ];
    }

    final parts = store.store.parts.map((p) => '${p.name} ${_short(p.startMin)}–${_short(p.endMin)}').join(' · ');
    return _Grid(
      labelWidth: 210,
      header: [_labelHead('구성원 · 주간 합계'), for (final d in days) _dayHead(store, d)],
      rows: [
        if (store.flexStaff.isNotEmpty) ...[
          [group('직원 · 유동 근무', '출근 시간이 날마다 달라요 · 주 40시간 기준')],
          for (final s in store.flexStaff) row(s),
        ],
        [group('알바생 · 파트 근무', parts)],
        for (final s in store.partStaff) row(s),
      ],
    );
  }
}

/// 한 달 보기 (Figma 151:9249): 달력 칸마다 파트별 근무자 · 유동 근무 · 연차.
class MonthView extends StatelessWidget {
  const MonthView({super.key, required this.month, required this.onOpenDay});

  final DateTime month;
  final ValueChanged<DateTime> onOpenDay;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final first = DateTime(month.year, month.month);
    final last = DateTime(month.year, month.month + 1, 0);
    final weeks = <DateTime>[
      for (var m = mondayOf(first); !m.isAfter(last); m = m.add(const Duration(days: 7))) m
    ];
    String name(Shift s) => store.personOf(store.staffById(s.staffId)!).fullName;

    Widget line(Color fg, Color bg, String tag, String text) => Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '$tag ', style: AppText.style(11, FontWeight.w500, fg)),
              TextSpan(text: text, style: AppText.style(11, FontWeight.w400, AppColors.textPrimary)),
            ]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );

    Widget cell(DateTime d) {
      if (d.month != month.month) return const SizedBox(height: 120);
      final list = store.scheduleOn(d);
      final flex = list.where((s) => s.kind == ShiftKind.work && isFlexShift(store, s)).toList();
      final rest = list.where((s) => s.kind != ShiftKind.work).toList();
      return InkWell(
        onTap: () => onOpenDay(d),
        child: Container(
          constraints: const BoxConstraints(minHeight: 120),
          padding: const EdgeInsets.all(6),
          color: d == store.today ? AppColors.primarySoft.withValues(alpha: 0.4) : null,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${d.day}', style: AppText.style(12, FontWeight.w500, dayColor(d))),
            for (final p in store.store.parts)
              if (list.where((s) => s.part == p.name && s.kind == ShiftKind.work) case final ps
                  when ps.isNotEmpty)
                line(partColors(p.name).$1, partColors(p.name).$2, p.name, ps.map(name).join(' ')),
            if (flex.isNotEmpty)
              line(AppColors.purple, AppColors.purpleSoft, '직원',
                  flex.map((s) => s.timeTbd ? '${name(s)} 미정' : '${name(s)} ${_short(s.startMin)}–${_short(s.endMin)}').join(' · ')),
            for (final s in rest)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 2),
                child: Text('${s.kind.label} ${name(s)}',
                    style: AppText.style(11, FontWeight.w400, AppColors.textSecondary)),
              ),
            if (!d.isBefore(store.today))
              for (final p in store.store.parts)
                if (list.where((s) => s.part == p.name && s.kind == ShiftKind.work).length < p.need)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 2),
                    child: Text('${p.name} 인원 부족',
                        style: AppText.style(11, FontWeight.w500, AppColors.danger)),
                  ),
          ]),
        ),
      );
    }

    return _Grid(
      labelWidth: 0,
      header: [
        const SizedBox(),
        for (var i = 0; i < 7; i++)
          Container(
            height: 40,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(weekday(DateTime(2024, 1, 1 + i)),
                style: AppText.style(12, FontWeight.w500, dayColor(DateTime(2024, 1, 1 + i), AppColors.textSecondary))),
          ),
      ],
      rows: [
        for (final m in weeks) [const SizedBox(), for (var i = 0; i < 7; i++) cell(m.add(Duration(days: i)))],
      ],
    );
  }
}

/// 일간 보기 (Figma 151:10046): 06–24시 타임라인. 영업 외 시간은 회색, 휴게는 가운데에 표시.
/// shortcut: 블록 가장자리 끌어 시간 조정은 없다. 블록을 누르면 수정 창에서 바꾼다.
class DayTimelineView extends StatelessWidget {
  const DayTimelineView({super.key, required this.day});

  final DateTime day;

  static const _from = 360, _to = 1440; // 06:00–24:00

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final list = store.scheduleOn(day).where((s) => s.kind != ShiftKind.off).toList();
    final flex = list.where((s) => isFlexShift(store, s)).toList();
    final part = list.where((s) => !isFlexShift(store, s)).toList();
    final parts = store.store.parts;
    final open = parts.map((p) => p.startMin).reduce((a, b) => a < b ? a : b);
    final close = parts.map((p) => p.endMin <= p.startMin ? p.endMin + 1440 : p.endMin).reduce((a, b) => a > b ? a : b);

    Widget axis() => Row(children: [
          const SizedBox(width: 200),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              return SizedBox(
                height: 18,
                child: Stack(children: [
                  for (var h = 6; h <= 24; h += 2)
                    Positioned(
                      left: (h * 60 - _from) / (_to - _from) * c.maxWidth - (h == 24 ? 14 : 0),
                      child: Text(h.toString().padLeft(2, '0'),
                          style: AppText.style(11, FontWeight.w400, AppColors.textTertiary)),
                    ),
                ]),
              );
            }),
          ),
        ]);

    Widget track(Shift s) {
      final (bar, bg) = blockColors(store, s);
      final staff = store.staffById(s.staffId)!;
      final tag = staff.kind.flex ? staff.kind.label : s.part;
      final (tagFg, tagBg) = staff.kind.flex ? (AppColors.purple, AppColors.purpleSoft) : partColors(s.part);
      final label = s.timeTbd
          ? '시간 미정 · 추천 ${hm(s.startMin)}–${hm(s.endMin)}'
          : s.kind == ShiftKind.leave
              ? '연차 · ${hours(s.scheduledMinutes)} 유급'
              : '${hm(s.startMin)}–${hm(s.endMin)} · 근무 ${hours(s.scheduledMinutes)}';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(
            width: 200,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(store.personOf(staff).fullName,
                      overflow: TextOverflow.ellipsis, style: AppText.style(14, FontWeight.w500)),
                ),
                const SizedBox(width: 6),
                WebTag(tag,
                    color: tagFg,
                    background: tagBg,
                    fontSize: 11,
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2)),
              ]),
              Text(label, style: AppText.style(11, FontWeight.w400, AppColors.textSecondary)),
            ]),
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              double x(int m) => (m - _from).clamp(0, _to - _from) / (_to - _from) * c.maxWidth;
              final left = x(s.startMin), right = x(s.endAbs);
              final mid = (s.startMin + s.endAbs) / 2;
              final bs = x((mid - s.breakMin / 2).round()), be = x((mid + s.breakMin / 2).round());
              return Container(
                height: 44,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(children: [
                  Positioned(left: 0, width: x(open), top: 0, bottom: 0, child: const ColoredBox(color: AppColors.bg)),
                  Positioned(left: x(close), right: 0, top: 0, bottom: 0, child: const ColoredBox(color: AppColors.bg)),
                  for (var h = 7; h < 24; h++)
                    Positioned(
                        left: x(h * 60), top: 0, bottom: 0, child: Container(width: 1, color: AppColors.border.withValues(alpha: 0.6))),
                  Positioned(
                    left: left,
                    width: (right - left).clamp(24, c.maxWidth),
                    top: 6,
                    bottom: 6,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => showShiftDialog(context, shift: s, date: day),
                        child: CustomPaint(
                          foregroundPainter: s.timeTbd ? const DashedBorderPainter(color: AppColors.danger, radius: 6) : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: s.timeTbd ? AppColors.surface : bg,
                              borderRadius: BorderRadius.circular(6),
                              border: s.timeTbd ? null : Border.all(color: bar),
                            ),
                            child: Stack(children: [
                              if (s.kind == ShiftKind.work && !s.timeTbd && s.breakMin > 0)
                                Positioned(
                                  left: bs - left,
                                  width: be - bs,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    color: bar.withValues(alpha: 0.18),
                                    alignment: Alignment.center,
                                    child: Text('휴게', style: AppText.style(10, FontWeight.w500, AppColors.textSecondary)),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    s.timeTbd ? '시간 미정' : s.kind == ShiftKind.leave ? '연차' : '${hm(s.startMin)}–${hm(s.endMin)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.clip,
                                    style: AppText.style(12, FontWeight.w500, s.timeTbd ? AppColors.danger : AppColors.textPrimary),
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              );
            }),
          ),
        ]),
      );
    }

    Widget group(String t) => Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 4),
          child: Text(t, style: AppText.style(12, FontWeight.w500, AppColors.textSecondary)),
        );

    return AppCard(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: LayoutBuilder(builder: (context, c) {
        final content = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          axis(),
          if (flex.isNotEmpty) ...[group('직원 · 유동 출퇴근'), for (final s in flex) track(s)],
          group('알바생 · 파트'),
          if (part.isEmpty) const EmptyNote('이날 파트 근무가 없어요'),
          for (final s in part) track(s),
          const SizedBox(height: 4),
          axis(),
        ]);
        return c.maxWidth >= 760
            ? content
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal, child: SizedBox(width: 760, child: content));
      }),
    );
  }
}
