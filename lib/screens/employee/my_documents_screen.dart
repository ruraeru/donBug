import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'contract_sign_screen.dart';
import 'health_cert_register_screen.dart';
import 'payslip_detail_screen.dart';

/// 내 서류: 보건증 · 근로계약서 · 급여 명세서.
class MyDocumentsScreen extends StatelessWidget {
  const MyDocumentsScreen({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final p = store.person(store.session.employeeId);
    final me = store.myStaff!;
    final days = store.certDaysLeft(p);
    final c = me.contract;
    final joined = parseYmd(me.joinedAt);
    final months = (store.today.year - joined.year) * 12 + store.today.month - joined.month + 1;
    return Scaffold(
      appBar: const AppHeader('내 서류'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          _DocCard(
            title: '보건증',
            chip: certPill(days),
            description: p.certExpiry == null
                ? '등록된 보건증이 없어요'
                : '만료일 ${dotDate(parseYmd(p.certExpiry!))}${p.certHasPhoto ? ' · 사진 등록됨' : ''}'
                    '${days != null && days <= 30 ? ' · 갱신 후 새 사진을 등록하세요' : ''}',
            button: AppButton(
              p.certExpiry == null ? '보건증 등록하기' : '갱신본 등록하기',
              variant: AppButtonVariant.soft,
              onPressed: () => _push(context, const HealthCertRegisterScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _DocCard(
            title: '전자 근로계약서',
            chip: c == null
                ? const Pill('없음', color: AppColors.textSecondary, background: AppColors.bg)
                : c.signed
                    ? const Pill('서명 완료')
                    : const Pill.accent('서명 필요'),
            description: c == null
                ? '사장님이 계약서를 보내면 여기서 서명해요'
                : '${dotDate(parseYmd(c.start))} ~ ${dotDate(parseYmd(c.end))} · '
                    '${c.signed ? '양쪽 서명 완료' : '사장님 서명 완료'}',
            button: c == null
                ? null
                : AppButton(
                    c.signed ? '계약서 보기' : '확인하고 서명하기',
                    variant: c.signed ? AppButtonVariant.outline : AppButtonVariant.primary,
                    onPressed: () => _push(context, const ContractSignScreen()),
                  ),
          ),
          const SizedBox(height: 16),
          _DocCard(
            title: '급여 명세서',
            chip: Pill('${months.clamp(1, 12)}건',
                color: AppColors.textSecondary, background: AppColors.bg),
            description: '${store.store.name} 월별 명세서를 열람할 수 있어요',
            button: AppButton(
              '이번 달 명세서 보기',
              variant: AppButtonVariant.outline,
              onPressed: () => _push(
                  context,
                  PayslipDetailScreen(
                      month: DateTime(store.today.year, store.today.month))),
            ),
          ),
        ],
      ),
    );
  }
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
                Expanded(child: Text(title, style: AppText.style(17, FontWeight.w500))),
                chip,
              ],
            ),
            const SizedBox(height: 12),
            Text(description, style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
            if (button != null) ...[const SizedBox(height: 12), button!],
          ],
        ),
      );
}
