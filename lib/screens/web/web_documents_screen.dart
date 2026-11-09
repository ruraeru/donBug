import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../employer/employer_contract_write_screen.dart';
import '../employer/employer_staff_documents_screen.dart';
import 'web_common.dart';

/// 노무 체크리스트: (항목, 완료?). 모두 매장 데이터에서 판정한다.
List<(String, bool)> laborChecklist(AppStore store) {
  final staff = store.activeStaff;
  return [
    ('근로계약서 서면 교부', staff.every((s) => s.contract?.signed ?? false)),
    ('4대보험·3.3% 공제 설정', staff.every((s) => s.deduction != Deduction.none)),
    // shortcut: 상시 근로자 수를 지금 재직 인원으로 근사. 정확히 하려면 월 평균 인원이 필요하다.
    ('5인 미만 사업장 설정 확인', store.store.isSmall == (staff.length < 5)),
    ('보건증 만료 관리', staff.every((s) => (store.certDaysLeft(store.personOf(s)) ?? -1) > 30)),
    ('급여명세서 교부 (앱 자동)', true),
  ];
}

/// W5 서류·컴플라이언스 (콘텐츠 영역).
class WebDocumentsScreen extends StatelessWidget {
  const WebDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final items = laborChecklist(store);
    final staff = store.activeStaff;
    return WebPage(
      title: '서류 · 컴플라이언스',
      subtitle: '보건증 · 근로계약서 · 5인 미만 사업장 체크리스트',
      actions: [
        WebButton('+ 계약서 작성',
            onPressed: () => showMobilePanel(context, const EmployerContractWriteScreen())),
      ],
      children: [
        WebSplit(
          leftWidth: 420,
          gap: 20,
          breakpoint: 1000,
          left: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                      child: Text('노무 체크리스트', style: AppText.style(16, FontWeight.w700))),
                  Pill.accent('${items.where((x) => x.$2).length} / ${items.length} 완료'),
                ]),
                for (final (label, done) in items) ...[
                  const SizedBox(height: 16),
                  Row(children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: done ? AppColors.primary : AppColors.surface,
                        shape: BoxShape.circle,
                        border: done ? null : Border.all(color: AppColors.border),
                      ),
                      child: done
                          ? Text('✓',
                              style: AppText.style(13, FontWeight.w700, AppColors.onPrimary))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: AppText.style(14, FontWeight.w500,
                            done ? AppColors.textPrimary : AppColors.textSecondary),
                      ),
                    ),
                  ]),
                ],
              ],
            ),
          ),
          right: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('직원별 서류', style: AppText.style(16, FontWeight.w700)),
                const SizedBox(height: 14),
                if (staff.isEmpty) const EmptyNote('재직 중인 직원이 없어요'),
                WebTable(
                  columns: const ['직원', '보건증', '만료일', '근로계약서'],
                  flex: const [170, 170, 130, 160],
                  onRowTap: (i) => showMobilePanel(
                      context, EmployerStaffDocumentsScreen(staffId: staff[i].id)),
                  rows: [
                    for (final s in staff)
                      [
                        webStaffCell(store, s),
                        certPill(store.certDaysLeft(store.personOf(s))),
                        webCellText(store.personOf(s).certExpiry == null
                            ? '-'
                            : dotDate(parseYmd(store.personOf(s).certExpiry!))),
                        contractPill(s.contract),
                      ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 근로계약서 상태 칩.
Pill contractPill(Contract? c) => switch (c) {
      null => Pill.accent('미작성'),
      Contract(signed: true) => const Pill('서명 완료'),
      _ => Pill.accent('서명 대기'),
    };
