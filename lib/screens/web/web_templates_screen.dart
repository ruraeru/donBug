import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/app_scope.dart';
import '../../data/models.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_common.dart';
import 'web_schedule_generate.dart';
import 'web_schedules_screen.dart';
import 'web_shell.dart';
import 'web_shift_dialog.dart' show flexPart;

/// 템플릿 메뉴(레퍼런스 Templates): 한 주 요일 패턴을 저장해 두고 다른 달에 적용.
class WebTemplatesScreen extends StatefulWidget {
  const WebTemplatesScreen({super.key});

  @override
  State<WebTemplatesScreen> createState() => _WebTemplatesScreenState();
}

class _WebTemplatesScreenState extends State<WebTemplatesScreen> {
  DateTime? _month;
  bool _busy = false;

  Future<void> _apply(ScheduleTemplate t, DateTime month) async {
    final store = AppScope.read(context);
    setState(() => _busy = true);
    try {
      await store.applyScheduleTemplate(t.id, ym(month));
      if (!mounted) return;
      WebSchedulesScreen.openRequest.value = ym(month);
      WebShell.open(context, WebMenu.schedule);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(ScheduleTemplate t) async {
    final ok = await showConfirmDialog(context,
        title: '"${t.name}" 템플릿을 삭제할까요?',
        message: '이미 적용한 근무표에는 영향이 없어요.',
        confirmLabel: '삭제',
        confirmVariant: AppButtonVariant.danger);
    if (!ok || !mounted) return;
    try {
      await AppScope.read(context).deleteScheduleTemplate(t.id);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final months = scheduleMonths(store.today);
    final month = _month ?? (months.length > 1 ? months[1] : months[0]);
    final list = store.templates;
    return WebPage(
      title: '템플릿',
      subtitle: "근무표의 한 주 요일 패턴을 저장해 두고 다른 달의 같은 요일마다 적용해요. 근무표 화면의 '템플릿으로 저장'으로 만들어요.",
      actions: [
        SizedBox(
          width: 180,
          child: WebSelect<DateTime>(
            value: month,
            items: [for (final m in months) (m, '${monthLabel(m)}에 적용')],
            onChanged: (m) => setState(() => _month = m),
          ),
        ),
      ],
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: list.isEmpty
              ? const Padding(padding: EdgeInsets.all(32), child: EmptyNote('저장된 템플릿이 없어요'))
              : Column(children: [
                  for (final (i, t) in list.indexed) ...[
                    if (i > 0) const Divider(height: 1, color: AppColors.border),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(t.name, style: AppText.style(15, FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text(templateSummary(t, [for (final p in store.store.parts) p.name]),
                                style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                          ]),
                        ),
                        WebButton('삭제', style: WebButtonStyle.outline, onPressed: _busy ? null : () => _delete(t)),
                        const SizedBox(width: 8),
                        WebButton(_busy ? '적용 중…' : '적용', onPressed: _busy ? null : () => _apply(t, month)),
                      ]),
                    ),
                  ],
                ]),
        ),
      ],
    );
  }
}

/// "근무 N건 · 직원 유동 근무 N건 · 연차 N건" (근무 = 연차 제외 근무 칸, 유동 = 파트 없는 근무).
String templateSummary(ScheduleTemplate t, [List<String>? partNames]) {
  final work = t.shifts.where((s) => s.kind == ShiftKind.work);
  final flex = work.where((s) => partNames == null ? s.part == flexPart : !partNames.contains(s.part)).length;
  final leave = t.shifts.where((s) => s.kind == ShiftKind.leave).length;
  return '근무 ${work.length}건 · 직원 유동 근무 $flex건 · 연차 $leave건';
}
