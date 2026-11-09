import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../employer/employer_parts.dart';
import '../employer/schedule_template_screen.dart';
import '../employer/shift_add_screen.dart';
import 'web_common.dart';

/// W2 근무표 편집 (콘텐츠 영역). 오른쪽 직원을 끌어다 칸에 놓으면 그 파트 시간으로 배정,
/// 칸의 이름을 누르면 삭제.
class WebScheduleScreen extends StatefulWidget {
  const WebScheduleScreen({super.key});

  @override
  State<WebScheduleScreen> createState() => _WebScheduleScreenState();
}

class _WebScheduleScreenState extends State<WebScheduleScreen> {
  /// 이번 주 기준 몇 주 떨어졌는지.
  int _week = 0;

  void _assign(String staffId, DateTime day, PartTemplate part) {
    final store = AppScope.read(context);
    final name = store.nameOf(staffId);
    if (day.isBefore(store.today)) {
      return showToast(context, '지난 날짜에는 배정할 수 없어요');
    }
    final draft = Shift(
      id: '',
      storeId: store.store.id,
      staffId: staffId,
      date: ymd(day),
      startMin: part.startMin,
      endMin: part.endMin,
      part: part.name,
    );
    if (store.overlappingShift(staffId, draft) case final other?) {
      return showToast(context, '$name님은 ${shiftDay(other)} ${shiftTime(other)}에 이미 근무가 있어요');
    }
    store.addShift(
        date: day,
        startMin: part.startMin,
        endMin: part.endMin,
        part: part.name,
        staffIds: [staffId]);
    showToast(context, '$name님을 ${md(day)} ${part.name}에 배정했어요');
  }

  Future<void> _delete(Shift s) async {
    final store = AppScope.read(context);
    final ok = await showConfirmDialog(
      context,
      title: '근무를 삭제할까요?',
      message: '${store.nameOf(s.staffId)} · ${shiftDay(s)} ${shiftTime(s)}',
      confirmLabel: '삭제',
      confirmVariant: AppButtonVariant.danger,
    );
    if (ok && mounted) store.deleteShift(s.id);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final monday = mondayOf(store.today).add(Duration(days: 7 * _week));
    final days = [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
    final sunday = days.last;
    int weekMinutes(Staff s) => store
        .shiftsOfStaff(s.id)
        .where((x) => !parseYmd(x.date).isBefore(monday) && !parseYmd(x.date).isAfter(sunday))
        .fold(0, (sum, x) => sum + x.scheduledMinutes);
    final addDate = monday.isBefore(store.today) ? store.today : monday;
    return WebPage(
      title: '근무표 편집',
      subtitle: '${monday.year}.${monday.month}.${monday.day} – ${sunday.month}.${sunday.day}'
          ' · 직원을 끌어다 칸에 놓으면 배정돼요',
      actions: [
        WebButton('‹', style: WebButtonStyle.outline, onPressed: () => setState(() => _week--)),
        WebButton('이번 주',
            style: WebButtonStyle.outline, onPressed: () => setState(() => _week = 0)),
        WebButton('›', style: WebButtonStyle.outline, onPressed: () => setState(() => _week++)),
        WebButton('템플릿 복사',
            style: WebButtonStyle.outline,
            onPressed: () => showMobilePanel(context, const ScheduleTemplateScreen())),
        WebButton('+ 근무 추가',
            onPressed: () => showMobilePanel(context, ShiftAddScreen(date: addDate))),
      ],
      children: [
        WebSplit(
          rightWidth: 280,
          gap: 20,
          left: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Column(children: [
              SizedBox(
                height: 30,
                child: Row(children: [
                  const SizedBox(width: 84),
                  for (final d in days) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: d == store.today ? AppColors.primary : null,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${weekday(d)} ${d.day}',
                          style: d == store.today
                              ? AppText.style(13, FontWeight.w700, AppColors.onPrimary)
                              : AppText.style(13, FontWeight.w400, AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ]),
              ),
              for (final part in store.store.parts) ...[
                const SizedBox(height: 10),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(
                    width: 84,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(part.name, style: AppText.style(15, FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(range(part.startMin, part.endMin).replaceAll(' ', ''),
                              style:
                                  AppText.style(11, FontWeight.w400, AppColors.textSecondary)),
                          Text('필요 ${part.need}명',
                              style:
                                  AppText.style(11, FontWeight.w400, AppColors.textTertiary)),
                        ],
                      ),
                    ),
                  ),
                  for (final d in days) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: DragTarget<String>(
                        onAcceptWithDetails: (e) => _assign(e.data, d, part),
                        builder: (context, hover, _) => _Slot(
                          shifts: store.shiftsOn(d).where((x) => x.part == part.name).toList(),
                          need: part.need,
                          part: part.name,
                          hover: hover.isNotEmpty,
                          onTapShift: _delete,
                        ),
                      ),
                    ),
                  ],
                ]),
              ],
            ]),
          ),
          right: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('직원 (끌어서 배정)', style: AppText.style(15, FontWeight.w700)),
                if (store.activeStaff.isEmpty) const EmptyNote('재직 중인 직원이 없어요'),
                for (final s in store.activeStaff) ...[
                  const SizedBox(height: 12),
                  Draggable<String>(
                    data: s.id,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Pill(store.personOf(s).name),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        MemberAvatar(s, size: 32),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(store.personOf(s).name,
                                style: AppText.style(14, FontWeight.w700))),
                        Text('주 ${hours(weekMinutes(s))}',
                            style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                      ]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.shifts,
    required this.need,
    required this.part,
    required this.hover,
    required this.onTapShift,
  });

  final List<Shift> shifts;
  final int need;
  final String part;
  final bool hover;
  final ValueChanged<Shift> onTapShift;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final (fg, bg) = partColors(part);
    final short = shifts.length < need;
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: hover ? AppColors.primarySoft : AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: hover
            ? Border.all(color: AppColors.primary)
            : short
                ? Border.all(color: AppColors.danger)
                : null,
      ),
      child: Column(children: [
        for (final s in shifts) ...[
          Tooltip(
            message: '${shiftTime(s)} · 눌러서 삭제',
            child: Material(
              color: store.pendingSubFor(s.id) != null ? AppColors.accentSoft : bg,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => onTapShift(s),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  alignment: Alignment.center,
                  child: Text(
                    '${store.nameOf(s.staffId)}${s.isSubstitute ? ' (대타)' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.style(12, FontWeight.w700,
                        store.pendingSubFor(s.id) != null ? AppColors.accent : fg),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
        if (short)
          Text('인원 부족 ${shifts.length}/$need',
              textAlign: TextAlign.center,
              style: AppText.style(11, FontWeight.w400, AppColors.danger)),
      ]),
    );
  }
}
