import 'package:flutter/material.dart';

import '../../data/ai_api.dart';
import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_common.dart';
import 'web_staff_screen.dart';

/// W7 AI 노무 도우미 (콘텐츠 영역). 추천 질문을 누르면 입력창에 채워진다.
class WebAiAssistantScreen extends StatefulWidget {
  const WebAiAssistantScreen({super.key});

  @override
  State<WebAiAssistantScreen> createState() => _WebAiAssistantScreenState();
}

class _WebAiAssistantScreenState extends State<WebAiAssistantScreen> {
  static const _suggestions = [
    '해고 예고 수당은 언제 필요해요?',
    '연차는 5인 미만도 적용되나요?',
    '대타 근무도 주휴수당에 포함되나요?',
    '근로계약서 필수 항목은?',
  ];

  final _input = TextEditingController();
  // 서버 모드 대화: (질문, 답). 답이 null 이면 답변 중.
  final _msgs = <(String, AiAnswer?)>[];
  bool _loading = false;
  // 매장 노무 점검 결과. 화면에 있는 동안만 남는다(대화와 같음).
  LaborAudit? _audit;
  bool _auditing = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final q = _input.text.trim();
    if (q.isEmpty || _loading) return;
    final store = AppScope.read(context);
    setState(() {
      _msgs.add((q, null));
      _loading = true;
    });
    _input.clear();
    final i = _msgs.length - 1;
    try {
      final r = await askLaborQuestion(store.api!, store.session.storeId, q);
      if (mounted) setState(() => _msgs[i] = (q, r));
    } catch (e) {
      if (mounted) {
        showToast(context, aiErrorText(e));
        setState(() => _msgs.removeAt(i));
        if (_input.text.isEmpty) _input.text = q;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _runAudit() async {
    if (_auditing) return;
    final store = AppScope.read(context);
    setState(() => _auditing = true);
    try {
      final r = await auditLabor(store.api!, store.session.storeId);
      if (mounted) setState(() => _audit = r);
    } catch (e) {
      if (mounted) showToast(context, aiErrorText(e));
    }
    if (mounted) setState(() => _auditing = false);
  }

  Widget _auditCard() => AppCard(
        color: AppColors.primarySoft,
        radius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('매장 노무 점검', style: AppText.style(14, FontWeight.w500)),
            const SizedBox(height: 4),
            Text('최저임금·계약서·보건증·근무시간을 한 번에 확인해요.',
                style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)
                    .copyWith(height: 18 / 12)),
            const SizedBox(height: 10),
            WebButton(_auditing ? '점검하는 중...' : '점검하기',
                expand: true, height: 38, fontSize: 13,
                onPressed: _auditing ? null : _runAudit),
          ],
        ),
      );

  Widget _auditResult(LaborAudit a) {
    final store = AppScope.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('매장 노무 점검 결과', style: AppText.style(16, FontWeight.w500)),
          if (a.summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(a.summary, style: AppText.style(14).copyWith(height: 22 / 14)),
          ],
          if (!a.aiUsed) ...[
            const SizedBox(height: 8),
            Text('AI 설명을 받지 못해 기본 안내를 보여 드려요.',
                style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
          ],
          const SizedBox(height: 14),
          if (a.findings.isEmpty)
            const NoteBox('찾은 위험 항목이 없어요',
                color: AppColors.primary, background: AppColors.primarySoft),
          for (final f in a.findings) ...[
            _finding(f, store),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _finding(AuditFinding f, AppStore store) {
    final (color, soft, label) = switch (f.severity) {
      AuditSeverity.high => (AppColors.danger, AppColors.dangerSoft, '높음'),
      AuditSeverity.medium => (AppColors.accent, AppColors.accentSoft, '보통'),
      AuditSeverity.low => (AppColors.textSecondary, AppColors.bg, '낮음'),
    };
    final staff = [for (final id in f.staffIds) ?store.staffById(id)];
    final small = AppText.style(13, FontWeight.w400, AppColors.textSecondary)
        .copyWith(height: 20 / 13);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Pill(label, color: color, background: soft),
            const SizedBox(width: 8),
            Expanded(child: Text(f.title, style: AppText.style(14, FontWeight.w500))),
          ]),
          if (f.detail.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(f.detail, style: small),
          ],
          if (f.action.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('할 일 · ${f.action}',
                style: AppText.style(13, FontWeight.w500).copyWith(height: 20 / 13)),
          ],
          if (staff.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final s in staff)
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => showStaffSheet(context, s.id),
                  child: Pill(store.personOf(s).name,
                      color: AppColors.textPrimary, background: AppColors.bg),
                ),
            ]),
          ],
          CitationChips(f.citations),
        ],
      ),
    );
  }

  Widget _chat() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_msgs.isEmpty)
            Text('궁금한 노무 질문을 아래에 입력하거나 오른쪽 추천 질문을 눌러 보세요.',
                style: AppText.style(14, FontWeight.w400, AppColors.textSecondary)),
          for (final (q, a) in _msgs) ...[
            Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                      color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                  child: Text(q,
                      style: AppText.style(15, FontWeight.w400, AppColors.onPrimary)
                          .copyWith(height: 22 / 15)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                decoration: BoxDecoration(
                    color: AppColors.bg, borderRadius: BorderRadius.circular(16)),
                child: a == null
                    ? Text('답변을 만들고 있어요...',
                        style: AppText.style(14, FontWeight.w400, AppColors.textTertiary))
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        SelectableText(a.answer,
                            style: AppText.style(14).copyWith(height: 23 / 14)),
                        CitationChips(a.citations),
                      ]),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      );

  @override
  Widget build(BuildContext context) {
    final remote = AppScope.read(context).remote;
    return WebPage(
        title: 'AI 노무 도우미',
        subtitle: 'AI 기반 · 5인 미만 사업장 노무 질의응답',
        children: [
          if (!remote)
          const NoteBox('추후 개발 예정인 기능이에요. 아래 화면은 예시예요.',
              color: AppColors.accent, background: AppColors.accentSoft),
          WebSplit(
            rightWidth: 320,
            gap: 20,
            left: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (remote && _audit != null) ...[_auditResult(_audit!), const SizedBox(height: 20)],
              AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: remote ? [_chat(), const SizedBox(height: 120), _inputBar()] : [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16)),
                      child: Text('5인 미만 사업장도 주휴수당을 줘야 하나요?',
                          style: AppText.style(15, FontWeight.w400, AppColors.onPrimary)
                              .copyWith(height: 22 / 15)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                      decoration: BoxDecoration(
                          color: AppColors.bg, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('네, 주휴수당은 사업장 규모와 상관없이 적용돼요.',
                              style: AppText.style(16, FontWeight.w500)
                                  .copyWith(height: 24 / 16)),
                          const SizedBox(height: 10),
                          Text(
                            '1주 소정근로시간이 15시간 이상이고 소정근로일을 개근한 근로자에게는 유급 주휴일을 부여해야 해요. 5인 미만 사업장도 동일하게 적용돼요.',
                            style: AppText.style(14, FontWeight.w400, AppColors.textSecondary)
                                .copyWith(height: 23 / 14),
                          ),
                          const SizedBox(height: 10),
                          const Pill('근로기준법 제55조',
                              color: AppColors.info, background: AppColors.infoSoft),
                        ],
                      ),
                    ),
                  ),
                  // 대화가 쌓일 빈 공간(Figma 의 flex spacer).
                  const SizedBox(height: 320),
                  _inputBar(),
                ],
              ),
            ),
            ]),
            right: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (remote) ...[_auditCard(), const SizedBox(height: 20)],
                  Text('추천 질문', style: AppText.style(15, FontWeight.w500)),
                  for (final q in _suggestions) ...[
                    const SizedBox(height: 12),
                    AppCard(
                      color: AppColors.bg,
                      radius: 12,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      onTap: () => _input.text = q,
                      child: Text(q,
                          style: AppText.style(13, FontWeight.w500)
                              .copyWith(height: 19 / 13)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  AppCard(
                    color: AppColors.accentSoft,
                    radius: 12,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Text('AI 답변은 참고용이에요. 중요한 판단은 노무사 확인을 권장해요.',
                        style: AppText.style(12, FontWeight.w400, AppColors.accent)
                            .copyWith(height: 18 / 12)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
  }

  Widget _inputBar() {
    final remote = AppScope.read(context).remote;
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 18, right: 5),
      decoration: BoxDecoration(
          color: AppColors.bg, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _input,
            maxLength: 1000,
            onSubmitted: remote ? (_) => _send() : null,
            style: AppText.style(14),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              counterText: '', // 52px 입력 줄이라 글자 수 표시는 숨긴다
              hintText: '궁금한 노무 질문을 입력하세요',
              hintStyle: AppText.style(
                  14, FontWeight.w400, AppColors.textTertiary),
            ),
          ),
        ),
        const SizedBox(width: 10),
        WebButton('보내기', onPressed: remote ? (_loading ? null : _send) : _input.clear),
      ]),
    );
  }
}
