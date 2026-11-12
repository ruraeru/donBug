import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_parts.dart';
import 'notice_read_status_screen.dart';
import 'notice_result_screen.dart';

/// B3 공지 작성 (사장님 공지 탭 루트).
class EmployerNoticeScreen extends StatefulWidget {
  const EmployerNoticeScreen({super.key});

  @override
  State<EmployerNoticeScreen> createState() => _EmployerNoticeScreenState();
}

class _EmployerNoticeScreenState extends State<EmployerNoticeScreen> {
  static const _categories = ['일반', '중요', '노무'];

  final _title = TextEditingController();
  final _body = TextEditingController();
  int _category = 0;
  bool? _required;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _publish(AppStore store) {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      return showToast(context, '제목과 내용을 입력해 주세요');
    }
    final n = AppScope.read(context).publishNotice(
      title: _title.text.trim(),
      body: _body.text.trim(),
      required: _required ?? store.store.noticeRequiredDefault,
      category: _categories[_category],
    );
    _title.clear();
    _body.clear();
    setState(() => _required = null);
    FocusScope.of(context).unfocus();
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => NoticeResultScreen(NoticeResult.published, noticeId: n.id)));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final required = _required ?? store.store.noticeRequiredDefault;
    final notices = [...store.storeNotices]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final targets = store.activeStaff.length;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(child: Text('공지', style: AppText.style(24, FontWeight.w500))),
                const Pill('새 공지'),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Input(controller: _title, hint: '제목', style: AppText.style(16, FontWeight.w500)),
                        const SizedBox(height: 12),
                        _Input(
                          controller: _body,
                          hint: '내용을 입력해 주세요',
                          style: AppText.style(14).copyWith(height: 1.5),
                          maxLines: null,
                        ),
                        const SizedBox(height: 12),
                        SegmentedPicker(
                          options: _categories,
                          selected: _category,
                          onChanged: (i) => setState(() => _category = i),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => setState(() => _required = !required),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('필독 (확인 여부 추적)',
                                    style: AppText.style(13, FontWeight.w500, AppColors.textSecondary)),
                              ),
                              AppToggle(required),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text('발송 대상',
                                  style: AppText.style(13, FontWeight.w500, AppColors.textSecondary)),
                            ),
                            Pill('전체 근로자 $targets명'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AppButton('전체 발송', onPressed: () => _publish(store)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('최근 공지', style: AppText.style(15, FontWeight.w500)),
                        if (notices.isEmpty) const EmptyNote('보낸 공지가 없어요'),
                        for (var i = 0; i < notices.length; i++) ...[
                          if (i > 0)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1, color: AppColors.border),
                            )
                          else
                            const SizedBox(height: 12),
                          _NoticeRow(store: store, notice: notices[i], targets: targets),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({required this.controller, required this.hint, required this.style, this.maxLines = 1});

  final TextEditingController controller;
  final String hint;
  final TextStyle style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        style: style,
        maxLines: maxLines,
        minLines: maxLines == null ? 3 : 1,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: style.copyWith(color: AppColors.textTertiary),
          isDense: true,
          filled: true,
          fillColor: AppColors.bg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      );
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({required this.store, required this.notice, required this.targets});

  final AppStore store;
  final Notice notice;
  final int targets;

  @override
  Widget build(BuildContext context) {
    final read = targets - store.unreadStaffOf(notice).length;
    final all = read >= targets;
    final label = '읽음 $read/$targets';
    return InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => NoticeReadStatusScreen(noticeId: notice.id))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${notice.required ? '[필독] ' : ''}${notice.title}',
                    style: AppText.style(14, FontWeight.w500), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(relative(DateTime.parse(notice.createdAt), store.now),
                    style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          all ? Pill(label) : Pill.accent(label),
        ],
      ),
    );
  }
}
