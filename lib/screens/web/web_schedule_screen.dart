import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_common.dart';

/// W2 근무표 편집 (콘텐츠 영역).
class WebScheduleScreen extends StatelessWidget {
  const WebScheduleScreen({super.key});

  static const _days = ['월 12', '화 13', '수 14', '목 15', '금 16', '토 17', '일 18'];

  // 시프트별 요일 칸 배정. 빈 리스트 = 인원 부족.
  static const _shifts = <(String, String, Color, Color, List<List<String>>)>[
    ('오픈', '10–16', AppColors.primary, AppColors.primarySoft, [
      ['지민', '수빈'], ['수빈'], ['지민', '수빈'], ['도현'], ['지민'], ['수빈'], [],
    ]),
    ('미들', '14–20', AppColors.info, AppColors.infoSoft, [
      ['서연'], ['하윤', '서연'], ['하윤'], ['서연'], ['도현', '서연'], ['하윤'], ['서연'],
    ]),
    ('마감', '18–22', AppColors.accent, AppColors.accentSoft, [
      ['하윤'], ['도현'], ['하윤'], ['하윤'], ['하윤'], ['도현'], ['도현'],
    ]),
  ];

  static const _staff = <(String, String, Color, Color)>[
    ('지민', '주 18h', AppColors.primary, AppColors.primarySoft),
    ('수빈', '주 22h', AppColors.accent, AppColors.accentSoft),
    ('하윤', '주 20h', AppColors.info, AppColors.infoSoft),
    ('도현', '주 16h', AppColors.danger, AppColors.dangerSoft),
    ('서연', '주 20h', AppColors.primary, AppColors.primarySoft),
  ];

  @override
  Widget build(BuildContext context) => WebPage(
        title: '근무표 편집',
        subtitle: '2026.5.12 – 5.18 · 직원을 끌어다 칸에 놓으면 배정돼요',
        actions: const [
          WebButton('템플릿 복사', style: WebButtonStyle.outline),
          WebButton('저장'),
        ],
        children: [
          WebSplit(
            rightWidth: 280,
            gap: 20,
            left: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Column(children: [
                SizedBox(
                  height: 30,
                  child: Row(children: [
                    const SizedBox(width: 84),
                    for (final d in _days) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: d == '수 14' ? AppColors.primary : null,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            d,
                            style: d == '수 14'
                                ? AppText.style(13, FontWeight.w700, AppColors.onPrimary)
                                : AppText.style(
                                    13, FontWeight.w400, AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ]),
                ),
                for (final (name, time, fg, bg, cells) in _shifts) ...[
                  const SizedBox(height: 10),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                      width: 84,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: AppText.style(15, FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(time,
                                style: AppText.style(
                                    12, FontWeight.w400, AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                    for (final people in cells) ...[
                      const SizedBox(width: 8),
                      Expanded(child: _Slot(people, fg, bg)),
                    ],
                  ]),
                ],
              ]),
            ),
            right: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('직원 (끌어서 배정)', style: AppText.style(15, FontWeight.w700)),
                  for (final (name, hours, fg, bg) in _staff) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        WebAvatar(name.substring(0, 1), color: fg, background: bg),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(name, style: AppText.style(14, FontWeight.w700))),
                        Text(hours,
                            style: AppText.style(
                                12, FontWeight.w400, AppColors.textSecondary)),
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

class _Slot extends StatelessWidget {
  const _Slot(this.people, this.fg, this.bg);

  final List<String> people;
  final Color fg, bg;

  @override
  Widget build(BuildContext context) => Container(
        height: 150,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: people.isEmpty ? Border.all(color: AppColors.danger) : null,
        ),
        child: people.isEmpty
            ? Text('인원 부족',
                textAlign: TextAlign.center,
                style: AppText.style(11, FontWeight.w400, AppColors.danger))
            : Column(children: [
                for (final p in people) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    margin: const EdgeInsets.only(bottom: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: bg, borderRadius: BorderRadius.circular(8)),
                    child: Text(p,
                        maxLines: 1, style: AppText.style(12, FontWeight.w700, fg)),
                  ),
                ],
              ]),
      );
}
