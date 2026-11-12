import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/tab_shell.dart';
import '../employee/notification_center_screen.dart';
import 'attendance_screen.dart';
import 'employer_parts.dart';
import 'staff_approval_screen.dart';
import 'staff_detail_screen.dart';
import 'staff_management_screen.dart';
import 'store_settings_screen.dart';
import 'substitute_approval_screen.dart';

/// B1 사장님 대시보드 (Figma 47:139, 대타 알림 변형 47:502 — 레이아웃 동일).
/// 탭 루트: 하단 탭바는 EmployerShell 이 그린다.
class EmployerDashboardScreen extends StatelessWidget {
  const EmployerDashboardScreen({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final t = store.today;
    final total = store.laborTotal(t.year, t.month, projected: true);
    final last = store.laborTotal(t.year, t.month - 1);
    final diff = last == 0 ? 0 : ((total - last) / last * 100).round();
    final todayShifts = store.shiftsOn(t);
    final statuses = todayShifts.map(store.attendanceStatus).toList();
    final present = statuses
        .where((s) => s == AttStatus.normal || s == AttStatus.late || s == AttStatus.working)
        .length;
    final waiting = statuses.where((s) => s == AttStatus.waiting).length;
    final subs = store.pendingSubs;
    final accepted = subs.where((r) => r.status == SubStatus.accepted).length;
    final alertSub = subs.where((r) => r.status == SubStatus.accepted).firstOrNull ?? subs.firstOrNull;
    final pending = store.pendingStaff;
    final cert = _nearestCert(store);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  // 매장 이름 → 매장 설정 (Figma에 진입 경로가 없어 임시 배치).
                  child: InkWell(
                    onTap: () => _push(context, const StoreSettingsScreen()),
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Flexible(
                            child: Text(store.store.name,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.style(22, FontWeight.w500)),
                          ),
                          const SizedBox(width: 2),
                          const AppIcon('chevron_right', size: 22, color: AppColors.textTertiary),
                        ]),
                        const SizedBox(height: 2),
                        Text('사장님 · ${md(t)}',
                            style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '알림',
                  onPressed: () => _push(
                      context, const NotificationCenterScreen(onOpen: employerTarget)),
                  icon: CountBadge(
                      count: store.unreadNotificationCount, child: const AppIcon('bell')),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppCard(
              color: AppColors.primary,
              onTap: () => TabShell.of(context)?.select(2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('이번 달 예상 인건비',
                      style: AppText.style(13, FontWeight.w500, AppColors.onPrimary)),
                  const SizedBox(height: 8),
                  Text(won(total), style: AppText.style(32, FontWeight.w500, AppColors.onPrimary)),
                  const SizedBox(height: 8),
                  Text(
                      '지난달 대비 ${diff >= 0 ? '+' : ''}$diff% · 근로자 ${store.activeStaff.length}명',
                      style: AppText.style(13, FontWeight.w400, AppColors.onPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: '오늘 근무',
                    value: '${todayShifts.length}명',
                    note: '출근 $present · 대기 $waiting',
                    onTap: () => _push(context, const AttendanceScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: '대타 모집',
                    value: '${subs.length}건',
                    note: '승인 대기 $accepted',
                    onTap: () => _push(context, const SubstituteApprovalScreen()),
                  ),
                ),
              ],
            ),
            if (alertSub != null) ...[
              const SizedBox(height: 16),
              _SubAlert(store: store, request: alertSub),
            ],
            if (pending.isNotEmpty) ...[
              const SizedBox(height: 16),
              AppCard(
                onTap: () => _push(context, const StaffApprovalScreen()),
                child: Row(children: [
                  Expanded(
                    child: Text('가입 신청 ${pending.length}명 · ${store.nameOf(pending.first.id)}님${pending.length > 1 ? ' 외' : ''}',
                        style: AppText.style(15, FontWeight.w500)),
                  ),
                  const AppIcon('chevron_right', size: 20, color: AppColors.textTertiary),
                ]),
              ),
            ],
            if (cert != null) ...[
              const SizedBox(height: 16),
              AppCard(
                onTap: () => _push(context, StaffDetailScreen(staffId: cert.$1.id)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Pill(cert.$2 < 0 ? '보건증 만료' : '보건증 D-${cert.$2}',
                            color: AppColors.danger, background: AppColors.dangerSoft),
                        const Spacer(),
                        const AppIcon('chevron_right', size: 20, color: AppColors.textTertiary),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                        '${store.nameOf(cert.$1.id)}님 보건증이 ${cert.$2 < 0 ? '만료됐어요' : '곧 만료돼요'}',
                        style: AppText.style(15, FontWeight.w500)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            PersonRow(
              avatar: const LetterAvatar('직'),
              title: '직원 관리',
              subtitle: '재직 ${store.activeStaff.length}명',
              trailing: const AppIcon('chevron_right', size: 20, color: AppColors.textTertiary),
              onTap: () => _push(context, const StaffManagementScreen()),
            ),
          ],
        ),
      ),
    );
  }

  /// 만료 30일 이내 보건증 중 가장 급한 직원.
  (Staff, int)? _nearestCert(AppStore store) {
    (Staff, int)? best;
    for (final s in store.activeStaff) {
      final d = store.certDaysLeft(store.personOf(s));
      if (d != null && d <= 30 && (best == null || d < best.$2)) best = (s, d);
    }
    return best;
  }
}

class _SubAlert extends StatelessWidget {
  const _SubAlert({required this.store, required this.request});

  final AppStore store;
  final SubstituteRequest request;

  @override
  Widget build(BuildContext context) {
    final s = store.shiftById(request.shiftId)!;
    final accepted = request.acceptedId != null;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Pill(accepted ? '대타 승인 필요' : '인력 공백 주의',
                  color: AppColors.accent, background: AppColors.accentSoft),
              const Spacer(),
              Text(relative(DateTime.parse(request.createdAt), store.now),
                  style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Text('${shiftDay(s)} ${shiftTime(s)} ${s.part}', style: AppText.style(16, FontWeight.w500)),
          const SizedBox(height: 8),
          Text(
              '${store.nameOf(request.requesterId)}님이 휴무를 신청했어요 · '
              '${accepted ? '${store.nameOf(request.acceptedId)}님 수락' : '지원 ${request.applicantIds.length}명'}',
              style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
          const SizedBox(height: 12),
          AppButton(
            '지원자 확인하고 확정',
            verticalPadding: 12,
            fontSize: 15,
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SubstituteApprovalScreen())),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.note,
    this.onTap,
  });

  final String label;
  final String value;
  final String note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.style(13, FontWeight.w500, AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(value, style: AppText.style(26, FontWeight.w500)),
            const SizedBox(height: 8),
            Text(note, style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
          ],
        ),
      );
}
