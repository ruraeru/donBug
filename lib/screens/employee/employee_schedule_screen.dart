import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../employer/employer_parts.dart';
import 'employee_parts.dart';
import 'leave_request_screen.dart';
import 'shift_detail_screen.dart';

/// A3 근무표 (탭 루트). 주 이동 · 날짜를 누르면 그날만 보기.
class EmployeeScheduleScreen extends StatefulWidget {
  const EmployeeScheduleScreen({super.key});

  @override
  State<EmployeeScheduleScreen> createState() => _EmployeeScheduleScreenState();
}

class _EmployeeScheduleScreenState extends State<EmployeeScheduleScreen> {
  int _weekOffset = 0;
  DateTime? _day;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final monday = mondayOf(store.today).add(Duration(days: 7 * _weekOffset));
    final days = [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
    final weekShifts = store.myShifts.where((s) {
      final d = parseYmd(s.date);
      return !d.isBefore(monday) && d.isBefore(monday.add(const Duration(days: 7)));
    }).toList();
    final shown = _day == null
        ? weekShifts
        : weekShifts.where((s) => s.date == ymd(_day!)).toList();
    final weekNo = ((monday.add(const Duration(days: 3)).day - 1) ~/ 7) + 1;
    return SafeArea(
      child: Column(
        children: [
          TabTitle('근무표', chip: '${monday.add(const Duration(days: 3)).month}월 $weekNo주차'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: PeriodNav(
                label: '${md(days.first)} – ${md(days.last)}',
                prevTip: '이전 주',
                nextTip: '다음 주',
                onPrev: () => setState(() {
                  _weekOffset--;
                  _day = null;
                }),
                onNext: () => setState(() {
                  _weekOffset++;
                  _day = null;
                }),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                for (var i = 0; i < 7; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _dayChip(store, days[i],
                        weekShifts.any((s) => s.date == ymd(days[i]))),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                Text(_day == null ? '${_weekOffset == 0 ? '이번 주' : '이 주'} 내 근무' : '${md(_day!)} 내 근무',
                    style: AppText.style(15, FontWeight.w500)),
                if (shown.isEmpty) const EmptyNote('근무가 없어요'),
                for (final s in shown) ...[
                  const SizedBox(height: 12),
                  _shiftCard(context, store, s),
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
  }

  Widget _dayChip(AppStore store, DateTime d, bool hasShift) {
    final selected = _day == d;
    final isToday = d == store.today;
    final fg = selected ? AppColors.onPrimary : AppColors.textPrimary;
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isToday && !selected
            ? const BorderSide(color: AppColors.primary)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _day = selected ? null : d),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(weekday(d),
                  style: AppText.style(12, FontWeight.w500,
                      selected ? AppColors.onPrimary : AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text('${d.day}', style: AppText.style(16, FontWeight.w500, fg)),
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

  Widget _shiftCard(BuildContext context, AppStore store, Shift s) {
    final (status, fg, bg) = shiftStatus(store, s);
    final d = parseYmd(s.date);
    return AppCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ShiftDetailScreen(shiftId: s.id)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(weekday(d), style: AppText.style(12, FontWeight.w500, AppColors.textSecondary)),
              Text('${d.day}', style: AppText.style(20, FontWeight.w500)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(shiftTime(s), style: AppText.style(15, FontWeight.w500)),
                  const SizedBox(width: 8),
                  Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: partColors(s.part).$1, shape: BoxShape.circle))),
                  Text(s.part, style: AppText.style(15, FontWeight.w500)),
                ]),
                const SizedBox(height: 2),
                Text(store.store.name,
                    style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (bg == Colors.transparent)
            Text(status, style: AppText.style(13, FontWeight.w400, AppColors.textSecondary))
          else
            Pill(status, color: fg, background: bg),
        ],
      ),
    );
  }
}
