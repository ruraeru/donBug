import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_widgets.dart';
import 'notice_result_screen.dart';

/// 필독 확인 현황.
class NoticeReadStatusScreen extends StatelessWidget {
  const NoticeReadStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const unread = Pill('미확인',
        color: EmpColors.danger, background: EmpColors.dangerSoft);
    final section =
        AppText.style(14, FontWeight.w700, AppColors.textSecondary);

    return Scaffold(
      appBar: const AppHeader('필독 확인 현황'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('확인율',
                          style: AppText.style(
                              14, FontWeight.w400, AppColors.textSecondary)),
                    ),
                    Text('3 / 5명 (60%)',
                        style: AppText.style(
                            14, FontWeight.w700, AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: const LinearProgressIndicator(
                    value: 0.6,
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
          const SizedBox(height: 12),
          const PersonRow(
              avatar: InitialAvatar('지'), title: '지민', subtitle: '10:02 확인'),
          const SizedBox(height: 12),
          const PersonRow(
            avatar: InitialAvatar('수',
                color: AppColors.accent, background: AppColors.accentSoft),
            title: '수빈',
            subtitle: '10:15 확인',
          ),
          const SizedBox(height: 12),
          const PersonRow(
            avatar: InitialAvatar('태',
                color: EmpColors.info, background: EmpColors.infoSoft),
            title: '태우',
            subtitle: '14:03 확인',
          ),
          const SizedBox(height: 12),
          Text('미확인', style: section),
          const SizedBox(height: 12),
          const PersonRow(
            avatar: InitialAvatar('하',
                color: AppColors.accent, background: AppColors.accentSoft),
            title: '하윤',
            subtitle: '아직 확인 안 함',
            trailing: unread,
          ),
          const SizedBox(height: 12),
          const PersonRow(
            avatar: InitialAvatar('서',
                color: EmpColors.info, background: EmpColors.infoSoft),
            title: '서연',
            subtitle: '아직 확인 안 함',
            trailing: unread,
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(children: [
        AppButton(
          '미확인자에게 리마인드',
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const NoticeResultScreen(NoticeResult.reminded)),
          ),
        ),
      ]),
    );
  }
}
