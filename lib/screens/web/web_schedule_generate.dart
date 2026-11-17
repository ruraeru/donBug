import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_common.dart';

/// 근무표를 만들 수 있는 달: 이번 달 + 3달. AI 생성은 상태 창(이번 달·다음 달)에 있는 달만 [count] 2.
List<DateTime> scheduleMonths(DateTime today, {int count = 4}) =>
    [for (var i = 0; i < count; i++) DateTime(today.year, today.month + i)];

String monthLabel(DateTime m) => '${m.year}년 ${m.month}월';

String _range(DateTime m) => '${m.month}/1 – ${m.month}/${DateTime(m.year, m.month + 1, 0).day}';

/// 선택 칸(레퍼런스 Choice).
class WebChoice extends StatelessWidget {
  const WebChoice(
      {super.key, required this.active, required this.onTap, required this.title, required this.desc});

  final bool active;
  final VoidCallback onTap;
  final String title, desc;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: active ? AppColors.primary : AppColors.border, width: active ? 1.5 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(title,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.style(14, FontWeight.w500,
                            active ? AppColors.primary : AppColors.textPrimary))),
                if (active) const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
              ]),
              const SizedBox(height: 4),
              Text(desc, style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
            ]),
          ),
        ),
      );
}

Widget _section(String title, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.style(14, FontWeight.w700)),
        const SizedBox(height: 10),
        child,
      ],
    );

Widget _grid(List<Widget> items, {int cols = 2}) => LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - 8 * (cols - 1)) / cols;
      return Wrap(spacing: 8, runSpacing: 8, children: [for (final i in items) SizedBox(width: w, child: i)]);
    });

Widget _error(String text) =>
    Padding(padding: const EdgeInsets.only(top: 12), child: Text(text, style: AppText.style(13, FontWeight.w500, AppColors.danger)));

/// 직접 만들기(레퍼런스 CreateSchedule). 만든 달('yyyy-MM')을 돌려준다.
Future<String?> showCreateScheduleDialog(BuildContext context) {
  final store = AppScope.read(context);
  final months = scheduleMonths(store.today);
  var month = months.length > 1 ? months[1] : months[0];
  var prefill = true;
  var busy = false;
  String? error;
  final fixedNames = [
    for (final s in store.flexStaff)
      if (s.workHours.any((w) => w != null)) store.personOf(s).fullName
  ];

  return showWebDialog<String>(
    context,
    title: '근무표 직접 만들기',
    builder: (ctx, set) {
      final draft = store.monthSchedule(ym(month));
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('빈 근무표를 만든 뒤 편집기에서 칸을 눌러 근무를 넣거나, 자동 채우기로 빈 곳을 채워요.',
            style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
        const SizedBox(height: 18),
        _section(
            '기간',
            _grid([
              for (final m in months)
                WebChoice(
                    active: m == month,
                    onTap: () => set(() => month = m),
                    title: monthLabel(m),
                    desc: _range(m)),
            ])),
        const SizedBox(height: 18),
        _section(
          '시작 내용',
          InkWell(
            onTap: () => set(() => prefill = !prefill),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Checkbox(
                    value: prefill,
                    activeColor: AppColors.primary,
                    onChanged: (v) => set(() => prefill = v ?? false)),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('직원 고정 근무 미리 넣기', style: AppText.style(14, FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      '${fixedNames.isEmpty ? '고정 근무가 등록된 직원이 없어요.' : '${fixedNames.join(', ')}님의 요일별 고정 근무를 한 달 내내 채워 둬요.'}'
                      ' 끄면 완전히 빈 근무표로 시작해요.',
                      style: AppText.style(12, FontWeight.w400, AppColors.textSecondary),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
        if (draft != null && draft.status == ScheduleStatus.draft)
          _error('${monthLabel(month)}에 작성 중인 근무표가 있어요. 만들면 새 근무표로 바뀌어요.'),
        if (error != null) _error('만들기 실패: $error'),
      ]);
    },
    actions: (ctx, set) => [
      WebButton('취소', style: WebButtonStyle.outline, onPressed: () => Navigator.pop(ctx)),
      WebButton(busy ? '만드는 중…' : '근무표 만들기', onPressed: busy
          ? null
          : () async {
              final key = ym(month);
              final old = store.monthSchedule(key);
              if (old != null && old.status == ScheduleStatus.draft) {
                final n = store.state.shifts.where((s) => s.storeId == store.store.id && s.date.startsWith(key)).length;
                final ok = await showConfirmDialog(ctx,
                    title: '${monthLabel(month)} 작성 중인 근무표가 있어요',
                    message: '기존 근무($n건)는 그대로 두고, 빠진 고정 근무만 채워요.',
                    confirmLabel: '계속');
                if (!ok || !ctx.mounted) return;
              }
              set(() {
                busy = true;
                error = null;
              });
              try {
                await store.createMonthSchedule(key, prefillFixed: prefill);
                if (ctx.mounted) Navigator.pop(ctx, key);
              } on ApiException catch (e) {
                if (ctx.mounted) set(() => error = e.message);
              } finally {
                if (ctx.mounted) set(() => busy = false);
              }
            }),
    ],
  );
}

const _steps = ['매장 조건·가능 시간 분석', '직원 출근 시간 배치', '알바생 파트 배치', '근로 규칙 검증·보정'];
const _stepAt = [0, 25, 55, 80];

/// 걸린 시간으로 추정한 진행률(%). 실제 진행률은 알 수 없다. 레퍼런스와 같은 식.
double estimateProgress(double sec) => 95 * (1 - math.exp(-sec / 60));

/// AI 근무표 생성(레퍼런스 Generate). 만든 달('yyyy-MM')을 돌려준다.
Future<String?> showGenerateScheduleDialog(BuildContext context) => showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GenerateDialog(store: AppScope.read(context)),
    );

class _GenerateDialog extends StatefulWidget {
  const _GenerateDialog({required this.store});

  final AppStore store;

  @override
  State<_GenerateDialog> createState() => _GenerateDialogState();
}

class _GenerateDialogState extends State<_GenerateDialog> {
  AppStore get store => widget.store;
  late final List<DateTime> months = scheduleMonths(store.today, count: 2);
  late DateTime month = months.length > 1 ? months[1] : months[0];
  var holiday = HolidayPolicy.minimize;
  var priority = SchedulePriority.fairness;
  var running = false;
  double sec = 0;
  String? error;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final started = DateTime.now();
    setState(() {
      running = true;
      error = null;
      sec = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => sec = DateTime.now().difference(started).inMilliseconds / 1000);
    });
    try {
      await store.generateSchedule(ym(month), weeklyHolidayPay: holiday, priority: priority);
      if (mounted) Navigator.pop(context, ym(month));
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() => error = '서버와 통신하지 못했어요');
    } finally {
      _timer?.cancel();
      if (mounted) setState(() => running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flex = store.flexStaff.length, part = store.partStaff.length;
    final pct = estimateProgress(sec);
    final step = _stepAt.where((a) => pct >= a).length - 1;
    final Widget body;
    if (running) {
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${monthLabel(month)} · 직원 $flex명 · 알바생 $part명 · 보통 1~2분 걸려요',
            style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6,
              backgroundColor: AppColors.primarySoft,
              color: AppColors.primary),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${pct.round()}%', style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
          Text('${sec ~/ 60}:${(sec % 60).floor().toString().padLeft(2, '0')} 경과',
              style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
        ]),
        const SizedBox(height: 18),
        for (final (i, s) in _steps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < step
                      ? AppColors.primarySoft
                      : i == step
                          ? AppColors.primary
                          : null,
                  border: i > step ? Border.all(color: AppColors.border, width: 1.5) : null,
                ),
                child: i < step
                    ? const Icon(Icons.check_rounded, size: 14, color: AppColors.primary)
                    : i == step
                        ? const SizedBox(width: 6, height: 6, child: DecoratedBox(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle)))
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(s,
                      style: AppText.style(14, FontWeight.w400,
                          i > step ? AppColors.textSecondary : AppColors.textPrimary))),
            ]),
          ),
      ]);
    } else {
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('조건을 고르면 AI가 직원 근무를 정하고 알바생은 고른 파트에 배치해요. 구성원 이름은 빼고 번호로만 전달해요.',
            style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
        const SizedBox(height: 18),
        _section(
            '기간',
            _grid([
              for (final m in months)
                WebChoice(
                    active: m == month,
                    onTap: () => setState(() => month = m),
                    title: monthLabel(m),
                    desc: _range(m)),
            ])),
        const SizedBox(height: 18),
        _section(
            '주휴수당',
            _grid([
              WebChoice(
                  active: holiday == HolidayPolicy.minimize,
                  onTap: () => setState(() => holiday = HolidayPolicy.minimize),
                  title: '최소화',
                  desc: '알바생을 가능하면 주 15시간 미만으로 배치'),
              WebChoice(
                  active: holiday == HolidayPolicy.allow,
                  onTap: () => setState(() => holiday = HolidayPolicy.allow),
                  title: '허용',
                  desc: '주휴수당은 피하지 않고 계산만'),
            ])),
        const SizedBox(height: 18),
        _section(
            '우선순위',
            _grid([
              WebChoice(
                  active: priority == SchedulePriority.fairness,
                  onTap: () => setState(() => priority = SchedulePriority.fairness),
                  title: '공평 배분',
                  desc: '알바생 간 근무시간 차이를 줄임'),
              WebChoice(
                  active: priority == SchedulePriority.cost,
                  onTap: () => setState(() => priority = SchedulePriority.cost),
                  title: '인건비 절감',
                  desc: '필요 인원만큼만 최소 배치'),
            ])),
        if (error != null) _error('생성 실패: $error'),
        if (flex + part == 0) _error('직원·알바생을 먼저 등록하세요.'),
      ]);
    }
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 14),
            child: Row(children: [
              Expanded(
                  child: Text(running ? 'AI가 근무표를 만들고 있어요' : 'AI 근무표 생성',
                      style: AppText.style(18, FontWeight.w500))),
              if (!running)
                IconButton(
                  tooltip: '닫기',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                ),
            ]),
          ),
          const Divider(height: 1, color: AppColors.border),
          Flexible(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 20), child: body)),
          if (!running) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                WebButton('취소', style: WebButtonStyle.outline, onPressed: () => Navigator.pop(context)),
                const SizedBox(width: 8),
                WebButton('근무표 생성', onPressed: flex + part == 0 ? null : _start),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}
