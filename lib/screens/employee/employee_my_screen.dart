import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employee_widgets.dart';
import 'login_screen.dart';
import 'my_documents_screen.dart';
import 'notification_center_screen.dart';
import 'store_switch_screen.dart';

/// MY (탭 루트): 프로필 · 매장 전환 · 내 서류 · 알림 · 로그아웃.
class EmployeeMyScreen extends StatelessWidget {
  const EmployeeMyScreen({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final chevron =
        Text('›', style: AppText.style(22, FontWeight.w400, AppColors.textTertiary));
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        children: [
          Text('MY', style: AppText.style(24, FontWeight.w700)),
          const SizedBox(height: 18),
          AppCard(
            child: Row(
              children: [
                const LetterAvatar('태',
                    color: AppColors.primary, background: AppColors.primarySoft),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('김태우', style: AppText.style(18, FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('알바생 · 카페 커푸치노',
                          style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AvatarRow(
            avatar: const LetterAvatar('매',
                color: AppColors.primary, background: AppColors.primarySoft),
            title: '근무 매장 전환',
            subtitle: '카페 커푸치노 외 1곳',
            trailing: chevron,
            onTap: () => _push(context, const StoreSwitchScreen()),
          ),
          const SizedBox(height: 12),
          AvatarRow(
            avatar: const LetterAvatar('서', color: kInfo, background: kInfoSoft),
            title: '내 서류',
            subtitle: '보건증 · 근로계약서',
            trailing: chevron,
            onTap: () => _push(context, const MyDocumentsScreen()),
          ),
          const SizedBox(height: 12),
          AvatarRow(
            avatar: const LetterAvatar('알',
                color: AppColors.accent, background: AppColors.accentSoft),
            title: '알림 설정',
            subtitle: '대타 · 공지 · 만료 알림',
            trailing: chevron,
            // shortcut: 알림 설정 화면이 디자인에 없어 알림 센터로 연결, 설정 화면 생기면 교체.
            onTap: () => _push(context, const NotificationCenterScreen()),
          ),
          const SizedBox(height: 12),
          AvatarRow(
            avatar: const LetterAvatar('로',
                color: AppColors.textSecondary, background: AppColors.bg),
            title: '로그아웃',
            trailing: chevron,
            onTap: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false),
          ),
        ],
      ),
    );
  }
}
