import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../data/payroll.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../employer/employer_parts.dart';
import 'web_common.dart';
import 'web_documents_screen.dart';

/// W3 직원 관리 (Figma 151:3613). 가입 대기는 위 카드에서 바로 승인 · 거절, 행을 누르면 상세 시트.
class WebStaffScreen extends StatefulWidget {
  const WebStaffScreen({super.key});

  @override
  State<WebStaffScreen> createState() => _WebStaffScreenState();
}

class _WebStaffScreenState extends State<WebStaffScreen> {
  /// null = 전체, 아니면 파트 이름(유동 근무는 [flexFilter]).
  String? _part;
  String _query = '';

  static const flexFilter = '직원';

  /// 서류 칸: 보건증 문제가 먼저, 그다음 계약서.
  Widget _docPill(AppStore store, Staff s) {
    final left = store.certDaysLeft(store.personOf(s));
    if (left == null || left <= 30) return certPill(left);
    if (!(s.contract?.signed ?? false)) return contractPill(s.contract);
    return webCellText('정상');
  }

  Future<void> _approve(Staff s) async {
    final store = AppScope.read(context);
    final r = await showWageDialog(context,
        title: '${store.personOf(s).name}님 가입 승인',
        wage: s.wage,
        deduction: store.store.defaultDeduction);
    if (r == null || !mounted) return;
    store.approveJoin(s.id, wage: r.$1, deduction: r.$2);
    showToast(context, '${store.personOf(s).name}님을 승인했어요');
  }

  Future<void> _reject(Staff s) async {
    final store = AppScope.read(context);
    final ok = await showConfirmDialog(context,
        title: '가입 신청을 거절할까요?',
        message: '${store.personOf(s).name}님에게 거절 알림이 가요.',
        confirmLabel: '거절하기',
        confirmVariant: AppButtonVariant.danger);
    if (ok && mounted) store.rejectJoin(s.id);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final active = store.activeStaff;
    final pending = store.pendingStaff;
    final rows = active
        .where((s) => switch (_part) {
              null => true,
              flexFilter => s.kind.flex,
              final p => !s.kind.flex && s.part == p,
            })
        .where((s) => store.personOf(s).fullName.contains(_query.trim()))
        .toList();
    final filters = <(String?, String)>[
      (null, '전체 ${active.length}'),
      if (store.flexStaff.isNotEmpty) (flexFilter, '유동 근무 ${store.flexStaff.length}'),
      for (final p in store.store.parts)
        (p.name, '${p.name} ${store.partStaff.where((s) => s.part == p.name).length}'),
    ];
    return WebPage(
      title: '직원 관리',
      subtitle: '재직 ${active.length}명 · 승인 대기 ${pending.length}명',
      actions: [WebButton('+ 직원 초대', onPressed: () => showInviteDialog(context))],
      children: [
        if (pending.isNotEmpty)
          AppCard(
            color: AppColors.infoSoft,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('가입 신청 ${pending.length}명', style: AppText.style(15, FontWeight.w500)),
              for (final s in pending) ...[
                const SizedBox(height: 12),
                Row(children: [
                  MemberAvatar(s, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(store.personOf(s).fullName, style: AppText.style(14, FontWeight.w500)),
                      Text(
                          '희망 파트 ${s.part}'
                          '${s.requestedAt == null ? '' : ' · ${relative(DateTime.parse(s.requestedAt!), store.now)} 신청'}',
                          style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                    ]),
                  ),
                  WebButton('거절',
                      height: 36, style: WebButtonStyle.outline, onPressed: () => _reject(s)),
                  const SizedBox(width: 8),
                  WebButton('승인하고 시급 설정', height: 36, onPressed: () => _approve(s)),
                ]),
              ],
            ]),
          ),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Container(
                  width: 280,
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration:
                      BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: '이름 검색',
                      hintStyle: AppText.style(14, FontWeight.w400, AppColors.textTertiary),
                    ),
                    style: AppText.style(14),
                  ),
                ),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final (part, label) in filters)
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() => _part = part),
                      child: part == _part
                          ? Pill(label)
                          : Pill(label, color: AppColors.textSecondary, background: AppColors.bg),
                    ),
                ]),
              ],
            ),
            const SizedBox(height: 14),
            WebTable(
              columns: const ['이름', '유형', '파트', '시급', '공제', '서류', ''],
              flex: const [200, 100, 100, 120, 110, 160, 70],
              minWidth: 760,
              onRowTap: (i) => showStaffSheet(context, rows[i].id),
              rows: [
                for (final s in rows)
                  [
                    webStaffCell(store, s),
                    webCellText(s.kind.label),
                    webPartCell(s.kind.flex ? '직원' : s.part, s.kind.flex ? '유동' : s.part),
                    webCellText(wonText(s.wage)),
                    webCellText(s.deduction.short),
                    _docPill(store, s),
                    webCellText('상세 ›'),
                  ],
              ],
            ),
            if (rows.isEmpty) const EmptyNote('조건에 맞는 직원이 없어요'),
          ]),
        ),
      ],
    );
  }
}

/// 직원 초대: 매장 코드를 알려 준다.
Future<void> showInviteDialog(BuildContext context) {
  final store = AppScope.read(context).store;
  return showWebDialog<void>(
    context,
    title: '직원 초대',
    builder: (ctx, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('알바생이 앱에서 매장 코드를 입력하면 가입 신청이 와요. 승인하면서 시급을 정해요.',
          style: AppText.style(14, FontWeight.w400, AppColors.textSecondary)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Text(store.name, style: AppText.style(13, FontWeight.w500, AppColors.primary)),
          const SizedBox(height: 6),
          Text(store.code, style: AppText.style(30, FontWeight.w500, AppColors.primary)),
        ]),
      ),
    ]),
    actions: (ctx, _) => [
      WebButton('코드 복사', onPressed: () {
        Clipboard.setData(ClipboardData(text: store.code));
        Navigator.pop(ctx);
        showToast(context, '매장 코드를 복사했어요');
      }),
    ],
  );
}

/// 직원 상세 시트: 근무 설정 · 서류 · 이번 달 급여 · 내보내기.
Future<void> showStaffSheet(BuildContext context, String staffId) => showWebSheet<void>(
      context,
      title: '직원 상세',
      builder: (_) => _StaffSheet(staffId),
    );

class _StaffSheet extends StatefulWidget {
  const _StaffSheet(this.staffId);

  final String staffId;

  @override
  State<_StaffSheet> createState() => _StaffSheetState();
}

class _StaffSheetState extends State<_StaffSheet> {
  final _wage = TextEditingController();
  String? _wageError;

  @override
  void initState() {
    super.initState();
    _wage.text = wonInput(AppScope.read(context).staffById(widget.staffId)?.wage ?? 0);
  }

  @override
  void dispose() {
    _wage.dispose();
    super.dispose();
  }

  void _saveWage(AppStore store) {
    final w = wonDigits(_wage.text);
    if (w == null || w < minimumWage2026) {
      return setState(() => _wageError = '2026 최저임금 ${wonText(minimumWage2026)} 이상이어야 해요');
    }
    setState(() => _wageError = null);
    store.updateStaff(widget.staffId, wage: w);
    showToast(context, '시급을 ${wonText(w)}으로 바꿨어요');
  }

  Future<void> _remove(AppStore store, Staff s) async {
    final name = store.personOf(s).name;
    final ok = await showConfirmDialog(context,
        title: '$name님을 매장에서 내보낼까요?',
        message: '앞으로의 근무가 지워지고, 진행 중인 대타 요청은 취소돼요.',
        confirmLabel: '내보내기',
        confirmVariant: AppButtonVariant.danger);
    if (!ok || !mounted) return;
    store.removeStaff(s.id);
    Navigator.pop(context);
    showToast(context, '$name님을 매장에서 내보냈어요');
  }

  Widget _section(String title, List<Widget> children) => AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: AppText.style(15, FontWeight.w500)),
          for (final c in children) ...[const SizedBox(height: 14), c],
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final s = store.staffById(widget.staffId);
    if (s == null || !s.active) return const EmptyNote('재직 중인 직원이 아니에요');
    final p = store.personOf(s);
    final t = store.today;
    final slip = store.payslip(s.id, t.year, t.month, projected: true);
    final left = store.certDaysLeft(p);
    return ListView(padding: const EdgeInsets.all(20), children: [
      Row(children: [
        MemberAvatar(s, size: 52),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.fullName, style: AppText.style(20, FontWeight.w500)),
            Text('${s.kind.label} · ${s.kind.flex ? '유동 근무' : s.part} · ${dotDate(parseYmd(s.joinedAt))} 입사',
                style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
          ]),
        ),
      ]),
      const SizedBox(height: 18),
      _section('근무 설정', [
        webPair(
          webField(
              '유형',
              WebSelect<StaffKind>(
                value: s.kind,
                items: [for (final k in StaffKind.values) (k, k.label)],
                onChanged: (k) => store.updateStaff(s.id, kind: k),
              )),
          webField(
              '기본 파트',
              WebSelect<String>(
                value: store.store.parts.any((x) => x.name == s.part) ? s.part : store.store.parts.first.name,
                enabled: !s.kind.flex,
                items: [for (final x in store.store.parts) (x.name, x.name)],
                onChanged: (v) => store.updateStaff(s.id, part: v),
              )),
        ),
        webField(
          '시급 (원)',
          Row(children: [
            Expanded(child: AppTextField(controller: _wage, won: true)),
            const SizedBox(width: 8),
            WebButton('저장', height: 48, onPressed: () => _saveWage(store)),
          ]),
          help: _wageError ?? '2026 최저임금 ${wonText(minimumWage2026)}',
        ),
        webField(
            '공제',
            WebSelect<Deduction>(
              value: s.deduction,
              items: [for (final d in Deduction.values) (d, d.label)],
              onChanged: (d) => store.updateStaff(s.id, deduction: d),
            )),
        ToggleCard(
          flat: true,
          title: '주휴수당 자동 계산',
          subtitle: '주 15시간 이상이면 자동으로 더해요',
          value: s.weeklyHolidayAuto,
          onChanged: (v) => store.updateStaff(s.id, weeklyHolidayAuto: v),
        ),
        ToggleCard(
          flat: true,
          title: '가산수당 적용',
          subtitle: store.store.isSmall ? '5인 미만 사업장은 적용하지 않아요' : '야간 · 8시간 초과분 0.5배',
          value: s.premium && !store.store.isSmall,
          onChanged: store.store.isSmall ? null : (v) => store.updateStaff(s.id, premium: v),
        ),
      ]),
      const SizedBox(height: 14),
      _section('서류', [
        Row(children: [
          Expanded(
            child: Text(
                '보건증 ${p.certExpiry == null ? '' : '· ${dotDate(parseYmd(p.certExpiry!))} 만료'}',
                style: AppText.style(14, FontWeight.w500)),
          ),
          certPill(left),
          if (left == null || left <= 30) ...[
            const SizedBox(width: 8),
            WebButton('갱신 요청', height: 32, fontSize: 12, style: WebButtonStyle.soft, onPressed: () {
              store.requestCertRenewal(s.id);
              showToast(context, '${p.name}님에게 갱신 요청을 보냈어요');
            }),
          ],
        ]),
        Row(children: [
          Expanded(child: Text('근로계약서', style: AppText.style(14, FontWeight.w500))),
          contractPill(s.contract),
          const SizedBox(width: 8),
          WebButton(s.contract == null ? '작성' : '다시 작성',
              height: 32,
              fontSize: 12,
              style: WebButtonStyle.outline,
              onPressed: () => showContractDialog(context, staffId: s.id)),
        ]),
      ]),
      const SizedBox(height: 14),
      PayBreakdown(slip: slip, staff: s, title: '${t.month}월 예상 급여'),
      const SizedBox(height: 18),
      WebButton('매장에서 내보내기',
          style: WebButtonStyle.danger, expand: true, onPressed: () => _remove(store, s)),
    ]);
  }
}
