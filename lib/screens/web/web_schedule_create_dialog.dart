import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../employer/employer_parts.dart';
import 'web_common.dart';

/// 주 최대 근무 선택지: (이름, 분). 15시간 미만 = 14:59.
const scheduleMaxOptions = [
  ('제한 없음', 7 * 24 * 60),
  ('40시간', 40 * 60),
  ('30시간', 30 * 60),
  ('15시간 미만', 14 * 60 + 59),
];

/// 근무표 만들기 창. 만들었으면 (그 달 1일, 추가한 수), 닫았으면 null.
/// [nextMonth] 면 "다음 달"이 먼저 골라져 있다.
Future<({DateTime month, int count})?> showScheduleCreateDialog(BuildContext context,
    {bool nextMonth = false}) {
  final store = AppScope.read(context);
  final today = store.today;
  final parts = store.store.parts;
  final people = store.partStaff;
  final needs = [for (final p in parts) p.need.clamp(0, 5)];
  final excluded = <String>{};
  var month = nextMonth ? 1 : 0;
  var copyLast = false;
  var maxIdx = 1;
  late SchedulePlan plan;

  DateTime first() => DateTime(today.year, today.month + month);
  DateTime from() => month == 0 ? today : first();
  DateTime last() => DateTime(today.year, today.month + month + 1, 0);

  return showWebDialog<({DateTime month, int count})>(
    context,
    title: '근무표 만들기',
    width: 880,
    builder: (ctx, set) {
      plan = store.planSchedule(
        from: from(),
        to: last(),
        needs: needs,
        copyLastWeek: copyLast,
        excludeStaffIds: excluded,
        weeklyMaxMin: scheduleMaxOptions[maxIdx].$2,
      );
      final settings = _Settings(
        month: month,
        rangeText: _rangeText(from(), last(), clipped: from().isAfter(first())),
        onMonth: (i) => set(() => month = i),
        copyLast: copyLast,
        onCopyLast: (v) => set(() => copyLast = v),
        parts: parts,
        needs: needs,
        onNeed: (i, v) => set(() => needs[i] = v.clamp(0, 5)),
        people: people,
        excluded: excluded,
        onToggle: (id) => set(() => excluded.contains(id) ? excluded.remove(id) : excluded.add(id)),
        maxIdx: maxIdx,
        onMax: (i) => set(() => maxIdx = i),
      );
      final preview = SchedulePlanPreview(plan: plan);
      return LayoutBuilder(builder: (context, c) {
        if (c.maxWidth < 680) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            settings,
            const SizedBox(height: 20),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 20),
            preview,
          ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 11, child: settings),
          const SizedBox(width: 24),
          Expanded(flex: 9, child: preview),
        ]);
      });
    },
    actions: (ctx, set) => [
      WebButton('취소', style: WebButtonStyle.outline, onPressed: () => Navigator.pop(ctx)),
      WebButton('근무표 만들기',
          onPressed: plan.shifts.isEmpty
              ? null
              : () {
                  final n = store.applySchedulePlan(plan, needs: needs);
                  Navigator.pop(ctx, (month: first(), count: n));
                }),
    ],
  );
}

String _rangeText(DateTime a, DateTime b, {required bool clipped}) =>
    '${a.month}.${a.day}–${b.month}.${b.day}${clipped ? ' · 오늘 이후만' : ''}';

class _Settings extends StatelessWidget {
  const _Settings({
    required this.month,
    required this.rangeText,
    required this.onMonth,
    required this.copyLast,
    required this.onCopyLast,
    required this.parts,
    required this.needs,
    required this.onNeed,
    required this.people,
    required this.excluded,
    required this.onToggle,
    required this.maxIdx,
    required this.onMax,
  });

  final int month, maxIdx;
  final String rangeText;
  final ValueChanged<int> onMonth, onMax;
  final bool copyLast;
  final ValueChanged<bool> onCopyLast;
  final List<PartTemplate> parts;
  final List<int> needs;
  final void Function(int, int) onNeed;
  final List<Staff> people;
  final Set<String> excluded;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      webField(
        '기간',
        Row(children: [
          WebSegmented(labels: const ['이번 달', '다음 달'], selected: month, onChanged: onMonth),
          const SizedBox(width: 12),
          Flexible(
            child: Text(rangeText,
                overflow: TextOverflow.ellipsis,
                style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
          ),
        ]),
      ),
      const SizedBox(height: 20),
      webField(
        '시작 방식',
        WebSegmented(
            labels: const ['자동 배정', '지난주 반복'],
            selected: copyLast ? 1 : 0,
            onChanged: (i) => onCopyLast(i == 1)),
        help: copyLast ? '지난주와 같은 사람으로 놓고, 빈 칸은 자동 배정으로 채워요' : '파트마다 필요한 인원을 자동으로 채워요',
      ),
      const SizedBox(height: 20),
      webField(
        '파트별 필요 인원',
        Column(children: [
          for (final (i, p) in parts.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: partColors(p.name).$1, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(p.name, style: AppText.style(14, FontWeight.w500)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(range(p.startMin, p.endMin),
                      overflow: TextOverflow.ellipsis,
                      style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
                ),
                _Step(Icons.remove_rounded, '${p.name} 인원 줄이기', needs[i] > 0 ? () => onNeed(i, needs[i] - 1) : null),
                SizedBox(
                    width: 40,
                    child: Center(child: Text('${needs[i]}명', style: AppText.style(14, FontWeight.w500)))),
                _Step(Icons.add_rounded, '${p.name} 인원 늘리기', needs[i] < 5 ? () => onNeed(i, needs[i] + 1) : null),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: 20),
      webField(
        '근무자',
        Wrap(runSpacing: 0, children: [
          for (final s in people)
            SizedBox(
              width: 148,
              child: InkWell(
              onTap: () => onToggle(s.id),
              borderRadius: BorderRadius.circular(8),
              child: Row(children: [
                Checkbox(
                  value: !excluded.contains(s.id),
                  activeColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                  onChanged: (_) => onToggle(s.id),
                ),
                Text(store.nameOf(s.id), style: AppText.style(14)),
                const SizedBox(width: 8),
                Text(s.part, style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
              ]),
            ),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      webField(
        '주 최대 근무',
        WebSelect<int>(
          value: maxIdx,
          items: [for (final (i, o) in scheduleMaxOptions.indexed) (i, o.$1)],
          onChanged: onMax,
        ),
      ),
    ]);
  }
}

class _Step extends StatelessWidget {
  const _Step(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: label,
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 18, color: onTap == null ? AppColors.textTertiary : AppColors.textSecondary),
      );
}

/// 만들기 미리보기. [plan] 만으로 그린다(화면 확인 · 테스트에서 가짜 plan 을 넘길 수 있다).
class SchedulePlanPreview extends StatelessWidget {
  const SchedulePlanPreview({super.key, required this.plan});

  final SchedulePlan plan;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final most = plan.minutesByStaff.values.fold(0, (a, b) => a > b ? a : b);
    final people = plan.minutesByStaff.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final muted = AppText.style(14, FontWeight.w400, AppColors.textSecondary);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('미리보기', style: AppText.style(13, FontWeight.w500)),
      const SizedBox(height: 12),
      Text('새 근무 ${plan.shifts.length}건', style: AppText.style(22, FontWeight.w500)),
      const SizedBox(height: 8),
      Text('못 채운 칸 ${plan.unfilled}',
          style: plan.unfilled > 0 ? AppText.style(14, FontWeight.w500, AppColors.accent) : muted),
      const SizedBox(height: 4),
      Text('예상 인건비 ${won(plan.cost)}', style: muted),
      if (plan.shifts.isEmpty) ...[
        const SizedBox(height: 16),
        Text('만들 근무가 없어요', style: AppText.style(13, FontWeight.w400, AppColors.textTertiary)),
      ],
      if (people.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('직원별 총 시간', style: AppText.style(13, FontWeight.w500)),
        const SizedBox(height: 8),
        for (final e in people)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              SizedBox(
                  width: 72,
                  child: Text(store.nameOf(e.key),
                      overflow: TextOverflow.ellipsis, style: AppText.style(13, FontWeight.w400))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: most == 0 ? 0 : e.value / most,
                    minHeight: 4,
                    color: AppColors.textTertiary,
                    backgroundColor: AppColors.bg,
                  ),
                ),
              ),
              SizedBox(
                  width: 56,
                  child: Text(hours(e.value),
                      textAlign: TextAlign.right,
                      style: AppText.style(13, FontWeight.w400, AppColors.textSecondary))),
            ]),
          ),
      ],
    ]);
  }
}
