import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../employer/staff_approval_screen.dart';
import '../employer/staff_detail_screen.dart';
import '../employer/store_code_screen.dart';
import 'web_common.dart';
import 'web_documents_screen.dart';

/// W3 직원 관리 (콘텐츠 영역). 가입 대기는 맨 위에 둔다.
class WebStaffScreen extends StatefulWidget {
  const WebStaffScreen({super.key});

  @override
  State<WebStaffScreen> createState() => _WebStaffScreenState();
}

class _WebStaffScreenState extends State<WebStaffScreen> {
  /// null = 전체, 아니면 파트 이름.
  String? _part;
  String _query = '';

  /// 서류 칸: 보건증 문제가 먼저, 그다음 계약서.
  Widget _docPill(AppStore store, Staff s) {
    final left = store.certDaysLeft(store.personOf(s));
    if (left == null || left <= 30) return certPill(left);
    if (!(s.contract?.signed ?? false)) return contractPill(s.contract);
    return const Pill('정상');
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final active = store.activeStaff;
    final pending = store.pendingStaff;
    final rows = [...pending, ...active]
        .where((s) => _part == null || s.part == _part)
        .where((s) => store.personOf(s).name.contains(_query.trim()))
        .toList();
    final filters = <(String?, String)>[
      (null, '전체 ${active.length}'),
      for (final p in store.store.parts)
        (p.name, '${p.name} ${active.where((s) => s.part == p.name).length}'),
    ];
    return WebPage(
      title: '직원 관리',
      subtitle: '재직 ${active.length}명 · 승인 대기 ${pending.length}명',
      actions: [
        WebButton('+ 직원 초대',
            onPressed: () => showMobilePanel(context, const StoreCodeScreen())),
      ],
      children: [
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Column(children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Container(
                  width: 300,
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                      color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: '이름 검색',
                      hintStyle: AppText.style(14, FontWeight.w400, AppColors.textTertiary),
                    ),
                    style: AppText.style(14),
                  ),
                ),
                Wrap(spacing: 8, children: [
                  for (final (part, label) in filters)
                    GestureDetector(
                      onTap: () => setState(() => _part = part),
                      child: part == _part
                          ? Pill(label)
                          : Pill(label,
                              color: AppColors.textSecondary, background: AppColors.bg),
                    ),
                ]),
              ],
            ),
            const SizedBox(height: 14),
            WebTable(
              columns: const ['이름', '파트', '시급', '공제', '서류', '상태', ''],
              flex: const [230, 120, 130, 150, 230, 120, 120],
              onRowTap: (i) => showMobilePanel(
                  context,
                  rows[i].active
                      ? StaffDetailScreen(staffId: rows[i].id)
                      : const StaffApprovalScreen()),
              rows: [
                for (final s in rows)
                  [
                    webStaffCell(store, s),
                    webCellText(s.part),
                    webCellText(s.active ? wonText(s.wage) : '-'),
                    webCellText(s.active ? s.deduction.short : '-'),
                    s.active ? _docPill(store, s) : webCellText('-'),
                    s.active ? const Pill('재직') : Pill.accent('승인 대기'),
                    webCellText(s.active ? '상세 ›' : '승인 ›'),
                  ],
              ],
            ),
            if (rows.isEmpty) const EmptyNote('조건에 맞는 직원이 없어요'),
          ]),
        ),
      ],
    );
  }
}
