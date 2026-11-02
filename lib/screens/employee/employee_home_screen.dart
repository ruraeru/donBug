import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/tab_shell.dart';
import 'clock_out_done_screen.dart';
import 'notification_center_screen.dart';
import 'qr_check_in_screen.dart';
import 'substitute_detail_screen.dart';

/// A2 알바생 홈 (탭 루트). 출근 전 ↔ 근무 중 상태를 로컬로 전환한다.
class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  bool _working = false;

  Future<void> _checkIn() async {
    final ok = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => const QrCheckInScreen()));
    if (ok == true && mounted) setState(() => _working = true);
  }

  Future<void> _checkOut() async {
    setState(() => _working = false);
    final openSchedule = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => const ClockOutDoneScreen()));
    // 퇴근 완료의 "근무표 보기" → 근무표 탭(index 1).
    if (openSchedule == true && mounted) TabShell.of(context)?.select(1);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
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
                        Text('안녕하세요, 태우님',
                            style: AppText.style(22, FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('카페 커푸치노 · 알바생',
                            style: AppText.style(
                                13, FontWeight.w400, AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationCenterScreen())),
                    icon: const AppIcon('bell'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                children: [
                  _working
                      ? _WorkingCard(onCheckOut: _checkOut)
                      : _TodayCard(onCheckIn: _checkIn),
                  const SizedBox(height: 16),
                  _PayCard(working: _working),
                  if (!_working) ...[
                    const SizedBox(height: 16),
                    const _SubstituteCard(),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.onCheckIn});

  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) => AppCard(
        color: AppColors.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('오늘 근무',
                style: AppText.style(13, FontWeight.w500, AppColors.onPrimary)),
            const SizedBox(height: 14),
            Text('14:00 – 20:00',
                style: AppText.style(30, FontWeight.w700, AppColors.onPrimary)),
            const SizedBox(height: 14),
            Text('6시간 · 홀 서빙 · 휴게 30분',
                style: AppText.style(13, FontWeight.w400, AppColors.onPrimary)),
            const SizedBox(height: 14),
            AppButton('출근하기',
                icon: 'scan',
                variant: AppButtonVariant.surface,
                onPressed: onCheckIn),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: Text('매장 POS 화면의 QR 코드를 스캔하세요',
                  textAlign: TextAlign.center,
                  style:
                      AppText.style(12, FontWeight.w400, AppColors.onPrimary)),
            ),
          ],
        ),
      );
}

class _WorkingCard extends StatelessWidget {
  const _WorkingCard({required this.onCheckOut});

  final VoidCallback onCheckOut;

  @override
  Widget build(BuildContext context) => AppCard(
        color: AppColors.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('근무 중 · 14:02 출근',
                style: AppText.style(13, FontWeight.w500, AppColors.onPrimary)),
            const SizedBox(height: 10),
            // shortcut: 경과 시간은 고정 더미, 실제 타이머는 출퇴근 데이터 연동 시.
            Text('01:24:08',
                style: AppText.style(40, FontWeight.w700, AppColors.onPrimary)),
            const SizedBox(height: 10),
            Text('예상 퇴근 20:00 · 오늘 일급 ₩14,092',
                style: AppText.style(13, FontWeight.w400, AppColors.onPrimary)),
            const SizedBox(height: 10),
            AppButton('퇴근하기',
                variant: AppButtonVariant.soft, onPressed: onCheckOut),
          ],
        ),
      );
}

class _PayCard extends StatelessWidget {
  const _PayCard({required this.working});

  final bool working;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('이번 달 예상 실수령액',
                      style: AppText.style(
                          14, FontWeight.w500, AppColors.textSecondary)),
                ),
                const Pill('세후 반영'),
              ],
            ),
            const SizedBox(height: 12),
            Text(working ? '₩ 856,349' : '₩ 842,257',
                style: AppText.style(30, FontWeight.w700)),
            const SizedBox(height: 12),
            Text(
              working
                  ? '근무 63시간 · 세금 3.3% 반영'
                  : '근무 62시간 · 세금 3.3% 반영 · 지난달보다 +12%',
              style: AppText.style(13, FontWeight.w400, AppColors.textSecondary),
            ),
          ],
        ),
      );
}

class _SubstituteCard extends StatelessWidget {
  const _SubstituteCard();

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Pill.accent('대타 구해요'),
                const Spacer(),
                Text('방금 전',
                    style: AppText.style(
                        12, FontWeight.w400, AppColors.textTertiary)),
              ],
            ),
            const SizedBox(height: 12),
            Text('5/14(수) 18:00 – 22:00',
                style: AppText.style(17, FontWeight.w700)),
            const SizedBox(height: 12),
            Text('수빈님이 대타를 찾고 있어요 · 사유: 병원 진료',
                style:
                    AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
            const SizedBox(height: 12),
            AppButton(
              '지원하기',
              variant: AppButtonVariant.soft,
              verticalPadding: 12,
              fontSize: 15,
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SubstituteDetailScreen())),
            ),
          ],
        ),
      );
}
