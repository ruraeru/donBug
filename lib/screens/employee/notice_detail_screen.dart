import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'employee_notice_screen.dart';

/// 공지 상세. 필독이 아니면 열면 읽음, 필독이면 '확인했어요'로 읽음.
class NoticeDetailScreen extends StatefulWidget {
  const NoticeDetailScreen({super.key, required this.noticeId});

  final String noticeId;

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = AppScope.read(context);
      final n = store.noticeById(widget.noticeId);
      if (n != null && !n.required) store.markNoticeRead(n.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final n = store.noticeById(widget.noticeId);
    if (n == null) return const MissingScreen(title: '공지');
    final read = store.isNoticeReadByMe(n);
    final active = store.activeStaff.length;
    final readCount = active - store.unreadStaffOf(n).length;
    return Scaffold(
      appBar: const AppHeader('공지'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    noticeTags(n),
                    const SizedBox(width: 8),
                    Text('${noticeTime(n)} · 사장님',
                        style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(n.title, style: AppText.style(20, FontWeight.w500)),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Text(n.body, style: AppText.style(15).copyWith(height: 1.6)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Text('확인 현황',
                      style: AppText.style(14, FontWeight.w500, AppColors.textSecondary)),
                ),
                Text('$readCount / $active명',
                    style: AppText.style(14, FontWeight.w500, AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(
        child: read
            ? AppButton('확인 완료 · 닫기',
                variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(context))
            : AppButton(n.required ? '확인했어요 (필독)' : '확인했어요', onPressed: () {
                AppScope.read(context).markNoticeRead(n.id);
                Navigator.pop(context);
              }),
      ),
    );
  }
}
