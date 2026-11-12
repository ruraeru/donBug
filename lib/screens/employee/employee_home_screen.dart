import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/tab_shell.dart';
import 'clock_out_done_screen.dart';
import 'notification_center_screen.dart';
import 'qr_check_in_screen.dart';
import 'substitute_detail_screen.dart';

/// A2 알바생 홈 (탭 루트). 오늘 근무 · 출근 중 타이머 · 예상 급여 · 대타 요청.
class EmployeeHomeScreen extends StatelessWidget {
  const EmployeeHomeScreen({super.key});

  Future<void> _checkIn(BuildContext context, Shift shift) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => QrCheckInScreen(shiftId: shift.id)));

  Future<void> _checkOut(BuildContext context) async {
    final ok = await showConfirmDialog(context,
        title: '퇴근할까요?',
        message: '지금 시각으로 퇴근 기록이 저장돼요.',
        confirmLabel: '퇴근하기');
    if (!ok || !context.mounted) return;
    final a = AppScope.read(context).clockOut();
    if (a == null) return;
    final openSchedule = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => ClockOutDoneScreen(attendanceId: a.id)));
    // 퇴근 완료의 "근무표 보기" → 근무표 탭(index 1).
    if (openSchedule == true && context.mounted) TabShell.of(context)?.select(1);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final open = store.myOpenAttendance;
    final today = store.myTodayShift;
    final sub = store.subsAvailableToMe.firstOrNull;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(md(store.today),
                          style: AppText.style(22, FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text('${store.store.name} · 알바생',
                          style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '알림',
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const NotificationCenterScreen())),
                  icon: CountBadge(
                      count: store.unreadNotificationCount, child: const AppIcon('bell')),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                if (open != null)
                  _WorkingCard(attendance: open, onCheckOut: () => _checkOut(context))
                else if (today != null && store.attendanceFor(today.id) == null)
                  _TodayCard(shift: today, onCheckIn: () => _checkIn(context, today))
                else
                  _NextShiftCard(store: store),
                const SizedBox(height: 16),
                _PayCard(store: store),
                if (sub != null && open == null) ...[
                  const SizedBox(height: 16),
                  _SubstituteCard(store: store, request: sub),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.shift, required this.onCheckIn});

  final Shift shift;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) => AppCard(
        color: AppColors.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shift.isSubstitute ? '오늘 근무 · 대타' : '오늘 근무',
                style: AppText.style(13, FontWeight.w500, AppColors.onPrimary)),
            const SizedBox(height: 12),
            Text(shiftTime(shift),
                style: AppText.style(30, FontWeight.w500, AppColors.onPrimary)),
            const SizedBox(height: 12),
            Text(shiftCaption(shift),
                style: AppText.style(13, FontWeight.w400, AppColors.onPrimary)),
            const SizedBox(height: 12),
            AppButton('출근하기',
                icon: 'scan', variant: AppButtonVariant.surface, onPressed: onCheckIn),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Text('매장 POS 화면의 QR 코드를 스캔하세요',
                  textAlign: TextAlign.center,
                  style: AppText.style(12, FontWeight.w400, AppColors.onPrimary)),
            ),
          ],
        ),
      );
}

/// 오늘 근무가 없거나 끝났을 때: 다음 근무 안내.
class _NextShiftCard extends StatelessWidget {
  const _NextShiftCard({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final next = store.myUpcomingShifts.firstOrNull;
    final doneToday = store.myShifts.any((s) =>
        s.date == ymd(store.today) && store.attendanceFor(s.id)?.clockOut != null);
    return AppCard(
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(doneToday ? '오늘 근무 완료 · 다음 근무' : '다음 근무',
              style: AppText.style(13, FontWeight.w500, AppColors.onPrimary)),
          const SizedBox(height: 12),
          Text(next == null ? '예정된 근무가 없어요' : '${shiftDay(next)} ${hm(next.startMin)}',
              style: AppText.style(next == null ? 20 : 30, FontWeight.w500, AppColors.onPrimary)),
          if (next != null) ...[
            const SizedBox(height: 12),
            Text('${shiftTime(next)} · ${shiftCaption(next)}',
                style: AppText.style(13, FontWeight.w400, AppColors.onPrimary)),
          ],
        ],
      ),
    );
  }
}

/// 근무 중: 1초마다 경과 시간을 다시 그린다.
class _WorkingCard extends StatefulWidget {
  const _WorkingCard({required this.attendance, required this.onCheckOut});

  final Attendance attendance;
  final VoidCallback onCheckOut;

  @override
  State<_WorkingCard> createState() => _WorkingCardState();
}

class _WorkingCardState extends State<_WorkingCard> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final a = widget.attendance;
    final shift = store.shiftById(a.shiftId);
    final inAt = DateTime.parse(a.clockIn);
    final e = store.now.difference(inAt);
    String two(int n) => n.toString().padLeft(2, '0');
    final elapsed = e.isNegative
        ? '00:00:00'
        : '${two(e.inHours)}:${two(e.inMinutes % 60)}:${two(e.inSeconds % 60)}';
    return AppCard(
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('근무 중 · ${clock(inAt)} 출근',
              style: AppText.style(13, FontWeight.w500, AppColors.onPrimary)),
          const SizedBox(height: 12),
          Text(elapsed, style: AppText.style(40, FontWeight.w500, AppColors.onPrimary)),
          const SizedBox(height: 12),
          Text(
              '${shift == null ? '' : '예상 퇴근 ${hm(shift.endMin)} · '}지금까지 ${won(store.dayPay(a))}',
              style: AppText.style(13, FontWeight.w400, AppColors.onPrimary)),
          const SizedBox(height: 12),
          AppButton('퇴근하기', variant: AppButtonVariant.soft, onPressed: widget.onCheckOut),
        ],
      ),
    );
  }
}

class _PayCard extends StatelessWidget {
  const _PayCard({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final m = store.myStaff!;
    final t = store.today;
    final p = store.payslip(m.id, t.year, t.month, projected: true);
    final last = store.payslip(m.id, t.year, t.month - 1);
    final diff = last.net == 0 ? null : ((p.net - last.net) / last.net * 100).round();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('이번 달 예상 실수령액',
                    style: AppText.style(14, FontWeight.w500, AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(won(p.net), style: AppText.style(30, FontWeight.w500)),
          const SizedBox(height: 12),
          Text(
            '근무 ${hours(p.minutes)} 예정 포함 · ${m.deduction.short} 반영'
            '${diff == null ? '' : ' · 지난달보다 ${diff >= 0 ? '+' : ''}$diff%'}',
            style: AppText.style(13, FontWeight.w400, AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SubstituteCard extends StatelessWidget {
  const _SubstituteCard({required this.store, required this.request});

  final AppStore store;
  final SubstituteRequest request;

  @override
  Widget build(BuildContext context) {
    final s = store.shiftById(request.shiftId)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Pill.accent('대타 구해요'),
              const Spacer(),
              Text(relative(DateTime.parse(request.createdAt), store.now),
                  style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 12),
          Text('${shiftDay(s)} ${shiftTime(s)}', style: AppText.style(17, FontWeight.w500)),
          const SizedBox(height: 12),
          Text('${store.nameOf(request.requesterId)}님이 대타를 찾고 있어요 · 사유: ${request.reason}',
              style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
          const SizedBox(height: 12),
          AppButton(
            '지원하기',
            variant: AppButtonVariant.soft,
            verticalPadding: 12,
            fontSize: 15,
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => SubstituteDetailScreen(requestId: request.id))),
          ),
        ],
      ),
    );
  }
}
