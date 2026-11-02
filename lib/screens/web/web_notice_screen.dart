import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_common.dart';

/// W6 공지 관리 (콘텐츠 영역). 목록에서 고르면 오른쪽 상세 제목이 바뀐다.
class WebNoticeScreen extends StatefulWidget {
  const WebNoticeScreen({super.key});

  @override
  State<WebNoticeScreen> createState() => _WebNoticeScreenState();
}

class _WebNoticeScreenState extends State<WebNoticeScreen> {
  // (필독?, 제목, 확인율)
  static const _notices = [
    (true, '5월 마감 청소 방법 안내', 0.6),
    (false, '여름 신메뉴 레시피 변경', 1.0),
    (true, '5/20 영업시간 변경', 0.8),
    (true, '위생 점검 체크리스트', 1.0),
  ];

  // (이름, 확인 시각 · null = 미확인)
  static const _readers = [
    ('지민', '10:02 확인'),
    ('수빈', '10:15 확인'),
    ('태우', '14:03 확인'),
    ('하윤', null),
    ('서연', null),
  ];

  int _selected = 0;

  Widget _tag(bool required) => required
      ? const Pill('필독', color: WebColors.danger, background: WebColors.dangerSoft)
      : const Pill('일반', color: AppColors.textSecondary, background: AppColors.bg);

  @override
  Widget build(BuildContext context) {
    final current = _notices[_selected];
    return WebPage(
      title: '공지 관리',
      subtitle: '매장 전체 공지와 필독 확인 현황',
      actions: const [WebButton('+ 공지 작성')],
      children: [
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
                for (var i = 0; i < _notices.length; i++) ...[
                  const SizedBox(height: 12),
                  _NoticeItem(
                    tag: _tag(_notices[i].$1),
                    title: _notices[i].$2,
                    ratio: _notices[i].$3,
                    selected: i == _selected,
                    onTap: () => setState(() => _selected = i),
                  ),
                ],
              ],
            ),
          ),
          right: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                      child: Text(current.$2, style: AppText.style(20, FontWeight.w700))),
                  _tag(current.$1),
                ]),
                const SizedBox(height: 16),
                Text(
                  '5월부터 마감 근무자는 에스프레소 머신 세척 → 홀 바닥·테이블 소독 → 쓰레기 분리배출 순서로 청소해 주세요.',
                  style: AppText.style(14, FontWeight.w400, AppColors.textSecondary)
                      .copyWith(height: 22 / 14),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: AppColors.border),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: Text('확인 현황 3 / 5명',
                          style: AppText.style(15, FontWeight.w700))),
                  const WebButton('미확인자 리마인드', style: WebButtonStyle.soft),
                ]),
                for (final (name, time) in _readers) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                        color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Expanded(
                          child: Text(name, style: AppText.style(14, FontWeight.w700))),
                      time == null
                          ? const Pill('미확인',
                              color: WebColors.danger, background: WebColors.dangerSoft)
                          : Pill(time),
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
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
