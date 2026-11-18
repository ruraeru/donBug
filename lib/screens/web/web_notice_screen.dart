import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_common.dart';

/// W6 공지 관리 (콘텐츠 영역). 목록에서 고르면 오른쪽에 확인 현황이 나온다.
class WebNoticeScreen extends StatefulWidget {
  const WebNoticeScreen({super.key});

  @override
  State<WebNoticeScreen> createState() => _WebNoticeScreenState();
}

class _WebNoticeScreenState extends State<WebNoticeScreen> {
  String? _selectedId;
  bool _reminding = false;

  Widget _tag(bool required) => required
      ? const Pill('필독', color: AppColors.danger, background: AppColors.dangerSoft)
      : const Pill('일반', color: AppColors.textSecondary, background: AppColors.bg);

  Future<void> _write() async {
    final id = await showNoticeDialog(context);
    if (id != null && mounted) setState(() => _selectedId = id);
  }

  // 서버는 1시간에 한 번만 다시 알린다(REMIND_TOO_SOON). 그동안 버튼을 막는다.
  bool _remindCooling(AppStore store, Notice n) =>
      n.remindedAt != null &&
      store.now.difference(DateTime.parse(n.remindedAt!)) < const Duration(hours: 1);

  Future<void> _remind(Notice n) async {
    setState(() => _reminding = true);
    try {
      final count = await AppScope.read(context).remindUnreadRemote(n.id);
      if (mounted) showToast(context, '$count명에게 다시 알렸어요');
    } catch (e) {
      if (mounted) showToast(context, remoteErrorText(e));
    } finally {
      if (mounted) setState(() => _reminding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final notices = store.storeNotices;
    final staff = store.activeStaff;
    final current = store.noticeById(_selectedId) ?? notices.firstOrNull;
    // 분모·분자는 확인 현황과 같다: 가입 전 공지 대상이 아닌 직원은 확인한 것으로 친다.
    double ratio(Notice n) =>
        staff.isEmpty ? 0 : (staff.length - store.unreadStaffOf(n).length) / staff.length;
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
                  Text('공지 목록', style: AppText.style(16, FontWeight.w500)),
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
    final unreadIds = {for (final s in store.unreadStaffOf(n)) s.id};
    final unread = unreadIds.length;
    final cooling = _remindCooling(store, n);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(n.title, style: AppText.style(20, FontWeight.w500))),
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
                    style: AppText.style(15, FontWeight.w500))),
            if (unread > 0 && n.required)
              WebButton(_reminding ? '보내는 중…' : '미확인자 리마인드',
                  style: WebButtonStyle.soft,
                  tooltip: cooling ? '방금 알렸어요. 1시간 뒤에 다시 알릴 수 있어요' : null,
                  onPressed: _reminding || cooling ? null : () => _remind(n)),
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
                        style: AppText.style(14, FontWeight.w500))),
                n.readBy[s.id] != null
                    ? webCellText('${clock(DateTime.parse(n.readBy[s.id]!))} 확인')
                    : unreadIds.contains(s.id)
                        ? webCellText('미확인', color: AppColors.danger, weight: FontWeight.w500)
                        : webCellText('가입 전 공지'),
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
                Expanded(child: Text(title, style: AppText.style(14, FontWeight.w500))),
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
                SizedBox(
                  width: 56,
                  child: Text('확인 ${(ratio * 100).round()}%',
                      textAlign: TextAlign.right,
                      style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                ),
              ]),
            ]),
          ),
        ),
      );
}

/// 공지 작성 창. 올리면 새 공지 id 를 돌려준다.
Future<String?> showNoticeDialog(BuildContext context) {
  final store = AppScope.read(context);
  const categories = ['일반', '중요', '노무'];
  final title = TextEditingController(), body = TextEditingController();
  var category = categories.first;
  var required = store.store.noticeRequiredDefault;
  String? error;
  var sending = false; // 연타로 같은 공지가 두 번 올라가지 않게
  return showWebDialog<String>(
    context,
    title: '공지 작성',
    width: 560,
    builder: (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      webField('제목', AppTextField(controller: title, maxLength: 200, hint: '예: 마감 청소 방법 안내')),
      const SizedBox(height: 14),
      webField('내용', AppTextField(controller: body, maxLines: 6, maxLength: 5000, hint: '직원에게 알릴 내용을 적어 주세요')),
      const SizedBox(height: 14),
      Row(children: [
        WebSegmented(
          labels: categories,
          selected: categories.indexOf(category),
          onChanged: (i) => set(() => category = categories[i]),
        ),
        const Spacer(),
        InkWell(
          onTap: () => set(() => required = !required),
          child: Row(children: [
            Checkbox(
                value: required,
                activeColor: AppColors.primary,
                onChanged: (v) => set(() => required = v ?? false)),
            Text('필독 (확인 현황 추적)', style: AppText.style(14)),
          ]),
        ),
      ]),
      const SizedBox(height: 6),
      Text('재직 직원 ${store.activeStaff.length}명에게 알림이 가요',
          style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
      if (error != null) ...[
        const SizedBox(height: 10),
        Text(error!, style: AppText.style(13, FontWeight.w500, AppColors.danger)),
      ],
    ]),
    actions: (ctx, set) => [
      WebButton('취소', style: WebButtonStyle.outline, onPressed: () => Navigator.pop(ctx)),
      WebButton(sending ? '올리는 중…' : '올리기', onPressed: sending ? null : () async {
        if (title.text.trim().isEmpty || body.text.trim().isEmpty) {
          return set(() => error = '제목과 내용을 입력해 주세요');
        }
        set(() => sending = true);
        final Notice n;
        try {
          n = await store.publishNoticeRemote(
              title: title.text.trim(), body: body.text.trim(), required: required, category: category);
        } catch (e) {
          if (ctx.mounted) {
            set(() {
              sending = false;
              error = remoteErrorText(e);
            });
          }
          return;
        }
        if (!ctx.mounted) return;
        Navigator.pop(ctx, n.id);
        if (context.mounted) showToast(context, '공지를 올렸어요');
      }),
    ],
  );
}
