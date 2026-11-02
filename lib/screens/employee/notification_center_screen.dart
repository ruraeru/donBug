import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employee_widgets.dart';

/// 알림 센터 (홈 종 아이콘에서 push).
class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  static const _items = [
    ('대', AppColors.primary, AppColors.primarySoft, '대타 승인 완료', '5/14 18:00–22:00 근무표에 반영됐어요', '방금'),
    ('공', kInfo, kInfoSoft, '새 필독 공지', '5월 마감 청소 방법 안내', '1시간 전'),
    ('건', kDanger, kDangerSoft, '보건증 만료 D-12', '갱신본을 등록해주세요', '어제'),
    ('급', AppColors.accent, AppColors.accentSoft, '4월 급여 확정', '실수령액 ₩812,430', '5/10'),
    ('지', AppColors.primary, AppColors.primarySoft, '하윤님이 대타에 지원했어요', '5/16 10:00–16:00', '5/9'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('알림'),
        body: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final (letter, fg, bg, title, sub, time) = _items[i];
            return AvatarRow(
              avatar: LetterAvatar(letter, color: fg, background: bg),
              title: title,
              subtitle: sub,
              trailing: Text(time,
                  style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
            );
          },
        ),
      );
}
