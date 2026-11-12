import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'store_code_screen.dart';

/// 근무 매장 전환. 바꾸면 홈·근무표·급여·공지가 모두 그 매장 기준이 된다.
class StoreSwitchScreen extends StatelessWidget {
  const StoreSwitchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final mine = store.state.staff
        .where((s) =>
            s.personId == store.session.employeeId &&
            (s.active || s.status == StaffStatus.pending))
        .toList();
    return Scaffold(
      appBar: const AppHeader('근무 매장'),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        itemCount: mine.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final m = mine[i];
          final st = store.storeById(m.storeId)!;
          final selected = st.id == store.session.employeeStoreId;
          final pending = m.status == StaffStatus.pending;
          const fg = AppColors.textSecondary, bg = AppColors.bg;
          return Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: selected
                  ? const BorderSide(color: AppColors.primary, width: 2)
                  : const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: pending || selected
                  ? null
                  : () {
                      AppScope.read(context).switchStore(st.id);
                      Navigator.pop(context);
                      showToast(context, '${st.name}(으)로 전환했어요');
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    LetterAvatar(st.name.substring(0, 1), color: fg, background: bg),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(st.name, style: AppText.style(16, FontWeight.w500)),
                          Text(
                              pending
                                  ? '가입 승인 대기 중'
                                  : '${m.part} · 시급 ${wonText(m.wage)}',
                              style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    if (selected) ...[const SizedBox(width: 12), Text('현재', style: AppText.style(13, FontWeight.w400, AppColors.textSecondary))],
                    if (pending) ...[const SizedBox(width: 12), const Pill.accent('승인 대기')],
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomBar(
        child: AppButton(
          '매장 코드로 추가 가입',
          variant: AppButtonVariant.outline,
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const StoreCodeScreen(addMode: true))),
        ),
      ),
    );
  }
}
