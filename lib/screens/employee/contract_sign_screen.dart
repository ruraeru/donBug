import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employee_widgets.dart';

/// 전자 근로계약서 확인 · 서명.
class ContractSignScreen extends StatelessWidget {
  const ContractSignScreen({super.key});

  static const _terms = [
    ('근무 장소', '카페 커푸치노'),
    ('업무 내용', '홀 서빙'),
    ('소정근로시간', '주 15시간'),
    ('임금', '시급 10,030원'),
    ('휴일', '주휴일 일요일'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('전자 근로계약서'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('표준 근로계약서', style: AppText.style(17, FontWeight.w700)),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  for (final (label, value) in _terms) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(label,
                            style: AppText.style(14, FontWeight.w400, AppColors.textSecondary)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(value,
                              textAlign: TextAlign.right,
                              style: AppText.style(14, FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 110,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('여기에 서명해주세요',
                  style: AppText.style(14, FontWeight.w400, AppColors.textTertiary)),
            ),
            const SizedBox(height: 16),
            const CheckLine('계약 내용을 모두 확인했어요'),
          ],
        ),
        bottomNavigationBar: BottomBar(
          child: AppButton('서명하고 제출', onPressed: () => Navigator.pop(context)),
        ),
      );
}
