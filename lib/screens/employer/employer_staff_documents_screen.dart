import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_health_cert_alert_screen.dart';
import 'payroll_docs_widgets.dart';

/// 직원 서류 상세 (Figma 48:269).
class EmployerStaffDocumentsScreen extends StatelessWidget {
  const EmployerStaffDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('수빈 · 서류'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            AppCard(
              child: Column(
                children: [
                  _header('보건증',
                      const Pill('만료 D-12', color: kDanger, background: kDangerSoft)),
                  const SizedBox(height: 12),
                  Container(
                    height: 110,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text('보건증 사진',
                        style: AppText.style(
                            13, FontWeight.w400, AppColors.textTertiary)),
                  ),
                  const SizedBox(height: 12),
                  const LabelValueRow('만료일', '2026.05.26', bold: true),
                  const SizedBox(height: 12),
                  AppButton(
                    '갱신 요청 보내기',
                    verticalPadding: 17,
                    // 완료 화면은 뒤로가기 대신 "서류 목록으로"로 끝나므로 교체.
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EmployerHealthCertAlertScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                children: [
                  _header('근로계약서', const Pill('서명 완료')),
                  const SizedBox(height: 10),
                  const LabelValueRow('계약 기간', '2026.05.01 ~ 2027.04.30'),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _header(String title, Widget chip) => Row(
        children: [
          Expanded(child: Text(title, style: AppText.style(17, FontWeight.w700))),
          chip,
        ],
      );
}
