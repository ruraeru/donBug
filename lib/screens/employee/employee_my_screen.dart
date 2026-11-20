import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/demo_menu.dart';
import '../employer/ai_labor_assistant_screen.dart';
import '../profile_edit_screen.dart';
import 'my_documents_screen.dart';
import 'notification_center_screen.dart';
import 'store_switch_screen.dart';

/// MY (탭 루트): 프로필 · 매장 전환 · 내 서류 · AI 노무 도우미(서버 모드) · 알림 · 로그아웃.
class EmployeeMyScreen extends StatelessWidget {
  const EmployeeMyScreen({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final p = store.person(store.session.employeeId);
    final others = store.myMemberships.length - 1;
    final docAlert = (store.certDaysLeft(p) ?? -1) <= 30 ||
        (store.myStaff?.contract != null && !store.myStaff!.contract!.signed);
    const chevron = Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        children: [
          Text('MY', style: AppText.style(24, FontWeight.w500)),
          const SizedBox(height: 16),
          AppCard(
            onTap: () => _push(context, const ProfileEditScreen()),
            child: Row(
              children: [
                LetterAvatar(p.letter,
                    color: AppColors.primary, background: AppColors.primarySoft, person: p),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.fullName, style: AppText.style(18, FontWeight.w500)),
                      if (p.contact != null) ...[
                        const SizedBox(height: 2),
                        Text(p.contact!,
                            style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
                      ],
                      const SizedBox(height: 2),
                      Text('알바생 · ${store.store.name}',
                          style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
                    ],
                  ),
                ),
                chevron,
              ],
            ),
          ),
          const SizedBox(height: 12),
          PersonRow(
            avatar: const LetterAvatar('매',
                color: AppColors.textSecondary, background: AppColors.bg),
            title: '근무 매장 전환',
            subtitle: others > 0 ? '${store.store.name} 외 $others곳' : store.store.name,
            trailing: chevron,
            onTap: () => _push(context, const StoreSwitchScreen()),
          ),
          const SizedBox(height: 12),
          PersonRow(
            avatar: const LetterAvatar('서',
                color: AppColors.textSecondary, background: AppColors.bg),
            title: '내 서류',
            subtitle: '보건증 · 근로계약서',
            trailing: docAlert ? const Pill.accent('확인 필요') : chevron,
            onTap: () => _push(context, const MyDocumentsScreen()),
          ),
          // 데모의 AI 화면은 사장님용 예시라 서버 모드에서만 보인다.
          if (store.remote) ...[
            const SizedBox(height: 12),
            PersonRow(
              avatar: const LetterAvatar('AI',
                  color: AppColors.textSecondary, background: AppColors.bg),
              title: 'AI 노무 도우미',
              subtitle: '주휴수당 · 휴게 · 급여 질문',
              trailing: chevron,
              onTap: () => _push(context, const AiLaborAssistantScreen()),
            ),
          ],
          const SizedBox(height: 12),
          PersonRow(
            avatar: const LetterAvatar('알',
                color: AppColors.textSecondary, background: AppColors.bg),
            title: '알림 설정',
            subtitle: '대타 · 공지 · 만료 알림',
            trailing: chevron,
            // shortcut: 알림 설정 화면이 디자인에 없어 알림 센터로 연결, 설정 화면 생기면 교체.
            onTap: () => _push(context, const NotificationCenterScreen()),
          ),
          const SizedBox(height: 12),
          PersonRow(
            avatar: const LetterAvatar('로',
                color: AppColors.textSecondary, background: AppColors.bg),
            title: '로그아웃',
            trailing: chevron,
            onTap: () => logoutToLogin(context),
          ),
          const SizedBox(height: 24),
          const DemoMenu(),
        ],
      ),
    );
  }
}
