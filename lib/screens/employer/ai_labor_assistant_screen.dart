import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'ai_answer_detail_screen.dart';

/// B6 AI 노무 도우미 (채팅).
class AiLaborAssistantScreen extends StatelessWidget {
  const AiLaborAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void openDetail() => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const AiAnswerDetailScreen()));
    final secondary =
        AppText.style(13, FontWeight.w400, AppColors.textSecondary)
            .copyWith(height: 1.5);

    return Scaffold(
      appBar: const AppHeader('AI 노무 도우미', actions: [
        Pill('Gemini', color: AppColors.info, background: AppColors.infoSoft),
        SizedBox(width: 16),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        children: [
          _Bubble(
            ai: true,
            child: Text('안녕하세요! 노동법이나 매장 관리, 궁금한 걸 편하게 물어보세요.',
                style: AppText.style(14)),
          ),
          const SizedBox(height: 14),
          _Bubble(
            ai: false,
            child: Text('5인 미만 사업장인데 주휴수당 꼭 줘야 하나요?',
                style: AppText.style(14, FontWeight.w500, AppColors.onPrimary)),
          ),
          const SizedBox(height: 14),
          _Bubble(
            ai: true,
            onTap: openDetail,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('네, 주휴수당은 5인 미만 사업장도 줘야 해요.',
                    style: AppText.style(14, FontWeight.w700)),
                const SizedBox(height: 10),
                Text('· 주 15시간 이상 일하고 정해진 근무일을 개근하면 발생해요', style: secondary),
                Text('· 연장·야간·휴일 가산수당(1.5배)은 5인 미만이면 적용되지 않아요',
                    style: secondary),
                const SizedBox(height: 10),
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
                              11, FontWeight.w700, AppColors.info)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('근로기준법 제55조 · 제11조',
                            style: AppText.style(
                                11, FontWeight.w400, AppColors.textTertiary)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('내 매장 설정(5인 미만)에 맞춰 급여 계산에 반영 중이에요',
                      style: AppText.style(
                          12, FontWeight.w500, AppColors.primary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('이런 것도 물어보세요',
              style: AppText.style(12, FontWeight.w500, AppColors.textTertiary)),
          const SizedBox(height: 14),
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
            20, 10, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
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
                        onTap: () {},
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: Text('↑',
                                style: AppText.style(16, FontWeight.w700,
                                    AppColors.onPrimary)),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Text(label,
                style: AppText.style(
                    12, FontWeight.w500, AppColors.textSecondary)),
          ),
        ),
      );
}
