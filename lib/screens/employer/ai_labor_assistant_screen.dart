import 'package:flutter/material.dart';

import '../../data/ai_api.dart';
import '../../data/app_scope.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'ai_answer_detail_screen.dart';

/// B6 AI 노무 도우미 (채팅). 사장님·알바생이 같이 쓴다(알바생은 MY 탭, 서버 모드만).
class AiLaborAssistantScreen extends StatefulWidget {
  const AiLaborAssistantScreen({super.key});

  @override
  State<AiLaborAssistantScreen> createState() => _AiLaborAssistantScreenState();
}

class _Msg {
  _Msg(this.question);

  final String question;
  AiAnswer? answer;
}

class _AiLaborAssistantScreenState extends State<AiLaborAssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _msgs = <_Msg>[];
  bool _loading = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final q = (preset ?? _input.text).trim();
    if (q.isEmpty || _loading) return;
    final store = AppScope.read(context);
    final msg = _Msg(q);
    setState(() {
      _msgs.add(msg);
      _loading = true;
    });
    _input.clear();
    _toEnd();
    try {
      final r = await askLaborQuestion(store.api!, store.session.storeId, q);
      msg.answer = r;
    } catch (e) {
      if (mounted) showToast(context, aiErrorText(e));
      _msgs.remove(msg);
      if (_input.text.isEmpty) _input.text = q;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    _toEnd();
  }

  void _toEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent + 200,
              duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      });

  @override
  Widget build(BuildContext context) {
    final remote = AppScope.read(context).remote;
    void openDetail([_Msg? m]) => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => m == null
                ? const AiAnswerDetailScreen()
                : AiAnswerDetailScreen(
                    question: m.question,
                    answer: m.answer?.answer,
                    citations: m.answer?.citations ?? const [])));
    final secondary =
        AppText.style(13, FontWeight.w400, AppColors.textSecondary)
            .copyWith(height: 1.5);

    return Scaffold(
      appBar: AppHeader('AI 노무 도우미', actions: [
        Text('AI',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(width: 16),
      ]),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        children: remote ? _serverChat(openDetail) : [
          const NoteBox('추후 개발 예정인 기능이에요. 아래 화면은 예시예요.',
              color: AppColors.accent, background: AppColors.accentSoft),
          const SizedBox(height: 16),
          _Bubble(
            ai: true,
            child: Text('노동법이나 매장 관리, 궁금한 걸 편하게 물어보세요.',
                style: AppText.style(14)),
          ),
          const SizedBox(height: 16),
          _Bubble(
            ai: false,
            child: Text('5인 미만 사업장인데 주휴수당 꼭 줘야 하나요?',
                style: AppText.style(14, FontWeight.w500, AppColors.onPrimary)),
          ),
          const SizedBox(height: 16),
          _Bubble(
            ai: true,
            onTap: openDetail,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('네, 주휴수당은 5인 미만 사업장도 줘야 해요.',
                    style: AppText.style(14, FontWeight.w500)),
                const SizedBox(height: 12),
                Text('· 주 15시간 이상 일하고 정해진 근무일을 개근하면 발생해요', style: secondary),
                Text('· 연장·야간·휴일 가산수당(1.5배)은 5인 미만이면 적용되지 않아요',
                    style: secondary),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text('근거',
                          style: AppText.style(
                              11, FontWeight.w500, AppColors.textSecondary)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('근로기준법 제55조 · 제11조',
                            style: AppText.style(
                                11, FontWeight.w400, AppColors.textTertiary)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('내 매장 설정(5인 미만)에 맞춰 급여 계산에 반영 중이에요',
                      style: AppText.style(
                          12, FontWeight.w400, AppColors.textSecondary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('이런 것도 물어보세요',
              style: AppText.style(12, FontWeight.w500, AppColors.textTertiary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Suggestion('4대보험 가입 기준은?', onTap: openDetail),
              _Suggestion('근로계약서 안 쓰면?', onTap: openDetail),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: AppColors.surface,
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI 답변은 참고용이며 법률 자문이 아니에요. 중요한 판단은 노무사와 상담하세요.',
                  style: AppText.style(
                      11, FontWeight.w400, AppColors.textTertiary)),
              const SizedBox(height: 8),
              Container(
                height: 48,
                padding: const EdgeInsets.only(left: 16, right: 6),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        enabled: !remote || !_loading,
                        textInputAction: TextInputAction.send,
                        onSubmitted: remote ? (_) => _send() : null,
                        maxLength: remote ? 1000 : null,
                        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                        style: AppText.style(14),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: '노무·매장 관리 질문을 입력하세요',
                          hintStyle: AppText.style(
                              14, FontWeight.w400, AppColors.textTertiary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: AppColors.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: remote ? _send : () {},
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: const Icon(Icons.arrow_upward_rounded,
                                size: 20, color: AppColors.onPrimary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 서버 모드 대화: 질문(오른쪽) → 로딩 → 답(왼쪽, 누르면 상세). 알바생이면 인사·추천 질문이 일하는 사람 쪽이다.
  List<Widget> _serverChat(void Function([_Msg?]) openDetail) {
    final employee = AppScope.read(context).session.role == Role.employee;
    return [
        _Bubble(
          ai: true,
          child: Text(
              employee
                  ? '주휴수당·휴게시간·급여처럼 일하면서 궁금한 걸 편하게 물어보세요.'
                  : '노동법이나 매장 관리, 궁금한 걸 편하게 물어보세요.',
              style: AppText.style(14)),
        ),
        for (final m in _msgs) ...[
          const SizedBox(height: 16),
          _Bubble(
            ai: false,
            child: Text(m.question,
                style: AppText.style(14, FontWeight.w500, AppColors.onPrimary)),
          ),
          const SizedBox(height: 16),
          if (m.answer != null)
            _Bubble(
              ai: true,
              onTap: () => openDetail(m),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.answer!.answer, style: AppText.style(14).copyWith(height: 1.5)),
                CitationChips(m.answer!.citations),
              ]),
            )
          else
            _Bubble(
              ai: true,
              child: Text('답변을 만들고 있어요...',
                  style: AppText.style(14, FontWeight.w400, AppColors.textTertiary)),
            ),
        ],
        if (_msgs.isEmpty) ...[
          const SizedBox(height: 16),
          Text('이런 것도 물어보세요',
              style: AppText.style(12, FontWeight.w500, AppColors.textTertiary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final q in employee
                  ? const ['저는 주휴수당 대상인가요?', '휴게시간은 얼마나 받아야 하나요?', '갑자기 그만두라고 하면 어떻게 하나요?']
                  : const ['주휴수당은 꼭 줘야 하나요?', '4대보험 가입 기준은?', '근로계약서 안 쓰면?'])
                _Suggestion(q, onTap: () => _send(q)),
            ],
          ),
        ],
      ];
  }
}

/// AI(왼쪽·흰색) / 사용자(오른쪽·primary) 말풍선. 최대 폭 310.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.ai, required this.child, this.onTap});

  final bool ai;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const r = Radius.circular(18);
    const tip = Radius.circular(4);
    return Align(
      alignment: ai ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: ai ? 310 : 250),
        child: Material(
          color: ai ? AppColors.surface : AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: ai ? tip : r,
            topRight: ai ? r : tip,
            bottomLeft: r,
            bottomRight: r,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion(this.label, {this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        shape: const StadiumBorder(side: BorderSide(color: AppColors.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(label,
                style: AppText.style(
                    12, FontWeight.w500, AppColors.textSecondary)),
          ),
        ),
      );
}
