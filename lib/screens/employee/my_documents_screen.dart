import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'contract_sign_screen.dart';
import 'health_cert_register_screen.dart';

/// 내 서류: 보건증 · 근로계약서 · 급여 명세서.
class MyDocumentsScreen extends StatelessWidget {
  const MyDocumentsScreen({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('내 서류'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            _DocCard(
              title: '보건증',
              chip: const Pill('만료 D-12', color: AppColors.danger, background: AppColors.dangerSoft),
              description: '만료일 2026.05.26 · 갱신 후 새 사진을 등록하세요',
              button: AppButton(
                '갱신본 등록하기',
                variant: AppButtonVariant.soft,
                onPressed: () => _push(context, const HealthCertRegisterScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _DocCard(
              title: '전자 근로계약서',
              chip: const Pill.accent('서명 필요'),
              description: '2026.05.01 작성 · 사장님 서명 완료',
              button: AppButton(
                '확인하고 서명하기',
                onPressed: () => _push(context, const ContractSignScreen()),
              ),
            ),
            const SizedBox(height: 16),
            const _DocCard(
              title: '급여 명세서',
              chip: Pill('5건', color: AppColors.textSecondary, background: AppColors.bg),
              description: '월별 명세서를 PDF로 열람할 수 있어요',
            ),
          ],
        ),
      );
}

class _DocCard extends StatelessWidget {
  const _DocCard({
    required this.title,
    required this.chip,
    required this.description,
    this.button,
  });

  final String title;
  final Widget chip;
  final String description;
  final Widget? button;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: AppText.style(17, FontWeight.w700))),
                chip,
              ],
            ),
            const SizedBox(height: 12),
            Text(description,
                style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
            if (button != null) ...[const SizedBox(height: 12), button!],
          ],
        ),
      );
}
