import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_signature_request_screen.dart';

/// 근로계약서 작성 (Figma 48:425).
class EmployerContractWriteScreen extends StatelessWidget {
  const EmployerContractWriteScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('근로계약서 작성'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            AppCard(
              child: Row(
                children: [
                  const LetterAvatar('서',
                      size: 40, color: AppColors.info, background: AppColors.infoSoft),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('이서연', style: AppText.style(16, FontWeight.w700)),
                        Text('표준 근로계약서 템플릿',
                            style: AppText.style(
                                12, FontWeight.w400, AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const Pill('신규', color: AppColors.info, background: AppColors.infoSoft),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const LabeledField('계약 기간', child: FieldBox('2026.05.15 ~ 2027.05.14')),
            const SizedBox(height: 14),
            const LabeledField('시급', child: FieldBox('10,030원')),
            const SizedBox(height: 14),
            const LabeledField('소정근로시간', child: FieldBox('주 15시간 (화·목·토 14:00–19:00)')),
            const SizedBox(height: 14),
            AppCard(
              color: AppColors.primarySoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('AI 노무 점검',
                            style: AppText.style(
                                14, FontWeight.w700, AppColors.primary)),
                      ),
                      const Pill('누락 항목 없음'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '근무 장소 · 업무 내용 · 소정근로시간 · 임금 · 휴일 필수 5개 항목이 모두 입력됐어요.',
                    style: AppText.style(13, FontWeight.w400, AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomBar.button(
          '서명 요청 보내기',
          // 완료 화면의 "서류 목록으로"가 한 번 pop으로 B2에 닿도록 교체.
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const EmployerSignatureRequestScreen()),
          ),
        ),
      );
}
