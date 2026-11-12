import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../employer/employer_parts.dart';
import 'web_common.dart';
import 'web_schedule_views.dart';

/// W2 근무표 (Figma v3 오토스케줄 151:9248): 한 달 · 파트별 · 인원별 · 일간.
/// 빈 칸을 누르면 근무 추가, 블록을 누르면 수정, 끌어 놓으면 이동. 바뀐 내용은 바로 저장된다.
class WebScheduleScreen extends StatefulWidget {
  const WebScheduleScreen({super.key});

  @override
  State<WebScheduleScreen> createState() => _WebScheduleScreenState();
}

class _WebScheduleScreenState extends State<WebScheduleScreen> {
  static const _views = ['한 달', '파트별', '인원별', '일간'];

  int _view = 1;

  /// 고른 날. 달 · 주 · 요일은 모두 여기서 나온다.
  DateTime? _day;

  List<DateTime> _weeks(DateTime month) {
    final first = DateTime(month.year, month.month);
    final last = DateTime(month.year, month.month + 1, 0);
    return [for (var m = mondayOf(first); !m.isAfter(last); m = m.add(const Duration(days: 7))) m];
  }

  void _moveMonth(DateTime day, int d) {
    final m = DateTime(day.year, day.month + d);
    final today = AppScope.read(context).today;
    // 이번 달로 오면 오늘, 아니면 그 달 1일.
    setState(() => _day = m.year == today.year && m.month == today.month ? today : m);
  }

  void _autoFill(List<DateTime> mondays) {
    final store = AppScope.read(context);
    final n = mondays.fold(0, (sum, m) => sum + store.autoFill(m));
    showToast(context, n == 0 ? '채울 빈 칸이 없어요' : '빈 칸 $n개를 채웠어요');
  }

  Future<void> _confirm(DateTime month) async {
    final store = AppScope.read(context);
    final tbd = store.tbdCount(month.year, month.month);
    if (tbd > 0) return showToast(context, '시간 미정 $tbd건을 먼저 정해 주세요');
    final ok = await showConfirmDialog(
      context,
      title: '${month.month}월 근무표를 확정할까요?',
      message: '재직 직원 ${store.activeStaff.length}명에게 확정 알림을 보내요.',
      confirmLabel: '확정하기',
    );
    if (!ok || !mounted) return;
    store.confirmSchedule(month.year, month.month);
    showToast(context, '${month.month}월 근무표를 확정했어요');
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final day = _day ?? store.today;
    final month = DateTime(day.year, day.month);
    final last = DateTime(day.year, day.month + 1, 0);
    final weeks = _weeks(month);
    final monday = mondayOf(day);
    final tbd = store.tbdCount(month.year, month.month);

    final title = Row(mainAxisSize: MainAxisSize.min, children: [
      _Arrow('‹', '이전 달', () => _moveMonth(day, -1)),
      Flexible(
        child: Text('근무표 · ${month.year}년 ${month.month}월',
            overflow: TextOverflow.ellipsis, style: AppText.style(28, FontWeight.w500)),
      ),
      _Arrow('›', '다음 달', () => _moveMonth(day, 1)),
      if (tbd > 0) ...[
        const SizedBox(width: 6),
        WebTag('미정 $tbd건',
            color: AppColors.danger,
            background: AppColors.dangerSoft,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3)),
      ],
    ]);

    final weekTabs = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: WebSegmented(
        labels: [
          for (final (i, m) in weeks.indexed)
            '${i + 1}주차 · ${_weekRange(m, month, last)}',
        ],
        selected: weeks.indexOf(monday).clamp(0, weeks.length - 1),
        onChanged: (i) => setState(() {
          final m = weeks[i];
          _day = m.isBefore(month) ? month : m;
        }),
      ),
    );

    final dayTabs = LayoutBuilder(builder: (context, c) {
      final days = [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
      return Row(children: [
        for (final (i, d) in days.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: d == day ? AppColors.primary : AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: d == day ? AppColors.primary : AppColors.border),
              ),
              child: InkWell(
                onTap: () => setState(() => _day = d),
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 40,
                  child: Center(
                    child: Text('${weekday(d)} ${d.month}/${d.day}',
                        style: AppText.style(13, FontWeight.w500,
                            d == day ? AppColors.onPrimary : dayColor(d))),
                  ),
                ),
              ),
            ),
          ),
        ],
      ]);
    });

    final view = switch (_view) {
      0 => MonthView(
          month: month,
          onOpenDay: (d) => setState(() {
            _day = d;
            _view = 3;
          })),
      1 => PartWeekView(monday: monday),
      2 => PeopleWeekView(monday: monday),
      _ => DayTimelineView(day: day),
    };

    final help = switch (_view) {
      0 => '날짜를 누르면 그날 타임라인으로 가요',
      1 => '블록을 다른 파트·요일 칸으로 끌어 옮겨요 · 빈 칸 클릭으로 추가',
      2 => '블록을 다른 사람·요일 칸으로 끌어 옮겨요 · 빈 칸 클릭으로 추가',
      _ => '블록을 누르면 출퇴근 시간을 바꿔요 · 회색은 영업 외 시간',
    };

    return WebPage(
      title: '근무표',
      titleWidget: title,
      subtitle: '${month.year}.${month.month}.1 – ${month.month}.${last.day}'
          ' · 직원 ${store.flexStaff.length}명(유동 근무) · 알바생 ${store.partStaff.length}명(파트 근무)'
          '${store.store.scheduleConfirmedAt == null ? '' : ' · ${relative(DateTime.parse(store.store.scheduleConfirmedAt!), store.now)} 확정'}',
      gap: 16,
      actions: [
        WebSegmented(
            labels: _views, selected: _view, onChanged: (i) => setState(() => _view = i)),
        WebButton('되돌리기',
            icon: Icons.undo_rounded,
            tooltip: '되돌리기',
            style: WebButtonStyle.outline,
            onPressed: store.canUndo ? store.undo : null),
        WebButton('다시하기',
            icon: Icons.redo_rounded,
            tooltip: '다시하기',
            style: WebButtonStyle.outline,
            onPressed: store.canRedo ? store.redo : null),
        WebButton('자동 채우기',
            style: WebButtonStyle.soft,
            onPressed: () => _autoFill(_view == 0 ? weeks : [monday])),
        const WebButton('저장', tooltip: '바뀐 내용은 바로 저장돼요', style: WebButtonStyle.outline),
        WebButton('확정하기', onPressed: () => _confirm(month)),
      ],
      children: [
        if (_view != 0) weekTabs,
        if (_view == 3) dayTabs,
        view,
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Wrap(spacing: 14, runSpacing: 6, children: [
              for (final p in store.store.parts) WebLegend(partColors(p.name).$1, p.name),
              const WebLegend(AppColors.purple, '직원 근무'),
              const WebLegend(AppColors.danger, '시간 미정', dashed: true),
              const WebLegend(AppColors.textTertiary, '연차·휴무'),
              const WebLegend(AppColors.accent, '대타 모집'),
            ]),
            Text(help, style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
          ],
        ),
      ],
    );
  }

  /// 그 달 안으로 자른 주 범위 '11/2–11/8' (한 날이면 '11/1').
  static String _weekRange(DateTime monday, DateTime month, DateTime last) {
    var a = monday, b = monday.add(const Duration(days: 6));
    if (a.isBefore(month)) a = month;
    if (b.isAfter(last)) b = last;
    return a == b ? '${a.month}/${a.day}' : '${a.month}/${a.day}–${b.month}/${b.day}';
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow(this.glyph, this.tooltip, this.onTap);

  final String glyph, tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Text(glyph, style: AppText.style(22, FontWeight.w400, AppColors.textSecondary)),
      );
}
