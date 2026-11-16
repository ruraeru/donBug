import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/app_scope.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_common.dart';
import 'web_schedule_generate.dart';
import 'web_schedule_screen.dart';

/// 근무표 메뉴: 월별 근무표 목록(레퍼런스 Schedules) → 행을 누르면 그 달 편집기.
class WebSchedulesScreen extends StatefulWidget {
  const WebSchedulesScreen({super.key});

  /// 다른 화면(템플릿 적용 등)이 근무표 메뉴로 넘어가며 열 달('yyyy-MM'). 한 번 읽으면 비운다.
  static final ValueNotifier<String?> openRequest = ValueNotifier(null);

  @override
  State<WebSchedulesScreen> createState() => _WebSchedulesScreenState();
}

class _WebSchedulesScreenState extends State<WebSchedulesScreen> {
  String? _editing;

  @override
  void initState() {
    super.initState();
    _editing = WebSchedulesScreen.openRequest.value;
    WebSchedulesScreen.openRequest.value = null;
  }

  static String sourceLabel(ScheduleSource s) => switch (s) {
        ScheduleSource.ai => 'AI 생성',
        ScheduleSource.template => '템플릿',
        ScheduleSource.manual => '직접 작성',
      };

  Future<void> _delete(MonthSchedule m) async {
    final store = AppScope.read(context);
    final d = parseMonth(m.month);
    final ok = await showConfirmDialog(
      context,
      title: '${monthLabel(d)} 근무표를 삭제할까요?',
      message: '${m.status == ScheduleStatus.confirmed ? '확정된 근무표예요. ' : ''}출근 기록이 없는 그 달 근무가 모두 지워지고 되돌릴 수 없어요.',
      confirmLabel: '삭제',
      confirmVariant: AppButtonVariant.danger,
    );
    if (!ok || !mounted) return;
    try {
      await store.deleteMonthSchedule(m.month);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  Future<void> _created(Future<String?> f) async {
    final month = await f;
    if (month != null && mounted) setState(() => _editing = month);
  }

  @override
  Widget build(BuildContext context) {
    if (_editing != null) {
      return WebScheduleScreen(
        key: const ValueKey('editor'),
        month: _editing,
        onBack: () => setState(() => _editing = null),
      );
    }
    final store = AppScope.of(context);
    final list = [...store.schedules]..sort((a, b) => b.month.compareTo(a.month));
    final noStaff = store.activeStaff.isEmpty;
    return WebPage(
      title: '근무표',
      subtitle: '월 단위 근무표 목록',
      actions: [
        WebButton('직접 만들기',
            style: WebButtonStyle.outline, onPressed: () => _created(showCreateScheduleDialog(context))),
        WebButton('AI 근무표 생성',
            tooltip: noStaff ? '직원·알바생을 먼저 등록하세요' : null,
            onPressed: noStaff ? null : () => _created(showGenerateScheduleDialog(context))),
      ],
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: list.isEmpty
              ? const Padding(padding: EdgeInsets.all(32), child: EmptyNote('근무표가 없어요'))
              : Column(children: [
                  for (final (i, m) in list.indexed) ...[
                    if (i > 0) const Divider(height: 1, color: AppColors.border),
                    _Row(
                      m,
                      onOpen: () => setState(() => _editing = m.month),
                      onDelete: () => _delete(m),
                    ),
                  ],
                ]),
        ),
      ],
    );
  }
}

/// 'yyyy-MM' → 그 달 1일.
DateTime parseMonth(String m) => DateTime(int.parse(m.substring(0, 4)), int.parse(m.substring(5, 7)));

class _Row extends StatelessWidget {
  const _Row(this.m, {required this.onOpen, required this.onDelete});

  final MonthSchedule m;
  final VoidCallback onOpen, onDelete;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final d = parseMonth(m.month);
    final last = DateTime(d.year, d.month + 1, 0);
    final n = store.state.shifts.where((s) => s.storeId == store.store.id && s.date.startsWith(m.month)).length;
    final confirmed = m.status == ScheduleStatus.confirmed;
    return Row(children: [
      Expanded(
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 12, 16),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${d.month}월', style: AppText.style(15, FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    '${d.month}/1–${d.month}/${last.day} · 근무 $n건 · ${_WebSchedulesScreenState.sourceLabel(m.source)}',
                    style: AppText.style(12, FontWeight.w400, AppColors.textSecondary),
                  ),
                ]),
              ),
              WebTag(confirmed ? '확정' : '작성 중',
                  color: confirmed ? AppColors.primary : AppColors.textSecondary,
                  background: confirmed ? AppColors.primarySoft : AppColors.bg,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3)),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
            ]),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 16),
        child: IconButton(
          tooltip: '${d.month}월 근무표 삭제',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.textSecondary),
        ),
      ),
    ]);
  }
}
