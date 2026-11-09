import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_parts.dart';
import 'schedule_template_screen.dart';
import 'shift_add_screen.dart';

/// 주간 근무표 편집 (Figma 47:211). 탭 루트.
class EmployerScheduleScreen extends StatefulWidget {
  const EmployerScheduleScreen({super.key});

  @override
  State<EmployerScheduleScreen> createState() => _EmployerScheduleScreenState();
}

class _EmployerScheduleScreenState extends State<EmployerScheduleScreen> {
  DateTime? _day;

  void _push(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Future<void> _deleteShift(AppStore store, Shift s) async {
    final ok = await showConfirmDialog(context,
        title: '${store.nameOf(s.staffId)}님 근무를 삭제할까요?',
        message: '${shiftDay(s)} ${shiftTime(s)} ${s.part}',
        confirmLabel: '삭제',
        confirmVariant: AppButtonVariant.danger);
    if (ok && mounted) AppScope.read(context).deleteShift(s.id);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final day = _day ?? store.today;
    final monday = mondayOf(day);
    final shifts = store.shiftsOn(day);
    final partNames = {...store.store.parts.map((p) => p.name), ...shifts.map((s) => s.part)};
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        children: [
          Row(
            children: [
              Expanded(child: Text('근무표', style: AppText.style(24, FontWeight.w700))),
              GestureDetector(
                onTap: () => _push(const ScheduleTemplateScreen()),
                child: Text('템플릿', style: AppText.style(14, FontWeight.w700, AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: [
            IconButton(
              tooltip: '이전 주',
              onPressed: () => setState(() => _day = day.subtract(const Duration(days: 7))),
              icon: Text('‹', style: AppText.style(24)),
            ),
            Expanded(
              child: Text('${md(monday)} – ${md(monday.add(const Duration(days: 6)))}',
                  textAlign: TextAlign.center,
                  style: AppText.style(14, FontWeight.w500, AppColors.textSecondary)),
            ),
            IconButton(
              tooltip: '다음 주',
              onPressed: () => setState(() => _day = day.add(const Duration(days: 7))),
              icon: Text('›', style: AppText.style(24)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: _dayChip(store, monday.add(Duration(days: i)), day)),
              ],
            ],
          ),
          for (final part in partNames) ...[
            const SizedBox(height: 12),
            _partCard(store, part, shifts.where((s) => s.part == part).toList()),
          ],
          const SizedBox(height: 12),
          AppButton('+ 근무 추가', onPressed: () => _push(ShiftAddScreen(date: day))),
        ],
      ),
    );
  }

  Widget _partCard(AppStore store, String part, List<Shift> list) {
    final template = store.store.parts.where((p) => p.name == part).firstOrNull;
    final need = template?.need ?? 0;
    final short = need - list.length;
    final (fg, bg) = partColors(part);
    final time = list.isNotEmpty
        ? shiftTime(list.first)
        : template == null
            ? ''
            : range(template.startMin, template.endMin);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Pill(part, color: fg, background: bg),
              const SizedBox(width: 8),
              Expanded(child: Text(time, style: AppText.style(16, FontWeight.w700))),
              Text(
                need == 0
                    ? '${list.length}명'
                    : '필요 $need명 · ${short > 0 ? '$short명 부족' : '충족'}',
                style: AppText.style(
                    12, FontWeight.w400, short > 0 ? AppColors.danger : AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (list.isEmpty)
            Text('배정된 근무자가 없어요',
                style: AppText.style(14, FontWeight.w400, AppColors.textTertiary))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in list)
                  InkWell(
                    onLongPress: () => _deleteShift(store, s),
                    onTap: () => _deleteShift(store, s),
                    borderRadius: BorderRadius.circular(999),
                    child: Pill(
                      '${store.nameOf(s.staffId)}${s.isSubstitute ? ' · 대타' : ''}'
                      '${s.startMin != template?.startMin || s.endMin != template?.endMin ? ' ${shiftTime(s)}' : ''}',
                      color: AppColors.textSecondary,
                      background: AppColors.bg,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _dayChip(AppStore store, DateTime d, DateTime selected) {
    final on = d == selected;
    final isToday = d == store.today;
    return GestureDetector(
      onTap: () => setState(() => _day = d),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: on ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !on ? Border.all(color: AppColors.primary) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(weekday(d),
                style: AppText.style(11, FontWeight.w400, on ? AppColors.onPrimary : AppColors.textTertiary)),
            Text('${d.day}',
                style: AppText.style(15, FontWeight.w700, on ? AppColors.onPrimary : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
