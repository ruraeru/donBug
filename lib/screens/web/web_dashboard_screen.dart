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
import 'web_shift_dialog.dart';
import 'web_staff_screen.dart';

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
                      ' · ${store.personOf(certs.first.$1).certAlertDays.where((d) => d > 0).join('·')}일 전 알림',
                  valueColor: AppColors.danger,
                  onTap: () => go(WebMenu.documents)),
        ]),
        WebSplit(
          breakpoint: 1000,
          left: _WeekCard(
            monday: mondayOf(t).add(Duration(days: 7 * _week)),
            onWeek: (d) => setState(() => _week += d),
          ),
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

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.monday, required this.onWeek});

  final DateTime monday;
  final ValueChanged<int> onWeek;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final days = [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
    final sunday = days.last;
    Widget arrow(String g, int d) => InkWell(
          onTap: () => onWeek(d),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(g, style: AppText.style(18, FontWeight.w400, AppColors.textSecondary)),
          ),
        );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('이번 주 근무표', style: AppText.style(17, FontWeight.w500))),
            arrow('‹', -1),
            const SizedBox(width: 4),
            Text('${monday.month}/${monday.day} – ${sunday.month}/${sunday.day}',
                style: AppText.style(13, FontWeight.w500)),
            const SizedBox(width: 4),
            arrow('›', 1),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 30,
            child: Row(children: [
              const SizedBox(width: 84),
              for (final d in days)
                Expanded(
                  child: Center(
                    child: d == store.today
                        ? Pill('${weekday(d)} ${d.day}',
                            color: AppColors.onPrimary, background: AppColors.primary)
                        : Text('${weekday(d)} ${d.day}',
                            style: AppText.style(12, FontWeight.w500, AppColors.textTertiary)),
                  ),
                ),
            ]),
          ),
          if (store.activeStaff.isEmpty) const EmptyNote('재직 중인 직원이 없어요'),
          for (final s in store.activeStaff) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: Row(children: [
                SizedBox(
                    width: 84,
                    child: Text(store.personOf(s).name,
                        style: AppText.style(14, FontWeight.w500))),
                for (final d in days)
                  Expanded(child: _cell(context, store, s, d)),
              ]),
            ),
          ],
          const SizedBox(height: 18),
          const Wrap(spacing: 14, children: [
            _Legend(AppColors.primarySoft, '근무'),
            _Legend(AppColors.accentSoft, '대타 모집·승인 대기'),
          ]),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, AppStore store, Staff staff, DateTime day) {
    final shift = store
        .shiftsOn(day)
        .where((x) => x.staffId == staff.id)
        .firstOrNull;
    if (shift == null) return const SizedBox();
    final sub = store.pendingSubFor(shift.id) != null;
    final label = '${_shortRange(shift)}${sub ? ' 대타' : ''}';
    return Center(
      child: InkWell(
        onTap: () => showShiftDialog(context, shift: shift, date: day),
        borderRadius: BorderRadius.circular(10),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: sub
              ? WebTag(label, color: AppColors.accent, background: AppColors.accentSoft)
              : day == store.today
                  ? WebTag(label, color: AppColors.onPrimary, background: AppColors.primary)
                  : WebTag(label),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
      ]);
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
              final page = target(n);
              if (page != null) WebShell.open(context, page);
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
                    Text('${s.nameOf(shift.staffId)} · ${shift.part}',
                        style: AppText.style(14, FontWeight.w500)),
                    Text(_attText(s, shift),
                        style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                  ]),
                ),
                Builder(builder: (_) {
                  final (label, fg, bg) = attStyle(s.attendanceStatus(shift));
                  return Pill(label, color: fg, background: bg);
                }),
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
        final clockIn = day.add(Duration(minutes: inMin));
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
