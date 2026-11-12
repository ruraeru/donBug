import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/demo_menu.dart';

/// 매장 설정.
class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final st = store.store;
    final toggles = [
      ('5인 미만 사업장', '가산수당(야간·8시간 초과) 적용 기준', st.isSmall,
          (bool v) => store.updateStore(isSmall: v)),
      ('공지 필독 기본 설정', '새 공지는 기본으로 필독 지정', st.noticeRequiredDefault,
          (bool v) => store.updateStore(noticeRequiredDefault: v)),
      ('대타 알림 푸시', '동료에게 대타 요청 알림 (사장님 알림은 유지)', st.substitutePush,
          (bool v) => store.updateStore(substitutePush: v)),
    ];
    return Scaffold(
      appBar: const AppHeader('매장 설정'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(st.name, style: AppText.style(18, FontWeight.w500)),
                const SizedBox(height: 12),
                Text(st.address, style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text('매장 코드',
                          style: AppText.style(14, FontWeight.w400, AppColors.textSecondary)),
                    ),
                    Text(st.code, style: AppText.style(15, FontWeight.w500, AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
          for (final (title, sub, value, onChanged) in toggles) ...[
            const SizedBox(height: 12),
            ToggleCard(title: title, subtitle: sub, value: value, onChanged: onChanged),
          ],
          const SizedBox(height: 12),
          PersonRow(
            avatar: const LetterAvatar('로', color: AppColors.textSecondary, background: AppColors.bg),
            title: '로그아웃',
            trailing: const AppIcon('chevron_right', size: 20, color: AppColors.textTertiary),
            onTap: () => logoutToLogin(context),
          ),
          const SizedBox(height: 24),
          const DemoMenu(),
        ],
      ),
    );
  }
}
