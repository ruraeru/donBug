import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/demo_menu.dart';
import 'employer_parts.dart';

/// 직원 가입 승인 (Figma 47:100). 온보딩 마지막 → EmployerShell.
class StaffApprovalScreen extends StatelessWidget {
  const StaffApprovalScreen({super.key});

  Future<void> _approve(BuildContext context, Staff s) async {
    final store = AppScope.read(context);
    final r = await showWageDialog(context,
        title: '${store.personOf(s).name}님 시급 설정',
        wage: s.wage,
        deduction: store.store.defaultDeduction);
    if (r == null || !context.mounted) return;
    AppScope.read(context).approveJoin(s.id, wage: r.$1, deduction: r.$2);
    showToast(context, '${store.personOf(s).name}님 가입을 승인했어요');
  }

  Future<void> _reject(BuildContext context, Staff s) async {
    final name = AppScope.read(context).personOf(s).name;
    final ok = await showConfirmDialog(context,
        title: '$name님 가입을 거절할까요?',
        message: '거절하면 다시 매장 코드로 신청해야 해요.',
        confirmLabel: '거절',
        confirmVariant: AppButtonVariant.danger);
    if (ok && context.mounted) AppScope.read(context).rejectJoin(s.id);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final requests = store.pendingStaff;
    return Scaffold(
      appBar: AppHeader('가입 신청 ${requests.length}건'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          if (requests.isEmpty) const EmptyNote('대기 중인 가입 신청이 없어요'),
          for (final s in requests) ...[
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      MemberAvatar(s),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(store.personOf(s).fullName, style: AppText.style(16, FontWeight.w500)),
                            if (s.requestedAt != null)
                              Text(
                                  '${relative(DateTime.parse(s.requestedAt!), store.now)} 신청',
                                  style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Pill('알바생', color: AppColors.textSecondary, background: AppColors.bg),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                          child: SmallButton.outline('거절', onPressed: () => _reject(context, s))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: SmallButton('승인하고 시급 설정',
                              onPressed: () => _approve(context, s))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
      bottomNavigationBar: BottomBar(children: [
        AppButton('대시보드로 이동', onPressed: () => openShell(context, Role.employer)),
      ]),
    );
  }
}
