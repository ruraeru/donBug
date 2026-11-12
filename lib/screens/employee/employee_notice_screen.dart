import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'notice_detail_screen.dart';

/// A7 공지 수신함 (탭 루트).
class EmployeeNoticeScreen extends StatefulWidget {
  const EmployeeNoticeScreen({super.key});

  @override
  State<EmployeeNoticeScreen> createState() => _EmployeeNoticeScreenState();
}

class _EmployeeNoticeScreenState extends State<EmployeeNoticeScreen> {
  int _filter = 0;

  void _openDetail(Notice n) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => NoticeDetailScreen(noticeId: n.id)));

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final all = store.storeNotices;
    final unread = store.unreadNoticeCount;
    final filters = ['전체', '중요', '안 읽음 $unread'];
    final shown = switch (_filter) {
      1 => all.where((n) => n.required || n.category == '중요').toList(),
      2 => all.where((n) => !store.isNoticeReadByMe(n)).toList(),
      _ => all,
    };
    final pinned = shown.where((n) => n.pinned).toList();
    final rest = shown.where((n) => !n.pinned).toList();
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(child: Text('공지', style: AppText.style(24, FontWeight.w500))),
                GestureDetector(
                  onTap: unread == 0 ? null : () => AppScope.read(context).markAllNoticesRead(),
                  child: Text('모두 읽음',
                      style: AppText.style(14, FontWeight.w500,
                          unread == 0 ? AppColors.textTertiary : AppColors.primary)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              children: [
                Row(
                  children: [
                    for (var i = 0; i < filters.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      _FilterChip(
                        filters[i],
                        selected: i == _filter,
                        onTap: () => setState(() => _filter = i),
                      ),
                    ],
                  ],
                ),
                if (shown.isEmpty) const EmptyNote('공지가 없어요'),
                for (final n in pinned) ...[
                  const SizedBox(height: 12),
                  _pinnedCard(store, n),
                ],
                for (final n in rest) ...[
                  const SizedBox(height: 12),
                  _NoticeCard(
                    tag: noticeTags(n),
                    title: n.title,
                    body: n.body,
                    meta: '사장님 · ${noticeTime(n)}',
                    status: _readStatus(store, n),
                    read: store.isNoticeReadByMe(n),
                    onTap: () => _openDetail(n),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _readStatus(AppStore store, Notice n) {
    final at = n.readBy[store.myStaff?.id];
    return at == null
        ? Text('안 읽음',
            style: AppText.style(
                12, FontWeight.w500, n.required ? AppColors.danger : AppColors.textSecondary))
        : Text('읽음 · ${noticeTime(n, at: at)}',
            style: AppText.style(12, FontWeight.w400, AppColors.textSecondary));
  }

  Widget _pinnedCard(AppStore store, Notice n) {
    final read = store.isNoticeReadByMe(n);
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(n),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  noticeTags(n),
                  const SizedBox(width: 6),
                  const Pill('상단 고정', color: AppColors.textSecondary, background: AppColors.bg),
                ],
              ),
              const SizedBox(height: 12),
              Text(n.title, style: AppText.style(17, FontWeight.w500)),
              const SizedBox(height: 12),
              Text(n.body, style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
              const SizedBox(height: 12),
              _MetaRow('사장님 · ${noticeTime(n)}', _readStatus(store, n)),
              if (!read) ...[
                const SizedBox(height: 12),
                AppButton('확인했어요',
                    verticalPadding: 12,
                    fontSize: 15,
                    onPressed: () => AppScope.read(context).markNoticeRead(n.id)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 공지 카테고리 칩 (+ 필독).
Widget noticeTags(Notice n) {
  final (fg, bg) = switch (n.category) {
    '중요' => (AppColors.onPrimary, AppColors.accent),
    _ => (AppColors.textSecondary, AppColors.bg),
  };
  return Row(mainAxisSize: MainAxisSize.min, children: [
    Pill(n.category, color: fg, background: bg),
    if (n.required) ...[
      const SizedBox(width: 6),
      const Pill('필독', color: AppColors.danger, background: AppColors.dangerSoft),
    ],
  ]);
}

/// '5/14 09:12'
String noticeTime(Notice n, {String? at}) {
  final t = DateTime.parse(at ?? n.createdAt);
  return '${t.month}/${t.day} ${clock(t)}';
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(this.label, {required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            border: selected ? null : Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: selected
                ? AppText.style(13, FontWeight.w500, AppColors.onPrimary)
                : AppText.style(13, FontWeight.w500, AppColors.textSecondary),
          ),
        ),
      );
}

class _MetaRow extends StatelessWidget {
  const _MetaRow(this.meta, this.status);

  final String meta;
  final Widget status;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(meta,
                style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
          ),
          status,
        ],
      );
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.tag,
    required this.title,
    required this.body,
    required this.meta,
    required this.status,
    required this.onTap,
    this.read = false,
  });

  final Widget tag;
  final String title;
  final String body;
  final String meta;
  final Widget status;
  final VoidCallback onTap;
  final bool read;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tag,
            const SizedBox(height: 8),
            Text(
              title,
              style: AppText.style(
                  16, FontWeight.w500, read ? AppColors.textSecondary : AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: AppText.style(13, FontWeight.w400,
                  read ? AppColors.textTertiary : AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            _MetaRow(meta, status),
          ],
        ),
      );
}
