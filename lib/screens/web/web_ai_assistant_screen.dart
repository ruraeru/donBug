import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_common.dart';

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

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WebPage(
        title: 'AI 노무 도우미',
        subtitle: 'Gemini 기반 · 5인 미만 사업장 노무 질의응답',
        children: [
          WebSplit(
            rightWidth: 320,
            gap: 20,
            left: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              style: AppText.style(16, FontWeight.w700)
                                  .copyWith(height: 24 / 16)),
                          const SizedBox(height: 10),
                          Text(
                            '1주 소정근로시간이 15시간 이상이고 소정근로일을 개근한 근로자에게는 유급 주휴일을 부여해야 해요. 5인 미만 사업장도 동일하게 적용돼요.',
                            style: AppText.style(14, FontWeight.w400, AppColors.textSecondary)
                                .copyWith(height: 23 / 14),
                          ),
                          const SizedBox(height: 10),
                          const Pill('근로기준법 제55조',
                              color: WebColors.info, background: WebColors.infoSoft),
                        ],
                      ),
                    ),
                  ),
                  // 대화가 쌓일 빈 공간(Figma 의 flex spacer).
                  const SizedBox(height: 320),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.only(left: 18, right: 5),
                    decoration: BoxDecoration(
                        color: AppColors.bg, borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          style: AppText.style(14),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: '궁금한 노무 질문을 입력하세요',
                            hintStyle: AppText.style(
                                14, FontWeight.w400, AppColors.textTertiary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      WebButton('보내기', onPressed: _input.clear),
                    ]),
                  ),
                ],
              ),
            ),
            right: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('추천 질문', style: AppText.style(15, FontWeight.w700)),
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
