import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../employer/employer_notice_screen.dart';
import 'web_common.dart';

/// W6 공지 관리 (콘텐츠 영역). 목록에서 고르면 오른쪽에 확인 현황이 나온다.
class WebNoticeScreen extends StatefulWidget {
  const WebNoticeScreen({super.key});

  @override
  State<WebNoticeScreen> createState() => _WebNoticeScreenState();
}

class _WebNoticeScreenState extends State<WebNoticeScreen> {
  String? _selectedId;

  Widget _tag(bool required) => required
      ? const Pill('필독', color: AppColors.danger, background: AppColors.dangerSoft)
      : const Pill('일반', color: AppColors.textSecondary, background: AppColors.bg);

  /// 공지 작성은 모바일 공지 탭(작성 폼 + 목록)을 패널로 연다.
  void _write() => showMobilePanel(
      context, const Scaffold(backgroundColor: AppColors.bg, body: EmployerNoticeScreen()));

  void _remind(Notice n) {
    final count = AppScope.read(context).remindUnread(n.id);
    showToast(context, '$count명에게 다시 알렸어요');
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final notices = store.storeNotices;
    final staff = store.activeStaff;
    final current = store.noticeById(_selectedId) ?? notices.firstOrNull;
    double ratio(Notice n) => staff.isEmpty
        ? 0
        : staff.where((s) => n.readBy.containsKey(s.id)).length / staff.length;
    return WebPage(
      title: '공지 관리',
      subtitle: '매장 전체 공지와 필독 확인 현황',
      actions: [WebButton('+ 공지 작성', onPressed: _write)],
      children: [
        if (current == null)
          const AppCard(child: EmptyNote('아직 올린 공지가 없어요'))
        else
          WebSplit(
            leftWidth: 460,
            gap: 20,
            breakpoint: 1000,
            left: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('공지 목록', style: AppText.style(16, FontWeight.w700)),
                  for (final n in notices) ...[
                    const SizedBox(height: 12),
                    _NoticeItem(
                      tag: _tag(n.required),
                      title: n.title,
                      ratio: ratio(n),
                      selected: n.id == current.id,
                      onTap: () => setState(() => _selectedId = n.id),
                    ),
                  ],
                ],
              ),
            ),
            right: _detail(store, current, staff),
          ),
      ],
    );
  }

  Widget _detail(AppStore store, Notice n, List<Staff> staff) {
    final unread = store.unreadStaffOf(n).length;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(n.title, style: AppText.style(20, FontWeight.w700))),
            _tag(n.required),
          ]),
          const SizedBox(height: 4),
          Text('${n.category} · ${relative(DateTime.parse(n.createdAt), store.now)}',
              style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
          const SizedBox(height: 16),
          Text(
            n.body,
            style: AppText.style(14, FontWeight.w400, AppColors.textSecondary)
                .copyWith(height: 22 / 14),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: Text('확인 현황 ${staff.length - unread} / ${staff.length}명',
                    style: AppText.style(15, FontWeight.w700))),
            if (unread > 0)
              WebButton('미확인자 리마인드',
                  style: WebButtonStyle.soft, onPressed: () => _remind(n)),
          ]),
          for (final s in staff) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Expanded(
                    child: Text(store.personOf(s).name,
                        style: AppText.style(14, FontWeight.w700))),
                n.readBy[s.id] == null
                    ? const Pill('미확인',
                        color: AppColors.danger, background: AppColors.dangerSoft)
                    : Pill('${clock(DateTime.parse(n.readBy[s.id]!))} 확인'),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoticeItem extends StatelessWidget {
  const _NoticeItem({
    required this.tag,
    required this.title,
    required this.ratio,
    required this.selected,
    required this.onTap,
  });

  final Widget tag;
  final String title;
  final double ratio;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? AppColors.primarySoft : AppColors.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: selected ? const BorderSide(color: AppColors.primary) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(children: [
              Row(children: [
                tag,
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: AppText.style(14, FontWeight.w700))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('확인 ${(ratio * 100).round()}%',
                    style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
              ]),
            ]),
          ),
        ),
      );
}
