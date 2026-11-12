import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'my_documents_screen.dart';
import 'notice_detail_screen.dart';
import 'substitute_detail_screen.dart';
import 'substitute_status_screen.dart';

/// 알림 센터. 지금 역할(알바생/사장님)의 내 알림. 탭하면 읽음 + 관련 화면.
class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key, this.onOpen});

  /// 역할별로 알림을 열 화면을 정한다. null 을 돌려주면 읽음 처리만.
  /// 기본은 알바생 화면 연결.
  final Widget? Function(BuildContext context, AppNotification n)? onOpen;

  static (String, Color, Color) _style(String type) => switch (type) {
        'sub' => ('대', AppColors.textSecondary, AppColors.bg),
        'notice' => ('공', AppColors.textSecondary, AppColors.bg),
        'cert' => ('건', AppColors.danger, AppColors.dangerSoft),
        'pay' => ('급', AppColors.textSecondary, AppColors.bg),
        'join' => ('가', AppColors.textSecondary, AppColors.bg),
        'contract' => ('계', AppColors.textSecondary, AppColors.bg),
        _ => ('알', AppColors.textSecondary, AppColors.bg),
      };

  static Widget? employeeTarget(BuildContext context, AppNotification n) {
    final store = AppScope.read(context);
    switch (n.type) {
      case 'sub':
        final r = store.subById(n.refId);
        if (r == null) return null;
        return r.requesterId == store.myStaff?.id || r.status != SubStatus.open
            ? const SubstituteStatusScreen()
            : SubstituteDetailScreen(requestId: r.id);
      case 'notice':
        return store.noticeById(n.refId) == null ? null : NoticeDetailScreen(noticeId: n.refId!);
      case 'cert':
      case 'contract':
        return const MyDocumentsScreen();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final items = store.myNotifications;
    return Scaffold(
      appBar: AppHeader('알림', actions: [
        if (store.unreadNotificationCount > 0)
          TextButton(
            onPressed: () => AppScope.read(context).markAllNotificationsRead(),
            child: Text('모두 읽음', style: AppText.style(14, FontWeight.w500, AppColors.primary)),
          ),
      ]),
      body: items.isEmpty
          ? const EmptyNote('알림이 없어요')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final n = items[i];
                final (letter, fg, bg) = _style(n.type);
                return Opacity(
                  opacity: n.read ? 0.6 : 1,
                  child: PersonRow(
                    avatar: LetterAvatar(letter, color: fg, background: bg),
                    title: n.title,
                    subtitle: n.body.isEmpty ? null : n.body,
                    trailing: Text(relative(DateTime.parse(n.createdAt), store.now),
                        style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
                    onTap: () {
                      AppScope.read(context).markNotificationRead(n.id);
                      final page = (onOpen ?? employeeTarget)(context, n);
                      if (page != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
