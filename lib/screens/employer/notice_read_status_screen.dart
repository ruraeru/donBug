import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'notice_result_screen.dart';

/// 필독 확인 현황.
class NoticeReadStatusScreen extends StatefulWidget {
  const NoticeReadStatusScreen({super.key, required this.noticeId});

  final String noticeId;

  @override
  State<NoticeReadStatusScreen> createState() => _NoticeReadStatusScreenState();
}

class _NoticeReadStatusScreenState extends State<NoticeReadStatusScreen> {
  bool _sending = false;

  /// 서버는 재알림 뒤 1시간 동안 다시 알리지 않는다(409 REMIND_TOO_SOON).
  static const remindCooldown = Duration(hours: 1);

  Future<void> _remind(Notice n, List<String> names) async {
    final store = AppScope.read(context);
    if (!store.remote) {
      store.remindUnread(n.id);
    } else {
      setState(() => _sending = true);
      try {
        await store.api!.post('/api/v1/stores/${n.storeId}/notices/${n.id}/remind');
      } catch (e) {
        if (mounted) {
          setState(() => _sending = false);
          showToast(context, e is ApiException ? e.message : '서버와 통신하지 못했어요');
        }
        return;
      }
      await store.refreshNow(quiet: true);
      if (!mounted) return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => NoticeResultScreen(NoticeResult.reminded, noticeId: n.id, remindedNames: names)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final n = store.noticeById(widget.noticeId);
    if (n == null) return const MissingScreen(title: '필독 확인 현황');
    final read = noticeReaders(store, n)
      ..sort((a, b) => n.readBy[a.id]!.compareTo(n.readBy[b.id]!));
    final unread = store.unreadStaffOf(n);
    // 분모 = 확인한 재직 직원 + 확인 대상인 미확인자(가입 전 공지는 대상 아님). 공지 목록과 같은 규칙.
    final total = read.length + unread.length;
    final ratio = total == 0 ? 0.0 : read.length / total;
    final remindedAt = DateTime.tryParse(n.remindedAt ?? '');
    final waitMin = remindedAt == null
        ? 0
        : (remindCooldown - store.now.difference(remindedAt)).inMinutes + 1;
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
                    Text('${read.length} / $total명 (${(ratio * 100).round()}%)',
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
        if (unread.isEmpty || !n.required)
          AppButton('닫기', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(context))
        else if (waitMin > 0 && waitMin <= remindCooldown.inMinutes)
          AppButton('$waitMin분 뒤에 다시 알릴 수 있어요', variant: AppButtonVariant.outline)
        else
          AppButton(
            _sending ? '알리는 중…' : '미확인자에게 리마인드',
            onPressed: _sending
                ? null
                : () => _remind(n, unread.map((s) => store.personOf(s).name).toList()),
          ),
      ]),
    );
  }
}

/// 공지를 확인한 지금 매장 재직 직원.
List<Staff> noticeReaders(AppStore store, Notice n) =>
    store.activeStaff.where((s) => n.readBy.containsKey(s.id)).toList();
