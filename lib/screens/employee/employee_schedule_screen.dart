import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'leave_request_screen.dart';
import 'shift_detail_screen.dart';
import 'employee_parts.dart';

/// A3 근무표 (탭 루트).
class EmployeeScheduleScreen extends StatefulWidget {
  const EmployeeScheduleScreen({super.key});

  @override
  State<EmployeeScheduleScreen> createState() => _EmployeeScheduleScreenState();
}

const _days = [
  ('월', 12, true),
  ('화', 13, false),
  ('수', 14, true),
  ('목', 15, false),
  ('금', 16, true),
  ('토', 17, true),
  ('일', 18, false),
];

const _shifts = [
  ('월', '12', '14:00 – 20:00 · 홀', '완료', AppColors.textSecondary, AppColors.bg),
  ('수', '14', '14:00 – 20:00 · 홀', '오늘', AppColors.primary, AppColors.primarySoft),
  ('금', '16', '10:00 – 16:00 · 주방', '휴무 신청 중', AppColors.accent, AppColors.accentSoft),
  ('토', '17', '16:00 – 22:00 · 홀', '대타 확정', AppColors.info, AppColors.infoSoft),
];

class _EmployeeScheduleScreenState extends State<EmployeeScheduleScreen> {
  int _selected = 2;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(
          children: [
            const TabTitle('근무표', chip: '5월 2주차'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  for (var i = 0; i < _days.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(child: _day(i)),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  Text('이번 주 내 근무', style: AppText.style(15, FontWeight.w700)),
                  for (final s in _shifts) ...[
                    const SizedBox(height: 12),
                    _shiftCard(context, s),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: AppButton(
                '휴무 · 대타 신청',
                icon: 'send',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LeaveRequestScreen()),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _day(int i) {
    final (label, date, hasShift) = _days[i];
    final selected = i == _selected;
    final fg = selected ? AppColors.onPrimary : AppColors.textPrimary;
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _selected = i),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Text(label,
                  style: AppText.style(12, FontWeight.w500,
                      selected ? AppColors.onPrimary : AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text('$date', style: AppText.style(16, FontWeight.w700, fg)),
              const SizedBox(height: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: !hasShift
                      ? Colors.transparent
                      : selected
                          ? AppColors.onPrimary
                          : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shiftCard(
    BuildContext context,
    (String, String, String, String, Color, Color) s,
  ) {
    final (day, date, time, status, fg, bg) = s;
    return AppCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ShiftDetailScreen()),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(day,
                  style: AppText.style(12, FontWeight.w500, AppColors.textSecondary)),
              Text(date, style: AppText.style(20, FontWeight.w700)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: AppText.style(15, FontWeight.w700)),
                const SizedBox(height: 2),
                Text('카페 커푸치노',
                    style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Pill(status, color: fg, background: bg),
        ],
      ),
    );
  }
}
