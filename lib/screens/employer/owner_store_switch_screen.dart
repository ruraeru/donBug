import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'store_create_screen.dart';
import 'store_settings_screen.dart';

/// 사장님 매장 전환. 소유 매장 목록 + 지금 매장 설정 + 새 매장 추가(서버 모드).
class OwnerStoreSwitchScreen extends StatelessWidget {
  const OwnerStoreSwitchScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final store = AppScope.read(context);
    final before = store.session.ownerStoreId;
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const StoreCreateScreen(addMode: true)));
    // 새 매장을 만들었으면 그 매장으로 바뀌어 있다. 전환 화면도 닫는다.
    if (context.mounted && store.session.ownerStoreId != before) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final owned = store.ownedStores;
    return Scaffold(
      appBar: const AppHeader('내 매장'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          for (final st in owned) ...[
            Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: st.id == store.store.id
                    ? const BorderSide(color: AppColors.primary, width: 2)
                    : const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: st.id == store.store.id
                    ? null
                    : () {
                        if (!AppScope.read(context).switchOwnerStore(st.id)) {
                          return showToast(context, '저장하지 않은 근무표 변경 사항이 있어요');
                        }
                        Navigator.pop(context);
                        showToast(context, '${st.name} 매장으로 전환했어요');
                      },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    LetterAvatar(st.name.substring(0, 1),
                        color: AppColors.textSecondary, background: AppColors.bg),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(st.name, style: AppText.style(16, FontWeight.w500)),
                        Text(st.code,
                            style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                      ]),
                    ),
                    if (st.id == store.store.id)
                      Text('현재', style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
      bottomNavigationBar: BottomBar(children: [
        AppButton(
          '${store.store.name} 매장 설정',
          variant: AppButtonVariant.outline,
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const StoreSettingsScreen())),
        ),
        // 데모 사장님은 1인 1매장 (매장 만들기가 기존 매장을 바꾼다).
        if (store.remote) AppButton('새 매장 추가', onPressed: () => _add(context)),
      ]),
    );
  }
}
