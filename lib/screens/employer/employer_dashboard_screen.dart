import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'attendance_screen.dart';
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
  Widget build(BuildContext context) => SafeArea(
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
                            Text('카페 커푸치노',
                                style: AppText.style(22, FontWeight.w700)),
                            const SizedBox(width: 2),
                            const AppIcon('chevron_right',
                                size: 22, color: AppColors.textTertiary),
                          ]),
                          const SizedBox(height: 2),
                          Text('사장님 · 5/14(수)',
                              style: AppText.style(
                                  13, FontWeight.w400, AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  const AppIcon('bell'),
                ],
              ),
              const SizedBox(height: 20),
              AppCard(
                color: AppColors.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('이번 달 예상 인건비',
                        style: AppText.style(13, FontWeight.w500, AppColors.onPrimary)),
                    const SizedBox(height: 8),
                    Text('₩ 4,812,000',
                        style: AppText.style(32, FontWeight.w700, AppColors.onPrimary)),
                    const SizedBox(height: 8),
                    Text('지난달 대비 -3% · 근로자 5명',
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
                      value: '3명',
                      note: '출근 2 · 대기 1',
                      noteColor: AppColors.primary,
                      onTap: () => _push(context, const AttendanceScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: '대타 모집',
                      value: '1건',
                      note: '지원자 2명',
                      noteColor: AppColors.accent,
                      onTap: () => _push(context, const SubstituteApprovalScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppCard(
                color: AppColors.accentSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Pill('인력 공백 주의',
                            color: AppColors.accent, background: AppColors.surface),
                        const Spacer(),
                        Text('5분 전',
                            style: AppText.style(
                                12, FontWeight.w400, AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('5/16(금) 10:00–16:00 주방',
                        style: AppText.style(16, FontWeight.w700)),
                    const SizedBox(height: 10),
                    Text('지민님이 휴무를 신청했어요 · 대타 지원 2명',
                        style: AppText.style(
                            13, FontWeight.w400, AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    AppButton(
                      '지원자 확인하고 확정',
                      verticalPadding: 12,
                      fontSize: 15,
                      onPressed: () =>
                          _push(context, const SubstituteApprovalScreen()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                color: AppColors.dangerSoft,
                onTap: () => _push(context, const StaffManagementScreen()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Pill('보건증 D-12',
                            color: AppColors.danger, background: AppColors.surface),
                        Spacer(),
                        AppIcon('chevron_right', size: 20, color: AppColors.danger),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('수빈님 보건증이 곧 만료돼요',
                        style: AppText.style(15, FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.note,
    required this.noteColor,
    this.onTap,
  });

  final String label;
  final String value;
  final String note;
  final Color noteColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppText.style(13, FontWeight.w500, AppColors.textSecondary)),
            const SizedBox(height: 6),
            Text(value, style: AppText.style(26, FontWeight.w700)),
            const SizedBox(height: 6),
            Text(note, style: AppText.style(12, FontWeight.w400, noteColor)),
          ],
        ),
      );
}
