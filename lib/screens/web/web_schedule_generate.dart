import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_common.dart';

/// 근무표를 만들 수 있는 달: 이번 달 + 3개월(4개). /me/state 가 3개월 뒤 말까지만 주므로 그 뒤 달은 만들면 안 보이고,
/// 빈 편집기를 저장하면 서버 근무가 지워진다(BE 도 MONTH_TOO_FAR 로 막는다).
List<DateTime> scheduleMonths(DateTime today) => [for (var i = 0; i < 4; i++) DateTime(today.year, today.month + i)];

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
      if (s.workHours.any((w) => w != null) || s.fixedParts.any((l) => l.isNotEmpty)) store.personOf(s).fullName
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

/// AI 근무표 생성(레퍼런스 Generate): 설정 → 미리보기 → 적용. 적용한 달('yyyy-MM')을 돌려준다.
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
  late final List<DateTime> months = scheduleMonths(store.today);
  late DateTime month = months.length > 1 ? months[1] : months[0];
  var holiday = HolidayPolicy.minimize;
  var priority = SchedulePriority.fairness;
  var busy = false;
  GeneratePreview? preview;
  String? error;

  Future<void> _run(String label, Future<void> Function() call) async {
    if (busy) return; // 같은 프레임 두 번 탭
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await call();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        error = '$label: ${e.message}';
        // 미리보기가 만료됐으면 설정 화면으로 돌아가 다시 만든다.
        if (e.status == 410) preview = null;
      });
    } catch (_) {
      if (mounted) setState(() => error = '$label: 서버와 통신하지 못했어요');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _preview() => _run('미리보기 실패', () async {
        final p = await store.previewGenerate(ym(month), weeklyHolidayPay: holiday, priority: priority);
        if (mounted) setState(() => preview = p);
      });

  Future<void> _apply(GeneratePreview p) => _run('적용 실패', () async {
        await store.applyGenerated(p);
        if (mounted) Navigator.pop(context, p.month);
      });

  Widget _settings(int staffCount) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('알바생은 고정 파트, 직원은 고정 근무시간대로 넣고, 빈 시간은 고정 시간이 없는 직원과 추가 근무 가능한 알바생으로 채워요. 미리보기를 보고 적용해요.',
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
                  desc: '주 15시간 근처 알바생과 줄일 시간·아낄 금액을 알려줘요'),
              WebChoice(
                  active: holiday == HolidayPolicy.allow,
                  onTap: () => setState(() => holiday = HolidayPolicy.allow),
                  title: '허용',
                  desc: '주휴수당을 그대로 두고 금액만 계산해요'),
            ])),
        const SizedBox(height: 18),
        _section(
            '우선순위',
            _grid([
              WebChoice(
                  active: priority == SchedulePriority.fairness,
                  onTap: () => setState(() => priority = SchedulePriority.fairness),
                  title: '공평 배분',
                  desc: '빈 시간을 이번 주 근무가 적은 직원부터 채워요'),
              WebChoice(
                  active: priority == SchedulePriority.cost,
                  onTap: () => setState(() => priority = SchedulePriority.cost),
                  title: '인건비 절감',
                  desc: '빈 시간을 시급이 낮은 직원부터 채워요'),
            ])),
        if (error != null) _error(error!),
        if (staffCount == 0) _error('직원·알바생을 먼저 등록하세요.'),
      ]);

  @override
  Widget build(BuildContext context) {
    final staffCount = store.flexStaff.length + store.partStaff.length;
    final p = preview;
    final Widget body;
    final List<Widget> actions;
    if (p == null) {
      body = busy
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
          : _settings(staffCount);
      actions = [
        WebButton('취소', style: WebButtonStyle.outline, onPressed: busy ? null : () => Navigator.pop(context)),
        const SizedBox(width: 8),
        WebButton(busy ? '만드는 중…' : '미리보기', onPressed: busy || staffCount == 0 ? null : _preview),
      ];
    } else {
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        GeneratePreviewView(preview: p),
        if (error != null) _error(error!),
      ]);
      actions = [
        WebButton('설정 바꾸기',
            style: WebButtonStyle.outline,
            onPressed: busy
                ? null
                : () => setState(() {
                      preview = null;
                      error = null;
                    })),
        const SizedBox(width: 8),
        WebButton(busy ? '적용하는 중…' : (p.replacing > 0 ? '덮어쓰고 적용' : '적용'),
            onPressed: busy || p.shifts.isEmpty ? null : () => _apply(p)),
      ];
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
                  child: Text(p == null ? 'AI 근무표 생성' : '${monthLabel(parseYmd('${p.month}-01'))} 근무표 미리보기',
                      style: AppText.style(18, FontWeight.w500))),
              IconButton(
                tooltip: '닫기',
                onPressed: busy ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
              ),
            ]),
          ),
          const Divider(height: 1, color: AppColors.border),
          Flexible(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 20), child: body)),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
          ),
        ]),
      ),
    );
  }
}

/// 생성 미리보기. [preview] 만으로 그린다(테스트에서 가짜를 넘길 수 있다).
class GeneratePreviewView extends StatelessWidget {
  const GeneratePreviewView({super.key, required this.preview});

  final GeneratePreview preview;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final p = preview;
    final byStaff = p.minutesByStaff;
    final most = byStaff.values.fold(0, (a, b) => a > b ? a : b);
    final people = byStaff.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final missing = p.unfilled.fold(0, (sum, u) => sum + u.missing);
    final muted = AppText.style(14, FontWeight.w400, AppColors.textSecondary);
    final small = AppText.style(13, FontWeight.w400, AppColors.textSecondary);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (p.replacing > 0) ...[
        NoteBox(
            '${int.parse(p.month.substring(5))}월 작성 중 근무 ${p.replacing}건(오늘 이후, 출근 기록 없는 것)을 지우고 이 근무표로 바꿔요',
            color: AppColors.danger, background: AppColors.dangerSoft),
        const SizedBox(height: 16),
      ],
      Text('새 근무 ${p.shifts.length}건', style: AppText.style(22, FontWeight.w500)),
      const SizedBox(height: 8),
      Text('못 채운 칸 $missing',
          style: missing > 0 ? AppText.style(14, FontWeight.w500, AppColors.accent) : muted),
      const SizedBox(height: 4),
      Text('예상 인건비 ${won(p.laborCost)}', style: muted),
      if (p.shifts.isEmpty) ...[
        const SizedBox(height: 16),
        Text('만들 근무가 없어요', style: AppText.style(13, FontWeight.w400, AppColors.textTertiary)),
      ],
      if (p.lines.isNotEmpty) ...[
        const SizedBox(height: 16),
        for (final l in p.lines)
          Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('· $l', style: small)),
      ],
      const SizedBox(height: 8),
      Text('AI 설명은 적용 뒤 잠시 후 근무표 상단에 붙어요.',
          style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
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
      if (p.unfilled.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('못 채운 칸', style: AppText.style(13, FontWeight.w500, AppColors.accent)),
        const SizedBox(height: 8),
        for (final u in p.unfilled)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text('${md(parseYmd(u.date))} · ${u.part} · ${range(u.startMin, u.endMin)} · ${u.missing}명 부족',
                style: small),
          ),
      ],
    ]);
  }
}
