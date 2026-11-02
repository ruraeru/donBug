import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_contract_write_screen.dart';
import 'employer_staff_documents_screen.dart';
import 'payroll_docs_widgets.dart';

/// B2 서류·컴플라이언스 (Figma 48:179, 계약서 variant 48:335). 탭 루트.
/// 두 variant는 화면이 같고 탭 가능한 카드만 다르다: 둘 다 연결했다.
class EmployerDocumentsScreen extends StatelessWidget {
  const EmployerDocumentsScreen({super.key});

  static const _checks = [
    ('근로계약서 작성 · 교부', true),
    ('최저임금 준수 (시급 10,320원)', true),
    ('주휴수당 지급', true),
    ('보건증 갱신 필요 · 1명', false),
  ];

  static const _workers = [
    ('지민', '보건증 정상', false),
    ('수빈', '보건증 D-12', true),
    ('현우', '보건증 정상', false),
  ];

  @override
  Widget build(BuildContext context) {
    void openStaff() => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmployerStaffDocumentsScreen()),
        );

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text('서류 · 컴플라이언스', style: AppText.style(22, FontWeight.w700)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                AppCard(
                  onTap: openStaff,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('노무 체크리스트',
                                style: AppText.style(15, FontWeight.w700)),
                          ),
                          const Pill('5인 미만 사업장',
                              color: kInfo, background: kInfoSoft),
                        ],
                      ),
                      for (var i = 0; i < _checks.length; i++) ...[
                        if (i > 0) const Divider(height: 1, color: AppColors.border),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: _checkRow(_checks[i].$1, ok: _checks[i].$2),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  onTap: openStaff,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('근로자별 서류', style: AppText.style(15, FontWeight.w700)),
                      for (var i = 0; i < _workers.length; i++) ...[
                        if (i > 0) const Divider(height: 1, color: AppColors.border),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: _workerRow(_workers[i]),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  '전자 근로계약서 작성',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EmployerContractWriteScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkRow(String label, {required bool ok}) => Row(
        children: [
          AppIcon(ok ? 'check' : 'alert_circle', size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: ok
                    ? AppText.style(14)
                    : AppText.style(14, FontWeight.w700, kDanger)),
          ),
        ],
      );

  Widget _workerRow((String, String, bool) w) => Row(
        children: [
          Expanded(child: Text(w.$1, style: AppText.style(15, FontWeight.w700))),
          const Pill('계약서 완료',
              color: AppColors.textSecondary, background: AppColors.bg),
          const SizedBox(width: 6),
          w.$3
              ? Pill(w.$2, color: kDanger, background: kDangerSoft)
              : Pill(w.$2),
        ],
      );
}
