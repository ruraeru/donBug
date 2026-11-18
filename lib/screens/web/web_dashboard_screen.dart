import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../employer/employer_parts.dart';
import 'web_common.dart';
import 'web_documents_screen.dart';
import 'web_notice_screen.dart';
import 'web_shell.dart';
import 'web_staff_screen.dart';
import 'web_today_strip.dart';
import 'web_schedules_screen.dart';
import 'web_schedule_screen.dart' show scheduleSummary;

/// 보건증 주의 대상: 미등록 · 만료 · 30일 이내. 급한 순.
List<(Staff, int?)> certAlerts(AppStore store) => [
      for (final s in store.activeStaff)
        if ((store.certDaysLeft(store.personOf(s)) ?? -1) <= 30)
          (s, store.certDaysLeft(store.personOf(s))),
    ]..sort((a, b) => (a.$2 ?? -9999).compareTo(b.$2 ?? -9999));

String certLabel(int? left) => switch (left) {
      null => '미등록',
      < 0 => '만료됨',
      0 => 'D-Day',
      _ => 'D-$left',
    };

/// W1 사장님 웹 대시보드 (콘텐츠 영역).
class WebDashboardScreen extends StatefulWidget {
  const WebDashboardScreen({super.key});

  @override
  State<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  /// 이번 주 기준 몇 주 떨어졌는지.
  int _week = 0;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final t = store.today;
    final total = store.laborTotal(t.year, t.month, projected: true);
    final last = store.laborTotal(t.year, t.month - 1);
    final diff = last == 0 ? 0 : ((total - last) / last * 100).round();
    final statuses = store.shiftsOn(t).map(store.attendanceStatus).toList();
    final present = statuses
        .where((s) => s == AttStatus.normal || s == AttStatus.late || s == AttStatus.working)
        .length;
    final waiting = statuses.where((s) => s == AttStatus.waiting).length;
    final subs = store.pendingSubs;
    final certs = certAlerts(store);
    void go(int page) => WebShell.open(context, page);
    return WebPage(
      title: '대시보드',
      subtitle: '${store.store.name} · ${t.year}년 ${t.month}월 ${t.day}일 ${weekday(t)}요일',
      gap: 16,
      actions: [
        WebButton('+ 공지 작성', onPressed: () => showNoticeDialog(context)),
        Material(
          color: AppColors.surface,
          shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
          child: IconButton(
            tooltip: '알림',
            onPressed: () => _showNotifications(context),
            icon: CountBadge(
                count: store.unreadNotificationCount, child: const AppIcon('bell')),
          ),
        ),
      ],
      children: [
        WebRow(children: [
          _Kpi('이번 달 예상 인건비', wonText(total),
              '지난달 대비 ${diff >= 0 ? '+' : ''}$diff% · 근로자 ${store.activeStaff.length}명',
              onTap: () => go(WebMenu.payroll)),
          _Kpi('오늘 근무', '${statuses.length}명', '출근 $present · 대기 $waiting',
              onTap: () => showTodayAttendance(context)),
          _Kpi(
              '대타 승인 대기',
              '${subs.length}건',
              subs.isEmpty
                  ? '진행 중인 요청 없음'
                  : '${subs.map((r) => store.nameOf(r.requesterId)).toSet().join(' · ')} 요청',
              onTap: () => go(WebMenu.substitute)),
          certs.isEmpty
              ? _Kpi('보건증 만료 임박', '없음', '30일 이내 만료 없음',
                  onTap: () => go(WebMenu.documents))
              : _Kpi(
                  '보건증 만료 임박',
                  certLabel(certs.first.$2),
                  '${store.nameOf(certs.first.$1.id)}님'
                      '${certs.length > 1 ? ' 외 ${certs.length - 1}명' : ''}'
                      '${_alertDaysText(certs.first.$2, store.personOf(certs.first.$1))}',
                  valueColor: AppColors.danger,
                  onTap: () => go(WebMenu.documents)),
        ]),
        WebSplit(
          breakpoint: 1000,
          left: Column(children: [
            const _TodayCard(),
            const SizedBox(height: 16),
            const _MonthStats(),
            const SizedBox(height: 16),
            _StaffWeekCard(
              monday: mondayOf(t).add(Duration(days: 7 * _week)),
              onWeek: (d) => setState(() => _week = clampWeek(t, _week + d)),
            ),
          ]),
          right: Column(children: [
            _SubstituteCard(subs),
            const SizedBox(height: 16),
            _RiskCard(certs: certs),
          ]),
        ),
      ],
    );
  }
}

/// 보건증 KPI 캡션 끝 " · 7·30일 전 알림". 미등록이거나 알림일이 없으면 뺀다.
String _alertDaysText(int? left, Person p) {
  final days = p.certAlertDays.where((d) => d > 0);
  return left == null || days.isEmpty ? '' : ' · ${days.join('·')}일 전 알림';
}

/// 직원 근무 현황 주 이동 범위: `/me/state` 가 주는 근무 범위
/// (지난달 1일이 든 주 월요일 ~ 3개월 뒤 말일이 든 주) 안으로 자른다.
int clampWeek(DateTime today, int week) {
  final base = mondayOf(today);
  int weeksTo(DateTime d) => (mondayOf(d).difference(base).inDays / 7).round();
  return week.clamp(weeksTo(DateTime(today.year, today.month - 1, 1)),
      weeksTo(DateTime(today.year, today.month + 4, 0)));
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.label, this.value, this.caption, {this.valueColor, this.onTap});

  final String label, value, caption;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: AppText.style(
                      28, FontWeight.w500, valueColor ?? AppColors.textPrimary)),
            ),
            const SizedBox(height: 8),
            Text(caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
          ],
        ),
      );
}

/// '14–20', 정각이 아니면 '14:30–20'.
String _shortRange(Shift s) {
  String h(int m) => m % 60 == 0 ? '${(m ~/ 60) % 24}' : hm(m);
  return '${h(s.startMin)}–${h(s.endMin)}';
}

/// 근무표 편집기로 (이번 달, [day] 를 주면 그날 일간 보기).
void _openEditor(BuildContext context, {DateTime? day}) {
  final t = AppScope.read(context).today;
  WebSchedulesScreen.openRequest.value = ym(t);
  WebSchedulesScreen.openDay.value = day;
  WebShell.open(context, WebMenu.schedule);
}

/// 오늘 근무 타임라인 (레퍼런스 Dashboard 의 오늘 카드 + TodayStrip).
class _TodayCard extends StatelessWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final t = store.today;
    final nowMin = store.now.hour * 60 + store.now.minute;
    final shifts = store.scheduleOn(t).where((s) => s.kind == ShiftKind.work).toList();
    final working = {
      for (final s in shifts)
        if (!s.timeTbd && s.startMin <= nowMin && nowMin < (s.endAbs < 1440 ? s.endAbs : 1440)) store.nameOf(s.staffId)
    };
    final ms = store.monthSchedule(ym(t));
    final tbd = store.state.shifts
        .where((s) => s.storeId == store.store.id && s.date.startsWith(ym(t)) && s.timeTbd)
        .length;
    final status = ms == null
        ? '${t.month}월 근무표 없음'
        : '${t.month}월 근무표 · ${ms.status == ScheduleStatus.confirmed ? '확정됨' : '작성 중'}${tbd > 0 ? ' · 미정 $tbd건' : ''}';
    return AppCard(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('오늘 · ${weekday(t)} ${t.month}/${t.day}', style: AppText.style(17, FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                  '${shifts.map((s) => s.staffId).toSet().length}명 근무 · 지금 '
                  '${working.isEmpty ? '근무자 없음' : '${working.join('·')} 근무 중'}',
                  style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(status, style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
            ]),
          ),
          Wrap(spacing: 8, runSpacing: 8, children: [
            WebButton('근무표 열기', style: WebButtonStyle.outline, height: 36, onPressed: () => _openEditor(context)),
            WebButton('일간 보기', style: WebButtonStyle.soft, height: 36, onPressed: () => _openEditor(context, day: t)),
          ]),
        ]),
        const SizedBox(height: 20),
        TodayStrip(shifts: shifts, nowMin: nowMin),
      ]),
    );
  }
}

/// 이번 달 근무표 통계 (레퍼런스 StatStrip). 예상 인건비는 위 KPI 에 있다.
class _MonthStats extends StatelessWidget {
  const _MonthStats();

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final t = store.today;
    final sum = scheduleSummary(store, DateTime(t.year, t.month));
    final flex = store.activeStaff.where((s) => s.kind.flex).length;
    return WebRow(children: [
      _Kpi('이번 달 총 근무시간', hours(sum.workMin), '직원 $flex명 · 알바생 ${store.activeStaff.length - flex}명',
          onTap: () => _openEditor(context)),
      _Kpi('주휴수당 대상', '${sum.holidayCount}명', '알바생 주 15시간 이상', onTap: () => _openEditor(context)),
      _Kpi('주휴수당 합계', wonText(sum.holidayPay), '이번 달 근무표 기준', onTap: () => _openEditor(context)),
    ]);
  }
}

/// 직원(유동 근무) 주간 근무 현황 (레퍼런스 Dashboard 의 직원 근무 현황).
class _StaffWeekCard extends StatelessWidget {
  const _StaffWeekCard({required this.monday, required this.onWeek});

  final DateTime monday;
  final ValueChanged<int> onWeek;

  static const _weekMin = 40 * 60;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final staff = store.activeStaff.where((s) => s.kind.flex).toList();
    if (staff.isEmpty) return const SizedBox.shrink();
    final days = [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
    Widget arrow(String g, int d) => InkWell(
          onTap: () => onWeek(d),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(g, style: AppText.style(18, FontWeight.w400, AppColors.textSecondary)),
          ),
        );
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
          child: Row(children: [
            Expanded(child: Text('직원 근무 현황', style: AppText.style(17, FontWeight.w700))),
            arrow('‹', -1),
            Text('${md(days.first)}–${md(days.last)}', style: AppText.style(13, FontWeight.w500)),
            arrow('›', 1),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),
        for (var i = 0; i < staff.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.border),
          _row(store, staff[i], days),
        ],
      ]),
    );
  }

  Widget _row(AppStore store, Staff st, List<DateTime> days) {
    var work = 0, tbd = 0, leave = 0;
    final cells = <Widget>[];
    for (final d in days) {
      final list = store.scheduleOfStaff(st.id).where((s) => s.date == ymd(d)).toList();
      final w = list.where((s) => s.kind == ShiftKind.work).firstOrNull;
      final isLeave = list.any((s) => s.kind == ShiftKind.leave);
      for (final s in list) {
        if (s.kind == ShiftKind.leave) {
          leave += s.scheduledMinutes;
        } else if (s.kind == ShiftKind.work) {
          s.timeTbd ? tbd += s.scheduledMinutes : work += s.scheduledMinutes;
        }
      }
      final (text, fg, bg, dashed) = w != null
          ? (w.timeTbd ? '미정' : _shortRange(w), AppColors.primary, w.timeTbd ? AppColors.surface : AppColors.primarySoft, w.timeTbd)
          : isLeave
              ? ('연차', AppColors.textSecondary, AppColors.bg, false)
              : ('휴무', AppColors.textTertiary, AppColors.surface, false);
      final cell = Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: w == null && !isLeave ? Border.all(color: AppColors.border) : null,
        ),
        child: Column(children: [
          Text(weekday(d), style: AppText.style(11, FontWeight.w400, fg)),
          const SizedBox(height: 2),
          FittedBox(fit: BoxFit.scaleDown, child: Text(text, style: AppText.style(12, FontWeight.w500, fg))),
        ]),
      );
      cells.add(Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: dashed
              ? CustomPaint(foregroundPainter: const DashedBorderPainter(color: AppColors.primary), child: cell)
              : cell,
        ),
      ));
    }
    double seg(int m) => (m / _weekMin).clamp(0.0, 1.0);
    final caption = [
      '확정 ${hours(work)}',
      if (tbd > 0) '미정 ${hours(tbd)}',
      if (leave > 0) '연차 ${hours(leave)}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: LayoutBuilder(builder: (context, c) {
        final who = Row(children: [
          MemberAvatar(st, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(store.personOf(st).name,
                      overflow: TextOverflow.ellipsis, style: AppText.style(14, FontWeight.w500)),
                ),
                const SizedBox(width: 6),
                WebTag(st.kind.label, fontSize: 11),
              ]),
              const SizedBox(height: 2),
              Text(caption, style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
            ]),
          ),
        ]);
        final total = Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text.rich(TextSpan(children: [
            TextSpan(text: hours(work + tbd + leave), style: AppText.style(20, FontWeight.w500)),
            TextSpan(text: ' / 40h', style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
          ])),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              width: 110,
              height: 6,
              child: ColoredBox(
                color: AppColors.bg,
                child: Row(children: [
                  Container(width: 110 * seg(work), color: AppColors.primary),
                  Container(width: 110 * seg(tbd), color: AppColors.primarySoft),
                  Container(width: 110 * seg(leave), color: AppColors.textTertiary),
                ]),
              ),
            ),
          ),
        ]);
        final week = Row(children: cells);
        if (c.maxWidth < 760) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [Expanded(child: who), total]),
            const SizedBox(height: 12),
            week,
          ]);
        }
        return Row(children: [
          SizedBox(width: 220, child: who),
          const SizedBox(width: 16),
          Expanded(child: week),
          const SizedBox(width: 16),
          SizedBox(width: 120, child: total),
        ]);
      }),
    );
  }
}

class _SubstituteCard extends StatelessWidget {
  const _SubstituteCard(this.subs);

  final List<SubstituteRequest> subs;

  Future<void> _approve(BuildContext context, SubstituteRequest r) async {
    final store = AppScope.read(context);
    final ok = await showConfirmDialog(
      context,
      title: '대타를 승인할까요?',
      message:
          '${store.nameOf(r.requesterId)}님 근무를 ${store.nameOf(r.acceptedId)}님이 대신해요. 근무표에 바로 반영돼요.',
      confirmLabel: '승인',
    );
    if (!ok || !context.mounted) return;
    store.approveSubstitute(r.id);
    showToast(context, '대타를 승인했어요');
  }

  void _resend(BuildContext context, SubstituteRequest r) {
    AppScope.read(context).resendSubstitute(r.id);
    showToast(context, '동료들에게 다시 알렸어요');
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('대타 승인 대기', style: AppText.style(15, FontWeight.w500))),
            InkWell(
              onTap: () => WebShell.open(context, WebMenu.substitute),
              child: Text('전체 보기 ›',
                  style: AppText.style(12, FontWeight.w500, AppColors.primary)),
            ),
          ]),
          if (subs.isEmpty) const EmptyNote('진행 중인 대타 요청이 없어요'),
          for (final r in subs.take(3)) ...[
            const SizedBox(height: 12),
            if (store.shiftById(r.shiftId) case final s?)
              r.status == SubStatus.accepted
                  ? _SubItem('${shiftDay(s)} ${shiftTime(s)}',
                      '${store.nameOf(r.requesterId)} → ${store.nameOf(r.acceptedId)} 수락',
                      '승인', true, () => _approve(context, r))
                  : _SubItem('${shiftDay(s)} ${shiftTime(s)}',
                      '${store.nameOf(r.requesterId)} · 동료 응답 대기',
                      '재알림', false, () => _resend(context, r)),
          ],
        ],
      ),
    );
  }
}

class _SubItem extends StatelessWidget {
  const _SubItem(this.title, this.caption, this.action, this.primary, this.onAction);

  final String title, caption, action;
  final bool primary;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: AppColors.bg, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppText.style(13, FontWeight.w500)),
              Text(caption,
                  style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
            ]),
          ),
          const SizedBox(width: 10),
          WebButton(
            action,
            style: primary ? WebButtonStyle.primary : WebButtonStyle.outline,
            height: 32,
            fontSize: 12,
            radius: 10,
            onPressed: onAction,
          ),
        ]),
      );
}

class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.certs});

  final List<(Staff, int?)> certs;

  void onNavigate(BuildContext context, int page) => WebShell.open(context, page);

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final unsigned =
        store.activeStaff.where((s) => !(s.contract?.signed ?? false)).toList();
    final checklist = laborChecklist(store);
    final done = checklist.where((x) => x.$2).length;
    final risks = <Widget>[
      for (final (s, left) in certs)
        _Risk(
          AppColors.danger,
          AppColors.dangerSoft,
          left == null ? '보건증 미등록' : '보건증 만료 ${certLabel(left)}',
          '${store.personOf(s).name}님 · 갱신 후 사진 등록 필요',
          onTap: () => showStaffSheet(context, s.id),
        ),
      if (unsigned.isNotEmpty)
        _Risk(
          AppColors.accent,
          AppColors.accentSoft,
          '전자 근로계약서 미서명 ${unsigned.length}건',
          '${store.personOf(unsigned.first).name}님'
              '${unsigned.length > 1 ? ' 외 ${unsigned.length - 1}명' : ''} · 서명 요청 보내기',
          onTap: () => onNavigate(context, WebMenu.documents),
        ),
      _Risk(
        AppColors.info,
        AppColors.infoSoft,
        '노무 체크리스트 $done/${checklist.length} 완료',
        store.store.isSmall ? '5인 미만 · 가산수당 미적용' : '5인 이상 · 가산수당 · 연차 적용',
        onTap: () => onNavigate(context, WebMenu.documents),
      ),
    ];
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('노무 리스크 알림', style: AppText.style(15, FontWeight.w500)),
          for (final r in risks) ...[const SizedBox(height: 12), r],
        ],
      ),
    );
  }
}

class _Risk extends StatelessWidget {
  const _Risk(this.color, this.soft, this.title, this.caption, {required this.onTap});

  final Color color, soft;
  final String title, caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Row(children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: soft,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppText.style(13, FontWeight.w500)),
              Text(caption,
                  style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
            ]),
          ),
        ]),
      );
}

/// 알림 목록. 누르면 읽음 처리하고 관련 메뉴로 간다.
Future<void> _showNotifications(BuildContext context) {
  final store = AppScope.read(context);
  int? target(AppNotification n) => switch (n.type) {
        'sub' => WebMenu.substitute,
        'join' => WebMenu.staff,
        'cert' || 'contract' => WebMenu.documents,
        'notice' => WebMenu.notice,
        _ => null,
      };
  return showWebDialog<void>(
    context,
    title: '알림',
    builder: (ctx, set) {
      final list = AppScope.of(ctx).myNotifications;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (list.isEmpty) const EmptyNote('새 알림이 없어요'),
        for (final n in list.take(20))
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              store.markNotificationRead(n.id);
              Navigator.pop(ctx);
              // 근태 알림(퇴근 미기록·자동 퇴근)은 오늘 근무 창에서 바로 고친다.
              if (n.type == 'pay') {
                showTodayAttendance(context);
              } else {
                final page = target(n);
                if (page != null) WebShell.open(context, page);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  decoration: BoxDecoration(
                      color: n.read ? Colors.transparent : AppColors.danger, shape: BoxShape.circle),
                ),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n.title,
                        style: AppText.style(14, n.read ? FontWeight.w400 : FontWeight.w500)),
                    if (n.body.isNotEmpty)
                      Text(n.body,
                          style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                  ]),
                ),
                Text(relative(DateTime.parse(n.createdAt), store.now),
                    style: AppText.style(11, FontWeight.w400, AppColors.textTertiary)),
              ]),
            ),
          ),
      ]);
    },
    actions: (ctx, set) => [
      WebButton('모두 읽음',
          style: WebButtonStyle.outline,
          onPressed: store.unreadNotificationCount == 0
              ? null
              : () => set(store.markAllNotificationsRead)),
    ],
  );
}

/// 오늘 근무 · 출근 현황. 기록이 틀리면 바로 고친다.
Future<void> showTodayAttendance(BuildContext context) {
  final store = AppScope.read(context);
  return showWebDialog<void>(
    context,
    title: '오늘 근무 · ${md(store.today)}',
    width: 520,
    builder: (ctx, set) {
      final s = AppScope.of(ctx);
      final list = s.shiftsOn(s.today);
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (list.isEmpty) const EmptyNote('오늘 근무가 없어요'),
        for (final shift in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration:
                  BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                MemberAvatar(s.staffById(shift.staffId)!, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${s.nameOf(shift.staffId)} · ${shift.part == '직원' ? '유동 근무' : shift.part}',
                        style: AppText.style(14, FontWeight.w500)),
                    Text(_attText(s, shift),
                        style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                  ]),
                ),
                attStatusTag(s, shift),
                const SizedBox(width: 8),
                WebButton('수정',
                    height: 32,
                    fontSize: 12,
                    radius: 10,
                    style: WebButtonStyle.outline,
                    onPressed: () => _editAttendance(ctx, shift)),
              ]),
            ),
          ),
      ]);
    },
  );
}

String _attText(AppStore s, Shift shift) {
  final a = s.attendanceFor(shift.id);
  final plan = '예정 ${shiftTime(shift)}';
  if (a == null) return plan;
  final out = a.clockOut == null ? '근무 중' : '${clock(DateTime.parse(a.clockOut!))} 퇴근';
  return '$plan · ${clock(DateTime.parse(a.clockIn))} 출근 · $out';
}

/// 출퇴근 기록 직접 입력 · 수정. 사유는 직원에게 알림으로 간다.
Future<void> _editAttendance(BuildContext context, Shift shift) {
  final store = AppScope.read(context);
  final a = store.attendanceFor(shift.id);
  final day = parseYmd(shift.date);
  var inMin = a == null ? shift.startMin : _minOf(DateTime.parse(a.clockIn), day);
  int? outMin = a?.clockOut == null ? null : _minOf(DateTime.parse(a!.clockOut!), day);
  // 끝난 근무는 퇴근 없이 저장하지 않는다(근무 중 기록이 남는다). 소정 종료로 시작.
  if (outMin == null && !store.shiftEnd(shift).isAfter(store.now)) outMin = shift.endMin;
  final reason = TextEditingController();
  String? error;
  return showWebDialog<void>(
    context,
    title: '${store.nameOf(shift.staffId)} · ${shiftDay(shift)} 근태 ${a == null ? '입력' : '수정'}',
    builder: (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      webPair(
        webField(
            '출근',
            FieldBox(hm(inMin), onTap: () async {
              final v = await pickTime(ctx, inMin);
              if (v != null) set(() => inMin = v);
            })),
        webField(
            '퇴근',
            FieldBox(outMin == null ? '근무 중' : hm(outMin!), onTap: () async {
              final v = await pickTime(ctx, outMin ?? shift.endMin);
              if (v != null) set(() => outMin = v);
            })),
      ),
      const SizedBox(height: 16),
      webField('수정 사유', AppTextField(controller: reason, hint: '예: 출근 태깅 누락')),
      if (error != null) ...[
        const SizedBox(height: 10),
        Text(error!, style: AppText.style(13, FontWeight.w500, AppColors.danger)),
      ],
    ]),
    actions: (ctx, set) => [
      WebButton('취소', style: WebButtonStyle.outline, onPressed: () => Navigator.pop(ctx)),
      WebButton('저장', onPressed: () {
        if (reason.text.trim().isEmpty) return set(() => error = '수정 사유를 적어 주세요');
        final clockIn = day.add(Duration(minutes: attendanceInMin(shift, inMin)));
        DateTime? clockOut;
        if (outMin != null) {
          clockOut = day.add(Duration(minutes: outMin!));
          if (!clockOut.isAfter(clockIn)) clockOut = clockOut.add(const Duration(days: 1));
        }
        if (a == null) {
          store.createAttendance(shift.id,
              clockIn: clockIn, clockOut: clockOut, reason: reason.text.trim());
        } else {
          store.editAttendance(a.id,
              clockIn: clockIn, clockOut: clockOut, reason: reason.text.trim());
        }
        Navigator.pop(ctx);
      }),
    ],
  );
}

int _minOf(DateTime t, DateTime day) => t.difference(day).inMinutes;

/// 출근 시각(근무 날짜 기준 분). 자정을 넘는 근무에서 시작보다 12시간 넘게 이른
/// 시각(예: 22:00 근무의 00:10)은 다음 날 출근으로 본다.
int attendanceInMin(Shift shift, int inMin) =>
    shift.endAbs > 1440 && inMin < shift.startMin - 720 ? inMin + 1440 : inMin;
