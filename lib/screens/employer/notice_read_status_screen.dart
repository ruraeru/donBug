import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'notice_result_screen.dart';

/// 필독 확인 현황.
class NoticeReadStatusScreen extends StatelessWidget {
  const NoticeReadStatusScreen({super.key, required this.noticeId});

  final String noticeId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final n = store.noticeById(noticeId);
    if (n == null) return const MissingScreen(title: '필독 확인 현황');
    final staff = store.activeStaff;
    final read = staff.where((s) => n.readBy.containsKey(s.id)).toList()
      ..sort((a, b) => n.readBy[a.id]!.compareTo(n.readBy[b.id]!));
    final unread = store.unreadStaffOf(n);
    final ratio = staff.isEmpty ? 0.0 : read.length / staff.length;
    final section = AppText.style(14, FontWeight.w500, AppColors.textSecondary);
    const unreadPill = Pill('미확인', color: AppColors.danger, background: AppColors.dangerSoft);

    return Scaffold(
      appBar: const AppHeader('필독 확인 현황'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          Text(n.title, style: AppText.style(17, FontWeight.w500)),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('확인율',
                          style: AppText.style(14, FontWeight.w400, AppColors.textSecondary)),
                    ),
                    Text('${read.length} / ${staff.length}명 (${(ratio * 100).round()}%)',
                        style: AppText.style(14, FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 10,
                    color: AppColors.primary,
                    backgroundColor: AppColors.bg,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('확인함', style: section),
          if (read.isEmpty) const EmptyNote('아직 확인한 사람이 없어요'),
          for (final s in read) ...[
            const SizedBox(height: 12),
            PersonRow(
              avatar: MemberAvatar(s),
              title: store.personOf(s).name,
              subtitle: '${relative(DateTime.parse(n.readBy[s.id]!), store.now)} 확인',
            ),
          ],
          const SizedBox(height: 12),
          Text('미확인', style: section),
          if (unread.isEmpty) const EmptyNote('모두 확인했어요'),
          for (final s in unread) ...[
            const SizedBox(height: 12),
            PersonRow(
              avatar: MemberAvatar(s),
              title: store.personOf(s).name,
              subtitle: '아직 확인 안 함',
              trailing: unreadPill,
            ),
          ],
        ],
      ),
      bottomNavigationBar: BottomBar(children: [
        if (unread.isEmpty)
          AppButton('닫기', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(context))
        else
          AppButton(
            '미확인자에게 리마인드',
            onPressed: () {
              final names = unread.map((s) => store.personOf(s).name).toList();
              AppScope.read(context).remindUnread(n.id);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => NoticeResultScreen(NoticeResult.reminded,
                        noticeId: n.id, remindedNames: names)),
              );
            },
          ),
      ]),
    );
  }
}
