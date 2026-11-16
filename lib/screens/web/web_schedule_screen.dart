import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../data/api_client.dart';
import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../data/payroll.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_common.dart';
import 'web_download.dart';
import 'web_schedule_views.dart';
import 'web_schedules_screen.dart' show parseMonth;

/// 월 근무표 합계(옆 패널): 총 근무시간 · 예상 인건비 · 주휴수당 대상(알바생) · 주휴수당 합계.
class ScheduleSummary {
  const ScheduleSummary(this.workMin, this.cost, this.holidayCount, this.holidayPay);

  final int workMin, cost, holidayCount, holidayPay;
}

/// [month] 에 속한 근무로 계산. 연차는 소정 시간만큼 유급, 시간 미정·휴무는 0. 주휴수당은 알바생만, 그 주(월~일) 근무 합으로.
ScheduleSummary scheduleSummary(AppStore store, DateTime month) {
  final key = ym(month);
  var workMin = 0, cost = 0, holidayPay = 0;
  final holidayStaff = <String>{};
  for (final st in store.activeStaff) {
    final weeks = <DateTime, int>{};
    for (final s in store.scheduleOfStaff(st.id)) {
      if (!s.date.startsWith(key) || s.timeTbd || s.kind == ShiftKind.off) continue;
      final m = s.scheduledMinutes;
      workMin += m;
      cost += (m * st.wage / 60).round();
      final mon = mondayOf(parseYmd(s.date));
      weeks[mon] = (weeks[mon] ?? 0) + m;
    }
    if (st.kind.flex) continue;
    for (final m in weeks.values) {
      final pay = weeklyHolidayPay(m, st.wage);
      if (pay > 0) {
        holidayStaff.add(st.id);
        holidayPay += pay;
      }
    }
  }
  return ScheduleSummary(workMin, cost + holidayPay, holidayStaff.length, holidayPay);
}

/// W2 근무표 편집기 (Figma v3 오토스케줄 151:9248 + 레퍼런스 ScheduleEditor).
/// 진입하면 초안 모드: 근무 편집은 로컬에만 쌓이고 '저장'을 눌러야 서버에 간다.
class WebScheduleScreen extends StatefulWidget {
  /// [month] 'yyyy-MM'. 없으면 이번 달. [onBack] 이 있으면 '‹ 목록' 버튼이 생긴다.
  const WebScheduleScreen({super.key, this.month, this.onBack});

  final String? month;
  final VoidCallback? onBack;

  @override
  State<WebScheduleScreen> createState() => _WebScheduleScreenState();
}

class _WebScheduleScreenState extends State<WebScheduleScreen> {
  static const _views = ['한 달', '파트별', '인원별', '일간'];

  late final AppStore _store = AppScope.read(context);
  final _shot = GlobalKey();
  int _view = 2;
  late DateTime _month;
  DateTime? _day;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final today = _store.today;
    _month = widget.month == null ? DateTime(today.year, today.month) : parseMonth(widget.month!);
    _day = _month.year == today.year && _month.month == today.month ? today : _month;
    // 빌드 중 notify 를 피해 다음 마이크로태스크에서 초안 모드 켬.
    Future.microtask(() => _store.setScheduleDraft(true));
  }

  @override
  void dispose() {
    final store = _store;
    // 다른 메뉴로 나가면 저장하지 않은 변경은 버린다(나가기 전 확인은 버튼 쪽에서).
    Future.microtask(() {
      if (store.scheduleDirty) store.discardScheduleDraft();
      store.setScheduleDraft(false);
    });
    super.dispose();
  }

  String get _key => ym(_month);
  MonthSchedule? get _ms => _store.monthSchedule(_key);

  Future<bool> _leaveOk() async {
    if (!_store.scheduleDirty) return true;
    final ok = await showConfirmDialog(context,
        title: '저장하지 않은 변경 사항이 있어요',
        message: '이동하면 저장하지 않은 변경 사항이 사라져요.',
        confirmLabel: '이동',
        confirmVariant: AppButtonVariant.danger);
    if (ok && mounted) _store.discardScheduleDraft();
    return ok && mounted;
  }

  Future<void> _guard(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _moveMonth(int d) async {
    final to = DateTime(_month.year, _month.month + d);
    if (_store.monthSchedule(ym(to)) == null || !await _leaveOk()) return;
    final today = _store.today;
    setState(() {
      _month = to;
      _day = to.year == today.year && to.month == today.month ? today : to;
    });
  }

  Future<void> _back() async {
    if (await _leaveOk()) widget.onBack?.call();
  }

  Future<void> _save() => _guard(() async {
        await _store.saveSchedule(_key);
        if (mounted) showToast(context, '근무표를 저장했어요');
      });

  Future<void> _autofill() => _guard(() async {
        if (_store.scheduleDirty) await _store.saveSchedule(_key);
        await _store.autofillMonth(_key);
        if (mounted) showToast(context, '고정 근무와 파트를 채웠어요');
      });

  Future<void> _confirm() async {
    final ok = await showConfirmDialog(context,
        title: '${_month.month}월 근무표를 확정할까요?',
        message: '재직 직원 ${_store.activeStaff.length}명에게 확정 알림을 보내요.',
        confirmLabel: '확정하기');
    if (!ok || !mounted) return;
    await _guard(() async {
      if (_store.scheduleDirty) await _store.saveSchedule(_key);
      await _store.confirmMonth(_key);
      if (mounted) showToast(context, '${_month.month}월 근무표를 확정했어요');
    });
  }

  Future<void> _saveTemplate() async {
    final c = TextEditingController(text: '${_month.year}년 ${_month.month}월 기본');
    final name = await showWebDialog<String>(
      context,
      title: '템플릿으로 저장',
      builder: (ctx, set) => webField('템플릿 이름', AppTextField(controller: c),
          help: '그 달 첫 완전한 월~일 주의 요일 패턴을 저장해요.'),
      actions: (ctx, set) => [
        WebButton('취소', style: WebButtonStyle.outline, onPressed: () => Navigator.pop(ctx)),
        WebButton('저장', onPressed: () => Navigator.pop(ctx, c.text.trim())),
      ],
    );
    c.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    await _guard(() async {
      if (_store.scheduleDirty) await _store.saveSchedule(_key);
      await _store.saveScheduleTemplate(name, _key);
      if (mounted) showToast(context, '템플릿 "$name"을 저장했어요');
    });
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(context,
        title: '${_month.month}월 근무표를 삭제할까요?',
        message:
            '${_ms?.status == ScheduleStatus.confirmed ? '확정된 근무표예요. ' : ''}${_store.scheduleDirty ? '저장하지 않은 변경도 사라져요. ' : ''}되돌릴 수 없어요.',
        confirmLabel: '삭제',
        confirmVariant: AppButtonVariant.danger);
    if (!ok || !mounted) return;
    await _guard(() async {
      _store.discardScheduleDraft();
      await _store.deleteMonthSchedule(_key);
      if (mounted) widget.onBack?.call();
    });
  }

  Future<void> _exportPng() async {
    final boundary = _shot.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null || !mounted) return;
    final ok = downloadBytes(data.buffer.asUint8List(), '근무표_$_key.png', 'image/png');
    showToast(context, ok ? '이미지를 저장했어요' : '이미지 저장은 웹에서만 돼요');
  }

  List<DateTime> _weeks() {
    final last = DateTime(_month.year, _month.month + 1, 0);
    return [for (var m = mondayOf(_month); !m.isAfter(last); m = m.add(const Duration(days: 7))) m];
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final ms = _ms;
    if (ms == null) {
      return WebPage(
        title: '근무표',
        actions: [if (widget.onBack != null) WebButton('목록으로', style: WebButtonStyle.outline, onPressed: widget.onBack)],
        children: const [EmptyNote('이 달 근무표가 없어요')],
      );
    }
    final confirmed = ms.status == ScheduleStatus.confirmed;
    final day = _day ?? store.today;
    final month = _month;
    final last = DateTime(month.year, month.month + 1, 0);
    final weeks = _weeks();
    final monday = mondayOf(day);
    final tbd = store.tbdCount(month.year, month.month);
    final dirty = store.scheduleDirty;
    final hasPrev = store.monthSchedule(ym(DateTime(month.year, month.month - 1))) != null;
    final hasNext = store.monthSchedule(ym(DateTime(month.year, month.month + 1))) != null;

    final title = Row(mainAxisSize: MainAxisSize.min, children: [
      if (widget.onBack != null) _Arrow('‹ 목록', '근무표 목록', _back, small: true),
      _Arrow('‹', '이전 달', hasPrev ? () => _moveMonth(-1) : null),
      Flexible(
        child: Text('근무표 · ${month.year}년 ${month.month}월',
            overflow: TextOverflow.ellipsis, style: AppText.style(28, FontWeight.w500)),
      ),
      _Arrow('›', '다음 달', hasNext ? () => _moveMonth(1) : null),
      if (confirmed) ...[
        const SizedBox(width: 6),
        const WebTag('확정됨',
            color: AppColors.primary,
            background: AppColors.primarySoft,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3)),
      ],
      if (tbd > 0) ...[
        const SizedBox(width: 6),
        WebTag('미정 $tbd건',
            color: AppColors.danger,
            background: AppColors.dangerSoft,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3)),
      ],
      if (dirty) ...[
        const SizedBox(width: 6),
        const WebTag('저장 안 됨',
            color: AppColors.textSecondary,
            background: AppColors.bg,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3)),
      ],
    ]);

    final weekTabs = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: WebSegmented(
        labels: [for (final (i, m) in weeks.indexed) '${i + 1}주차 · ${_weekRange(m, month, last)}'],
        selected: weeks.indexOf(monday).clamp(0, weeks.length - 1),
        onChanged: (i) => setState(() {
          final m = weeks[i];
          _day = m.isBefore(month) ? month : m;
        }),
      ),
    );

    final dayTabs = Row(children: [
      for (final (i, d) in [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))].indexed) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(
          child: Opacity(
            opacity: d.month == month.month ? 1 : 0.4,
            child: Material(
              color: d == day ? AppColors.primary : AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: d == day ? AppColors.primary : AppColors.border),
              ),
              child: InkWell(
                onTap: d.month == month.month ? () => setState(() => _day = d) : null,
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 40,
                  child: Center(
                    child: Text('${weekday(d)} ${d.month}/${d.day}',
                        style: AppText.style(13, FontWeight.w500, d == day ? AppColors.onPrimary : dayColor(d))),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ]);

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
      _ => '블록을 끌어 이동 · 양 끝을 끌어 시간 조정(15분) · 누르면 상세 편집',
    };

    final summary = scheduleSummary(store, month);
    final panel = _SidePanel(
      summary: summary,
      comment: ms.aiComment,
      busy: _busy,
      onExport: _exportPng,
      onTemplate: _saveTemplate,
      onDelete: _delete,
    );
    final tbdTip = '시간 미정을 먼저 해결하세요';

    final body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_view != 0) ...[weekTabs, const SizedBox(height: 16)],
      if (_view == 3) ...[dayTabs, const SizedBox(height: 16)],
      LayoutBuilder(builder: (context, c) {
        final main = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          RepaintBoundary(key: _shot, child: ColoredBox(color: AppColors.bg, child: view)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Wrap(spacing: 14, runSpacing: 6, children: [
                for (final p in store.store.parts) WebLegend(partColor(p).$1, p.name),
                const WebLegend(AppColors.purple, '직원 근무'),
                const WebLegend(AppColors.danger, '시간 미정', dashed: true),
                const WebLegend(AppColors.textTertiary, '연차·휴무'),
              ]),
              Text(help, style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
            ],
          ),
          if (confirmed)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('확정된 근무표예요. 수정 후 저장하면 변경 내역이 반영돼요.',
                  style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
            ),
        ]);
        if (c.maxWidth >= 1280) {
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: main),
            const SizedBox(width: 16),
            SizedBox(width: 300, child: panel),
          ]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          main,
          const SizedBox(height: 16),
          panel,
        ]);
      }),
    ]);

    return CallbackShortcuts(
      bindings: {
        for (final meta in [false, true]) ...{
          SingleActivator(LogicalKeyboardKey.keyZ, control: !meta, meta: meta): store.undo,
          SingleActivator(LogicalKeyboardKey.keyZ, control: !meta, meta: meta, shift: true): store.redo,
        },
      },
      child: Focus(
        autofocus: true,
        child: WebPage(
          title: '근무표',
          titleWidget: title,
          subtitle: '${month.year}.${month.month}.1 – ${month.month}.${last.day}'
              ' · 직원 ${store.flexStaff.length}명(유동 근무) · 알바생 ${store.partStaff.length}명(파트 근무)',
          gap: 0,
          actions: [
            WebSegmented(labels: _views, selected: _view, onChanged: (i) => setState(() => _view = i)),
            WebButton('자동 채우기',
                style: WebButtonStyle.outline,
                tooltip: confirmed ? '확정된 근무표는 자동 채우기를 쓸 수 없어요' : '이미 넣은 근무는 두고 직원 고정 근무와 알바생 고정 파트를 채워요',
                onPressed: confirmed || _busy ? null : _autofill),
            WebButton('되돌리기',
                icon: Icons.undo_rounded,
                tooltip: '되돌리기 (Ctrl/⌘ Z)',
                style: WebButtonStyle.outline,
                onPressed: store.canUndo ? store.undo : null),
            WebButton('다시하기',
                icon: Icons.redo_rounded,
                tooltip: '다시하기 (Shift Ctrl/⌘ Z)',
                style: WebButtonStyle.outline,
                onPressed: store.canRedo ? store.redo : null),
            WebButton(_busy ? '처리 중…' : '저장',
                style: WebButtonStyle.outline, onPressed: dirty && !_busy ? _save : null),
            WebButton('확정하기',
                tooltip: tbd > 0 ? tbdTip : null,
                onPressed: tbd > 0 || confirmed || _busy ? null : _confirm),
          ],
          children: [const SizedBox(height: 16), body],
        ),
      ),
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

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.summary,
    required this.comment,
    required this.busy,
    required this.onExport,
    required this.onTemplate,
    required this.onDelete,
  });

  final ScheduleSummary summary;
  final String comment;
  final bool busy;
  final VoidCallback onExport, onTemplate, onDelete;

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value, {bool big = false}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(value, style: AppText.style(big ? 18 : 15, FontWeight.w700)),
          ],
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: stat('총 근무시간', hours(summary.workMin), big: true)),
            Expanded(child: stat('예상 인건비', won(summary.cost), big: true)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: stat('주휴수당 대상', '알바생 ${summary.holidayCount}명')),
            Expanded(child: stat('주휴수당 합계', won(summary.holidayPay))),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: WebButton('이미지 저장', style: WebButtonStyle.outline, onPressed: onExport)),
            const SizedBox(width: 8),
            Expanded(child: WebButton('템플릿으로 저장', style: WebButtonStyle.outline, onPressed: busy ? null : onTemplate)),
          ]),
          const SizedBox(height: 8),
          WebButton('근무표 삭제', style: WebButtonStyle.danger, onPressed: busy ? null : onDelete),
        ]),
      ),
      if (comment.isNotEmpty) ...[
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI 브리핑', style: AppText.style(14, FontWeight.w700)),
            const SizedBox(height: 6),
            Text(comment, style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
          ]),
        ),
      ],
    ]);
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow(this.glyph, this.tooltip, this.onTap, {this.small = false});

  final String glyph, tooltip;
  final VoidCallback? onTap;
  final bool small;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Text(glyph,
            style: AppText.style(small ? 14 : 22, FontWeight.w400,
                onTap == null ? AppColors.border : AppColors.textSecondary)),
      );
}
