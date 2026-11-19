import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/demo_menu.dart';
import '../profile_edit_screen.dart';
import '../web/web_view_mode.dart';
import 'store_info_edit_screen.dart';

/// 매장 설정.
class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  void _push(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  /// '10:00 – 익일 02:00'
  static String _hours(int open, int close) =>
      '${hm(open)} – ${close > 1440 ? '익일 ${hm(close)}' : close == 1440 ? '24:00' : hm(close)}';

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
                KeyValueRow('평일 영업', _hours(st.openMin, st.closeMin)),
                const SizedBox(height: 8),
                KeyValueRow('주말·공휴일 영업', _hours(st.weekendOpenMin, st.weekendCloseMin)),
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
          const SizedBox(height: 12),
          PersonRow(
            avatar: const LetterAvatar('정', color: AppColors.textSecondary, background: AppColors.bg),
            title: '매장 정보 수정',
            subtitle: '이름 · 주소 · 영업시간',
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
            onTap: () => _push(const StoreInfoEditScreen()),
          ),
          const SizedBox(height: 12),
          PersonRow(
            avatar: LetterAvatar(store.me.letter, person: store.me),
            title: '내 프로필',
            subtitle: [store.me.fullName, ?store.me.contact].join(' · '),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
            onTap: () => _push(const ProfileEditScreen()),
          ),
          for (final (title, sub, value, onChanged) in toggles) ...[
            const SizedBox(height: 12),
            ToggleCard(title: title, subtitle: sub, value: value, onChanged: onChanged),
          ],
          if (kIsWeb && AppScope.of(context).remote) ...[
            const SizedBox(height: 12),
            PersonRow(
              avatar: const LetterAvatar('P', color: AppColors.textSecondary, background: AppColors.bg),
              title: 'PC 화면으로',
              subtitle: '웹 사장님 대시보드로 바꿔요',
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
              onTap: () => openPcView(context),
            ),
          ],
          const SizedBox(height: 12),
          PersonRow(
            avatar: const LetterAvatar('로', color: AppColors.textSecondary, background: AppColors.bg),
            title: '로그아웃',
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
            onTap: () => logoutToLogin(context),
          ),
          const SizedBox(height: 24),
          const DemoMenu(),
        ],
      ),
    );
  }
}
